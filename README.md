# Shenzhen Emotion Map

A static, participatory emotion map for Shenzhen.

Main entry:

- `index.html`

Deployment:

- Connect this repository to Netlify.
- Build command: leave empty.
- Publish directory: repository root.

Notes:

- User-added points are stored in browser `localStorage` as a local backup and synced to Supabase.
- Use the in-page export/import JSON feature to move local points between browsers or deployments.
- The AMap JS API key is configured inside `index.html`; remember to add the Netlify domain to the AMap domain whitelist after deployment.

## Backend database setup (Supabase Auth + RLS)

The site talks directly to Supabase from the browser — no server-side Netlify Function needed.

### 1. Create the table + RLS policies

Open Supabase SQL Editor and run the full SQL in `supabase/schema.sql`.

It creates `public.emotion_points` with:

- public coordinates rounded to 3 decimals (privacy: ~block / neighborhood scale),
- a `user_id` column referencing `auth.users`,
- row-level security (RLS): anyone can read (anonymous), but only the owning user can insert / update / delete.

### 2. Configure `index.html`

Fill in two values at the top of `index.html`:

- `SUPABASE_URL` — your Supabase project URL (e.g. `https://xxxx.supabase.co`)
- `SUPABASE_ANON_KEY` — your anon / publishable key

The anon key is safe to expose in the browser. Do **not** paste your `service_role` key.

### 3. Enable email magic-link login

In Supabase Dashboard → Authentication:

- Under Providers → Email, enable the Email provider. (Passwordless is optional — the site only uses magic links.)
- Set **Site URL** to your Netlify URL (e.g. `https://your-site.netlify.app`).
- Add the same URL to the **Redirect URLs** allow-list.

The site calls `signInWithOtp`, so a user enters their email, receives a login link, and clicks it to sign in. On redirect, `getSession()` restores the session automatically.

### 4. Privacy behavior

- Public points can be created / edited / deleted only by their owner (RLS: `auth.uid() = user_id`).
- Coordinates are rounded to 3 decimals at the database layer (`numeric(9,3)` / `numeric(8,3)`).
- The browser keeps a local `localStorage` copy, so the page still works offline; sync happens opportunistically.
