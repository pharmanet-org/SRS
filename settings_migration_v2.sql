-- ============================================================
-- PharmaNet Settings Schema Migration v2
-- Description: Extends settings table with new columns for
-- encryption, JSON support, and seeds all system-wide settings
-- that replace hardcoded values across admin/web/mobile apps.
-- ============================================================

-- 1. Extend settings table with new columns
ALTER TABLE public.settings
  ADD COLUMN IF NOT EXISTS is_encrypted boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS is_json boolean DEFAULT false,
  ADD COLUMN IF NOT EXISTS description text,
  ADD COLUMN IF NOT EXISTS metadata jsonb DEFAULT '{}'::jsonb;

-- 2. Ensure unique index on key for upsert
CREATE UNIQUE INDEX IF NOT EXISTS settings_key_key ON public.settings USING btree (key);

-- 3. Seed/upsert all system-wide settings
-- Each setting replaces a previously hardcoded value

-- ========== GENERAL ==========
INSERT INTO public.settings (key, value, "group", type, description, is_json)
VALUES
  ('site_name', 'PharmaNet', 'general', 'string', 'Platform display name'),
  ('platform_name', 'PharmaNet', 'general', 'string', 'Platform brand name used in UI'),
  ('contact_email', 'admin@pharmanet.com', 'general', 'string', 'Primary admin contact email'),
  ('contact_phone', '', 'general', 'string', 'Primary contact phone number'),
  ('contact_address', '', 'general', 'string', 'Business physical address'),
  ('logo_url', '', 'general', 'string', 'Platform logo image URL'),
  ('timezone', 'Africa/Addis_Ababa', 'general', 'string', 'Default system timezone'),
  ('currency', 'ETB', 'general', 'string', 'Default currency code'),
  ('currency_symbol', 'Br', 'general', 'string', 'Currency display symbol'),
  ('language', 'en', 'general', 'string', 'Default system language code')
ON CONFLICT (key) DO UPDATE SET
  "group" = EXCLUDED."group",
  type = EXCLUDED.type,
  description = EXCLUDED.description,
  is_json = EXCLUDED.is_json;

-- ========== SUBSCRIPTION ==========
INSERT INTO public.settings (key, value, "group", type, description, is_json)
VALUES
  ('subscription_monthly_price', '500', 'subscription', 'number', 'Monthly subscription plan price'),
  ('subscription_yearly_price', '5000', 'subscription', 'number', 'Yearly subscription plan price'),
  ('subscription_monthly_label', 'Monthly Plan', 'subscription', 'string', 'Monthly plan display label'),
  ('subscription_yearly_label', 'Yearly Plan', 'subscription', 'string', 'Yearly plan display label'),
  ('subscription_monthly_duration_days', '30', 'subscription', 'number', 'Monthly plan duration in days'),
  ('subscription_yearly_duration_days', '365', 'subscription', 'number', 'Yearly plan duration in days'),
  ('subscription_monthly_featured_slots', '5', 'subscription', 'number', 'Featured product slots per month for monthly plan'),
  ('subscription_yearly_featured_slots', '10', 'subscription', 'number', 'Featured product slots per month for yearly plan'),
  ('subscription_monthly_features', '["Full platform access","Unlimited products","Featured products: 5/month","Priority support"]', 'subscription', 'json', 'Monthly plan feature list'),
  ('subscription_yearly_features', '["Everything in Monthly","2 months FREE","Featured products: 10/month","Dedicated account manager","Advanced analytics"]', 'subscription', 'json', 'Yearly plan feature list')
ON CONFLICT (key) DO UPDATE SET
  "group" = EXCLUDED."group",
  type = EXCLUDED.type,
  description = EXCLUDED.description,
  is_json = EXCLUDED.is_json;

-- ========== FEATURED PRODUCTS ==========
INSERT INTO public.settings (key, value, "group", type, description, is_json)
VALUES
  ('featured_price_per_month', '100', 'featured', 'number', 'Price per month for featuring a product'),
  ('featured_duration_options', '[{"days":30,"label":"1 Month","months":1},{"days":90,"label":"3 Months","months":3},{"days":180,"label":"6 Months","months":6},{"days":365,"label":"1 Year","months":12}]', 'featured', 'json', 'Available duration options for featured products')
ON CONFLICT (key) DO UPDATE SET
  "group" = EXCLUDED."group",
  type = EXCLUDED.type,
  description = EXCLUDED.description,
  is_json = EXCLUDED.is_json;

-- ========== FEES ==========
INSERT INTO public.settings (key, value, "group", type, description)
VALUES
  ('commission_rate', '12.0', 'fees', 'string', 'Platform commission percentage on sales'),
  ('seller_commission_rate', '10.0', 'fees', 'string', 'Default seller commission percentage'),
  ('tax_rate', '0', 'fees', 'number', 'Default tax rate percentage'),
  ('tax_enabled', 'false', 'fees', 'boolean', 'Whether tax calculation is enabled'),
  ('minimum_order_amount', '0', 'fees', 'number', 'Minimum order amount required'),
  ('shipping_fee', '0', 'fees', 'number', 'Default shipping fee (0 = free)')
ON CONFLICT (key) DO UPDATE SET
  "group" = EXCLUDED."group",
  type = EXCLUDED.type,
  description = EXCLUDED.description;

-- ========== INVENTORY ==========
INSERT INTO public.settings (key, value, "group", type, description)
VALUES
  ('low_stock_threshold', '10', 'inventory', 'number', 'Alert when stock quantity drops below this value'),
  ('expiry_warning_days', '7', 'inventory', 'number', 'Days before expiry to show warning')
ON CONFLICT (key) DO UPDATE SET
  "group" = EXCLUDED."group",
  type = EXCLUDED.type,
  description = EXCLUDED.description;

-- ========== SECURITY ==========
INSERT INTO public.settings (key, value, "group", type, description)
VALUES
  ('session_inactivity_timeout', '30', 'security', 'number', 'Session inactivity timeout in minutes'),
  ('session_token_refresh_interval', '15', 'security', 'number', 'Token refresh interval in minutes')
ON CONFLICT (key) DO UPDATE SET
  "group" = EXCLUDED."group",
  type = EXCLUDED.type,
  description = EXCLUDED.description;

-- ========== UPLOAD ==========
INSERT INTO public.settings (key, value, "group", type, description)
VALUES
  ('upload_max_file_size_mb', '5', 'upload', 'number', 'Maximum file upload size in MB'),
  ('upload_max_image_size_mb', '2', 'upload', 'number', 'Maximum image upload size in MB')
ON CONFLICT (key) DO UPDATE SET
  "group" = EXCLUDED."group",
  type = EXCLUDED.type,
  description = EXCLUDED.description;

-- ========== PAGINATION ==========
INSERT INTO public.settings (key, value, "group", type, description, is_json)
VALUES
  ('pagination_default_limit', '10', 'pagination', 'number', 'Default items per page'),
  ('pagination_limit_options', '[10,25,50,100]', 'pagination', 'json', 'Available page size options')
ON CONFLICT (key) DO UPDATE SET
  "group" = EXCLUDED."group",
  type = EXCLUDED.type,
  description = EXCLUDED.description,
  is_json = EXCLUDED.is_json;

-- ========== CHECKOUT ==========
INSERT INTO public.settings (key, value, "group", type, description)
VALUES
  ('allow_guest_checkout', 'false', 'checkout', 'boolean', 'Allow unauthenticated users to checkout')
ON CONFLICT (key) DO UPDATE SET
  "group" = EXCLUDED."group",
  type = EXCLUDED.type,
  description = EXCLUDED.description;

-- ========== PAYMENT GATEWAY (ENCRYPTED) ==========
-- Keys will be encrypted via the encryption setup; seed as empty placeholders
INSERT INTO public.settings (key, value, "group", type, description, is_encrypted)
VALUES
  ('chapa_public_key', '', 'payment', 'string', 'Chapa payment gateway public key - ENCRYPTED', true),
  ('chapa_secret_key', '', 'payment', 'string', 'Chapa payment gateway secret key - ENCRYPTED', true),
  ('chapa_encryption_key', '', 'payment', 'string', 'Chapa payment gateway encryption key - ENCRYPTED', true),
  ('chapa_webhook_url', '', 'payment', 'string', 'Chapa webhook callback URL - ENCRYPTED', true),
  ('chapa_api_url', 'https://api.chapa.co/v1', 'payment', 'string', 'Chapa API base URL'),
  ('chapa_test_mode', 'true', 'payment', 'boolean', 'Whether Chapa is in test mode')
ON CONFLICT (key) DO UPDATE SET
  "group" = EXCLUDED."group",
  type = EXCLUDED.type,
  description = EXCLUDED.description,
  is_encrypted = EXCLUDED.is_encrypted;
