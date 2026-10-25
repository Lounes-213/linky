-- Polls / Votes
CREATE TABLE IF NOT EXISTS polls (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  question TEXT NOT NULL,
  description TEXT DEFAULT '',
  type TEXT DEFAULT 'poll' CHECK(type IN ('poll','survey','election')),
  status TEXT DEFAULT 'active' CHECK(status IN ('active','closed')),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  ends_at DATETIME
);

CREATE TABLE IF NOT EXISTS poll_options (
  id TEXT PRIMARY KEY,
  poll_id TEXT NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
  option_text TEXT NOT NULL,
  option_image TEXT DEFAULT '',
  votes_count INTEGER DEFAULT 0,
  sort_order INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS poll_votes (
  id TEXT PRIMARY KEY,
  poll_id TEXT NOT NULL REFERENCES polls(id) ON DELETE CASCADE,
  option_id TEXT NOT NULL REFERENCES poll_options(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(id),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(poll_id, user_id)
);

-- Donations
CREATE TABLE IF NOT EXISTS donations (
  id TEXT PRIMARY KEY,
  recipient_id TEXT NOT NULL REFERENCES users(id),
  donor_name TEXT DEFAULT 'Anonyme',
  donor_message TEXT DEFAULT '',
  amount REAL NOT NULL,
  currency TEXT DEFAULT 'DA',
  payment_method TEXT DEFAULT 'cod',
  status TEXT DEFAULT 'pending' CHECK(status IN ('pending','completed','failed')),
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS donation_settings (
  user_id TEXT PRIMARY KEY REFERENCES users(id),
  is_enabled INTEGER DEFAULT 0,
  description TEXT DEFAULT 'Soutenez mon travail !',
  preset_amounts TEXT DEFAULT '100,200,500,1000',
  payment_methods TEXT DEFAULT 'BordiMob,CCP,RedotPay'
);

-- Playlists / Videos
CREATE TABLE IF NOT EXISTS playlists (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  name TEXT NOT NULL,
  description TEXT DEFAULT '',
  platform TEXT DEFAULT 'youtube' CHECK(platform IN ('youtube','tiktok','reels','facebook','custom')),
  cover_image TEXT DEFAULT '',
  video_count INTEGER DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS playlist_videos (
  id TEXT PRIMARY KEY,
  playlist_id TEXT NOT NULL REFERENCES playlists(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  url TEXT NOT NULL,
  thumbnail TEXT DEFAULT '',
  duration TEXT DEFAULT '',
  platform TEXT DEFAULT 'youtube',
  sort_order INTEGER DEFAULT 0,
  views_count INTEGER DEFAULT 0,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
