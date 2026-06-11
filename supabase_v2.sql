-- ============================================================================
-- PharmaNet Supabase v2 — Fix circular RLS on order_items + add customer insert
-- ============================================================================
-- Run in Supabase SQL Editor.
-- ============================================================================

-- Function to get order owner bypassing RLS (breaks circular policy dependency)
CREATE OR REPLACE FUNCTION public.get_order_owner(order_id uuid)
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT user_id FROM public.orders WHERE id = order_id;
$$;

-- Order Items
DROP POLICY IF EXISTS "admin_order_items_all" ON public.order_items;
CREATE POLICY "admin_order_items_all" ON public.order_items
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "customer_view_own_order_items" ON public.order_items;
CREATE POLICY "customer_view_own_order_items" ON public.order_items
  FOR SELECT USING (
    auth.uid() = public.get_order_owner(order_id)
  );

DROP POLICY IF EXISTS "customer_insert_order_items" ON public.order_items;
CREATE POLICY "customer_insert_order_items" ON public.order_items
  FOR INSERT WITH CHECK (
    auth.uid() = public.get_order_owner(order_id)
  );

DROP POLICY IF EXISTS "seller_manage_own_order_items" ON public.order_items;
CREATE POLICY "seller_manage_own_order_items" ON public.order_items
  FOR ALL USING (
    auth.uid() IN (SELECT user_id FROM public.sellers WHERE id = seller_id)
  );
