CREATE TABLE IF NOT EXISTS public.media (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    filename varchar NOT NULL,
    original_name varchar NOT NULL,
    mime_type varchar,
    size bigint NOT NULL,
    s3_key varchar,
    s3_url varchar,
    type varchar,
    uploaded_by_user_id uuid NOT NULL REFERENCES public.users(id) ON DELETE SET NULL,
    created_at timestamptz DEFAULT now(),
    updated_at timestamptz DEFAULT now()
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.media ENABLE ROW LEVEL SECURITY;

CREATE OR REPLACE TRIGGER update_media_updated_at
    BEFORE UPDATE ON public.media
    FOR EACH ROW 
    EXECUTE FUNCTION public.update_updated_at_column();