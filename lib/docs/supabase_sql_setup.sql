-- =============================================================================
-- Supabase Database Setup Script
-- Run this in the Supabase SQL Editor
-- =============================================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================================
-- 1. PROFILES TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT,
    avatar_url TEXT,
    bio TEXT,
    website TEXT,
    email TEXT,
    phone TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_profiles_user_id ON profiles(user_id);
CREATE INDEX idx_profiles_created_at ON profiles(created_at);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;

-- =============================================================================
-- 2. POSTS TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS posts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    tags TEXT[] DEFAULT '{}',
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'published', 'archived')),
    views_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_status ON posts(status);
CREATE INDEX idx_posts_created_at ON posts(created_at);
CREATE INDEX idx_posts_deleted_at ON posts(deleted_at);

ALTER PUBLICATION supabase_realtime ADD TABLE posts;

-- =============================================================================
-- 3. MESSAGES TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_id UUID NOT NULL,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    attachment_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_messages_chat_id ON messages(chat_id);
CREATE INDEX idx_messages_user_id ON messages(user_id);
CREATE INDEX idx_messages_created_at ON messages(created_at);

ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- =============================================================================
-- 4. TASKS TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    completed BOOLEAN DEFAULT FALSE,
    due_date DATE,
    priority TEXT DEFAULT 'medium' CHECK (priority IN ('low', 'medium', 'high')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_completed ON tasks(completed);
CREATE INDEX idx_tasks_due_date ON tasks(due_date);

ALTER PUBLICATION supabase_realtime ADD TABLE tasks;

-- =============================================================================
-- 5. FOLLOWS TABLE (Social Graph)
-- =============================================================================

CREATE TABLE IF NOT EXISTS follows (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    follower_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    following_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(follower_id, following_id),
    CONSTRAINT no_self_follow CHECK (follower_id != following_id)
);

CREATE INDEX idx_follows_follower_id ON follows(follower_id);
CREATE INDEX idx_follows_following_id ON follows(following_id);

ALTER PUBLICATION supabase_realtime ADD TABLE follows;

-- =============================================================================
-- 6. LIKES TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, post_id)
);

CREATE INDEX idx_likes_user_id ON likes(user_id);
CREATE INDEX idx_likes_post_id ON likes(post_id);

-- =============================================================================
-- 7. COMMENTS TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    post_id UUID NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    deleted_at TIMESTAMP WITH TIME ZONE
);

CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);

ALTER PUBLICATION supabase_realtime ADD TABLE comments;

-- =============================================================================
-- 8. NOTIFICATIONS TABLE
-- =============================================================================

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    actor_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('follow', 'like', 'comment', 'message')),
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at);

ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

-- =============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

-- Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE follows ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- PROFILES POLICIES
CREATE POLICY "Profiles are public" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users can update their own profile" ON profiles FOR UPDATE
    USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own profile" ON profiles FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- POSTS POLICIES
CREATE POLICY "Published posts are public" ON posts FOR SELECT
    USING (status = 'published' OR (auth.uid() = user_id));
CREATE POLICY "Users can create posts" ON posts FOR INSERT
    WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own posts" ON posts FOR UPDATE
    USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own posts" ON posts FOR DELETE
    USING (auth.uid() = user_id);

-- MESSAGES POLICIES
CREATE POLICY "Users can read messages in their chats" ON messages FOR SELECT
    USING (true); -- Implement more granular checks in application
CREATE POLICY "Users can send messages" ON messages FOR INSERT
    WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their own messages" ON messages FOR DELETE
    USING (auth.uid() = user_id);

-- TASKS POLICIES
CREATE POLICY "Users can see their own tasks" ON tasks FOR SELECT
    USING (auth.uid() = user_id);
CREATE POLICY "Users can create tasks" ON tasks FOR INSERT
    WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own tasks" ON tasks FOR UPDATE
    USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own tasks" ON tasks FOR DELETE
    USING (auth.uid() = user_id);

-- FOLLOWS POLICIES
CREATE POLICY "Follows are public" ON follows FOR SELECT USING (true);
CREATE POLICY "Users can follow others" ON follows FOR INSERT
    WITH CHECK (auth.uid() = follower_id);
CREATE POLICY "Users can unfollow" ON follows FOR DELETE
    USING (auth.uid() = follower_id);

-- LIKES POLICIES
CREATE POLICY "Likes are public" ON likes FOR SELECT USING (true);
CREATE POLICY "Users can like posts" ON likes FOR INSERT
    WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can unlike posts" ON likes FOR DELETE
    USING (auth.uid() = user_id);

-- COMMENTS POLICIES
CREATE POLICY "Comments are public" ON comments FOR SELECT
    USING (deleted_at IS NULL);
CREATE POLICY "Users can comment on posts" ON comments FOR INSERT
    WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can delete their comments" ON comments FOR DELETE
    USING (auth.uid() = user_id);

-- NOTIFICATIONS POLICIES
CREATE POLICY "Users can see their notifications" ON notifications FOR SELECT
    USING (auth.uid() = user_id);

-- =============================================================================
-- FUNCTIONS & TRIGGERS
-- =============================================================================

-- Update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to tables with updated_at
CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_posts_updated_at BEFORE UPDATE ON posts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_messages_updated_at BEFORE UPDATE ON messages
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tasks_updated_at BEFORE UPDATE ON tasks
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_comments_updated_at BEFORE UPDATE ON comments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Increment view count
CREATE OR REPLACE FUNCTION increment_post_views()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE posts SET views_count = views_count + 1 WHERE id = NEW.post_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create notification on follow
CREATE OR REPLACE FUNCTION create_follow_notification()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO notifications (user_id, actor_id, type)
    VALUES (NEW.following_id, NEW.follower_id, 'follow');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_follow_created AFTER INSERT ON follows
    FOR EACH ROW EXECUTE FUNCTION create_follow_notification();

-- Create notification on like
CREATE OR REPLACE FUNCTION create_like_notification()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO notifications (user_id, actor_id, type, post_id)
    SELECT p.user_id, NEW.user_id, 'like', NEW.post_id
    FROM posts p WHERE p.id = NEW.post_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_like_created AFTER INSERT ON likes
    FOR EACH ROW EXECUTE FUNCTION create_like_notification();

-- =============================================================================
-- STORAGE BUCKETS
-- =============================================================================

-- Create storage buckets (if not exists)
INSERT INTO storage.buckets (id, name, public)
VALUES 
    ('public', 'public', true),
    ('avatars', 'avatars', true),
    ('uploads', 'uploads', true),
    ('private', 'private', false)
ON CONFLICT (id) DO NOTHING;

-- Storage bucket policies for public bucket
CREATE POLICY "Public uploads" ON storage.objects FOR SELECT
    USING (bucket_id = 'public');

CREATE POLICY "Anyone can upload to public" ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'public');

-- Storage policies for avatars
CREATE POLICY "Avatar uploads are public" ON storage.objects FOR SELECT
    USING (bucket_id = 'avatars');

CREATE POLICY "Users can upload their avatars" ON storage.objects FOR INSERT
    WITH CHECK (bucket_id = 'avatars' AND auth.uid()::text = (storage.foldername(name))[1]);

-- =============================================================================
-- HELPER VIEWS
-- =============================================================================

-- Posts with author info and stats
CREATE OR REPLACE VIEW posts_with_stats AS
SELECT
    p.*,
    pr.name as author_name,
    pr.avatar_url,
    (SELECT COUNT(*) FROM likes WHERE post_id = p.id) as likes_count,
    (SELECT COUNT(*) FROM comments WHERE post_id = p.id) as comments_count
FROM posts p
LEFT JOIN profiles pr ON p.user_id = pr.id
WHERE p.deleted_at IS NULL;

-- User stats
CREATE OR REPLACE VIEW user_stats AS
SELECT
    p.id,
    p.name,
    (SELECT COUNT(*) FROM posts WHERE user_id = p.id AND deleted_at IS NULL) as posts_count,
    (SELECT COUNT(*) FROM follows WHERE follower_id = p.id) as following_count,
    (SELECT COUNT(*) FROM follows WHERE following_id = p.id) as followers_count
FROM profiles p;

-- =============================================================================
-- INDEXES FOR PERFORMANCE
-- =============================================================================

-- Full-text search index on posts
CREATE INDEX idx_posts_search ON posts USING GIN (
    to_tsvector('english', title || ' ' || content)
);

-- JSON operations
CREATE INDEX idx_posts_tags ON posts USING GIN (tags);

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

-- Grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- =============================================================================
-- CLEANUP COMMANDS (if needed)
-- =============================================================================

-- To reset all tables:
-- DROP TABLE IF EXISTS notifications CASCADE;
-- DROP TABLE IF EXISTS comments CASCADE;
-- DROP TABLE IF EXISTS likes CASCADE;
-- DROP TABLE IF EXISTS follows CASCADE;
-- DROP TABLE IF EXISTS tasks CASCADE;
-- DROP TABLE IF EXISTS messages CASCADE;
-- DROP TABLE IF EXISTS posts CASCADE;
-- DROP TABLE IF EXISTS profiles CASCADE;
