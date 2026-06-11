-- ============================================================
-- PharmaNet v5: Fix seller product creation — add SELECT policy
-- ============================================================
-- Run after supabase_v4.sql and supabase_changes.sql.
-- Allows sellers to SELECT (read back) their own products,
-- fixing the "INSERT ... RETURNING" flow during product creation.
-- ============================================================

DROP POLICY IF EXISTS "seller_select_own_products" ON public.products;
CREATE POLICY "seller_select_own_products" ON public.products
  FOR SELECT
  USING (
    auth.uid() IN (SELECT user_id FROM public.sellers WHERE id = seller_id)
  );
