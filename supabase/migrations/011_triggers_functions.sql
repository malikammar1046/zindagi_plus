-- ============================================================================
-- Migration 011: Triggers & Dynamic Helper Functions
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Apply handle_updated_at trigger across all applicable tables
-- ----------------------------------------------------------------------------

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

-- ----------------------------------------------------------------------------
-- Function: calculate_patient_age
-- Dynamically calculates exact clinical age in years from date_of_birth.
-- Marked STABLE because output depends on CURRENT_DATE.
-- Hardened with explicit safe search_path.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.calculate_patient_age(p_dob DATE)
RETURNS INT AS $$
BEGIN
    IF p_dob IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN EXTRACT(YEAR FROM age(CURRENT_DATE, p_dob))::INT;
END;
$$ LANGUAGE plpgsql STABLE SET search_path = public;

-- ----------------------------------------------------------------------------
-- Function: fn_get_patient_health_metrics
-- Aggregates raw metrics for the 4 health score pillars dynamically without
-- hardcoding arbitrary weights into the schema.
-- Hardened with SECURITY DEFINER and explicit safe search_path.
-- ----------------------------------------------------------------------------
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
    -- 1. Medication Adherence (past 30 days)
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

    -- 2. Latest Lab Report Biomarkers
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

    -- 3. Activity Minutes (current week)
    SELECT COALESCE(SUM(duration_min), 0) INTO v_weekly_activity_mins
    FROM public.user_activity_logs
    WHERE user_id = p_user_id 
      AND logged_at >= date_trunc('week', CURRENT_TIMESTAMP);

    -- 4. Nutrition Adherence (current week)
    SELECT COUNT(*) INTO v_weekly_meals_consumed
    FROM public.user_meal_plan_items
    WHERE user_id = p_user_id 
      AND is_consumed = TRUE
      AND logged_at >= date_trunc('week', CURRENT_TIMESTAMP);

    -- Build Raw Output Object
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
