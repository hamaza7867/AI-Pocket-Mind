-- CLEANUP SCRIPT
-- Run this BEFORE the Milestone Schema to ensure a fresh start.
-- This will DELETE ALL EXISTING DATA in these tables.

DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.chat_sessions CASCADE;
DROP TABLE IF EXISTS public.personas CASCADE;
DROP TABLE IF EXISTS public.api_configs CASCADE;
DROP TABLE IF EXISTS public.knowledge_base CASCADE;
DROP TABLE IF EXISTS public.users CASCADE;

-- Note: This does NOT delete user accounts from Supabase Auth (Authentication),
-- only the profile data in the public schema.
