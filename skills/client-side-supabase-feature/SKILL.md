---
name: client-side-supabase-feature
description: Use when adding features to a vanilla JS + Supabase web app.
version: 1
license: MIT
author: hermetic
---

# Client-side Supabase Feature Work

## When to Use

Use for feature additions, UI fixes, and client-side logic changes in an existing vanilla JS + Supabase app where auth, DB, i18n, and UI state are already wired.

## Always-on rules

1. **Preserve module boundaries.** HTML markup stays in root-level `.html` files. Page-specific JS stays in `assets/js/`. Shared CSS stays in `assets/css/`. Supabase config stays in `supabase/config.js`. Do not relocate files to match a different framework layout.

2. **Resolve user identity through the auth helper, never by parsing email.** Login IDs stored in `user_roles.user_id` are shortcodes or display names (e.g. `LEAD TECH`, `25102801`), not email prefixes. Use `window.SAMHO_AUTH.currentUserId()` or equivalent. Parsing the email prefix returns wrong values for these accounts.

3. **Source records from the page's canonical array; route filtered views through the existing filter function.** Most pages keep loaded records in a module-scoped array (e.g. `currentRecords`). UI filters expose a `getVisibleRecords()` function. Charts and stats must consume `getVisibleRecords()` so they stay consistent with the table and calendar.

4. **Adding Chart.js visualizations.** Load Chart.js from CDN in the page `<head>`. Write a render function that accepts records and the page's i18n helper. Destroy the previous chart instance before creating a new one. Call the render function from the main data load path, from filter-change handlers, and from the language-change event so the chart stays in sync.

5. **UI action buttons derive from role flags, not from role strings inline.** Compute `currentUserRole` and `isValidator` once from the `user_roles` lookup. Render buttons conditionally based on those flags. This keeps permission logic centralized and prevents drift.

6. **Append-only status flags.** Flags like `rescheduled` are booleans that are set but never cleared. When an edit changes a due date, set the flag. Do not unset it when the date changes again.

7. **Register i18n keys for every new user-facing string.** Place keys in the page's existing `SAMHO_LANG.register` block. Re-render new UI pieces inside the page's existing `samho:langchange` handler.

9. **Syntax-check before declaring done.** Run `node --check "C:/path/to/file.js"` on any edited JS file. This catches mismatched braces from partial-file edits.

10. **Role lookups must fall back to a dedicated permission table when DB returns no row.** `user_roles` may be missing a row due to seed drift or RLS mismatch. After the query, if the role is still unknown, query a dedicated table like `pm_validators` (columns: `user_id`, `display_name`) before defaulting to viewer. Never hardcode role lists in `supabase/config.js` — client config is for display constants only; permission membership belongs in a Supabase table so it can change without a code deploy.

11. **Rephrase the user's request with corrected grammar before acting, every time** (standing user preference — do it even when the request is already grammatical).

12. **Mobile zoom fixes need all layers at once — see `references/mobile-safari-zoom.md`.** iOS Safari ignores `user-scalable=no` in the viewport meta tag; the CSS `touch-action` rule plus the ≥16px input rule are what actually stop pinch and focus zoom. Applying only the meta tag or only the JS gesture blockers leaves zoom working.
