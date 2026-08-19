-- ============================================================================
-- Migration 016: Allow WebP and BMP in 'reports' Storage Bucket
-- ============================================================================

-- Update allowed MIME types for the private 'reports' storage bucket to include image/webp and image/bmp
UPDATE storage.buckets
SET allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/bmp', 'application/pdf']
WHERE id = 'reports';
