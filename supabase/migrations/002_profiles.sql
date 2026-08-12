-- ============================================================================
-- Migration 002: Profiles Table & Auth Trigger
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: public.profiles
-- Core user demographic, biometric baseline, and onboarding status.
-- References auth.users(id) directly as its Primary Key.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL DEFAULT '',
    date_of_birth DATE NULL,
    gender TEXT NULL,
    height_cm NUMERIC(5, 1) NULL,
    weight_kg NUMERIC(5, 1) NULL,
    blood_type TEXT NULL,
    city TEXT NULL DEFAULT NULL,
    phone TEXT NULL,
    avatar_url TEXT NULL,
    is_onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Constraints
    CONSTRAINT chk_profiles_height CHECK (height_cm IS NULL OR (height_cm >= 30.0 AND height_cm <= 300.0)),
    CONSTRAINT chk_profiles_weight CHECK (weight_kg IS NULL OR (weight_kg >= 10.0 AND weight_kg <= 500.0)),
    CONSTRAINT chk_profiles_gender CHECK (gender IS NULL OR gender IN ('Male', 'Female', 'Other', 'Prefer not to say')),
    CONSTRAINT chk_profiles_blood_type CHECK (blood_type IS NULL OR blood_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'))
);

CREATE INDEX IF NOT EXISTS idx_profiles_city ON public.profiles(city);

-- ----------------------------------------------------------------------------
-- Function & Trigger: handle_new_user
-- Automatically creates a corresponding public.profiles entry when a new user
-- registers through Supabase Auth.
-- Hardened with SECURITY DEFINER and explicit safe search_path.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (
        id,
        full_name,
        is_onboarding_completed,
        created_at,
        updated_at
    )
    VALUES (
        NEW.id,
        COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', ''),
        FALSE,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, auth;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();
