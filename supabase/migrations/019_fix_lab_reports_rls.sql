-- ============================================================================
-- Migration 019: Fix lab_reports and report_biomarkers RLS & Permissions
-- Resolves PostgrestException 42501 (Permission Denied) on lab_reports & report_biomarkers.
-- ============================================================================

-- 1. Ensure Columns Exist
ALTER TABLE public.lab_reports 
    ADD COLUMN IF NOT EXISTS extracted_text TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS biomarker_count INT NOT NULL DEFAULT 0;

-- 2. Schema & Table Grants for Authenticated Users
GRANT USAGE ON SCHEMA public TO anon, authenticated;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.lab_reports TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.report_biomarkers TO authenticated;

-- Service role bypass / admin grants
GRANT ALL ON public.lab_reports TO service_role;
GRANT ALL ON public.report_biomarkers TO service_role;

-- 3. Enable Row Level Security (RLS)
ALTER TABLE public.lab_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.report_biomarkers ENABLE ROW LEVEL SECURITY;

-- 4. Reset and Recreate RLS Policies on public.lab_reports
DROP POLICY IF EXISTS "lab_reports_select_own" ON public.lab_reports;
DROP POLICY IF EXISTS "lab_reports_insert_own" ON public.lab_reports;
DROP POLICY IF EXISTS "lab_reports_update_own" ON public.lab_reports;
DROP POLICY IF EXISTS "lab_reports_delete_own" ON public.lab_reports;
DROP POLICY IF EXISTS "Users can manage their own lab reports" ON public.lab_reports;

CREATE POLICY "lab_reports_select_own" ON public.lab_reports
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "lab_reports_insert_own" ON public.lab_reports
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "lab_reports_update_own" ON public.lab_reports
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "lab_reports_delete_own" ON public.lab_reports
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);

-- 5. Reset and Recreate RLS Policies on public.report_biomarkers
DROP POLICY IF EXISTS "report_biomarkers_select_own" ON public.report_biomarkers;
DROP POLICY IF EXISTS "report_biomarkers_insert_own" ON public.report_biomarkers;
DROP POLICY IF EXISTS "report_biomarkers_update_own" ON public.report_biomarkers;
DROP POLICY IF EXISTS "report_biomarkers_delete_own" ON public.report_biomarkers;
DROP POLICY IF EXISTS "Users can manage their own report biomarkers" ON public.report_biomarkers;

CREATE POLICY "report_biomarkers_select_own" ON public.report_biomarkers
    FOR SELECT TO authenticated
    USING (auth.uid() = user_id);

CREATE POLICY "report_biomarkers_insert_own" ON public.report_biomarkers
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "report_biomarkers_update_own" ON public.report_biomarkers
    FOR UPDATE TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "report_biomarkers_delete_own" ON public.report_biomarkers
    FOR DELETE TO authenticated
    USING (auth.uid() = user_id);
