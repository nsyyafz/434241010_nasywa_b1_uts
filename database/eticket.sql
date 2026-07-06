-- WARNING: This schema is for context only and is not meant to be run.
-- Table order and constraints may not be valid for execution.

CREATE TABLE public.users (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  email text NOT NULL UNIQUE,
  full_name text,
  role text DEFAULT 'user'::text CHECK (role = ANY (ARRAY['user'::text, 'helpdesk'::text, 'admin'::text])),
  created_at timestamp with time zone DEFAULT now(),
  is_active boolean DEFAULT true,
  CONSTRAINT users_pkey PRIMARY KEY (id)
);
CREATE TABLE public.tickets (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text,
  status text DEFAULT 'open'::text CHECK (status = ANY (ARRAY['open'::text, 'in_progress'::text, 'closed'::text])),
  priority text DEFAULT 'medium'::text CHECK (priority = ANY (ARRAY['low'::text, 'medium'::text, 'high'::text])),
  user_id uuid,
  assigned_to uuid,
  created_at timestamp with time zone DEFAULT now(),
  category text DEFAULT 'Lainnya'::text,
  CONSTRAINT tickets_pkey PRIMARY KEY (id),
  CONSTRAINT tickets_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT tickets_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES public.users(id)
);
CREATE TABLE public.comments (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  ticket_id uuid,
  user_id uuid,
  message text NOT NULL,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT comments_pkey PRIMARY KEY (id),
  CONSTRAINT comments_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id),
  CONSTRAINT comments_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id)
);
CREATE TABLE public.notifications (
  id uuid NOT NULL DEFAULT gen_random_uuid(),
  user_id uuid,
  title text NOT NULL,
  message text NOT NULL,
  is_read boolean DEFAULT false,
  type text DEFAULT 'info'::text,
  ticket_id uuid,
  created_at timestamp with time zone DEFAULT now(),
  CONSTRAINT notifications_pkey PRIMARY KEY (id),
  CONSTRAINT notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id),
  CONSTRAINT notifications_ticket_id_fkey FOREIGN KEY (ticket_id) REFERENCES public.tickets(id)
);