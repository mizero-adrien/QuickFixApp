-- QuickFix — Messaging tables
-- Run this in the Supabase Dashboard → SQL Editor

-- 1. conversations: one per homeowner–artisan pair
CREATE TABLE IF NOT EXISTS conversations (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  homeowner_id     UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  artisan_id       UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  job_id           UUID REFERENCES jobs(id) ON DELETE SET NULL,
  last_message     TEXT,
  last_message_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (homeowner_id, artisan_id)
);

-- 2. messages
CREATE TABLE IF NOT EXISTS messages (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id  UUID NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
  sender_id        UUID NOT NULL REFERENCES profiles(id),
  body             TEXT NOT NULL,
  is_read          BOOLEAN NOT NULL DEFAULT false,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 3. Enable Realtime (Dashboard → Database → Replication → enable messages table)
ALTER TABLE messages REPLICA IDENTITY FULL;

-- 4. Row-level security
ALTER TABLE conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages     ENABLE ROW LEVEL SECURITY;

CREATE POLICY "conversation_members_only" ON conversations
  FOR ALL USING (homeowner_id = auth.uid() OR artisan_id = auth.uid());

CREATE POLICY "message_members_only" ON messages
  FOR ALL USING (
    conversation_id IN (
      SELECT id FROM conversations
      WHERE homeowner_id = auth.uid() OR artisan_id = auth.uid()
    )
  );

-- 5. Index for fast per-conversation message listing
CREATE INDEX IF NOT EXISTS messages_conversation_created
  ON messages (conversation_id, created_at);
