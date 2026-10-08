# Campusly

A responsive student and teacher campus dashboard made with React, Vite and Supabase. It includes announcements, assignments, a timetable, teacher class analytics, messages, a campus-aware demo assistant, and “What did I miss?”.

## Run locally

```sh
npm install
npm run dev
```

Without Supabase credentials, sample campus data powers the demo UI. Copy `.env.example` to `.env.local` and provide `VITE_SUPABASE_URL` and `VITE_SUPABASE_ANON_KEY` to connect a Supabase project. Run `supabase/schema.sql` in its SQL editor first. The frontend uses only the public anon key; configure Auth and review RLS for your institution before adding real campus data. Faculty roles must be assigned by an administrator.

## Vercel

Import the GitHub repository in Vercel, choose the Vite preset, and set the two Supabase environment variables for Preview and Production. Vite builds with `npm run build` into `dist`.

## GitHub

Create a repository in your GitHub account and push this folder. GitHub and Vercel publishing need access to your accounts; credentials do not belong in this project. See `.env.example` for configuration names.
