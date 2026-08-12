-- ============================================================================
-- Migration 005: Medications & Dose Logs Tables
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: public.medications
-- Active and archived prescription schedules.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.medications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    dose TEXT NOT NULL,
    schedule_time TEXT NOT NULL,
    scheduled_time_of_day TIME NULL,
    notes TEXT NOT NULL DEFAULT '',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Composite uniqueness to support parent-child ownership enforcement
    CONSTRAINT uq_medications_id_user UNIQUE (id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_medications_user_active ON public.medications(user_id, is_active);

-- ----------------------------------------------------------------------------
-- Table: public.medication_dose_logs
-- Historical adherence logs tracking taken and missed doses.
-- Normalized design with composite foreign key enforcing strict parent-child ownership.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.medication_dose_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    medication_id UUID NOT NULL,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    logged_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_dose_log_status CHECK (status IN ('taken', 'missed')),
    -- Enforces that a dose log cannot reference another user's medication
    CONSTRAINT fk_dose_logs_medication_user FOREIGN KEY (medication_id, user_id)
        REFERENCES public.medications(id, user_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_dose_logs_user_logged ON public.medication_dose_logs(user_id, logged_at DESC);
CREATE INDEX IF NOT EXISTS idx_dose_logs_med_id ON public.medication_dose_logs(medication_id);
