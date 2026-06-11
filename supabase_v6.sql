-- ============================================================
-- PharmaNet v6: Comprehensive Notification System
-- ============================================================
-- Run after supabase_v5.sql and supabase_changes.sql.
-- Minimal DB footprint: one JSONB column, triggers, RLS.
-- ============================================================

-- ============================================================
-- 1. Add notification_preferences column to profiles
-- ============================================================
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS notification_preferences jsonb
  DEFAULT '{}'::jsonb;

-- ============================================================
-- 2. Add missing DELETE RLS for notifications
-- ============================================================
DROP POLICY IF EXISTS "users_delete_own_notifications" ON public.notifications;
CREATE POLICY "users_delete_own_notifications" ON public.notifications
  FOR DELETE TO authenticated
  USING (user_id = auth.uid());

-- ============================================================
-- 3. Auto-notify admins when a seller creates a product
-- ============================================================
CREATE OR REPLACE FUNCTION public.notify_product_created()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.notifications (user_id, type, title, message, related_id, related_type, data)
  SELECT
    p.id,
    'admin',
    'New Product Needs Approval',
    format('Product "%s" has been created and needs admin approval.', NEW.name),
    NEW.id,
    'product',
    jsonb_build_object('path', format('/products?id=%s', NEW.id), 'product_id', NEW.id, 'seller_id', NEW.seller_id)
  FROM public.profiles p
  WHERE p.role = 'admin';
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_product_created ON public.products;
CREATE TRIGGER trg_notify_product_created
  AFTER INSERT ON public.products
  FOR EACH ROW
  WHEN (NEW.approval_status = 'pending')
  EXECUTE FUNCTION public.notify_product_created();

-- ============================================================
-- 4. Auto-notify seller when product is approved/rejected
-- ============================================================
CREATE OR REPLACE FUNCTION public.notify_product_approval()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_seller_user_id uuid;
  v_title text;
  v_message text;
BEGIN
  SELECT user_id INTO v_seller_user_id FROM public.sellers WHERE id = NEW.seller_id;

  IF NEW.approval_status = 'approved' AND OLD.approval_status = 'pending' THEN
    v_title := 'Product Approved';
    v_message := format('Your product "%s" has been approved by the admin.', NEW.name);
  ELSIF NEW.approval_status = 'rejected' AND OLD.approval_status = 'pending' THEN
    v_title := 'Product Rejected';
    v_message := format('Your product "%s" was rejected by the admin. Reason: %s', NEW.name, COALESCE(NEW.rejection_reason, 'No reason provided'));
  ELSE
    RETURN NEW;
  END IF;

  INSERT INTO public.notifications (user_id, type, title, message, related_id, related_type, data)
  VALUES (
    v_seller_user_id, 'product', v_title, v_message,
    NEW.id, 'product',
    jsonb_build_object('path', format('/products?id=%s', NEW.id), 'product_id', NEW.id)
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_product_approval ON public.products;
CREATE TRIGGER trg_notify_product_approval
  AFTER UPDATE OF approval_status ON public.products
  FOR EACH ROW
  WHEN (OLD.approval_status = 'pending' AND NEW.approval_status IN ('approved', 'rejected'))
  EXECUTE FUNCTION public.notify_product_approval();

-- ============================================================
-- 5. Auto-notify seller when seller registration approved/rejected
-- ============================================================
CREATE OR REPLACE FUNCTION public.notify_seller_approval()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_title text;
  v_message text;
BEGIN
  IF NEW.approval_status = 'approved' AND OLD.approval_status = 'pending' THEN
    v_title := 'Pharmacy Approved';
    v_message := format('Your pharmacy "%s" has been approved! You can now start selling.', NEW.store_name);
  ELSIF NEW.approval_status = 'rejected' AND OLD.approval_status = 'pending' THEN
    v_title := 'Pharmacy Rejected';
    v_message := format('Your pharmacy "%s" was rejected. Reason: %s', NEW.store_name, COALESCE(NEW.rejection_reason, 'No reason provided'));
  ELSE
    RETURN NEW;
  END IF;

  INSERT INTO public.notifications (user_id, type, title, message, related_id, related_type, data)
  VALUES (
    NEW.user_id, 'seller', v_title, v_message,
    NEW.id, 'seller',
    jsonb_build_object('path', '/settings')
  );
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_seller_approval ON public.sellers;
CREATE TRIGGER trg_notify_seller_approval
  AFTER UPDATE OF approval_status ON public.sellers
  FOR EACH ROW
  WHEN (OLD.approval_status = 'pending' AND NEW.approval_status IN ('approved', 'rejected'))
  EXECUTE FUNCTION public.notify_seller_approval();

-- ============================================================
-- 6. Auto-notify admins when a new seller registers
-- ============================================================
CREATE OR REPLACE FUNCTION public.notify_seller_registered()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.notifications (user_id, type, title, message, related_id, related_type, data)
  SELECT
    p.id,
    'admin',
    'New Seller Registration',
    format('A new pharmacy "%s" has registered and is pending approval.', NEW.store_name),
    NEW.id,
    'seller',
    jsonb_build_object('path', '/users', 'seller_id', NEW.id)
  FROM public.profiles p
  WHERE p.role = 'admin';
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_seller_registered ON public.sellers;
CREATE TRIGGER trg_notify_seller_registered
  AFTER INSERT ON public.sellers
  FOR EACH ROW
  WHEN (NEW.approval_status = 'pending')
  EXECUTE FUNCTION public.notify_seller_registered();

-- ============================================================
-- 7. Auto-notify seller on new order + customer on status change
-- ============================================================
CREATE OR REPLACE FUNCTION public.notify_order_event()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.notifications (user_id, type, title, message, related_id, related_type, data)
    SELECT DISTINCT
      s.user_id,
      'order',
      'New Order Received',
      format('New order #%s has been placed.', NEW.order_number),
      NEW.id,
      'order',
      jsonb_build_object('path', format('/orders?id=%s', NEW.id), 'order_id', NEW.id, 'order_number', NEW.order_number)
    FROM public.order_items oi
    JOIN public.sellers s ON s.id = oi.seller_id
    WHERE oi.order_id = NEW.id;
  END IF;

  IF TG_OP = 'UPDATE' AND NEW.order_status IS DISTINCT FROM OLD.order_status THEN
    INSERT INTO public.notifications (user_id, type, title, message, related_id, related_type, data)
    VALUES (
      NEW.user_id,
      'order',
      format('Order #%s: %s', NEW.order_number, INITCAP(NEW.order_status)),
      format('Your order #%s is now %s.', NEW.order_number, NEW.order_status),
      NEW.id,
      'order',
      jsonb_build_object('path', format('/orders?id=%s', NEW.id), 'order_id', NEW.id, 'order_number', NEW.order_number)
    );
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_notify_order_event ON public.orders;
CREATE TRIGGER trg_notify_order_event
  AFTER INSERT OR UPDATE OF order_status ON public.orders
  FOR EACH ROW
  EXECUTE FUNCTION public.notify_order_event();

-- ============================================================
-- 8. Seed notification settings
-- ============================================================
INSERT INTO public.settings (key, value, "group", type, description)
VALUES
  ('notification_notify_admins_on_product_creation', 'true', 'notifications', 'boolean', 'Notify admins when a new product is created'),
  ('notification_notify_admins_on_seller_registration', 'true', 'notifications', 'boolean', 'Notify admins when a new seller registers'),
  ('notification_notify_seller_on_product_approval', 'true', 'notifications', 'boolean', 'Notify seller when product is approved or rejected'),
  ('notification_notify_seller_on_new_order', 'true', 'notifications', 'boolean', 'Notify seller when a new order arrives'),
  ('notification_notify_customer_on_order_status', 'true', 'notifications', 'boolean', 'Notify customer when order status changes')
ON CONFLICT (key) DO UPDATE SET
  "group" = EXCLUDED."group",
  type = EXCLUDED.type,
  description = EXCLUDED.description;

-- ============================================================
-- 9. Enable realtime for notifications (idempotent)
-- ============================================================
DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================
-- 10. Set updated_at trigger on notifications
-- ============================================================
DROP TRIGGER IF EXISTS trg_notifications_updated_at ON public.notifications;
CREATE TRIGGER trg_notifications_updated_at
  BEFORE UPDATE ON public.notifications
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();
