-- ============================================================================
-- Migration 020: Fix medications & medication_dose_logs Table Grants and RLS
-- Resolves PostgrestException 42501 (Permission Denied) on medication_dose_logs.
-- ============================================================================

-- 1. Table Grants for Authenticated Role (No write permissions granted to anon)
GRANT SELECT, INSERT, UPDATE, DELETE ON public.medications TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.medication_dose_logs TO authenticated;

-- 2. Ensure Row Level Security (RLS) is Enabled
ALTER TABLE public.medications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.medication_dose_logs ENABLE ROW LEVEL SECURITY;

-- 3. Medications RLS Policies (Strict User Ownership)
DROP POLICY IF EXISTS "medications_select_own" ON public.medications;
DROP POLICY IF EXISTS "medications_insert_own" ON public.medications;
DROP POLICY IF EXISTS "medications_update_own" ON public.medications;
DROP POLICY IF EXISTS "medications_delete_own" ON public.medications;
DROP POLICY IF EXISTS "Users can manage their own medications" ON public.medications;

CREATE POLICY "medications_select_own" ON public.medications
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "medications_insert_own" ON public.medications
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "medications_update_own" ON public.medications
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "medications_delete_own" ON public.medications
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

-- 4. Medication Dose Logs RLS Policies (Strict User Ownership + Parent Medication Check)
DROP POLICY IF EXISTS "dose_logs_select_own" ON public.medication_dose_logs;
DROP POLICY IF EXISTS "dose_logs_insert_own" ON public.medication_dose_logs;
DROP POLICY IF EXISTS "dose_logs_update_own" ON public.medication_dose_logs;
DROP POLICY IF EXISTS "dose_logs_delete_own" ON public.medication_dose_logs;
DROP POLICY IF EXISTS "Users can manage their own dose logs" ON public.medication_dose_logs;

CREATE POLICY "dose_logs_select_own" ON public.medication_dose_logs
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "dose_logs_insert_own" ON public.medication_dose_logs
    FOR INSERT TO authenticated
    WITH CHECK (
        auth.uid() = user_id
        AND EXISTS (
            SELECT 1 FROM public.medications m
            WHERE m.id = medication_id
              AND m.user_id = auth.uid()
        )
    );

CREATE POLICY "dose_logs_update_own" ON public.medication_dose_logs
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "dose_logs_delete_own" ON public.medication_dose_logs
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);
