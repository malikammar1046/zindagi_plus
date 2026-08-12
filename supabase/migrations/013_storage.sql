-- ============================================================================
-- Migration 013: Supabase Storage Buckets & Storage RLS Policies
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Create Storage Buckets
-- ----------------------------------------------------------------------------

-- 1. Private 'reports' bucket for diagnostic medical documents
-- Note: SQL configures the private bucket and strict user-folder RLS.
-- Short-lived signed URL generation and expiration are handled at runtime by the
-- application/backend when generating URLs.
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'reports',
    'reports',
    FALSE,
    15728640, -- 15 MB
    ARRAY['image/jpeg', 'image/png', 'application/pdf']
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- 2. Public 'avatars' bucket for user profile photos
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    TRUE,
    5242880, -- 5 MB
    ARRAY['image/jpeg', 'image/png', 'image/webp']
)
ON CONFLICT (id) DO UPDATE SET
    public = EXCLUDED.public,
    file_size_limit = EXCLUDED.file_size_limit,
    allowed_mime_types = EXCLUDED.allowed_mime_types;

-- ----------------------------------------------------------------------------
-- Storage Policies for 'reports' Bucket (Strict User Folder Isolation)
-- ----------------------------------------------------------------------------

CREATE POLICY "reports_select_own" ON storage.objects
    FOR SELECT TO authenticated
    USING (
        bucket_id = 'reports' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "reports_insert_own" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'reports' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "reports_update_own" ON storage.objects
    FOR UPDATE TO authenticated
    USING (
        bucket_id = 'reports' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "reports_delete_own" ON storage.objects
    FOR DELETE TO authenticated
    USING (
        bucket_id = 'reports' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- ----------------------------------------------------------------------------
-- Storage Policies for 'avatars' Bucket (Public Read, Owner Write)
-- ----------------------------------------------------------------------------

CREATE POLICY "avatars_select_public" ON storage.objects
    FOR SELECT
    USING (bucket_id = 'avatars');

CREATE POLICY "avatars_insert_own" ON storage.objects
    FOR INSERT TO authenticated
    WITH CHECK (
        bucket_id = 'avatars' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "avatars_update_own" ON storage.objects
    FOR UPDATE TO authenticated
    USING (
        bucket_id = 'avatars' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

CREATE POLICY "avatars_delete_own" ON storage.objects
    FOR DELETE TO authenticated
    USING (
        bucket_id = 'avatars' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );
