-- ============================================================================
-- Migration 006: Lab Reports & Biomarkers Tables
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: public.lab_reports
-- Uploaded diagnostic medical document metadata and AI processing status.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.lab_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    file_name TEXT NOT NULL,
    storage_path TEXT NOT NULL,
    file_size_bytes BIGINT NULL,
    mime_type TEXT NULL,
    status TEXT NOT NULL DEFAULT 'uploaded',
    ai_summary TEXT NOT NULL DEFAULT '',
    error_message TEXT NULL,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMPTZ NULL,

    CONSTRAINT chk_lab_report_status CHECK (status IN ('uploaded', 'processing', 'processed', 'failed')),
    -- Composite uniqueness to support parent-child ownership enforcement
    CONSTRAINT uq_lab_reports_id_user UNIQUE (id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_lab_reports_user_uploaded ON public.lab_reports(user_id, uploaded_at DESC);

-- ----------------------------------------------------------------------------
-- Table: public.report_biomarkers
-- Normalized discrete clinical measurements parsed from uploaded reports.
-- Enforces composite foreign key matching the report owner.
-- ----------------------------------------------------------------------------
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
    -- Enforces that a biomarker cannot reference another user's lab report
    CONSTRAINT fk_report_biomarkers_report_user FOREIGN KEY (report_id, user_id)
        REFERENCES public.lab_reports(id, user_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_biomarkers_user_name ON public.report_biomarkers(user_id, biomarker_name);
CREATE INDEX IF NOT EXISTS idx_biomarkers_report_id ON public.report_biomarkers(report_id);
