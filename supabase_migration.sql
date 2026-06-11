-- ============================================================
-- PharmaNet Supabase Schema Migration
-- Description: Makes payments table support featured product
-- and subscription payments in addition to order payments.
-- Run this in your Supabase SQL Editor.
-- ============================================================

-- 1. Make payments.order_id nullable so payments can exist
--    for featured products and subscriptions (not just orders)
ALTER TABLE public.payments ALTER COLUMN order_id DROP NOT NULL;

-- 2. Add payment_id FK column to featured_product_payments
--    to link it back to the payments table
ALTER TABLE public.featured_product_payments
  ADD COLUMN IF NOT EXISTS payment_id uuid,
  ADD CONSTRAINT featured_product_payments_payment_id_fkey
    FOREIGN KEY (payment_id) REFERENCES public.payments(id)
    ON DELETE SET NULL;

-- 3. Add payment_id FK column to pharmacy_subscriptions
--    to link it back to the payments table
ALTER TABLE public.pharmacy_subscriptions
  ADD COLUMN IF NOT EXISTS payment_id uuid,
  ADD CONSTRAINT pharmacy_subscriptions_payment_id_fkey
    FOREIGN KEY (payment_id) REFERENCES public.payments(id)
    ON DELETE SET NULL;

-- 4. Add index on featured_product_payments.payment_id for performance
CREATE INDEX IF NOT EXISTS idx_featured_product_payments_payment_id
  ON public.featured_product_payments(payment_id);

-- 5. Add index on pharmacy_subscriptions.payment_id for performance
CREATE INDEX IF NOT EXISTS idx_pharmacy_subscriptions_payment_id
  ON public.pharmacy_subscriptions(payment_id);

-- 6. Add index on payments.chapa_tx_ref for faster lookups
CREATE INDEX IF NOT EXISTS idx_payments_chapa_tx_ref
  ON public.payments(chapa_tx_ref);
