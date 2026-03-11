WITH new_admin AS (
INSERT INTO auth.users (
    id,
    email,
    encrypted_password, 
    email_confirmed_at,
    created_at,
    updated_at, 
    aud, 
    role
)
VALUES (
    gen_random_uuid(), 
    'admin@gmail.com',
    crypt('Admin123!', gen_salt('bf')),
    now(), 
    now(),
    now(),
    'authenticated',
    'authenticated'
)
RETURNING id, email
)
INSERT INTO public.users (
    id,
    first_name,
    last_name,
    user_role,
    email
)
SELECT
    id,
    'Admin',
    'NSC',
    'admin',
    'admin@gmail.com'
FROM new_admin;