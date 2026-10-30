-- ====================================================================
-- EduSync PostgreSQL Database Schema for Supabase
-- Target Package: com.edusync.app
-- Architecture: Row-Level Security (RLS) enabled on all tables
-- ====================================================================

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Student Profiles Table
CREATE TABLE IF NOT EXISTS public.student_profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL UNIQUE,
    mobile TEXT UNIQUE,
    name TEXT NOT NULL,
    is_school_student BOOLEAN NOT NULL DEFAULT true,
    grade TEXT,
    board TEXT,
    state TEXT,
    medium TEXT DEFAULT 'English',
    school_name TEXT,
    degree TEXT,
    college_name TEXT,
    department TEXT,
    year_or_sem TEXT,
    subjects JSONB DEFAULT '[]'::jsonb,
    main_goal TEXT DEFAULT 'Understand concepts',
    daily_questions_used INT DEFAULT 0,
    last_question_date DATE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable RLS on student_profiles
ALTER TABLE public.student_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view only their own profile"
    ON public.student_profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can insert only their own profile"
    ON public.student_profiles FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update only their own profile"
    ON public.student_profiles FOR UPDATE
    USING (auth.uid() = id);

CREATE POLICY "Users can delete only their own profile"
    ON public.student_profiles FOR DELETE
    USING (auth.uid() = id);

-- 3. Conversations Table
CREATE TABLE IF NOT EXISTS public.conversations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    subject TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can access their own conversations"
    ON public.conversations FOR ALL
    USING (auth.uid() = user_id);

-- 4. Messages Table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant')),
    content TEXT NOT NULL,
    suggested_follow_ups JSONB DEFAULT '[]'::jsonb,
    source_citations JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view messages in their conversations"
    ON public.messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can insert messages into their conversations"
    ON public.messages FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.conversations
            WHERE conversations.id = messages.conversation_id
            AND conversations.user_id = auth.uid()
        )
    );

-- 5. Study Materials Table
CREATE TABLE IF NOT EXISTS public.study_materials (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    file_name TEXT NOT NULL,
    file_type TEXT NOT NULL,
    file_size_bytes BIGINT NOT NULL,
    storage_url TEXT,
    extracted_text TEXT,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.study_materials ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage only their own study materials"
    ON public.study_materials FOR ALL
    USING (auth.uid() = user_id);

-- 6. Material Chunks Table (for RAG document search)
CREATE TABLE IF NOT EXISTS public.material_chunks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    material_id UUID NOT NULL REFERENCES public.study_materials(id) ON DELETE CASCADE,
    chunk_index INT NOT NULL,
    chunk_content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.material_chunks ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view chunks of their own materials"
    ON public.material_chunks FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.study_materials
            WHERE study_materials.id = material_chunks.material_id
            AND study_materials.user_id = auth.uid()
        )
    );

-- 7. Quizzes Table
CREATE TABLE IF NOT EXISTS public.quizzes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    subject TEXT NOT NULL,
    mode TEXT NOT NULL CHECK (mode IN ('mcq', 'short_answer')),
    questions JSONB NOT NULL,
    score INT,
    total_questions INT NOT NULL,
    is_completed BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.quizzes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage only their own quizzes"
    ON public.quizzes FOR ALL
    USING (auth.uid() = user_id);

-- 8. Flashcards Table
CREATE TABLE IF NOT EXISTS public.flashcards (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    subject TEXT NOT NULL,
    cards JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.flashcards ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage only their own flashcards"
    ON public.flashcards FOR ALL
    USING (auth.uid() = user_id);

-- 9. Daily Usage Limits Table
CREATE TABLE IF NOT EXISTS public.usage_limits (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    date DATE NOT NULL,
    questions_used INT DEFAULT 0,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id, date)
);

ALTER TABLE public.usage_limits ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage only their own usage limits"
    ON public.usage_limits FOR ALL
    USING (auth.uid() = user_id);

-- 10. Curriculum Topics Table (Known Syllabus Reference for AI Personalization)
CREATE TABLE IF NOT EXISTS public.curriculum_topics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    board_or_university TEXT NOT NULL,          -- e.g. 'CBSE', 'Tamil Nadu State Board', 'Anna University', 'VTU'
    grade_or_degree TEXT NOT NULL,              -- e.g. 'Grade 10', 'B.Tech'
    department_or_stream TEXT,                  -- e.g. 'Science', 'CSE'
    subject TEXT NOT NULL,                      -- e.g. 'Science', 'Software Engineering'
    chapter_or_unit TEXT NOT NULL,              -- e.g. 'Life Processes', 'SDLC'
    topic_name TEXT NOT NULL,                   -- e.g. 'Photosynthesis', 'Waterfall Model'
    key_concepts TEXT NOT NULL,                 -- Essential formulas, definitions, key exam facts
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.curriculum_topics ENABLE ROW LEVEL SECURITY;

-- Allow all authenticated and anonymous clients to query curriculum topics
CREATE POLICY "Curriculum topics are readable by all users"
    ON public.curriculum_topics FOR SELECT
    USING (true);

-- 11. Automatically Create Student Profile on Auth Sign Up Trigger
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.student_profiles (id, email, name, mobile, is_school_student, subjects, main_goal)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data->>'name', 'Student'),
        NEW.raw_user_meta_data->>'mobile',
        true,
        '["Mathematics", "Science", "English"]'::jsonb,
        'Understand concepts'
    )
    ON CONFLICT (id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
