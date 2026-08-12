-- ============================================================================
-- Migration 003: User Goals & Preferences Table
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: public.user_goals
-- Stores primary/secondary wellness targets, baseline activity tier, workout
-- equipment, and dietary styles collected during onboarding or profile editing.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
    primary_goal TEXT NOT NULL DEFAULT 'Improve overall health',
    secondary_goals TEXT[] NOT NULL DEFAULT '{}',
    activity_level TEXT NOT NULL DEFAULT 'Lightly active',
    fitness_experience TEXT NOT NULL DEFAULT 'Beginner',
    workout_time_per_day TEXT NOT NULL DEFAULT '30 minutes',
    equipment TEXT NOT NULL DEFAULT 'Basic home equipment',
    diet_type TEXT NOT NULL DEFAULT 'No specific diet',
    food_preferences TEXT[] NOT NULL DEFAULT '{}',
    foods_to_avoid TEXT[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_user_goals_user_id ON public.user_goals(user_id);
