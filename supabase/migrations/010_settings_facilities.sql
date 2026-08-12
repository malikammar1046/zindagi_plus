-- ============================================================================
-- Migration 010: Medical Facilities & Notification Settings
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: public.medical_facilities
-- Global reference catalog of verified local hospitals, clinics, and pharmacies.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.medical_facilities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    type TEXT NOT NULL,
    city TEXT NOT NULL DEFAULT 'Lahore',
    address TEXT NOT NULL DEFAULT '',
    latitude NUMERIC(10, 7) NULL,
    longitude NUMERIC(10, 7) NULL,
    phone TEXT NULL,
    is_open_24_7 BOOLEAN NOT NULL DEFAULT FALSE,
    is_verified BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_facilities_city_type ON public.medical_facilities(city, type);

-- ----------------------------------------------------------------------------
-- Table: public.user_notification_settings
-- User preferences for push notification channels and quiet hours.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_notification_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    med_reminders BOOLEAN NOT NULL DEFAULT TRUE,
    weekly_reviews BOOLEAN NOT NULL DEFAULT TRUE,
    report_analysis BOOLEAN NOT NULL DEFAULT TRUE,
    health_insights BOOLEAN NOT NULL DEFAULT FALSE,
    promotions BOOLEAN NOT NULL DEFAULT FALSE,
    quiet_start TIME NOT NULL DEFAULT '22:00:00',
    quiet_end TIME NOT NULL DEFAULT '07:00:00',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_notif_settings_user ON public.user_notification_settings(user_id);
