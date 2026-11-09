---
name: smed-supabase-integration
description: Add Supabase sync to SMED changeover app
version: 1.0.0
author: Nous Research
license: MIT
platforms: [windows, linux, macos]
metadata:
  hermes:
    tags: [smed, supabase, javascript, single-page-app, database-schema]
    category: devops
    related_skills: [xlsx-changeover-filling]
---

# SMED Changeover ↔ Supabase Integration

This reference covers the pattern for wiring the SMED changeover app to Supabase, covering the schema, the client entry (`index.html`), and the store (`src/core/store.js`). It is derived from a production codebase (`C:\\Users\\LEAN15\\Desktop\\smed-system`). The task: make the SMED app (Dashboard, Changeovers, Prep, Quality pages) read from and write to a Supabase table, without spawning a separate `index_supabase.html`.

## Output convention

- Output: `supabase/schema.sql` (the migration), `supabase-config.js` (client config), `index.html` (modified entry).
- `index.html` becomes the canonical single entry point; do **not** create `index_supabase.html`.

## Architecture overview

The SMED app uses a document-store approach: one table `smed_docs` with `jsonb` documents. Each row is one document keyed by `(coll, id)` where `coll` is a collection name (`changeovers`, `models`, `sops`, `kaizen`, `auditlog`, `smed`) and `id` is the document id. This keeps the schema flat and avoids a large number of tables.

## Step-by-step procedure

### 1. Explore the page code first

1. Read `src/pages/dashboard.js`, `src/pages/changeovers.js`, `src/pages/prep-board.js`, `src/pages/quality-board.js` to understand what data each page needs.
2. Read `src/core/store.js` to find the `init()` method and the `mode` field (local vs cloud).
3. Verify the data shape: each page reads `Store.data.changeovers` (as a js object, not a Firestore query), then computes KPIs, pareto, alerts, etc.

### 2. Design the Supabase schema

1. Create a single document-store table `public.smed_docs` with columns `coll text`, `id text`, `data jsonb`, `updated_at timestamptz`.
2. Define the primary key as `(coll, id)`:
   - `create table public.smed_docs (coll text not null, id text not null, data jsonb not null default '{}'::jsonb, updated_at timestamptz not null default now(), constraint smed_docs_pkey primary key (coll, id))`);
3. Add indexes on `coll` and `(coll, id)`.
4. Create a recursive `jsonb` merge function `public.smed_jsonb_merge(base jsonb, patch jsonb)` for deep merging.
5. Create an upsert RPC `public.smed_patch(coll text, id text, patch jsonb)` that uses `on conflict (coll, id) do update set data = smed_jsonb_merge(public.smed_docs.data, excluded.data)`. This is used by `store.update()`.
6. Enable RLS and realtime publication for `smed_docs`.
7. Grant `select, insert, update, delete` to `anon, authenticated`.

### 3. Write the schema.sql migration file

1. Structure the `.sql` file with clear sections:
   - `create table public.smed_docs` + comments
   - `create index` on `coll` and `(coll, id)`
   - `create function public.smed_jsonb_merge(base jsonb, patch jsonb)`
   - `create function public.smed_patch(coll text, id text, patch jsonb)`
   - `grant` statements
   - `do $$ create publication ...` (realtime)
   - `alter table ... enable row level security`
   - `create policy ...` (anon+authenticated read/write)
   - `create function public.smed_selfcheck()`
2. Include working query examples in comments at the end.

### 4. Configure the Supabase client

1. In `supabase-config.js`, set `window.SMED_SUPABASE = { url: '...', anonKey: '...' }`.
2. The `anonKey` is public (designed by Supabase); security lives in RLS.
3. Install `supabase-js` (via CDN) before the inline script that references it.

### 5. Modify `index.html` entry point

1. Add the Supabase script tags **before** the inline script:
   ```html
   <script src="supabase-config.js"></script>
   <script src="supabase.min.js"></script>
   <script src="supabase-client.js"></script>
   ```
2. Insert an inline `<script>` that detects and initializes Supabase:
   ```js
   let SMED_DB = null;
   if (window.SMED_SUPABASE && window.SMED_SUPABASE.url && window.SMED_SUPABASE.anonKey) {
     const { createClient } = window['supabase'];
     SMED_DB = createClient(window.SMED_SUPABASE.url, window.SMED_SUPABASE.anonKey, {
       global: { fetch: window.fetch },
       auth: { persistSession: false }
     });
     window.SMED_DB = SMED_DB;
   }
   ```
3. Keep the existing `window.SMED_SEED` inline script unchanged (it remains the fallback input).
4. Ensure the inline script ends with `window.SMED_DB = SMED_DB;` before the seed is assigned.

### 6. Integrate with `store.js`

1. The `init()` method already tries `window.claude.use('db')` first. Extend it to also try Supabase:
   ```js
   async init() {
     let db = null;
     try { if (window.claude && typeof window.claude.use === 'function') db = await window.claude.use('db'); } catch (e) { db = null; }
     if (!db && window.SMED_DB) db = window.SMED_DB;
     if (db) { this.db = db; this.mode = 'cloud'; this.startCloud(); }
     else { this.mode = 'local'; this.startLocal(); }
   }
   ```
2. The `startCloud()` method already subscribes to `smed/config`, `changeovers`, `models`, `sops`, `kaizen`, `auditlog` using `db.doc()` / `db.collection().onSnapshot()`.
3. The `write()` method already handles `mode === 'cloud'` with `db.doc()` / `db.collection().doc().set()` / `.update()` / `.delete()`.
4. The `ref(coll, id)` helper maps `smed` → `db.doc('smed/config')`, others → `db.collection(coll).doc(id)`.
5. Make sure the cloud mode honors `pending` queue, `flush()`, and `offline` fallback.

### 8. Vercel deployment

1. Create `vercel.json` with `@vercel/static` build for `index.html` and a fallback route `/(.*)` → `index.html`.
2. Push all files to Vercel: `index.html`, `vercel.json`, `supabase-config.js`, `supabase.min.js`, `supabase-client.js`, `src/`, `supabase/`.
3. Ensure the deployment provides `window.SMED_DB` (the Supabase adapter) so `store.js` switches to cloud mode.
4. Verify: load the Vercel URL, check that data is synced to Supabase (not just `localStorage`).

## Common pitfalls

- **Supabase client library is mandatory**: the CDN must load `supabase.min.js` **before** the inline script that calls `createClient()`. If you forget this, `window['supabase']` is undefined and the app silently falls back to local mode.
- **Seed data must not shadow Supabase data**: `window.SMED_SEED` is the fallback input. When `window.SMED_DB` is set, `store.init()` should prefer Supabase. Keep the seed script intact (it is the offline fallback).
- **LocalStorage vs Supabase**: `store.js` has `mode: 'local'` and `mode: 'cloud'`. The `init()` method decides. If `SMED_DB` is set, use cloud mode; otherwise use local.
- **Seed ≠ storage**: `window.SMED_SEED` is the initial fallback data, not the live storage mechanism. Data is actually persisted to `localStorage` (local mode) or Supabase (cloud mode). The two only combine at startup when loading the seed into `localStorage` as the initial state.
- **Full-table access overrides RLS**: the policies `smed_docs_read`, `smed_docs_insert`, `smed_docs_update`, `smed_docs_delete` grant `anon` + `authenticated` full access for pilot/internal. For production, disable these and use scoped RLS.
- **`store.js` expects `db.doc()` / `db.collection()`**: the store calls these directly. Your adapter must expose the same thin wrappers around the Supabase JS client.
- **`anonKey` must be real**: the placeholder `eyJhbG...Yf2M` blocks any Supabase write. Replace it with the real key from Supabase Dashboard → Project Settings → API before testing sync.
- **CSS lives only in `index.html`'s `<style>` block** — `src/` holds JS only, there are no CSS files under `src/`. Make all style edits directly in `index.html`; grep `src/` first only to confirm.
- **Treat `index.html` as the source of truth.** The `src/` ↔ `index.html` split/build round-trip is currently broken (`tools/build-app.mjs` expects a missing `index_split.html`; `tools/split-app.mjs` fails on stale per-file markers), so it cannot regenerate `index.html`. Apply JS changes to `index.html` and mirror them into the matching `src/` file by hand so the two do not drift.
- **First `git push` on a fresh branch needs `--set-upstream origin main` once**; afterwards plain `git push` works.

## Common pitfalls

- **Supabase client library is mandatory**: the CDN must load `supabase.min.js` **before** the inline script that calls `createClient()`. If you forget this, `window['supabase']` is undefined and the app silently falls back to local mode.
- **Seed data must not shadow Supabase data**: `window.SMED_SEED` is the fallback input. When `window.SMED_DB` is set, `store.init()` should prefer Supabase. Keep the seed script intact (it is the offline fallback).
- **LocalStorage vs Supabase**: `store.js` has `mode: 'local'` and `mode: 'cloud'`. The `init()` method decides. If `SMED_DB` is set, use cloud mode; otherwise use local.
## When to Use

Use this skill when the user needs to:
- Integrate the SMED changeover app with Supabase (single-page app `index.html` + `store.js`).
- Design a Supabase schema for the SMED dashboard, changeover, prep, and quality pages.
- Add real-time sync to the SMED app's data layer.
- Verify Supabase connectivity and push data to the `smed_docs` table.
- Deploy the SMED app to Vercel with Supabase backend.

## User interaction preferences

- **Concise, direct answers**: no filler, no restating the question, no restating what was done. State the result, the artifacts produced, and what is left to verify.
- **Working artifacts over prose**: deliver files, rendered output, and verified commands — not descriptions of what you would do.
- **Rephrase with corrected grammar** before acting on every request.
- **Credentials**: `supabase-config.js` `anonKey` comes from Supabase Dashboard → Project Settings → API → anon public. Redact the exact value in any record; the URL and key location are the operative facts.

## Related skills

- `xlsx-changeover-filling` — changeover system, but focused on filling Excel template from production data. The database schema here complements the Excel pipeline.
- `csv-xlsx-data-pipeline` — for merging CSV + XLSX data.
- `web-artifact-generation` — HTML data-viz chart generation.
