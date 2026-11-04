# Supabase object ordering

## Canonical execution order for a single `schema.sql`

Supabase SQL Editor runs the entire file top-to-bottom. Every statement must be valid when its turn comes.

| Step | Object | Must precede |
|------|--------|-------------|
| 1 | `create extension` | everything |
| 2 | `create table if not exists` | indexes, functions, policies, RPCs, triggers that reference it |
| 3 | `create index if not exists` | nothing (can appear anytime after table) |
| 4 | SQL-language `create or replace function` | RLS policies, RPCs, triggers that call it |
| 5 | PL/pgSQL `create or replace function` | triggers that execute it |
| 6 | `drop trigger if exists` + `create trigger` | nothing (can appear after function) |
| 7 | `alter table ... enable row level security` | policies on that table |
| 8 | `drop policy if exists` + `create policy` | nothing (can appear after table is enabled) |
| 9 | `revoke ... from authenticated` | nothing |
| 10 | RPC `create or replace function` | nothing |
| 11 | Storage `insert into storage.buckets` | storage policies |
| 12 | Storage policies | nothing |
| 13 | `alter publication ... add table` | nothing |

## Why SQL-language functions must come after their tables

PostgreSQL parses the query body of a SQL-language function at `CREATE FUNCTION` time. If the referenced table does not exist yet, the statement fails immediately with `42P01`. PL/pgSQL functions are parsed lazily at first call, so they can reference tables defined later in the same transaction.

**Rule:** If a helper function is written as `language sql`, define it only after every table it queries. If it must be called by RLS policies, put it right after the last table it depends on and before the `enable row level security` block.

## Realtime publications

`alter publication supabase_realtime add table` is idempotent in effect (Supabase ignores duplicates). No need to drop and re-add. List each table exactly once in the final file to keep it readable.
