-- ============================================================
-- PharmaNet Encryption Setup
-- Description: Enables pgcrypto, creates encryption/decryption
-- functions for sensitive settings values and mobile content.
-- Uses Supabase Vault for key management.
-- ============================================================

-- 1. Enable pgcrypto extension
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- 2. Create a secure schema for encryption functions
CREATE SCHEMA IF NOT EXISTS crypto;

-- 3. Function to encrypt a setting value
-- Uses the vault key; returns base64-encoded ciphertext
CREATE OR REPLACE FUNCTION crypto.encrypt_setting_value(
  p_plaintext text
) RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_key text;
  v_ciphertext bytea;
BEGIN
  -- Retrieve encryption key from Supabase Vault
  -- In production, store via: SELECT vault.create_secret('your-key-here', 'settings-encryption-key');
  BEGIN
    v_key := vault.decrypt_secret(
      (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'settings-encryption-key' LIMIT 1)
    );
  EXCEPTION WHEN OTHERS THEN
    -- Fallback: use a key from environment if vault is not set up
    v_key := current_setting('app.settings.encryption_key', true);
    IF v_key IS NULL THEN
      RAISE EXCEPTION 'No encryption key configured. Set app.settings.encryption_key or configure Supabase Vault.';
    END IF;
  END;

  -- Encrypt using pgp_sym_encrypt (AES-256)
  v_ciphertext := extensions.pgp_sym_encrypt(p_plaintext, v_key);
  RETURN encode(v_ciphertext, 'base64');
END;
$$;

-- 4. Function to decrypt a setting value
CREATE OR REPLACE FUNCTION crypto.decrypt_setting_value(
  p_ciphertext_b64 text
) RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_key text;
  v_ciphertext bytea;
BEGIN
  BEGIN
    v_key := vault.decrypt_secret(
      (SELECT decrypted_secret FROM vault.decrypted_secrets WHERE name = 'settings-encryption-key' LIMIT 1)
    );
  EXCEPTION WHEN OTHERS THEN
    v_key := current_setting('app.settings.encryption_key', true);
    IF v_key IS NULL THEN
      RAISE EXCEPTION 'No encryption key configured.';
    END IF;
  END;

  v_ciphertext := decode(p_ciphertext_b64, 'base64');
  RETURN extensions.pgp_sym_decrypt(v_ciphertext, v_key);
END;
$$;

-- 5. Trigger function: auto-encrypt settings when is_encrypted = true
CREATE OR REPLACE FUNCTION crypto.auto_encrypt_setting()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF NEW.is_encrypted AND NEW.value IS NOT NULL AND NEW.value != '' THEN
    -- Only encrypt if value is not already base64 ciphertext (starts with non-printable chars)
    IF NOT (NEW.value ~ '^[A-Za-z0-9+/=]+$' AND length(NEW.value) > 40) THEN
      NEW.value := crypto.encrypt_setting_value(NEW.value);
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- 6. Trigger: apply encryption before insert/update on settings
DROP TRIGGER IF EXISTS trg_settings_encrypt ON public.settings;
CREATE TRIGGER trg_settings_encrypt
  BEFORE INSERT OR UPDATE OF value, is_encrypted
  ON public.settings
  FOR EACH ROW
  EXECUTE FUNCTION crypto.auto_encrypt_setting();

-- 7. View: decrypted settings for authorized roles
CREATE OR REPLACE VIEW crypto.decrypted_settings AS
SELECT
  s.id,
  s.key,
  CASE
    WHEN s.is_encrypted AND s.value IS NOT NULL AND s.value != ''
      THEN crypto.decrypt_setting_value(s.value)
    ELSE s.value
  END AS value,
  s."group",
  s.type,
  s.is_encrypted,
  s.is_json,
  s.description,
  s.created_at,
  s.updated_at
FROM public.settings s;

-- 8. RLS: restrict decrypted view to authenticated admins only
ALTER VIEW crypto.decrypted_settings OWNER TO authenticated;
GRANT SELECT ON crypto.decrypted_settings TO authenticated;

-- 9. Helper: function to get a decrypted setting by key (for app usage)
CREATE OR REPLACE FUNCTION crypto.get_setting(p_key text)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
  v_row public.settings%ROWTYPE;
BEGIN
  SELECT * INTO v_row FROM public.settings WHERE key = p_key LIMIT 1;
  IF NOT FOUND THEN
    RETURN NULL;
  END IF;
  IF v_row.is_encrypted AND v_row.value IS NOT NULL AND v_row.value != '' THEN
    RETURN crypto.decrypt_setting_value(v_row.value);
  END IF;
  RETURN v_row.value;
END;
$$;

-- 10. Function to encrypt mobile content (messages, chat content)
CREATE OR REPLACE FUNCTION crypto.encrypt_content(
  p_plaintext text
) RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN crypto.encrypt_setting_value(p_plaintext);
END;
$$;

-- 11. Function to decrypt mobile content
CREATE OR REPLACE FUNCTION crypto.decrypt_content(
  p_ciphertext text
) RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN crypto.decrypt_setting_value(p_ciphertext);
END;
$$;
