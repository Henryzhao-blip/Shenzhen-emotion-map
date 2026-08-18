# Shenzhen Emotion Map

A static, participatory emotion map for Shenzhen.

Main entry:

- `index.html`

Deployment:

- Connect this repository to Netlify.
- Build command: leave empty.
- Publish directory: repository root.

Notes:

- User-added points are stored in browser `localStorage`.
- Use the in-page export/import JSON feature to move local points between browsers or deployments.
- The AMap JS API key is configured inside `index.html`; remember to add the Netlify domain to the AMap domain whitelist after deployment.

## Backend database setup

This project can optionally sync public emotion points to Supabase through Netlify Functions.

### 1. Create the Supabase table

Open Supabase SQL Editor and run:

```sql
-- see supabase/schema.sql
```

Use the full SQL in `supabase/schema.sql`.

### 2. Configure Netlify environment variables

In Netlify:

Site configuration -> Environment variables -> Add variables

Required variables:

- `SUPABASE_URL`: your Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY`: your Supabase service role key

Keep `SUPABASE_SERVICE_ROLE_KEY` server-side only. Do not paste it into `index.html`.

### 3. Privacy behavior

The Netlify Function stores public emotion points with rounded coordinates:

- Longitude and latitude are rounded to 3 decimals, roughly neighborhood/block scale.
- Public points are append-only through the public form. The API does not update or delete existing database rows.
- The browser still keeps a local `localStorage` copy so the page works even if the database is not configured.
