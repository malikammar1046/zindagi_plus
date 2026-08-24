-- ============================================================================
-- Migration 017: Foundation Hardening & Real-Data Integrity
-- 1. Secure RPC for user account deletion (cascading auth.users and storage).
-- 2. Atomic RPC for multi-table user profile & onboarding synchronization.
-- 3. Hardened v_health_timeline view with explicit security_invoker = true.
-- 4. Default notification settings trigger for new users.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Function: public.delete_user_account()
-- Securely deletes the calling authenticated user's account and all cascaded data.
-- Does NOT require client-side service-role key.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.delete_user_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, storage
AS $$
DECLARE
    v_user_id UUID := auth.uid();
BEGIN
    -- Verify the caller is genuinely authenticated
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated: cannot delete account without an active session.';
    END IF;

    -- Clean up storage objects owned by this user
    BEGIN
        DELETE FROM storage.objects 
        WHERE bucket_id IN ('reports', 'avatars') 
          AND (storage.foldername(name))[1] = v_user_id::TEXT;
    EXCEPTION WHEN OTHERS THEN
        -- Log or continue if storage objects deletion meets non-fatal errors
        RAISE NOTICE 'Notice: Storage cleanup for user % encountered notice: %', v_user_id, SQLERRM;
    END;

    -- Delete user record from auth.users
    -- This automatically cascades to public.profiles and all child tables:
    -- user_goals, user_conditions, user_allergies, medications, medication_dose_logs,
    -- lab_reports, report_biomarkers, user_meal_plans, user_activity_plans,
    -- user_activity_logs, chat_conversations, ai_recommendations, user_notification_settings.
    DELETE FROM auth.users WHERE id = v_user_id;
END;
$$;

-- Grant execution to authenticated users
GRANT EXECUTE ON FUNCTION public.delete_user_account() TO authenticated;


-- ----------------------------------------------------------------------------
-- 2. Function: public.update_user_profile(payload jsonb)
-- Executes atomic multi-table profile & onboarding updates in a single transaction.
-- If any single step fails, PostgreSQL automatically rolls back the entire transaction.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.update_user_profile(payload JSONB)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth
AS $$
DECLARE
    v_user_id UUID := auth.uid();
    v_goals JSONB;
    v_cond TEXT;
    v_allergy TEXT;
BEGIN
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Not authenticated: cannot update profile without an active session.';
    END IF;

    -- 1. Update public.profiles
    UPDATE public.profiles SET
        full_name = COALESCE(payload->>'full_name', full_name),
        date_of_birth = CASE 
            WHEN payload ? 'date_of_birth' AND payload->>'date_of_birth' IS NOT NULL AND payload->>'date_of_birth' != ''
            THEN (payload->>'date_of_birth')::DATE 
            ELSE date_of_birth 
        END,
        gender = COALESCE(payload->>'gender', gender),
        height_cm = CASE 
            WHEN payload ? 'height_cm' AND payload->>'height_cm' IS NOT NULL AND payload->>'height_cm' != ''
            THEN (payload->>'height_cm')::NUMERIC(5,1) 
            ELSE height_cm 
        END,
        weight_kg = CASE 
            WHEN payload ? 'weight_kg' AND payload->>'weight_kg' IS NOT NULL AND payload->>'weight_kg' != ''
            THEN (payload->>'weight_kg')::NUMERIC(5,1) 
            ELSE weight_kg 
        END,
        blood_type = COALESCE(payload->>'blood_type', blood_type),
        city = COALESCE(payload->>'city', city),
        phone = COALESCE(payload->>'phone', phone),
        avatar_url = COALESCE(payload->>'avatar_url', avatar_url),
        is_onboarding_completed = CASE 
            WHEN payload ? 'is_onboarding_completed' AND payload->>'is_onboarding_completed' IS NOT NULL
            THEN (payload->>'is_onboarding_completed')::BOOLEAN 
            ELSE is_onboarding_completed 
        END,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = v_user_id;

    -- 2. Upsert public.user_goals if provided in payload
    IF payload ? 'goals' AND payload->'goals' IS NOT NULL THEN
        v_goals := payload->'goals';
        INSERT INTO public.user_goals (
            user_id,
            primary_goal,
            secondary_goals,
            activity_level,
            fitness_experience,
            workout_time_per_day,
            equipment,
            diet_type,
            food_preferences,
            foods_to_avoid,
            updated_at
        ) VALUES (
            v_user_id,
            COALESCE(v_goals->>'primary_goal', 'Improve overall health'),
            COALESCE((SELECT array_agg(x)::TEXT[] FROM jsonb_array_elements_text(v_goals->'secondary_goals') t(x)), '{}'::TEXT[]),
            COALESCE(v_goals->>'activity_level', 'Lightly active'),
            COALESCE(v_goals->>'fitness_experience', 'Beginner'),
            COALESCE(v_goals->>'workout_time_per_day', '30 minutes'),
            COALESCE(v_goals->>'equipment', 'Basic home equipment'),
            COALESCE(v_goals->>'diet_type', 'No specific diet'),
            COALESCE((SELECT array_agg(x)::TEXT[] FROM jsonb_array_elements_text(v_goals->'food_preferences') t(x)), '{}'::TEXT[]),
            COALESCE((SELECT array_agg(x)::TEXT[] FROM jsonb_array_elements_text(v_goals->'foods_to_avoid') t(x)), '{}'::TEXT[]),
            CURRENT_TIMESTAMP
        )
        ON CONFLICT (user_id) DO UPDATE SET
            primary_goal = EXCLUDED.primary_goal,
            secondary_goals = EXCLUDED.secondary_goals,
            activity_level = EXCLUDED.activity_level,
            fitness_experience = EXCLUDED.fitness_experience,
            workout_time_per_day = EXCLUDED.workout_time_per_day,
            equipment = EXCLUDED.equipment,
            diet_type = EXCLUDED.diet_type,
            food_preferences = EXCLUDED.food_preferences,
            foods_to_avoid = EXCLUDED.foods_to_avoid,
            updated_at = CURRENT_TIMESTAMP;
    END IF;

    -- 3. Atomically replace public.user_conditions
    IF payload ? 'conditions' AND payload->'conditions' IS NOT NULL THEN
        DELETE FROM public.user_conditions WHERE user_id = v_user_id;
        FOR v_cond IN SELECT jsonb_array_elements_text(payload->'conditions')
        LOOP
            IF v_cond IS NOT NULL AND v_cond != 'None' AND trim(v_cond) != '' THEN
                INSERT INTO public.user_conditions (user_id, condition_name)
                VALUES (v_user_id, trim(v_cond))
                ON CONFLICT (user_id, condition_name) DO NOTHING;
            END IF;
        END LOOP;
    END IF;

    -- 4. Atomically replace public.user_allergies
    IF payload ? 'allergies' AND payload->'allergies' IS NOT NULL THEN
        DELETE FROM public.user_allergies WHERE user_id = v_user_id;
        FOR v_allergy IN SELECT jsonb_array_elements_text(payload->'allergies')
        LOOP
            IF v_allergy IS NOT NULL AND v_allergy != 'None' AND trim(v_allergy) != '' THEN
                INSERT INTO public.user_allergies (user_id, allergen_name, severity)
                VALUES (v_user_id, trim(v_allergy), 'moderate')
                ON CONFLICT (user_id, allergen_name) DO NOTHING;
            END IF;
        END LOOP;
    END IF;

    RETURN jsonb_build_object('success', TRUE, 'user_id', v_user_id);
END;
$$;

-- Grant execution to authenticated users
GRANT EXECUTE ON FUNCTION public.update_user_profile(JSONB) TO authenticated;


-- ----------------------------------------------------------------------------
-- 3. Hardened View: public.v_health_timeline WITH (security_invoker = true)
-- In PostgreSQL 15+, setting security_invoker = true guarantees that PostgREST queries
-- enforce the caller's (auth.uid()) RLS policies on all underlying tables.
-- ----------------------------------------------------------------------------
DROP VIEW IF EXISTS public.v_health_timeline;

CREATE VIEW public.v_health_timeline
WITH (security_invoker = true) AS

-- 1. Medication Adherence Events
SELECT 
    l.id AS id,
    l.user_id AS user_id,
    l.logged_at AS event_timestamp,
    'Medication'::TEXT AS category,
    m.name || ' (' || m.dose || ') ' || l.status AS title,
    'Dose scheduled at ' || COALESCE(m.schedule_time, m.scheduled_time_of_day, '') AS subtitle,
    l.status::TEXT AS status
FROM public.medication_dose_logs l
JOIN public.medications m ON l.medication_id = m.id

UNION ALL

-- 2. Diagnostic Lab Report Uploads
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

-- 3. Completed Physical Activities
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

-- 4. High-Priority Health Alerts & Action Items
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

-- Grant access to authenticated users
GRANT SELECT ON public.v_health_timeline TO authenticated;


-- ----------------------------------------------------------------------------
-- 4. Auto-Provisioning for public.user_notification_settings
-- Automatically creates default notification settings when a new profile is created.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user_notification_settings()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.user_notification_settings (
        user_id,
        med_reminders,
        weekly_reviews,
        report_analysis,
        health_insights,
        promotions,
        quiet_start,
        quiet_end,
        created_at,
        updated_at
    )
    VALUES (
        NEW.id,
        TRUE,
        TRUE,
        TRUE,
        FALSE,
        FALSE,
        '22:00:00'::TIME,
        '07:00:00'::TIME,
        CURRENT_TIMESTAMP,
        CURRENT_TIMESTAMP
    )
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_profile_created_notification_settings ON public.profiles;

CREATE TRIGGER on_profile_created_notification_settings
    AFTER INSERT ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user_notification_settings();
