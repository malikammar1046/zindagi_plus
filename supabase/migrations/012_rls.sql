-- ============================================================================
-- Migration 012: Row Level Security (RLS) Policies
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. Profiles
-- ----------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select_own" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "profiles_insert_own" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_update_own" ON public.profiles
    FOR UPDATE USING (auth.uid() = id) WITH CHECK (auth.uid() = id);

CREATE POLICY "profiles_delete_own" ON public.profiles
    FOR DELETE USING (auth.uid() = id);

-- ----------------------------------------------------------------------------
-- 2. User Goals
-- ----------------------------------------------------------------------------
ALTER TABLE public.user_goals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_goals_select_own" ON public.user_goals
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "user_goals_insert_own" ON public.user_goals
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_goals_update_own" ON public.user_goals
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_goals_delete_own" ON public.user_goals
    FOR DELETE USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 3. User Conditions
-- ----------------------------------------------------------------------------
ALTER TABLE public.user_conditions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_conditions_select_own" ON public.user_conditions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "user_conditions_insert_own" ON public.user_conditions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_conditions_update_own" ON public.user_conditions
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_conditions_delete_own" ON public.user_conditions
    FOR DELETE USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 4. User Allergies
-- ----------------------------------------------------------------------------
ALTER TABLE public.user_allergies ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_allergies_select_own" ON public.user_allergies
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "user_allergies_insert_own" ON public.user_allergies
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_allergies_update_own" ON public.user_allergies
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_allergies_delete_own" ON public.user_allergies
    FOR DELETE USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 5. Medications
-- ----------------------------------------------------------------------------
ALTER TABLE public.medications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "medications_select_own" ON public.medications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "medications_insert_own" ON public.medications
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "medications_update_own" ON public.medications
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "medications_delete_own" ON public.medications
    FOR DELETE USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 6. Medication Dose Logs
-- ----------------------------------------------------------------------------
ALTER TABLE public.medication_dose_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "dose_logs_select_own" ON public.medication_dose_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "dose_logs_insert_own" ON public.medication_dose_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "dose_logs_update_own" ON public.medication_dose_logs
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "dose_logs_delete_own" ON public.medication_dose_logs
    FOR DELETE USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 7. Lab Reports
-- ----------------------------------------------------------------------------
ALTER TABLE public.lab_reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "lab_reports_select_own" ON public.lab_reports
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "lab_reports_insert_own" ON public.lab_reports
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "lab_reports_update_own" ON public.lab_reports
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "lab_reports_delete_own" ON public.lab_reports
    FOR DELETE USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 8. Report Biomarkers
-- ----------------------------------------------------------------------------
ALTER TABLE public.report_biomarkers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "report_biomarkers_select_own" ON public.report_biomarkers
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "report_biomarkers_insert_own" ON public.report_biomarkers
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "report_biomarkers_update_own" ON public.report_biomarkers
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "report_biomarkers_delete_own" ON public.report_biomarkers
    FOR DELETE USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 9. User Meal Plans
-- ----------------------------------------------------------------------------
ALTER TABLE public.user_meal_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_meal_plans_select_own" ON public.user_meal_plans
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "user_meal_plans_insert_own" ON public.user_meal_plans
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_meal_plans_update_own" ON public.user_meal_plans
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user_meal_plans_delete_own" ON public.user_meal_plans
    FOR DELETE USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 10. User Meal Plan Items
-- ----------------------------------------------------------------------------
ALTER TABLE public.user_meal_plan_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "meal_plan_items_select_own" ON public.user_meal_plan_items
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "meal_plan_items_insert_own" ON public.user_meal_plan_items
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "meal_plan_items_update_own" ON public.user_meal_plan_items
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "meal_plan_items_delete_own" ON public.user_meal_plan_items
    FOR DELETE USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 11. User Activity Plans
-- ----------------------------------------------------------------------------
ALTER TABLE public.user_activity_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "activity_plans_select_own" ON public.user_activity_plans
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "activity_plans_insert_own" ON public.user_activity_plans
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "activity_plans_update_own" ON public.user_activity_plans
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "activity_plans_delete_own" ON public.user_activity_plans
    FOR DELETE USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 12. User Activity Logs
-- ----------------------------------------------------------------------------
ALTER TABLE public.user_activity_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "activity_logs_select_own" ON public.user_activity_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "activity_logs_insert_own" ON public.user_activity_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "activity_logs_update_own" ON public.user_activity_logs
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "activity_logs_delete_own" ON public.user_activity_logs
    FOR DELETE USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 13. AI Recommendations
-- ----------------------------------------------------------------------------
ALTER TABLE public.ai_recommendations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "ai_recs_select_own" ON public.ai_recommendations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "ai_recs_insert_own" ON public.ai_recommendations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "ai_recs_update_own" ON public.ai_recommendations
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "ai_recs_delete_own" ON public.ai_recommendations
    FOR DELETE USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 14. Chat Conversations
-- ----------------------------------------------------------------------------
ALTER TABLE public.chat_conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "chat_conv_select_own" ON public.chat_conversations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "chat_conv_insert_own" ON public.chat_conversations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "chat_conv_update_own" ON public.chat_conversations
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "chat_conv_delete_own" ON public.chat_conversations
    FOR DELETE USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 15. Chat Messages
-- ----------------------------------------------------------------------------
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "chat_msg_select_own" ON public.chat_messages
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "chat_msg_insert_own" ON public.chat_messages
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "chat_msg_update_own" ON public.chat_messages
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "chat_msg_delete_own" ON public.chat_messages
    FOR DELETE USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 16. User Notification Settings
-- ----------------------------------------------------------------------------
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notif_settings_select_own" ON public.user_notification_settings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "notif_settings_insert_own" ON public.user_notification_settings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "notif_settings_update_own" ON public.user_notification_settings
    FOR UPDATE USING (auth.uid() = user_id) WITH CHECK (auth.uid() = user_id);

CREATE POLICY "notif_settings_delete_own" ON public.user_notification_settings
    FOR DELETE USING (auth.uid() = user_id);

-- ----------------------------------------------------------------------------
-- 17. Global Reference Tables (Public Read-Only for Authenticated Users)
-- ----------------------------------------------------------------------------
ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;
CREATE POLICY "recipes_select_authenticated" ON public.recipes
    FOR SELECT USING (auth.role() = 'authenticated');

ALTER TABLE public.activity_catalog ENABLE ROW LEVEL SECURITY;
CREATE POLICY "activity_catalog_select_authenticated" ON public.activity_catalog
    FOR SELECT USING (auth.role() = 'authenticated');

ALTER TABLE public.medical_facilities ENABLE ROW LEVEL SECURITY;
CREATE POLICY "medical_facilities_select_authenticated" ON public.medical_facilities
    FOR SELECT USING (auth.role() = 'authenticated');
