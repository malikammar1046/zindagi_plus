-- ============================================================================
-- Migration 015: OCR Raw Extracted Text Support for Medical Reports
-- ============================================================================

-- 1. Add extracted_text column to public.lab_reports table
ALTER TABLE public.lab_reports 
    ADD COLUMN IF NOT EXISTS extracted_text TEXT NOT NULL DEFAULT '';

-- 2. Update status check constraint to support 'completed' as well as 'processed'
ALTER TABLE public.lab_reports 
    DROP CONSTRAINT IF EXISTS chk_lab_report_status;

ALTER TABLE public.lab_reports 
    ADD CONSTRAINT chk_lab_report_status 
    CHECK (status IN ('uploaded', 'processing', 'completed', 'processed', 'failed'));
