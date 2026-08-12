-- ============================================================================
-- Migration 007: Nutrition Schema (Recipes & User Meal Plans)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: public.recipes
-- Global reference catalog of healthy recipes with clinical macronutrients.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.recipes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    calories INT NOT NULL,
    protein_g NUMERIC(5, 1) NOT NULL,
    carbs_g NUMERIC(5, 1) NOT NULL,
    fat_g NUMERIC(5, 1) NOT NULL,
    serving_size TEXT NOT NULL DEFAULT '1 portion',
    emoji TEXT NOT NULL DEFAULT '🍲',
    clinical_reason TEXT NOT NULL DEFAULT '',
    dietary_tags TEXT[] NOT NULL DEFAULT '{}',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX IF NOT EXISTS idx_recipes_tags ON public.recipes USING gin(dietary_tags);

-- ----------------------------------------------------------------------------
-- Table: public.user_meal_plans
-- Weekly meal plan container for an authenticated user.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_meal_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    week_start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    title TEXT NOT NULL DEFAULT 'Weekly Health Plan',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_user_meal_plan_week UNIQUE (user_id, week_start_date),
    -- Composite uniqueness to support parent-child ownership enforcement
    CONSTRAINT uq_user_meal_plans_id_user UNIQUE (id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_meal_plans_user ON public.user_meal_plans(user_id, is_active);

-- ----------------------------------------------------------------------------
-- Table: public.user_meal_plan_items
-- Individual recipe items assigned to specific days/meal slots in a plan.
-- Enforces composite foreign key matching the meal plan owner.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.user_meal_plan_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meal_plan_id UUID NOT NULL,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    recipe_id UUID NOT NULL REFERENCES public.recipes(id) ON DELETE RESTRICT,
    day_of_week INT NOT NULL DEFAULT 1,
    meal_type TEXT NOT NULL DEFAULT 'lunch',
    is_consumed BOOLEAN NOT NULL DEFAULT FALSE,
    logged_at TIMESTAMPTZ NULL,

    CONSTRAINT chk_day_of_week CHECK (day_of_week BETWEEN 1 AND 7),
    CONSTRAINT chk_meal_type CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack')),
    -- Enforces that a meal item cannot reference another user's meal plan
    CONSTRAINT fk_meal_plan_items_plan_user FOREIGN KEY (meal_plan_id, user_id)
        REFERENCES public.user_meal_plans(id, user_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_meal_items_plan ON public.user_meal_plan_items(meal_plan_id, day_of_week);
CREATE INDEX IF NOT EXISTS idx_meal_items_user ON public.user_meal_plan_items(user_id);
