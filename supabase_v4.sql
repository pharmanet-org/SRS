-- ============================================================
-- PharmaNet v4: Order Role Enforcement + Security Fixes
-- ============================================================
-- Run in Supabase SQL Editor after supabase_v3.sql and supabase_changes.sql.
-- All statements use DROP IF EXISTS / IF NOT EXISTS for safety.
-- ============================================================

-- ============================================================
-- PART 1: ORDERS RLS — Stricter enforcement
-- ============================================================
-- The existing `customer_own_orders` policy allows any authenticated
-- user (including sellers) to INSERT orders. We now restrict INSERT
-- to customers only, and update the SELECT policy to be explicit.

-- 1a. Drop existing order policies created by supabase_changes.sql
DROP POLICY IF EXISTS "customer_own_orders" ON public.orders;
DROP POLICY IF EXISTS "seller_view_involved_orders" ON public.orders;

-- 1b. Only customers can create orders (INSERT)
CREATE POLICY "customer_insert_orders" ON public.orders
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'customer'
    )
  );

-- 1c. Customers can view / update / delete their own orders
CREATE POLICY "customer_own_orders" ON public.orders
  FOR ALL
  USING (auth.uid() = user_id);

-- 1d. Sellers can SELECT orders containing their products (for management)
CREATE POLICY "seller_view_involved_orders" ON public.orders
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM public.order_items oi
      WHERE oi.order_id = orders.id
        AND oi.seller_id IN (
          SELECT id FROM public.sellers WHERE user_id = auth.uid()
        )
    )
  );

-- 1e. Sellers can UPDATE orders containing their products (for status management)
CREATE POLICY "seller_update_involved_orders" ON public.orders
  FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM public.order_items oi
      WHERE oi.order_id = orders.id
        AND oi.seller_id IN (
          SELECT id FROM public.sellers WHERE user_id = auth.uid()
        )
    )
  );

-- Ensure RLS is enabled (idempotent)
ALTER TABLE IF EXISTS public.orders ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- PART 2: ORDER_ITEMS RLS — Ensure sellers can manage their items
-- ============================================================

-- 2a. Drop then recreate to avoid duplicates
DROP POLICY IF EXISTS "seller_manage_own_order_items" ON public.order_items;

-- 2b. Sellers can read/update order items that belong to their products
CREATE POLICY "seller_manage_own_order_items" ON public.order_items
  FOR ALL
  USING (
    seller_id IN (
      SELECT id FROM public.sellers WHERE user_id = auth.uid()
    )
  );

-- ============================================================
-- PART 3: SELLER REVIEWS TABLE (if not already created by v3)
-- ============================================================

CREATE TABLE IF NOT EXISTS public.seller_reviews (
  id            uuid DEFAULT gen_random_uuid() PRIMARY KEY,
  seller_id     uuid NOT NULL REFERENCES public.sellers(id) ON DELETE CASCADE,
  user_id       uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  order_id      uuid NOT NULL REFERENCES public.orders(id) ON DELETE CASCADE,
  rating        integer NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment       text,
  created_at    timestamptz DEFAULT now() NOT NULL,
  updated_at    timestamptz DEFAULT now() NOT NULL,
  CONSTRAINT one_review_per_user_per_seller UNIQUE (seller_id, user_id)
);

-- 3b. Add order_id to existing product reviews (idempotent)
ALTER TABLE IF EXISTS public.reviews
  ADD COLUMN IF NOT EXISTS order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL;

-- ============================================================
-- PART 4: HELPER FUNCTIONS (idempotent — safe to re-run)
-- ============================================================

-- 4a. Check if user ordered from a seller (delivered)
CREATE OR REPLACE FUNCTION public.has_ordered_from_seller(p_user_id uuid, p_seller_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.order_items oi
    JOIN public.orders o ON o.id = oi.order_id
    WHERE o.user_id = p_user_id
      AND oi.seller_id = p_seller_id
      AND o.order_status = 'delivered'
  );
$$;

-- 4b. Check if user ordered a product (delivered)
CREATE OR REPLACE FUNCTION public.has_ordered_product(p_user_id uuid, p_product_id uuid)
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
    FROM public.order_items oi
    JOIN public.orders o ON o.id = oi.order_id
    WHERE o.user_id = p_user_id
      AND oi.product_id = p_product_id
      AND o.order_status = 'delivered'
  );
$$;

-- ============================================================
-- PART 5: TRIGGER — Auto-update sellers.rating from seller_reviews
-- ============================================================

CREATE OR REPLACE FUNCTION public.update_seller_rating_from_reviews()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_seller_id uuid;
BEGIN
  v_seller_id := COALESCE(NEW.seller_id, OLD.seller_id);

  UPDATE public.sellers
  SET
    rating = COALESCE(
      (SELECT AVG(rating::numeric) FROM public.seller_reviews WHERE seller_id = v_seller_id),
      0
    ),
    total_reviews = (SELECT COUNT(*) FROM public.seller_reviews WHERE seller_id = v_seller_id)
  WHERE id = v_seller_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_seller_reviews_rating ON public.seller_reviews;
CREATE TRIGGER trg_seller_reviews_rating
  AFTER INSERT OR UPDATE OR DELETE ON public.seller_reviews
  FOR EACH ROW
  EXECUTE FUNCTION public.update_seller_rating_from_reviews();

-- ============================================================
-- PART 6: RLS FOR SELLER_REVIEWS
-- ============================================================

ALTER TABLE IF EXISTS public.seller_reviews ENABLE ROW LEVEL SECURITY;

-- Admins full access
DROP POLICY IF EXISTS "admin_seller_reviews_all" ON public.seller_reviews;
CREATE POLICY "admin_seller_reviews_all"
  ON public.seller_reviews
  FOR ALL
  USING (public.is_admin());

-- Owners can see / update / delete their own reviews
DROP POLICY IF EXISTS "owner_seller_reviews_all" ON public.seller_reviews;
CREATE POLICY "owner_seller_reviews_all"
  ON public.seller_reviews
  FOR ALL
  USING (auth.uid() = user_id);

-- Anyone can read seller reviews
DROP POLICY IF EXISTS "public_read_seller_reviews" ON public.seller_reviews;
CREATE POLICY "public_read_seller_reviews"
  ON public.seller_reviews
  FOR SELECT
  USING (true);

-- Insert only if: user is author, has ordered from seller, and hasn't already reviewed
DROP POLICY IF EXISTS "customer_insert_seller_reviews" ON public.seller_reviews;
CREATE POLICY "customer_insert_seller_reviews"
  ON public.seller_reviews
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id
    AND public.has_ordered_from_seller(auth.uid(), seller_id)
    AND NOT EXISTS (
      SELECT 1 FROM public.seller_reviews sr
      WHERE sr.seller_id = seller_reviews.seller_id AND sr.user_id = auth.uid()
    )
  );

-- ============================================================
-- PART 7: HELPER FUNCTIONS FOR REVIEW ELIGIBILITY
-- ============================================================

CREATE OR REPLACE FUNCTION public.get_reviewed_product_ids(p_user_id uuid)
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT product_id FROM public.reviews WHERE user_id = p_user_id;
$$;

CREATE OR REPLACE FUNCTION public.get_reviewed_seller_ids(p_user_id uuid)
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT seller_id FROM public.seller_reviews WHERE user_id = p_user_id;
$$;

-- ============================================================
-- PART 8: REALTIME SUBSCRIPTIONS
-- ============================================================

DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.seller_reviews;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
