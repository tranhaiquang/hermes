---
name: security-audit
description: Audit Supabase apps for RLS gaps, anon exposure, and leaks.
version: 1.0.0
author: Hermes Agent
license: MIT
category: security
metadata:
  hermes:
    tags: [supabase, rls, security, audit, anon]
    related_skills: [codebase-inspection, dogfood]
---

# When to Use

Use this skill whenever you are asked to audit or verify the security posture of a web application backed by Supabase — before any policy changes are applied, after RLS hardening, or when investigating a suspected leak. It is the workflow for turning a Supabase-backed app into a verified-secure one.

# Security Audit

Class-level skill for auditing the security posture of web applications backed by Supabase. Covers RLS, anon/authenticated role blocking, RPC access control, storage bucket visibility, and secret hygiene.

## Always-on rules

1. **Read config and policy files before probing.** Start with `supabase/config.js` for the canonical URL, keys, and table/column mappings. Then read `supabase/policies/*.sql` for the intended RLS policies. Only then probe the live database to confirm the deployed state matches intent.

2. **Retrieve audit scripts from git first.** The scripts `supabase/policies/security_audit.sql`, `revoke_anon_grants.sql`, and `harden_anon_surface.sql` are the authoritative record of the intended policy state. Always restore them from git before running — the working tree can hold stale copies. The scripts are idempotent and safe to re-run.

3. **Probe the Supabase REST API as the anon role.** The anon key (`sb_publishable_...`) is public-by-design. Use it to probe:
   - Table SELECT/DELETE/PATCH/INSERT — each should return 401 or 403 after hardening.
   - RPCs (e.g. `rpc/list_user_display_names`) — should return 401.
   - Storage endpoints — verify visibility is controlled.
   A `200` with `[]` is NOT a security pass for tables: the anon role may still hold DELETE grants that bypass RLS.

4. **Check git history for leaked secrets.** Run `git grep -i -P '(eyJ[A-Za-z0-9_-]+.[eyJ[A-Za-z0-9_-]+.[A-Za-z0-9_-]+|service_role|SUPABASE_SERVICE_ROLE_KEY)' --all`. Any match in a tracked file or commit is a leak to treat as compromised (rotate + purge). Guard admin scripts (`update-display-name.js`, `sync-users.mjs`, `prune-users.mjs`) with grep checks before committing to confirm the secret key is not in the tree.

5. **Summarize in three tiers:**
   - High: anon role blocked from all application tables and RPCs.
   - Medium: any anon-executable function, world-writable table, or overly-permissive storage.
   - Low: design notes (e.g. storage bucket visibility is public by default).

## Pitfalls

- **The anon key is public-by-design.** `sb_publishable_...` is intended to be in a committed config file. Never treat its presence in the repo as a leak.
- **The secret key must never be committed.** `sb_secret_...` 401s from browsers by UA check. Guard `supabase/update-display-name.js`, `sync-users.mjs`, `prune-users.mjs` — they should read the key from `SUPABASE_SERVICE_ROLE_KEY` env var, not hardcode it.
- **RLS is only as good as the grants.** A table can have RLS enabled but still be world-writable if `anon` holds a DELETE/INSERT/PATCH grant. Verify with `information_schema.role_table_grants` after any policy change.
- **Storage buckets are public unless declared private.** `storage.buckets` rows with `public = true` serve objects to everyone. If the app serves images via `/storage/v1/object/public/`, the editor-only `SELECT` policy on `storage.objects` is bypassed by design — decide publicly or private+signed URLs deliberately.
- **Secret revocation is blocked while legacy JWT-based keys exist.** You cannot rotate signing keys alone: API Keys → JWT Signing Keys → Rotate Keys → ⋮ then Revoke. Legacy secrets cannot be rotated directly on unmigrated projects.
- **No arbitrary SQL via the Rest API.** Supabase REST does not accept arbitrary SQL; the SQL Editor is a separate tool. For catalog-level queries (pg_proc, storage.buckets) you need a privileged role — ask the user for a service_role client or run the scripts locally via the SQL Editor.
