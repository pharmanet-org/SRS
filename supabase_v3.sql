-- ============================================================
-- PharmaNet v3: Seller Reviews + Order-linked Product Reviews
-- ============================================================

-- 1. Create seller_reviews table
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

-- 2. Add order_id to existing product reviews
ALTER TABLE IF EXISTS public.reviews
  ADD COLUMN IF NOT EXISTS order_id uuid REFERENCES public.orders(id) ON DELETE SET NULL;

-- 3. Helper: check if user ordered from a seller (delivered)
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

-- 4. Helper: check if user ordered a product (delivered)
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

-- 5. Trigger: auto-update sellers.rating and sellers.total_reviews
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

-- 6. RLS policies for seller_reviews
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
      SELECT 1 FROM public.seller_reviews
      WHERE seller_id = seller_reviews.seller_id AND user_id = auth.uid()
    )
  );

-- 7. Helper: fetch reviewed product IDs for a user (for eligibility checks)
CREATE OR REPLACE FUNCTION public.get_reviewed_product_ids(p_user_id uuid)
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT product_id FROM public.reviews WHERE user_id = p_user_id;
$$;

-- 8. Helper: fetch reviewed seller IDs for a user (for eligibility checks)
CREATE OR REPLACE FUNCTION public.get_reviewed_seller_ids(p_user_id uuid)
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT seller_id FROM public.seller_reviews WHERE user_id = p_user_id;
$$;
