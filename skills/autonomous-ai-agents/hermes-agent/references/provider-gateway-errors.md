# Provider / gateway error diagnosis

Procedure for a model call that fails with an upstream error (503, 401, 402) through a local router. Apply steps in order; stop once the failing layer is identified.

1. **Identify the failing backend.** The error names a provider/model (`cfp/...`, `unc/turboderp/...`, `cloudflare-playground/...`). That prefix maps to the router's backend provider, not the router itself.
2. **Check local config.** `model.provider`, `model.base_url`, `model.key_env` in `config.yaml`; the credential named by `key_env` in Hermes `.env`. Verify the router is wired to the right endpoint and has a valid key.
3. **Check the router's own records.** In the router `storage.db`: `provider_connections` (is_active, auth_type, api_key, error_code, last_error) and `api_keys`. A connection flagged `noauth` with a backend 503/401 usually means the *router has no credential* for that backend — not that the backend is down.
4. **Read the router `call_logs` for the upstream error text.** The backend's status text is the ground truth: e.g. "needs Playwright + Chromium", "public beta closed", "insufficient balance", "high demand". These are *upstream-provider* messages.
5. **Apply the fix at the right layer.**
   - Local config/tooling fix (missing credential, `npm i playwright && npx playwright install chromium`, auth re-run) — fix in this config. This is rare.
   - Upstream availability — the redirect provider must reopen, restore quota, or grant access. Nothing in the router config changes it. Wait or request access.

## Pitfalls

- **Do not edit router config.yaml to chase an upstream 503/401.** The router usually routes correctly; the backend is the one rejecting. Config changes only fix the layer that is actually misconfigured (missing/invalid key, missing browser runtime, wrong base_url).
- **Status codes are upstream-provided, not router-generated.** A 503 from `cloudflare-playground` means the playground needs a browser, not that the proxy is broken.
- **Read the error text before acting.** The fix for "503" is "503" — implement the browser run, the closed-beta, or the quota issue, not a config edit.

## Known upstream states (examples)

| Upstream signal | Meaning | Fix layer |
|---|---|---|
| `needs Playwright and its Chromium browser` (503) | Backend worker cannot launch a browser | Local tooling: install Playwright + Chromium |
| `public beta is closed ... key registration is closed` (401) | Backend registration shut | Upstream access (reopen / invite) |
| `Insufficient Balance` (402) | Account quota exhausted | Upstream funding |
| `high demand` / `capacity` (503) | Backend throttled | Retry later |
