-- Migration: create_users_table
-- Creates users table for NSC Events

CREATE TABLE IF NOT EXISTS public.users (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    first_name varchar NOT NULL, 
    last_name varchar NOT NULL, 
    pronouns varchar, 
    email varchar NOT NULL UNIQUE, 
    google_credentials jsonb,
    reset_password_token varchar UNIQUE,
    reset_password_expires timestamptz,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- users can only read/update their own row
CREATE POLICY "Users can view own profile"
    ON public.users
    FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.users
    FOR UPDATE
    USING (auth.uid() = id)
    WITH CHECK (auth.uid() = id);
    
CREATE OR REPLACE TRIGGER update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW 
    EXECUTE FUNCTION public.update_updated_at_column();