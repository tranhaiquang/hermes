---
description: 'Author and fix Supabase schema.sql ordering.'
name: supabase-schema
---

# Supabase schema

Use when authoring, fixing, or verifying a Supabase `schema.sql` migration file. Covers correct object ordering, idempotency, corruption cleanup, and verification.

## Always-on user preferences

1. **Concise, direct answers** — no filler, no restating the user's request back, no narrating tool calls they can see. Short report of what changed, what's verified, what's left.
2. **Working artifacts over prose** — deliver files, rendered output, verified results. Never describe an artifact you didn't produce.
3. **Rephrase the user's request before acting** — correct the grammar of every request in your reasoning, then act.

## Procedure

### 1. Identify all objects and their dependencies

List every object: tables, indexes, SQL/PL/pgSQL functions, triggers, RLS policies, RPCs, realtime publications. Grep each SQL function's body for table references — those tables must exist first.

### 2. Enforce correct ordering

1. Extensions
2. Tables
3. Indexes
4. SQL-language helper functions (reference tables)
5. Triggers
6. RLS: `enable row level security` on each table
7. RLS policies
8. RPCs
9. Storage buckets and policies
10. Realtime publications

**Critical rule:** SQL-language functions are parsed at creation time, not call time. A table queried in a function body must be defined first. PL/pgSQL functions parse lazily; SQL functions do not.

### 3. Make idempotent

`create or replace function`, `create or replace trigger`, `drop ... if exists`, `create table if not exists`, `create index if not exists`, `on conflict do nothing`, `drop policy if exists ... create policy ...`.

### 4. Clean corruption

Duplicate headers, duplicate definitions, `||` prefixes from markdown paste, orphaned section stubs. Grep for `create extension`, `create or replace function <name>`, and `^\|\`.

### 5. Verify before delivering

1. Duplicate scan: exactly one definition per function
2. Corruption scan: no `||` lines, no duplicate headers
3. Dependency order: every `create table` before any function/policy querying it
4. Final grep: every referenced object has one prior definition

## Pitfalls

- **SQL-language function before table = hard error.** Move the table above the function.
- **Supabase runs schema.sql top-to-bottom in one transaction.** File order is the only thing that matters.
- **RLS policies can reference functions in the same file** — function must appear before the `create policy`.
- **`alter publication ... add table` is safe to repeat** — no drop-then-add needed.
- **`create extension` must not be inside a transaction block**.
- **Verify before delivering:** always run the checks (duplicate scan, corruption scan, dependency order) before claiming the schema is correct.
- **Schema design for doc-store (jsonb):** when a system stores data as `jsonb` in a single `smed_docs` table, design queries that traverse the JSONB with `jsonb_array_elements`, `->`, and `->>` operators rather than creating separate relational tables. The article's three pages (Dashboard, Changeovers, Prep, Quality) all read from `coll='changeovers'` with nested `checklist`, `trials`, `defects` arrays — no new tables needed beyond `smed_docs` itself.

## Testing Supabase connectivity

After writing or updating `schema.sql`, verify the connection before claiming done.

1. **Check `supabase-config.js` API key is complete** — it must not contain `...` (placeholder). The full key must be present. If the key is truncated, Supabase returns `Invalid API key` for every request.

2. **Test the connection with curl**:

```bash
curl -s "https://<project>.supabase.co/rest/v1/smed_docs?select=coll,id&limit=1" \
  -H "apikey: <FULL_ANON_KEY>" \
  -H "Authorization: Bearer <FULL_ANON_KEY>" \
  -H "Content-Type: application/json"
```

- Return `[]` → connection OK, table exists, no data yet
- Return `Invalid API key` → key wrong / truncated
- Return `403` → RLS or table missing

3. **After deploying `schema.sql`**, re-run the curl test. If the response is still `[]`, schema is active but empty (normal).

4. **Push data through the app** (open `index_supabase.html` in the browser), then re-query `smed_docs` to confirm records appear.

### Pitfall

- `supabase-config.js` API key must be the full key from Supabase Dashboard → Project Settings → API. A truncated key (`eyJhbG...Yf2M`) silently makes every request return `Invalid API key`. `supabase-config.js` stores the key in plain text; it is public by design (Supabase anon public key), but RLS policies in `schema.sql` are the real access control.