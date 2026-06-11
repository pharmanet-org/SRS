-- ============================================================================
-- PharmaNet Supabase Schema Changes
-- Description:
--   1. New tables: payment_methods, loyalty_points, loyalty_transactions
--   2. RLS policies for all tables (staged for safety)
--   3. Storage bucket setup & RLS policies
--   4. Loyalty points functions, triggers, and helper utilities
-- ============================================================================
-- Run in Supabase SQL Editor. All statements use IF [NOT] EXISTS for safety.
-- IMPORTANT: Apply in order. RLS on existing tables (section 3.3+) should
-- be tested in staging before production.
-- ============================================================================

-- ============================================================================
-- PART 1: NEW TABLES
-- ============================================================================

-- 1.1. Payment Methods (Chapa, Telebirr, CBE phone numbers)
CREATE TABLE IF NOT EXISTS public.payment_methods (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  method_type text NOT NULL CHECK (method_type IN ('chapa', 'telebirr', 'cbe')),
  phone_number text NOT NULL,
  account_holder_name text,
  is_default boolean NOT NULL DEFAULT false,
  is_active boolean NOT NULL DEFAULT true,
  created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT payment_methods_pkey PRIMARY KEY (id),
  CONSTRAINT payment_methods_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES public.profiles(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_payment_methods_user
  ON public.payment_methods(user_id);

CREATE UNIQUE INDEX IF NOT EXISTS idx_payment_methods_user_default
  ON public.payment_methods(user_id) WHERE is_default = true;

-- 1.2. Loyalty Points (balance per user)
CREATE TABLE IF NOT EXISTS public.loyalty_points (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  points_balance integer NOT NULL DEFAULT 0,
  lifetime_points integer NOT NULL DEFAULT 0,
  tier text NOT NULL DEFAULT 'bronze'
    CHECK (tier IN ('bronze', 'silver', 'gold', 'platinum')),
  created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT loyalty_points_pkey PRIMARY KEY (id),
  CONSTRAINT loyalty_points_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES public.profiles(id) ON DELETE CASCADE,
  CONSTRAINT loyalty_points_user_id_unique UNIQUE (user_id)
);

-- 1.3. Loyalty Transactions (full audit trail — complements existing points_payments)
CREATE TABLE IF NOT EXISTS public.loyalty_transactions (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  points integer NOT NULL,
  type text NOT NULL
    CHECK (type IN ('earned', 'redeemed', 'expired', 'bonus', 'adjusted')),
  reference_type text
    CHECK (reference_type IN ('order', 'promotion', 'redemption', 'admin')),
  reference_id uuid,
  description text,
  created_at timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT loyalty_transactions_pkey PRIMARY KEY (id),
  CONSTRAINT loyalty_transactions_user_id_fkey FOREIGN KEY (user_id)
    REFERENCES public.profiles(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_user
  ON public.loyalty_transactions(user_id);

CREATE INDEX IF NOT EXISTS idx_loyalty_transactions_created
  ON public.loyalty_transactions(created_at DESC);

-- ============================================================================
-- PART 2: HELPER FUNCTIONS (used by RLS policies)
-- ============================================================================

-- 2.1. Check if current user has admin role
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS boolean
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$;

-- 2.2. Get seller/pharmacy id for current authenticated user
CREATE OR REPLACE FUNCTION public.current_seller_id()
RETURNS uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
AS $$
  SELECT id FROM public.sellers WHERE user_id = auth.uid() LIMIT 1;
$$;

-- 2.3. Auto-update updated_at timestamp
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- PART 3: RLS POLICIES
-- ============================================================================
-- Applied in tiers:
--   Tier 1 (safe): New tables only
--   Tier 2 (low risk): Tables with existing RLS (promotions, offer_products, notifications)
--   Tier 3 (medium risk): Tables that need careful testing
--   Tier 4 (new feature): Loyalty tables
-- ============================================================================

-- 3.1. ENABLE RLS ON ALL TABLES (idempotent)
-- New tables always get RLS
ALTER TABLE IF EXISTS public.payment_methods      ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.loyalty_points        ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.loyalty_transactions  ENABLE ROW LEVEL SECURITY;

-- Existing tables — RLS is idempotent (safe to re-run)
ALTER TABLE IF EXISTS public.profiles                ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.sellers                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.products                ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.categories              ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.brands                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.variant_options         ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.variant_values          ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.variant_combinations    ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.variant_combination_values ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.carts                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.cart_items              ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.addresses               ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.orders                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.order_items             ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.payments                ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.reviews                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.wishlists               ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.wishlist_items          ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.chats                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.chat_participants       ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.messages                ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.notifications           ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.order_status_history    ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.banners                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.static_pages            ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.settings                ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.analytics               ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.featured_product_payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.pharmacy_subscriptions  ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.featured_product_access ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.bookmarks               ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.promotions              ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.offer_products          ENABLE ROW LEVEL SECURITY;

-- ========================
-- TIER 1: NEW TABLES RLS
-- ========================

-- Payment Methods
DROP POLICY IF EXISTS "admin_payment_methods_all" ON public.payment_methods;
CREATE POLICY "admin_payment_methods_all" ON public.payment_methods
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "owner_payment_methods_all" ON public.payment_methods;
CREATE POLICY "owner_payment_methods_all" ON public.payment_methods
  FOR ALL USING (auth.uid() = user_id);

-- Loyalty Points
DROP POLICY IF EXISTS "admin_loyalty_points_all" ON public.loyalty_points;
CREATE POLICY "admin_loyalty_points_all" ON public.loyalty_points
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "owner_loyalty_points_select" ON public.loyalty_points;
CREATE POLICY "owner_loyalty_points_select" ON public.loyalty_points
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "system_loyalty_points_update" ON public.loyalty_points;
CREATE POLICY "system_loyalty_points_update" ON public.loyalty_points
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Loyalty Transactions
DROP POLICY IF EXISTS "admin_loyalty_transactions_all" ON public.loyalty_transactions;
CREATE POLICY "admin_loyalty_transactions_all" ON public.loyalty_transactions
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "owner_loyalty_transactions_select" ON public.loyalty_transactions;
CREATE POLICY "owner_loyalty_transactions_select" ON public.loyalty_transactions
  FOR SELECT USING (auth.uid() = user_id);

-- ========================
-- TIER 2: EXISTING RLS REFRESH
-- ========================

-- Promotions (refreshing existing policies)
DROP POLICY IF EXISTS "admin_promotions_all" ON public.promotions;
CREATE POLICY "admin_promotions_all" ON public.promotions
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "sellers_read_promotions" ON public.promotions;
CREATE POLICY "sellers_read_promotions" ON public.promotions
  FOR SELECT TO authenticated
  USING (
    status = 'active' OR public.is_admin()
  );

DROP POLICY IF EXISTS "anon_read_active_promotions" ON public.promotions;
CREATE POLICY "anon_read_active_promotions" ON public.promotions
  FOR SELECT TO anon, authenticated
  USING (status = 'active');

-- Offer Products (refreshing existing policies)
DROP POLICY IF EXISTS "admin_offer_products_all" ON public.offer_products;
CREATE POLICY "admin_offer_products_all" ON public.offer_products
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS "sellers_manage_own_offers" ON public.offer_products;
CREATE POLICY "sellers_manage_own_offers" ON public.offer_products
  FOR ALL TO authenticated
  USING (
    pharmacy_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
  )
  WITH CHECK (
    pharmacy_id IN (SELECT id FROM public.sellers WHERE user_id = auth.uid())
  );

DROP POLICY IF EXISTS "anon_read_active_offers" ON public.offer_products;
CREATE POLICY "anon_read_active_offers" ON public.offer_products
  FOR SELECT TO anon, authenticated
  USING (is_active = true);

-- Notifications (refreshing + adding UPDATE)
DROP POLICY IF EXISTS "users_read_own_notifications" ON public.notifications;
CREATE POLICY "users_read_own_notifications" ON public.notifications
  FOR SELECT TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "users_insert_notifications" ON public.notifications;
CREATE POLICY "users_insert_notifications" ON public.notifications
  FOR INSERT TO authenticated
  WITH CHECK (
    user_id = auth.uid() OR public.is_admin()
  );

DROP POLICY IF EXISTS "users_update_own_notifications" ON public.notifications;
CREATE POLICY "users_update_own_notifications" ON public.notifications
  FOR UPDATE TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- ========================
-- TIER 3: EXISTING TABLES RLS
-- ========================

-- Profiles
DROP POLICY IF EXISTS "admin_profiles_all" ON public.profiles;
CREATE POLICY "admin_profiles_all" ON public.profiles
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "owner_profiles_select" ON public.profiles;
CREATE POLICY "owner_profiles_select" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "owner_profiles_update" ON public.profiles;
CREATE POLICY "owner_profiles_update" ON public.profiles
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

DROP POLICY IF EXISTS "owner_profiles_insert" ON public.profiles;
CREATE POLICY "owner_profiles_insert" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Sellers (Pharmacies)
DROP POLICY IF EXISTS "admin_sellers_all" ON public.sellers;
CREATE POLICY "admin_sellers_all" ON public.sellers
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "owner_sellers_select" ON public.sellers;
CREATE POLICY "owner_sellers_select" ON public.sellers
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "owner_sellers_update" ON public.sellers;
CREATE POLICY "owner_sellers_update" ON public.sellers
  FOR UPDATE USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "owner_sellers_insert" ON public.sellers;
CREATE POLICY "owner_sellers_insert" ON public.sellers
  FOR INSERT WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "public_read_approved_sellers" ON public.sellers;
CREATE POLICY "public_read_approved_sellers" ON public.sellers
  FOR SELECT USING (approval_status = 'approved');

-- Products
DROP POLICY IF EXISTS "admin_products_all" ON public.products;
CREATE POLICY "admin_products_all" ON public.products
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "seller_insert_products" ON public.products;
CREATE POLICY "seller_insert_products" ON public.products
  FOR INSERT WITH CHECK (
    auth.uid() IN (SELECT user_id FROM public.sellers WHERE id = seller_id)
  );

DROP POLICY IF EXISTS "seller_update_products" ON public.products;
CREATE POLICY "seller_update_products" ON public.products
  FOR UPDATE USING (
    auth.uid() IN (SELECT user_id FROM public.sellers WHERE id = seller_id)
  );

DROP POLICY IF EXISTS "seller_delete_products" ON public.products;
CREATE POLICY "seller_delete_products" ON public.products
  FOR DELETE USING (
    auth.uid() IN (SELECT user_id FROM public.sellers WHERE id = seller_id)
  );

DROP POLICY IF EXISTS "seller_select_own_products" ON public.products;
CREATE POLICY "seller_select_own_products" ON public.products
  FOR SELECT USING (
    auth.uid() IN (SELECT user_id FROM public.sellers WHERE id = seller_id)
  );

DROP POLICY IF EXISTS "public_read_published_products" ON public.products;
CREATE POLICY "public_read_published_products" ON public.products
  FOR SELECT USING (
    is_published = true AND approval_status = 'approved'
  );

-- Orders
DROP POLICY IF EXISTS "admin_orders_all" ON public.orders;
CREATE POLICY "admin_orders_all" ON public.orders
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "customer_own_orders" ON public.orders;
CREATE POLICY "customer_own_orders" ON public.orders
  FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "seller_view_involved_orders" ON public.orders;
CREATE POLICY "seller_view_involved_orders" ON public.orders
  FOR SELECT USING (
    auth.uid() IN (
      SELECT s.user_id FROM public.order_items oi
      JOIN public.sellers s ON s.id = oi.seller_id
      WHERE oi.order_id = orders.id
    )
  );

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

-- Carts
DROP POLICY IF EXISTS "admin_carts_all" ON public.carts;
CREATE POLICY "admin_carts_all" ON public.carts
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "owner_carts_all" ON public.carts;
CREATE POLICY "owner_carts_all" ON public.carts
  FOR ALL USING (auth.uid() = user_id);

-- Cart Items
DROP POLICY IF EXISTS "admin_cart_items_all" ON public.cart_items;
CREATE POLICY "admin_cart_items_all" ON public.cart_items
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "owner_cart_items_all" ON public.cart_items;
CREATE POLICY "owner_cart_items_all" ON public.cart_items
  FOR ALL USING (
    auth.uid() IN (SELECT user_id FROM public.carts WHERE id = cart_id)
  );

-- Addresses
DROP POLICY IF EXISTS "admin_addresses_all" ON public.addresses;
CREATE POLICY "admin_addresses_all" ON public.addresses
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "owner_addresses_all" ON public.addresses;
CREATE POLICY "owner_addresses_all" ON public.addresses
  FOR ALL USING (auth.uid() = user_id);

-- Payments
DROP POLICY IF EXISTS "admin_payments_all" ON public.payments;
CREATE POLICY "admin_payments_all" ON public.payments
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "owner_payments_all" ON public.payments;
CREATE POLICY "owner_payments_all" ON public.payments
  FOR ALL USING (
    auth.uid() IN (SELECT user_id FROM public.orders WHERE id = order_id)
  );

-- Reviews
DROP POLICY IF EXISTS "admin_reviews_all" ON public.reviews;
CREATE POLICY "admin_reviews_all" ON public.reviews
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "owner_reviews_all" ON public.reviews;
CREATE POLICY "owner_reviews_all" ON public.reviews
  FOR ALL USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "public_read_reviews" ON public.reviews;
CREATE POLICY "public_read_reviews" ON public.reviews
  FOR SELECT USING (true);

-- Wishlists
DROP POLICY IF EXISTS "admin_wishlists_all" ON public.wishlists;
CREATE POLICY "admin_wishlists_all" ON public.wishlists
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "owner_wishlists_all" ON public.wishlists;
CREATE POLICY "owner_wishlists_all" ON public.wishlists
  FOR ALL USING (auth.uid() = user_id);

-- Wishlist Items
DROP POLICY IF EXISTS "admin_wishlist_items_all" ON public.wishlist_items;
CREATE POLICY "admin_wishlist_items_all" ON public.wishlist_items
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "owner_wishlist_items_all" ON public.wishlist_items;
CREATE POLICY "owner_wishlist_items_all" ON public.wishlist_items
  FOR ALL USING (
    auth.uid() IN (SELECT user_id FROM public.wishlists WHERE id = wishlist_id)
  );

-- Chats
DROP POLICY IF EXISTS "participant_select_chats" ON public.chats;
CREATE POLICY "participant_select_chats" ON public.chats
  FOR SELECT USING (
    auth.uid() IN (SELECT user_id FROM public.chat_participants WHERE chat_id = chats.id)
  );

DROP POLICY IF EXISTS "participant_insert_chats" ON public.chats;
CREATE POLICY "participant_insert_chats" ON public.chats
  FOR INSERT WITH CHECK (
    auth.uid() IN (SELECT user_id FROM public.chat_participants WHERE chat_id = chats.id)
  );

-- Chat Participants
DROP POLICY IF EXISTS "participant_select_chat_participants" ON public.chat_participants;
CREATE POLICY "participant_select_chat_participants" ON public.chat_participants
  FOR SELECT USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "participant_insert_chat_participants" ON public.chat_participants;
CREATE POLICY "participant_insert_chat_participants" ON public.chat_participants
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Messages
DROP POLICY IF EXISTS "participant_select_messages" ON public.messages;
CREATE POLICY "participant_select_messages" ON public.messages
  FOR SELECT USING (
    auth.uid() IN (SELECT user_id FROM public.chat_participants WHERE chat_participants.chat_id = messages.chat_id)
  );

DROP POLICY IF EXISTS "sender_insert_messages" ON public.messages;
CREATE POLICY "sender_insert_messages" ON public.messages
  FOR INSERT WITH CHECK (auth.uid() = sender_id);

DROP POLICY IF EXISTS "sender_update_own_messages" ON public.messages;
CREATE POLICY "sender_update_own_messages" ON public.messages
  FOR UPDATE USING (auth.uid() = sender_id)
  WITH CHECK (auth.uid() = sender_id);

-- Banners
DROP POLICY IF EXISTS "admin_banners_all" ON public.banners;
CREATE POLICY "admin_banners_all" ON public.banners
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "public_read_active_banners" ON public.banners;
CREATE POLICY "public_read_active_banners" ON public.banners
  FOR SELECT USING (is_active = true);

-- Static Pages
DROP POLICY IF EXISTS "admin_static_pages_all" ON public.static_pages;
CREATE POLICY "admin_static_pages_all" ON public.static_pages
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "public_read_static_pages" ON public.static_pages;
CREATE POLICY "public_read_static_pages" ON public.static_pages
  FOR SELECT USING (true);

-- Settings
DROP POLICY IF EXISTS "admin_settings_all" ON public.settings;
CREATE POLICY "admin_settings_all" ON public.settings
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "authenticated_read_settings" ON public.settings;
CREATE POLICY "authenticated_read_settings" ON public.settings
  FOR SELECT USING (auth.role() = 'authenticated');

-- Categories
DROP POLICY IF EXISTS "admin_categories_all" ON public.categories;
CREATE POLICY "admin_categories_all" ON public.categories
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "public_read_active_categories" ON public.categories;
CREATE POLICY "public_read_active_categories" ON public.categories
  FOR SELECT USING (status = 'active');

-- Brands
DROP POLICY IF EXISTS "admin_brands_all" ON public.brands;
CREATE POLICY "admin_brands_all" ON public.brands
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "public_read_active_brands" ON public.brands;
CREATE POLICY "public_read_active_brands" ON public.brands
  FOR SELECT USING (is_active = true);

-- Bookmarks
DROP POLICY IF EXISTS "admin_bookmarks_all" ON public.bookmarks;
CREATE POLICY "admin_bookmarks_all" ON public.bookmarks
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "owner_bookmarks_all" ON public.bookmarks;
CREATE POLICY "owner_bookmarks_all" ON public.bookmarks
  FOR ALL USING (auth.uid() = user_id);

-- Order Status History
DROP POLICY IF EXISTS "admin_order_status_history_all" ON public.order_status_history;
CREATE POLICY "admin_order_status_history_all" ON public.order_status_history
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "owner_view_order_status_history" ON public.order_status_history;
CREATE POLICY "owner_view_order_status_history" ON public.order_status_history
  FOR SELECT USING (
    auth.uid() IN (SELECT user_id FROM public.orders WHERE orders.id = order_status_history.order_id)
    OR auth.uid() IN (
      SELECT s.user_id FROM public.order_items oi
      JOIN public.sellers s ON s.id = oi.seller_id
      WHERE oi.order_id = order_status_history.order_id
    )
  );

-- Analytics
DROP POLICY IF EXISTS "admin_analytics_all" ON public.analytics;
CREATE POLICY "admin_analytics_all" ON public.analytics
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "seller_own_analytics" ON public.analytics;
CREATE POLICY "seller_own_analytics" ON public.analytics
  FOR SELECT USING (
    auth.uid() IN (SELECT user_id FROM public.sellers WHERE id = seller_id)
  );

-- Featured Product Payments
DROP POLICY IF EXISTS "admin_featured_payments_all" ON public.featured_product_payments;
CREATE POLICY "admin_featured_payments_all" ON public.featured_product_payments
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "seller_own_featured_payments" ON public.featured_product_payments;
CREATE POLICY "seller_own_featured_payments" ON public.featured_product_payments
  FOR ALL USING (
    auth.uid() IN (SELECT user_id FROM public.sellers WHERE id = pharmacy_id)
  );

-- Pharmacy Subscriptions
DROP POLICY IF EXISTS "admin_subscriptions_all" ON public.pharmacy_subscriptions;
CREATE POLICY "admin_subscriptions_all" ON public.pharmacy_subscriptions
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "seller_own_subscriptions" ON public.pharmacy_subscriptions;
CREATE POLICY "seller_own_subscriptions" ON public.pharmacy_subscriptions
  FOR ALL USING (
    auth.uid() IN (SELECT user_id FROM public.sellers WHERE id = pharmacy_id)
  );

-- Variant tables (read-only public, admin full, seller write)
DROP POLICY IF EXISTS "admin_variant_options_all" ON public.variant_options;
CREATE POLICY "admin_variant_options_all" ON public.variant_options
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "seller_variant_options_write" ON public.variant_options;
CREATE POLICY "seller_variant_options_write" ON public.variant_options
  FOR INSERT WITH CHECK (
    auth.uid() IN (SELECT user_id FROM public.sellers)
  );

DROP POLICY IF EXISTS "public_read_variant_options" ON public.variant_options;
CREATE POLICY "public_read_variant_options" ON public.variant_options
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "admin_variant_values_all" ON public.variant_values;
CREATE POLICY "admin_variant_values_all" ON public.variant_values
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "public_read_variant_values" ON public.variant_values;
CREATE POLICY "public_read_variant_values" ON public.variant_values
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "admin_variant_combinations_all" ON public.variant_combinations;
CREATE POLICY "admin_variant_combinations_all" ON public.variant_combinations
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "public_read_variant_combinations" ON public.variant_combinations;
CREATE POLICY "public_read_variant_combinations" ON public.variant_combinations
  FOR SELECT USING (true);

DROP POLICY IF EXISTS "admin_variant_combination_values_all" ON public.variant_combination_values;
CREATE POLICY "admin_variant_combination_values_all" ON public.variant_combination_values
  FOR ALL USING (public.is_admin());

DROP POLICY IF EXISTS "public_read_variant_combination_values" ON public.variant_combination_values;
CREATE POLICY "public_read_variant_combination_values" ON public.variant_combination_values
  FOR SELECT USING (true);

-- ============================================================================
-- PART 4: STORAGE BUCKETS & POLICIES
-- ============================================================================

-- 4.1. Ensure storage buckets exist
INSERT INTO storage.buckets (id, name, public, avif_autodetection, file_size_limit, allowed_mime_types)
VALUES
  ('products',   'products',   true, false, 5242880,  ARRAY['image/png', 'image/jpeg', 'image/webp', 'image/gif']),
  ('profiles',   'profiles',   true, false, 2097152,  ARRAY['image/png', 'image/jpeg', 'image/webp']),
  ('categories', 'categories', true, false, 2097152,  ARRAY['image/png', 'image/jpeg', 'image/webp']),
  ('settings',   'settings',   true, false, 5242880,  ARRAY['image/png', 'image/jpeg', 'image/webp', 'image/svg+xml'])
ON CONFLICT (id) DO NOTHING;

-- 4.2. Storage RLS: Public can read files
DROP POLICY IF EXISTS "public_read_storage" ON storage.objects;
CREATE POLICY "public_read_storage" ON storage.objects
  FOR SELECT USING (bucket_id IN ('products', 'profiles', 'categories', 'settings'));

-- 4.3. Storage RLS: Authenticated users can upload
DROP POLICY IF EXISTS "authenticated_upload_storage" ON storage.objects;
CREATE POLICY "authenticated_upload_storage" ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id IN ('products', 'profiles', 'categories', 'settings')
    AND auth.role() = 'authenticated'
  );

-- 4.4. Storage RLS: Users can update own uploads
DROP POLICY IF EXISTS "owner_update_storage" ON storage.objects;
CREATE POLICY "owner_update_storage" ON storage.objects
  FOR UPDATE USING (auth.uid() = owner);

-- 4.5. Storage RLS: Users can delete own uploads
DROP POLICY IF EXISTS "owner_delete_storage" ON storage.objects;
CREATE POLICY "owner_delete_storage" ON storage.objects
  FOR DELETE USING (auth.uid() = owner);

-- 4.6. Storage RLS: Admins can manage all objects
DROP POLICY IF EXISTS "admin_full_access_storage" ON storage.objects;
CREATE POLICY "admin_full_access_storage" ON storage.objects
  FOR ALL USING (public.is_admin());

-- ============================================================================
-- PART 5: LOYALTY POINTS FUNCTIONS & TRIGGERS
-- ============================================================================

-- 5.1. Earn points automatically when an order is paid
CREATE OR REPLACE FUNCTION public.earn_loyalty_points()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_points integer;
BEGIN
  -- 1 point per 10 ETB (floor), minimum 1
  v_points := GREATEST(1, FLOOR(NEW.total_amount / 10)::integer);

  INSERT INTO public.loyalty_points (user_id, points_balance, lifetime_points)
  VALUES (NEW.user_id, v_points, v_points)
  ON CONFLICT (user_id) DO UPDATE SET
    points_balance = loyalty_points.points_balance + v_points,
    lifetime_points = loyalty_points.lifetime_points + v_points,
    updated_at = now();

  INSERT INTO public.loyalty_transactions
    (user_id, points, type, reference_type, reference_id, description)
  VALUES (
    NEW.user_id, v_points, 'earned', 'order', NEW.id,
    format('Earned %s points from order %s', v_points, NEW.order_number)
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_earn_loyalty_points ON public.orders;
CREATE TRIGGER trg_earn_loyalty_points
  AFTER UPDATE OF payment_status ON public.orders
  FOR EACH ROW
  WHEN (NEW.payment_status = 'completed'
    AND (OLD.payment_status IS DISTINCT FROM 'completed'))
  EXECUTE FUNCTION public.earn_loyalty_points();

-- 5.2. Redeem loyalty points (called by app backend)
CREATE OR REPLACE FUNCTION public.redeem_loyalty_points(
  p_user_id uuid,
  p_points integer,
  p_reference_id uuid DEFAULT NULL,
  p_description text DEFAULT NULL
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_balance integer;
BEGIN
  SELECT points_balance INTO v_balance
  FROM public.loyalty_points
  WHERE user_id = p_user_id
  FOR UPDATE;

  IF v_balance IS NULL OR v_balance < p_points THEN
    RETURN false;
  END IF;

  UPDATE public.loyalty_points
  SET points_balance = points_balance - p_points,
      updated_at = now()
  WHERE user_id = p_user_id;

  INSERT INTO public.loyalty_transactions
    (user_id, points, type, reference_type, reference_id, description)
  VALUES (
    p_user_id, -p_points, 'redeemed', 'redemption',
    p_reference_id, COALESCE(p_description, format('Redeemed %s points', p_points))
  );

  RETURN true;
END;
$$;

-- 5.3. Apply auto-update triggers to new tables
DROP TRIGGER IF EXISTS trg_payment_methods_updated_at ON public.payment_methods;
CREATE TRIGGER trg_payment_methods_updated_at
  BEFORE UPDATE ON public.payment_methods
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

DROP TRIGGER IF EXISTS trg_loyalty_points_updated_at ON public.loyalty_points;
CREATE TRIGGER trg_loyalty_points_updated_at
  BEFORE UPDATE ON public.loyalty_points
  FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- ============================================================================
-- PART 6: REALTIME SUBSCRIPTIONS
-- ============================================================================

DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.payment_methods;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.loyalty_points;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  ALTER PUBLICATION supabase_realtime ADD TABLE public.loyalty_transactions;
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
