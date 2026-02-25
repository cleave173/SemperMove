-- Users profile table (extends Supabase auth.users)
CREATE TABLE profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT NOT NULL,
  username TEXT NOT NULL,
  avatar_url TEXT,
  daily_steps INT DEFAULT 0,
  push_ups INT DEFAULT 0,
  squats INT DEFAULT 0,
  plank_seconds INT DEFAULT 0,
  water_ml INT DEFAULT 0,
  steps_goal INT DEFAULT 10000,
  push_ups_goal INT DEFAULT 100,
  squats_goal INT DEFAULT 100,
  plank_goal INT DEFAULT 300,
  water_goal INT DEFAULT 2000,
  current_streak INT DEFAULT 0,
  last_activity_date DATE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Progress history
CREATE TABLE progress_history (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES profiles(id) NOT NULL,
  date DATE NOT NULL,
  steps INT DEFAULT 0,
  push_ups INT DEFAULT 0,
  squats INT DEFAULT 0,
  plank_seconds INT DEFAULT 0,
  water_ml INT DEFAULT 0
);

-- Duels
CREATE TABLE duels (
  id BIGSERIAL PRIMARY KEY,
  challenger_id UUID REFERENCES profiles(id) NOT NULL,
  opponent_id UUID REFERENCES profiles(id) NOT NULL,
  status TEXT DEFAULT 'IN_PROGRESS',
  winner TEXT,
  exercise_category TEXT,
  challenger_score INT DEFAULT 0,
  opponent_score INT DEFAULT 0,
  type TEXT DEFAULT 'SINGLE_CATEGORY',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Storage Bucket for Avatars
INSERT INTO storage.buckets (id, name, public) VALUES ('avatars', 'avatars', true);

-- RLS Policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE progress_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE duels ENABLE ROW LEVEL SECURITY;

-- Allow public access to read profiles + update own
CREATE POLICY "Public profiles" ON profiles FOR SELECT USING (true);
CREATE POLICY "Update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Insert own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);

-- Allow full access to own avatar files
CREATE POLICY "Avatar images are publicly accessible" ON storage.objects FOR SELECT USING ( bucket_id = 'avatars' );
CREATE POLICY "Anyone can upload an avatar" ON storage.objects FOR INSERT WITH CHECK ( bucket_id = 'avatars' );
CREATE POLICY "Anyone can update an avatar" ON storage.objects FOR UPDATE WITH CHECK ( bucket_id = 'avatars' );

-- Progress history: own data only
CREATE POLICY "Own history select" ON progress_history FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Own history insert" ON progress_history FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Duels: participants access
CREATE POLICY "Duel select" ON duels FOR SELECT USING (auth.uid() = challenger_id OR auth.uid() = opponent_id);
CREATE POLICY "Duel insert" ON duels FOR INSERT WITH CHECK (auth.uid() = challenger_id);
CREATE POLICY "Duel update" ON duels FOR UPDATE USING (auth.uid() = challenger_id OR auth.uid() = opponent_id);

-- ==================== ACHIEVEMENTS ====================
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

-- ==================== NOTIFICATIONS ====================
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

-- ==================== FRIENDS ====================
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

