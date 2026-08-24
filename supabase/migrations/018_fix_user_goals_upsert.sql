-- ============================================================================
-- Migration 018: Explicit User Goals Upsert & Profile Update Hardening
-- ============================================================================
-- Fixes unique constraint violations ("user_goals_user_id_key") during profile
-- editing by explicitly checking existence and performing UPDATE vs INSERT.
-- ============================================================================

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

    -- 2. Update or Insert public.user_goals safely
    IF payload ? 'goals' AND payload->'goals' IS NOT NULL THEN
        v_goals := payload->'goals';
        
        IF EXISTS (SELECT 1 FROM public.user_goals WHERE user_id = v_user_id) THEN
            UPDATE public.user_goals SET
                primary_goal = COALESCE(v_goals->>'primary_goal', primary_goal),
                secondary_goals = CASE 
                    WHEN v_goals ? 'secondary_goals' AND v_goals->'secondary_goals' IS NOT NULL 
                    THEN COALESCE((SELECT array_agg(x)::TEXT[] FROM jsonb_array_elements_text(v_goals->'secondary_goals') t(x)), '{}'::TEXT[])
                    ELSE secondary_goals 
                END,
                activity_level = COALESCE(v_goals->>'activity_level', activity_level),
                fitness_experience = COALESCE(v_goals->>'fitness_experience', fitness_experience),
                workout_time_per_day = COALESCE(v_goals->>'workout_time_per_day', workout_time_per_day),
                equipment = COALESCE(v_goals->>'equipment', equipment),
                diet_type = COALESCE(v_goals->>'diet_type', diet_type),
                food_preferences = CASE 
                    WHEN v_goals ? 'food_preferences' AND v_goals->'food_preferences' IS NOT NULL 
                    THEN COALESCE((SELECT array_agg(x)::TEXT[] FROM jsonb_array_elements_text(v_goals->'food_preferences') t(x)), '{}'::TEXT[])
                    ELSE food_preferences 
                END,
                foods_to_avoid = CASE 
                    WHEN v_goals ? 'foods_to_avoid' AND v_goals->'foods_to_avoid' IS NOT NULL 
                    THEN COALESCE((SELECT array_agg(x)::TEXT[] FROM jsonb_array_elements_text(v_goals->'foods_to_avoid') t(x)), '{}'::TEXT[])
                    ELSE foods_to_avoid 
                END,
                updated_at = CURRENT_TIMESTAMP
            WHERE user_id = v_user_id;
        ELSE
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
                created_at,
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
                CURRENT_TIMESTAMP,
                CURRENT_TIMESTAMP
            );
        END IF;
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

GRANT EXECUTE ON FUNCTION public.update_user_profile(JSONB) TO authenticated;
