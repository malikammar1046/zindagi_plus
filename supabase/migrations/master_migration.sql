-- ============================================================================
-- ZINDAGI+ REFERENCE COMBINED MIGRATION SCRIPT
-- ============================================================================
-- CAUTION / IMPORTANT NOTICE:
-- The CANONICAL migration source for this project is the set of modular files:
--   supabase/migrations/001_extensions.sql
--   supabase/migrations/002_profiles.sql
--   ...
--   supabase/migrations/014_views.sql
--
-- DO NOT execute this file if you are using Supabase CLI / automated migrations,
-- as running both will cause duplicate execution errors.
-- This combined file is provided SOLELY as a static, single-file reference.
-- ============================================================================

-- ============================================================================
-- 001_extensions.sql
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

-- ============================================================================
-- 002_profiles.sql
-- ============================================================================
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

    CONSTRAINT chk_profiles_height CHECK (height_cm IS NULL OR (height_cm >= 30.0 AND height_cm <= 300.0)),
    CONSTRAINT chk_profiles_weight CHECK (weight_kg IS NULL OR (weight_kg >= 10.0 AND weight_kg <= 500.0)),
    CONSTRAINT chk_profiles_gender CHECK (gender IS NULL OR gender IN ('Male', 'Female', 'Other', 'Prefer not to say')),
    CONSTRAINT chk_profiles_blood_type CHECK (blood_type IS NULL OR blood_type IN ('A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'))
);

CREATE INDEX IF NOT EXISTS idx_profiles_city ON public.profiles(city);

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

-- ============================================================================
-- 003_user_goals.sql
-- ============================================================================
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

-- ============================================================================
-- 004_conditions_allergies.sql
-- ============================================================================
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

-- ============================================================================
-- 005_medications.sql
-- ============================================================================
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

    CONSTRAINT uq_medications_id_user UNIQUE (id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_medications_user_active ON public.medications(user_id, is_active);

CREATE TABLE IF NOT EXISTS public.medication_dose_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    medication_id UUID NOT NULL,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL,
    logged_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_dose_log_status CHECK (status IN ('taken', 'missed')),
    CONSTRAINT fk_dose_logs_medication_user FOREIGN KEY (medication_id, user_id)
        REFERENCES public.medications(id, user_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_dose_logs_user_logged ON public.medication_dose_logs(user_id, logged_at DESC);
CREATE INDEX IF NOT EXISTS idx_dose_logs_med_id ON public.medication_dose_logs(medication_id);

-- ============================================================================
-- 006_lab_reports.sql
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.lab_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    file_size_bytes BIGINT NULL,
    mime_type TEXT NULL,
    status TEXT NOT NULL DEFAULT 'uploaded',
    extracted_text TEXT NOT NULL DEFAULT '',
    ai_summary TEXT NOT NULL DEFAULT '',
    error_message TEXT NULL,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMPTZ NULL,

    CONSTRAINT chk_lab_report_status CHECK (status IN ('uploaded', 'processing', 'completed', 'processed', 'failed')),
    CONSTRAINT uq_lab_reports_id_user UNIQUE (id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_lab_reports_user_uploaded ON public.lab_reports(user_id, uploaded_at DESC);

CREATE TABLE IF NOT EXISTS public.report_biomarkers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    report_id UUID NOT NULL,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    biomarker_name TEXT NOT NULL,
    measured_value TEXT NOT NULL,
    numeric_value NUMERIC(8, 2) NULL,
    unit TEXT NULL,
    reference_range TEXT NOT NULL DEFAULT '',
    reference_low NUMERIC(8, 2) NULL,
    reference_high NUMERIC(8, 2) NULL,
    status TEXT NOT NULL DEFAULT 'normal',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_biomarker_status CHECK (status IN ('normal', 'borderline', 'high', 'low')),
    CONSTRAINT fk_report_biomarkers_report_user FOREIGN KEY (report_id, user_id)
        REFERENCES public.lab_reports(id, user_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_biomarkers_user_name ON public.report_biomarkers(user_id, biomarker_name);
CREATE INDEX IF NOT EXISTS idx_biomarkers_report_id ON public.report_biomarkers(report_id);

-- ============================================================================
-- 007_nutrition.sql
-- ============================================================================
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

CREATE TABLE IF NOT EXISTS public.user_meal_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    week_start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    title TEXT NOT NULL DEFAULT 'Weekly Health Plan',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_user_meal_plan_week UNIQUE (user_id, week_start_date),
    CONSTRAINT uq_user_meal_plans_id_user UNIQUE (id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_meal_plans_user ON public.user_meal_plans(user_id, is_active);

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
    CONSTRAINT fk_meal_plan_items_plan_user FOREIGN KEY (meal_plan_id, user_id)
        REFERENCES public.user_meal_plans(id, user_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_meal_items_plan ON public.user_meal_plan_items(meal_plan_id, day_of_week);
CREATE INDEX IF NOT EXISTS idx_meal_items_user ON public.user_meal_plan_items(user_id);

-- ============================================================================
-- 008_fitness.sql
-- ============================================================================
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

    CONSTRAINT uq_user_activity_plans_id_user UNIQUE (id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_user_activity_plans_week ON public.user_activity_plans(user_id, week_start_date, is_added_to_week);

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

    CONSTRAINT fk_activity_logs_plan_user FOREIGN KEY (activity_plan_id, user_id)
        REFERENCES public.user_activity_plans(id, user_id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_activity_logs_user_logged ON public.user_activity_logs(user_id, logged_at DESC);

-- ============================================================================
-- 009_chat_recommendations.sql
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.chat_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL DEFAULT 'Health Consultation',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_chat_conversations_id_user UNIQUE (id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_chat_conversations_user ON public.chat_conversations(user_id, updated_at DESC);

CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    is_user BOOLEAN NOT NULL,
    text TEXT NOT NULL,
    sources TEXT[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_chat_messages_conv_user FOREIGN KEY (conversation_id, user_id)
        REFERENCES public.chat_conversations(id, user_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_conv ON public.chat_messages(conversation_id, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user ON public.chat_messages(user_id);

-- ============================================================================
-- 009 continued: AI Recommendations
-- ============================================================================
CREATE TABLE IF NOT EXISTS public.ai_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL DEFAULT 'insight',
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    priority TEXT NOT NULL DEFAULT 'medium',
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    action_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    expires_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_rec_type CHECK (type IN ('medication', 'nutrition', 'activity', 'insight')),
    CONSTRAINT chk_rec_priority CHECK (priority IN ('high', 'medium', 'low'))
);

CREATE INDEX IF NOT EXISTS idx_ai_recommendations_user ON public.ai_recommendations(user_id, is_completed, priority);

-- ============================================================================
-- 010_settings_facilities.sql
-- ============================================================================
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

-- ============================================================================
-- 011_triggers_functions.sql
-- ============================================================================
DROP TRIGGER IF EXISTS trg_profiles_updated_at ON public.profiles;
CREATE TRIGGER trg_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_user_goals_updated_at ON public.user_goals;
CREATE TRIGGER trg_user_goals_updated_at
    BEFORE UPDATE ON public.user_goals
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_medications_updated_at ON public.medications;
CREATE TRIGGER trg_medications_updated_at
    BEFORE UPDATE ON public.medications
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_user_meal_plans_updated_at ON public.user_meal_plans;
CREATE TRIGGER trg_user_meal_plans_updated_at
    BEFORE UPDATE ON public.user_meal_plans
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_user_activity_plans_updated_at ON public.user_activity_plans;
CREATE TRIGGER trg_user_activity_plans_updated_at
    BEFORE UPDATE ON public.user_activity_plans
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_ai_recommendations_updated_at ON public.ai_recommendations;
CREATE TRIGGER trg_ai_recommendations_updated_at
    BEFORE UPDATE ON public.ai_recommendations
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_chat_conversations_updated_at ON public.chat_conversations;
CREATE TRIGGER trg_chat_conversations_updated_at
    BEFORE UPDATE ON public.chat_conversations
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS trg_notif_settings_updated_at ON public.user_notification_settings;
CREATE TRIGGER trg_notif_settings_updated_at
    BEFORE UPDATE ON public.user_notification_settings
    FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

CREATE OR REPLACE FUNCTION public.calculate_patient_age(p_dob DATE)
RETURNS INT AS $$
BEGIN
    IF p_dob IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN EXTRACT(YEAR FROM age(CURRENT_DATE, p_dob))::INT;
END;
$$ LANGUAGE plpgsql STABLE SET search_path = public;

CREATE OR REPLACE FUNCTION public.fn_get_patient_health_metrics(p_user_id UUID)
RETURNS JSONB AS $$
DECLARE
    v_active_meds INT;
    v_doses_taken INT;
    v_doses_total INT;
    v_latest_report_id UUID;
    v_total_biomarkers INT;
    v_normal_biomarkers INT;
    v_weekly_activity_mins INT;
    v_weekly_meals_consumed INT;
    v_result JSONB;
BEGIN
    SELECT COUNT(*) INTO v_active_meds 
    FROM public.medications 
    WHERE user_id = p_user_id AND is_active = TRUE;

    SELECT 
        COUNT(*) FILTER (WHERE status = 'taken'),
        COUNT(*)
    INTO v_doses_taken, v_doses_total
    FROM public.medication_dose_logs
    WHERE user_id = p_user_id 
      AND logged_at >= (CURRENT_TIMESTAMP - INTERVAL '30 days');

    SELECT id INTO v_latest_report_id
    FROM public.lab_reports
    WHERE user_id = p_user_id AND status = 'processed'
    ORDER BY uploaded_at DESC
    LIMIT 1;

    IF v_latest_report_id IS NOT NULL THEN
        SELECT 
            COUNT(*),
            COUNT(*) FILTER (WHERE status = 'normal')
        INTO v_total_biomarkers, v_normal_biomarkers
        FROM public.report_biomarkers
        WHERE report_id = v_latest_report_id;
    ELSE
        v_total_biomarkers := 0;
        v_normal_biomarkers := 0;
    END IF;

    SELECT COALESCE(SUM(duration_min), 0) INTO v_weekly_activity_mins
    FROM public.user_activity_logs
    WHERE user_id = p_user_id 
      AND logged_at >= date_trunc('week', CURRENT_TIMESTAMP);

    SELECT COUNT(*) INTO v_weekly_meals_consumed
    FROM public.user_meal_plan_items
    WHERE user_id = p_user_id 
      AND is_consumed = TRUE
      AND logged_at >= date_trunc('week', CURRENT_TIMESTAMP);

    v_result := jsonb_build_object(
        'active_medications_count', v_active_meds,
        'doses_taken_30d', v_doses_taken,
        'doses_total_30d', v_doses_total,
        'latest_report_id', v_latest_report_id,
        'biomarkers_total_count', v_total_biomarkers,
        'biomarkers_normal_count', v_normal_biomarkers,
        'weekly_activity_minutes', v_weekly_activity_mins,
        'weekly_meals_consumed', v_weekly_meals_consumed
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

-- ============================================================================
-- 012_rls.sql
-- ============================================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "profiles_select_own" ON public.profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "profiles_insert_own" ON public.profiles FOR INSERT WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_update_own" ON public.profiles FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);
CREATE POLICY "profiles_delete_own" ON public.profiles FOR DELETE USING (auth.uid() = id);

ALTER TABLE public.user_goals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_goals_select_own" ON public.user_goals FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "user_goals_insert_own" ON public.user_goals FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_goals_update_own" ON public.user_goals FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_goals_delete_own" ON public.user_goals FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE public.user_conditions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_conditions_select_own" ON public.user_conditions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "user_conditions_insert_own" ON public.user_conditions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_conditions_update_own" ON public.user_conditions FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_conditions_delete_own" ON public.user_conditions FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE public.user_allergies ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_allergies_select_own" ON public.user_allergies FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "user_allergies_insert_own" ON public.user_allergies FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_allergies_update_own" ON public.user_allergies FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_allergies_delete_own" ON public.user_allergies FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE public.medications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "medications_select_own" ON public.medications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "medications_insert_own" ON public.medications FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "medications_update_own" ON public.medications FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "medications_delete_own" ON public.medications FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE public.medication_dose_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "dose_logs_select_own" ON public.medication_dose_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "dose_logs_insert_own" ON public.medication_dose_logs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "dose_logs_update_own" ON public.medication_dose_logs FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "dose_logs_delete_own" ON public.medication_dose_logs FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE public.lab_reports ENABLE ROW LEVEL SECURITY;
CREATE POLICY "lab_reports_select_own" ON public.lab_reports FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "lab_reports_insert_own" ON public.lab_reports FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "lab_reports_update_own" ON public.lab_reports FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "lab_reports_delete_own" ON public.lab_reports FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE public.report_biomarkers ENABLE ROW LEVEL SECURITY;
CREATE POLICY "report_biomarkers_select_own" ON public.report_biomarkers FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "report_biomarkers_insert_own" ON public.report_biomarkers FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "report_biomarkers_update_own" ON public.report_biomarkers FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "report_biomarkers_delete_own" ON public.report_biomarkers FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE public.user_meal_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "user_meal_plans_select_own" ON public.user_meal_plans FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "user_meal_plans_insert_own" ON public.user_meal_plans FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_meal_plans_update_own" ON public.user_meal_plans FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "user_meal_plans_delete_own" ON public.user_meal_plans FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE public.user_meal_plan_items ENABLE ROW LEVEL SECURITY;
CREATE POLICY "meal_plan_items_select_own" ON public.user_meal_plan_items FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "meal_plan_items_insert_own" ON public.user_meal_plan_items FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "meal_plan_items_update_own" ON public.user_meal_plan_items FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "meal_plan_items_delete_own" ON public.user_meal_plan_items FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE public.user_activity_plans ENABLE ROW LEVEL SECURITY;
CREATE POLICY "activity_plans_select_own" ON public.user_activity_plans FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "activity_plans_insert_own" ON public.user_activity_plans FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "activity_plans_update_own" ON public.user_activity_plans FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "activity_plans_delete_own" ON public.user_activity_plans FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE public.user_activity_logs ENABLE ROW LEVEL SECURITY;
CREATE POLICY "activity_logs_select_own" ON public.user_activity_logs FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "activity_logs_insert_own" ON public.user_activity_logs FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "activity_logs_update_own" ON public.user_activity_logs FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "activity_logs_delete_own" ON public.user_activity_logs FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE public.ai_recommendations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "ai_recs_select_own" ON public.ai_recommendations FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "ai_recs_insert_own" ON public.ai_recommendations FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "ai_recs_update_own" ON public.ai_recommendations FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "ai_recs_delete_own" ON public.ai_recommendations FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE public.chat_conversations ENABLE ROW LEVEL SECURITY;
CREATE POLICY "chat_conv_select_own" ON public.chat_conversations FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "chat_conv_insert_own" ON public.chat_conversations FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "chat_conv_update_own" ON public.chat_conversations FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "chat_conv_delete_own" ON public.chat_conversations FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "chat_msg_select_own" ON public.chat_messages FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "chat_msg_insert_own" ON public.chat_messages FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "chat_msg_update_own" ON public.chat_messages FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "chat_msg_delete_own" ON public.chat_messages FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;
CREATE POLICY "notif_settings_select_own" ON public.user_notification_settings FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "notif_settings_insert_own" ON public.user_notification_settings FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "notif_settings_update_own" ON public.user_notification_settings FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);
CREATE POLICY "notif_settings_delete_own" ON public.user_notification_settings FOR DELETE USING (auth.uid() = user_id);

ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "recipes_select_authenticated" ON public.recipes FOR SELECT USING (auth.role() = 'authenticated');

ALTER TABLE public.activity_catalog ENABLE ROW LEVEL SECURITY;
CREATE POLICY "activity_catalog_select_authenticated" ON public.activity_catalog FOR SELECT USING (auth.role() = 'authenticated');

ALTER TABLE public.medical_facilities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "medical_facilities_select_authenticated" ON public.medical_facilities FOR SELECT USING (auth.role() = 'authenticated');

-- ============================================================================
-- 013_storage.sql
-- ============================================================================
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'reports',
    'reports',
    FALSE,
    15728640,
    ARRAY['image/jpeg', 'image/png', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    TRUE,
    5242880,
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

CREATE POLICY "reports_select_own" ON storage.objects
    FOR SELECT TO authenticated
    USING (bucket_id = 'reports' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "reports_insert_own" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'reports' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "reports_update_own" ON storage.objects
    FOR UPDATE TO authenticated
    USING (bucket_id = 'reports' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "reports_delete_own" ON storage.objects
    FOR DELETE TO authenticated
    USING (bucket_id = 'reports' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "avatars_select_public" ON storage.objects
    FOR SELECT USING (bucket_id = 'avatars');

CREATE POLICY "avatars_insert_own" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "avatars_update_own" ON storage.objects
    FOR UPDATE TO authenticated
    USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

CREATE POLICY "avatars_delete_own" ON storage.objects
    FOR DELETE TO authenticated
    USING (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- ============================================================================
-- 014_views.sql
-- ============================================================================
CREATE OR REPLACE VIEW public.v_health_timeline AS
SELECT 
    l.id AS id,
    l.user_id AS user_id,
    l.logged_at AS event_timestamp,
    'Medication'::TEXT AS category,
    m.name || ' (' || m.dose || ') ' || l.status AS title,
    'Dose scheduled at ' || m.schedule_time AS subtitle,
    l.status::TEXT AS status
FROM public.medication_dose_logs l
JOIN public.medications m ON l.medication_id = m.id

UNION ALL

SELECT 
    r.id AS id,
    r.user_id AS user_id,
    r.uploaded_at AS event_timestamp,
    'Report'::TEXT AS category,
    'Lab Report: ' || r.file_name AS title,
    COALESCE(NULLIF(r.ai_summary, ''), 'Document status: ' || r.status) AS subtitle,
    r.status::TEXT AS status
FROM public.lab_reports r

UNION ALL

SELECT 
    a.id AS id,
    a.user_id AS user_id,
    a.logged_at AS event_timestamp,
    'Activity'::TEXT AS category,
    a.activity_name AS title,
    a.duration_min || ' min · ' || a.calories_burned || ' kcal burned' AS subtitle,
    'completed'::TEXT AS status
FROM public.user_activity_logs a

UNION ALL

SELECT 
    rec.id AS id,
    rec.user_id AS user_id,
    rec.created_at AS event_timestamp,
    'Alert'::TEXT AS category,
    rec.title AS title,
    rec.description AS subtitle,
    rec.priority::TEXT AS status
FROM public.ai_recommendations rec
WHERE rec.priority = 'high';
