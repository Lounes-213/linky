-- Linky D1 Database Schema

-- Users Table
CREATE TABLE users (
    id TEXT PRIMARY KEY,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    profile_image TEXT,
    bio TEXT,
    is_pro BOOLEAN DEFAULT 0,
    referral_code TEXT UNIQUE NOT NULL,
    referrer_id TEXT,
    trial_ends_at DATETIME,
    subscription_ends_at DATETIME,
    views INTEGER DEFAULT 0,
    score INTEGER DEFAULT 0,
    referrals_count INTEGER DEFAULT 0,
    global_rank INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (referrer_id) REFERENCES users(id)
);

-- Links Table
CREATE TABLE links (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    title TEXT NOT NULL,
    url TEXT NOT NULL,
    icon_url TEXT,
    clicks_count INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT 1,
    position INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Referrals Table (Tracking detailed status)
CREATE TABLE referrals (
    id TEXT PRIMARY KEY,
    referrer_id TEXT NOT NULL,
    referred_user_id TEXT NOT NULL,
    status TEXT CHECK(status IN ('pending', 'successful', 'converted')) DEFAULT 'pending',
    reward_days_granted INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (referrer_id) REFERENCES users(id),
    FOREIGN KEY (referred_user_id) REFERENCES users(id)
);

-- Stats History (Optional, for gamification over time)
CREATE TABLE stats_history (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    date DATE NOT NULL,
    views_diff INTEGER DEFAULT 0,
    score_diff INTEGER DEFAULT 0,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Indices
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_links_user_id ON links(user_id);
CREATE INDEX idx_referrals_referrer_id ON referrals(referrer_id);

-- Conversations Table
CREATE TABLE IF NOT EXISTS conversations (
    id TEXT PRIMARY KEY,
    user1_id TEXT NOT NULL,
    user2_id TEXT NOT NULL,
    last_message TEXT,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user1_id) REFERENCES users(id),
    FOREIGN KEY (user2_id) REFERENCES users(id)
);

-- Messages Table
CREATE TABLE IF NOT EXISTS messages (
    id TEXT PRIMARY KEY,
    conversation_id TEXT NOT NULL,
    sender_id TEXT NOT NULL,
    content TEXT NOT NULL,
    type TEXT DEFAULT 'text', -- 'text' or 'image'
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (conversation_id) REFERENCES conversations(id),
    FOREIGN KEY (sender_id) REFERENCES users(id)
);

-- Notifications Table
CREATE TABLE IF NOT EXISTS notifications (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL,
    type TEXT NOT NULL, -- 'like', 'follow', 'referral', 'mention'
    sender_id TEXT,
    content TEXT NOT NULL,
    is_read INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (sender_id) REFERENCES users(id)
);

CREATE INDEX idx_messages_conversation_id ON messages(conversation_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
