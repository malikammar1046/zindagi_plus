-- ============================================================================
-- Migration 008: Fitness Schema (Activity Catalog, Plans & Logs)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: public.activity_catalog
-- Global reference library of exercises, default durations, and calorie burns.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.activity_catalog (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    category TEXT NOT NULL DEFAULT 'cardio',
    default_duration_min INT NOT NULL DEFAULT 30,
    intensity TEXT NOT NULL DEFAULT 'Low',
    est_calories_burned INT NOT NULL DEFAULT 100,
    equipment_required TEXT NOT NULL DEFAULT 'None',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ----------------------------------------------------------------------------
-- Table: public.user_activity_plans
-- Customized weekly physical routine items scheduled by the user.
-- Includes week_start_date and scheduled_date for explicit weekly planning.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_activity_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    activity_id UUID NULL REFERENCES public.activity_catalog(id) ON DELETE SET NULL,
    custom_name TEXT NULL,
    week_start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    scheduled_date DATE NULL,
    target_duration_min INT NOT NULL DEFAULT 30,
    target_intensity TEXT NOT NULL DEFAULT 'Low',
    is_added_to_week BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Composite uniqueness to support parent-child ownership enforcement
    CONSTRAINT uq_user_activity_plans_id_user UNIQUE (id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_user_activity_plans_week ON public.user_activity_plans(user_id, week_start_date, is_added_to_week);

-- ----------------------------------------------------------------------------
-- Table: public.user_activity_logs
-- Completed workout, walking, and exercise session history.
-- Enforces composite foreign key matching the activity plan owner when an activity_plan_id is supplied.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_activity_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    activity_plan_id UUID NULL,
    activity_name TEXT NOT NULL,
    duration_min INT NOT NULL DEFAULT 0,
    calories_burned INT NOT NULL DEFAULT 0,
    steps INT NULL,
    logged_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Enforces that a log cannot reference another user's activity plan
    CONSTRAINT fk_activity_logs_plan_user FOREIGN KEY (activity_plan_id, user_id)
        REFERENCES public.user_activity_plans(id, user_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_activity_logs_user_logged ON public.user_activity_logs(user_id, logged_at DESC);
