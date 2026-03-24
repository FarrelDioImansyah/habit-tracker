-- ============================================================
--  HABIT TRACKER — Supabase SQL Schema
--  Jalankan di: Supabase Dashboard > SQL Editor
-- ============================================================

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ── HABIT GROUPS ────────────────────────────────────────────
CREATE TABLE habit_groups (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  icon         TEXT DEFAULT '📁',
  color        TEXT DEFAULT '#6750A4',
  sort_order   INTEGER DEFAULT 0,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── HABITS ──────────────────────────────────────────────────
CREATE TABLE habits (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name         TEXT NOT NULL,
  icon         TEXT DEFAULT '🌟',
  color        TEXT DEFAULT '#1D9E75',
  type         TEXT NOT NULL CHECK (type IN ('good', 'bad')),
  frequency    TEXT DEFAULT 'daily' CHECK (frequency IN ('daily', 'weekly')),
  group_id     UUID REFERENCES habit_groups(id) ON DELETE SET NULL,
  reason       TEXT,                    -- khusus bad habit: alasan berhenti
  is_paused    BOOLEAN DEFAULT FALSE,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ── HABIT LOGS (good habit check-in) ────────────────────────
CREATE TABLE habit_logs (
  id           UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  habit_id     UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
  user_id      UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  completed_at TIMESTAMPTZ DEFAULT NOW(),
  note         TEXT
);

-- ── BAD HABIT SESSIONS (timer) ───────────────────────────────
CREATE TABLE bad_habit_sessions (
  id             UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  habit_id       UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
  user_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  started_at     TIMESTAMPTZ DEFAULT NOW(),
  ended_at       TIMESTAMPTZ,
  duration_days  INTEGER,
  is_current     BOOLEAN DEFAULT TRUE
);

-- ── RELAPSES ─────────────────────────────────────────────────
CREATE TABLE relapses (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  habit_id              UUID NOT NULL REFERENCES habits(id) ON DELETE CASCADE,
  user_id               UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  relapsed_at           TIMESTAMPTZ DEFAULT NOW(),
  note                  TEXT,
  previous_duration_days INTEGER DEFAULT 0
);

-- ── INDEXES ──────────────────────────────────────────────────
CREATE INDEX idx_habits_user        ON habits(user_id);
CREATE INDEX idx_habits_type        ON habits(type);
CREATE INDEX idx_habit_logs_habit   ON habit_logs(habit_id);
CREATE INDEX idx_habit_logs_date    ON habit_logs(completed_at);
CREATE INDEX idx_sessions_habit     ON bad_habit_sessions(habit_id);
CREATE INDEX idx_sessions_current   ON bad_habit_sessions(is_current);
CREATE INDEX idx_relapses_habit     ON relapses(habit_id);

-- ============================================================
--  ROW LEVEL SECURITY (RLS)
--  WAJIB diaktifkan agar data setiap user terisolasi
-- ============================================================

ALTER TABLE habit_groups        ENABLE ROW LEVEL SECURITY;
ALTER TABLE habits               ENABLE ROW LEVEL SECURITY;
ALTER TABLE habit_logs           ENABLE ROW LEVEL SECURITY;
ALTER TABLE bad_habit_sessions   ENABLE ROW LEVEL SECURITY;
ALTER TABLE relapses             ENABLE ROW LEVEL SECURITY;

-- Policy: user hanya bisa akses data miliknya sendiri
CREATE POLICY "user owns habit_groups"
  ON habit_groups FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user owns habits"
  ON habits FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user owns habit_logs"
  ON habit_logs FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user owns bad_habit_sessions"
  ON bad_habit_sessions FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "user owns relapses"
  ON relapses FOR ALL
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- ============================================================
--  REALTIME
--  Aktifkan agar perubahan data langsung sync antar device
-- ============================================================

ALTER PUBLICATION supabase_realtime ADD TABLE habits;
ALTER PUBLICATION supabase_realtime ADD TABLE habit_logs;
ALTER PUBLICATION supabase_realtime ADD TABLE bad_habit_sessions;
ALTER PUBLICATION supabase_realtime ADD TABLE relapses;
