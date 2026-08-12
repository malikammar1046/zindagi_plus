-- ============================================================================
-- Migration 014: Views & Timeline Aggregation
-- ============================================================================

-- ----------------------------------------------------------------------------
-- View: public.v_health_timeline
-- Aggregates time-series patient interactions into a unified clinical feed.
-- Returns purely semantic fields. Flutter determines colors, icons, and themes.
-- Automatically inherits underlying table RLS policies when queried.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW public.v_health_timeline AS

-- 1. Medication Adherence Events
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
