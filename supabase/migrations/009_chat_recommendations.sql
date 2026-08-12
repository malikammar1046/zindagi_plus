-- ============================================================================
-- Migration 009: Chat Consultations & AI Recommendations
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Table: public.chat_conversations
-- Conversational consultation sessions with the Zindagi AI health assistant.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.chat_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL DEFAULT 'Health Consultation',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Composite uniqueness to support parent-child ownership enforcement
    CONSTRAINT uq_chat_conversations_id_user UNIQUE (id, user_id)
);

CREATE INDEX IF NOT EXISTS idx_chat_conversations_user ON public.chat_conversations(user_id, updated_at DESC);

-- ----------------------------------------------------------------------------
-- Table: public.chat_messages
-- Individual message exchanges with role tagging and source citations.
-- Enforces composite foreign key matching the conversation owner.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    is_user BOOLEAN NOT NULL,
    text TEXT NOT NULL,
    sources TEXT[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    -- Enforces that a message cannot reference another user's conversation
    CONSTRAINT fk_chat_messages_conv_user FOREIGN KEY (conversation_id, user_id)
        REFERENCES public.chat_conversations(id, user_id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_conv ON public.chat_messages(conversation_id, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_user ON public.chat_messages(user_id);

-- ----------------------------------------------------------------------------
-- Table: public.ai_recommendations
-- Actionable clinical and lifestyle recommendations generated for the patient.
-- ----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.ai_recommendations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL DEFAULT 'insight',
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    priority TEXT NOT NULL DEFAULT 'medium',
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    action_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    expires_at TIMESTAMPTZ NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT chk_rec_type CHECK (type IN ('medication', 'nutrition', 'activity', 'insight')),
    CONSTRAINT chk_rec_priority CHECK (priority IN ('high', 'medium', 'low'))
);

CREATE INDEX IF NOT EXISTS idx_ai_recommendations_user ON public.ai_recommendations(user_id, is_completed, priority);
