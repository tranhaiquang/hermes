# Role resolution

`user_roles.user_id` stores the login identifier, which in this app is a shortcode or display name, not an email prefix. Examples:
- `LEAD TECH`
- `25102801`
- `21051708`

## Resolution chain

Use the auth helper's `currentUserId()` which returns, in order of precedence:
1. `user_metadata.login_id`
2. `user_metadata.user_id`
3. email prefix (split on `@`)

Never skip straight to the email split. When login IDs are arbitrary strings, the email prefix returns a value that does not match any row in `user_roles`, causing the role lookup to fail and the UI to fall back to viewer permissions.

## Server-side enforcement

Postgres functions `is_pm_pid()` and `is_pm_validator()` use `split_part(auth.jwt() -> 'email', '@', 1)` to resolve the user ID from the JWT. This works because the JWT email contains the same value as the login ID in these deployments. The client-side code must match that value for consistency.

## Dedicated permission tables

When a role list needs to change without a code deploy, store it in its own Supabase table (e.g. `pm_validators` with `user_id` PK, `display_name`). The client queries it as a fallback after `user_roles` returns no row:

```js
const validators = await window.SAMHO_DB.select("pm_validators", {
  columns: "user_id",
  where: { user_id: userId },
  limit: 1
});
if (validators.length) isValidator = true;
```

Do NOT hardcode role membership in `supabase/config.js`. Config files are for display constants (colors, labels, plant lists); permission membership is data and belongs in a table with an RLS policy allowing authenticated reads.
