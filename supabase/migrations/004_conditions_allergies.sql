-- ============================================================================
-- Migration 004: Health Conditions & Allergies Tables
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: public.user_conditions
-- Normalized tracking of patient chronic or pre-existing medical conditions.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_conditions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    condition_name TEXT NOT NULL,
    diagnosed_date DATE NULL,
    notes TEXT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_user_conditions UNIQUE (user_id, condition_name)
);

CREATE INDEX IF NOT EXISTS idx_user_conditions_user_id ON public.user_conditions(user_id);

-- ----------------------------------------------------------------------------
-- Table: public.user_allergies
-- Normalized tracking of patient sensitivities and food/drug allergies.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_allergies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    allergen_name TEXT NOT NULL,
    severity TEXT NOT NULL DEFAULT 'moderate',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_allergy_severity CHECK (severity IN ('mild', 'moderate', 'severe')),
    CONSTRAINT uq_user_allergies UNIQUE (user_id, allergen_name)
);

CREATE INDEX IF NOT EXISTS idx_user_allergies_user_id ON public.user_allergies(user_id);
