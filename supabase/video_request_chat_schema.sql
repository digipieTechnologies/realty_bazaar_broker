-- Supabase Schema for Video Request Live Chat System

-- 1. Create custom ENUM for chat message types if not exists
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'chat_message_type') THEN
    CREATE TYPE public.chat_message_type AS ENUM ('text', 'image', 'location', 'document');
  END IF;
END$$;

-- 2. Create chat_rooms table (1:1 with video_requests)
CREATE TABLE IF NOT EXISTS public.chat_rooms (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  video_request_id UUID NOT NULL REFERENCES public.video_requests(id) ON DELETE CASCADE,
  broker_id UUID NOT NULL REFERENCES public.brokers(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  CONSTRAINT uq_chat_rooms_video_request UNIQUE (video_request_id)
);

-- 3. Create chat_messages table
CREATE TABLE IF NOT EXISTS public.chat_messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  room_id UUID NOT NULL REFERENCES public.chat_rooms(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL,
  sender_type VARCHAR(50) DEFAULT 'broker' NOT NULL, -- 'broker' or 'marketing' / 'admin'
  message TEXT,
  message_type public.chat_message_type DEFAULT 'text'::public.chat_message_type NOT NULL,
  media_url TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Create Indexes for High Performance Querying
CREATE INDEX IF NOT EXISTS idx_chat_rooms_video_request_id ON public.chat_rooms USING btree (video_request_id);
CREATE INDEX IF NOT EXISTS idx_chat_rooms_broker_id ON public.chat_rooms USING btree (broker_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_room_id ON public.chat_messages USING btree (room_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON public.chat_messages USING btree (created_at ASC);

-- 5. Enable Row Level Security (RLS)
ALTER TABLE public.chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies for chat_rooms
DROP POLICY IF EXISTS "Allow public selects on chat_rooms" ON public.chat_rooms;
CREATE POLICY "Allow public selects on chat_rooms" ON public.chat_rooms
  FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Allow public inserts on chat_rooms" ON public.chat_rooms;
CREATE POLICY "Allow public inserts on chat_rooms" ON public.chat_rooms
  FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public updates on chat_rooms" ON public.chat_rooms;
CREATE POLICY "Allow public updates on chat_rooms" ON public.chat_rooms
  FOR UPDATE TO public USING (true) WITH CHECK (true);

-- Create RLS Policies for chat_messages
DROP POLICY IF EXISTS "Allow public selects on chat_messages" ON public.chat_messages;
CREATE POLICY "Allow public selects on chat_messages" ON public.chat_messages
  FOR SELECT TO public USING (true);

DROP POLICY IF EXISTS "Allow public inserts on chat_messages" ON public.chat_messages;
CREATE POLICY "Allow public inserts on chat_messages" ON public.chat_messages
  FOR INSERT TO public WITH CHECK (true);

DROP POLICY IF EXISTS "Allow public updates on chat_messages" ON public.chat_messages;
CREATE POLICY "Allow public updates on chat_messages" ON public.chat_messages
  FOR UPDATE TO public USING (true) WITH CHECK (true);

-- 6. Trigger for updated_at column
DROP TRIGGER IF EXISTS trg_set_updated_at_chat_rooms ON public.chat_rooms;
CREATE TRIGGER trg_set_updated_at_chat_rooms BEFORE UPDATE ON public.chat_rooms
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trg_set_updated_at_chat_messages ON public.chat_messages;
CREATE TRIGGER trg_set_updated_at_chat_messages BEFORE UPDATE ON public.chat_messages
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 7. Consolidating RPC to Get or Create Video Request Chat Room in 1 call
CREATE OR REPLACE FUNCTION public.get_or_create_video_request_chat_room(p_video_request_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_broker_id UUID;
  v_room_record public.chat_rooms%ROWTYPE;
  v_video_request_json JSONB;
  v_result JSONB;
BEGIN
  -- Retrieve broker_id from the video request
  SELECT broker_id INTO v_broker_id
  FROM public.video_requests
  WHERE id = p_video_request_id;

  IF v_broker_id IS NULL THEN
    RAISE EXCEPTION 'Video request with ID % not found', p_video_request_id;
  END IF;

  -- Insert chat_room if it doesn't already exist
  INSERT INTO public.chat_rooms (video_request_id, broker_id)
  VALUES (p_video_request_id, v_broker_id)
  ON CONFLICT (video_request_id) DO UPDATE
  SET updated_at = timezone('utc'::text, now())
  RETURNING * INTO v_room_record;

  -- Build video_request JSON including all columns (vr.*) and nested property (p.*)
  SELECT to_jsonb(vr.*) || jsonb_build_object(
    'property', (
      SELECT to_jsonb(p.*)
      FROM public.properties p
      WHERE p.id = vr.property_id
    )
  ) INTO v_video_request_json
  FROM public.video_requests vr
  WHERE vr.id = v_room_record.video_request_id;

  -- Build complete room JSON including all columns (v_room_record.*) and video_request object
  v_result := to_jsonb(v_room_record.*) || jsonb_build_object(
    'video_request', v_video_request_json
  );

  RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 8. Enable Realtime Publications
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_rooms;
ALTER PUBLICATION supabase_realtime ADD TABLE public.chat_messages;

-- 9. Storage Bucket for Chat Attachments
INSERT INTO storage.buckets (id, name, public)
VALUES ('chat_attachments', 'chat_attachments', true)
ON CONFLICT (id) DO NOTHING;
