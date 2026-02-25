-- ==========================================
-- MIGRATION: Add achievements, notifications, friends tables
-- Run this SQL in Supabase SQL Editor
-- ==========================================

-- 1. ACHIEVEMENTS
CREATE TABLE achievements (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  description TEXT,
  unlocked_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, type)
);

ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Own achievements select" ON achievements FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Own achievements insert" ON achievements FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 2. NOTIFICATIONS
CREATE TABLE notifications (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  related_id TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Own notifications select" ON notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Own notifications update" ON notifications FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Notifications insert" ON notifications FOR INSERT WITH CHECK (true);

-- 3. FRIENDS
CREATE TABLE friends (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  friend_id UUID REFERENCES profiles(id) NOT NULL,
  status TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, friend_id)
);

ALTER TABLE friends ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Friends select" ON friends FOR SELECT USING (auth.uid() = user_id OR auth.uid() = friend_id);
CREATE POLICY "Friends insert" ON friends FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Friends update" ON friends FOR UPDATE USING (auth.uid() = user_id OR auth.uid() = friend_id);
