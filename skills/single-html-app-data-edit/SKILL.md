---
name: single-html-app-data-edit
description: Use when editing a person in the single-file dashboard.
category: software-development
version: 0.1.0
author: Hermes Agent
license: MIT
hermes:
  tags: [dashboard, html, data-edit, roster, single-file]
  related_skills: []
---

# Single-file HTML app — data edit

## When to Use

Use this skill for any request to change a person's role, team, or seniority in the single-file HTML dashboard — promote, transfer, re-tier, or re-award — and for every request that touches the roster seed, the leader maps, or the Supabase roster seed.

- Always-on rules (user preferences)

- Concise, direct answers only: no filler, no restating the request back to the user.
- Working artifacts on disk, not prose summaries.
- Rephrase the user's request with corrected grammar before acting; confirm the person (by ID and name), the target role, and the target team in one line before writing.
- Report one line: person, new role/team, files changed, verified on disk.

- Read every mirror before editing and state which source files you touched; every consumer of `PEOPLE` is also a consumer of the seed and of the Supabase seed.
- Keep the pristine seed intact. Edits are deltas, not rewrites. If you change a seed row, the CSV, the app seed, and the Supabase seed move together or the dashboard and the cloud disagree on the next pull.

## Procedure

1. **Rephrase the request (corrected grammar) and state the plan** in one line: person ID, target role, target team. Do not restate the user's request back verbatim.
2. **Read every mirror once** and decide the exact file set: the seed CSV, the app's `PEOPLE` + `BASE_PEOPLE`, the leader maps (`TEAM_GL`, `ORG_CHART.reports`, `ORG_CHART.teamsUnder`), the Supabase seed SQL, and any doc (AGENTS.md). Read each once; do not guess from memory.
3. **Anchor every edit by person ID (plus name)**. Never by a non-unique field value — `team: "LEAN TECH", pos: "Staff"` matches several rows and reaches the wrong person. The ID makes the match single.
4. **Apply the edits** to every mirror the person appears in, then **verify each file on disk** (re-read the changed lines) rather than trusting memory. Run the app's own checks where it has them (e.g., the `select count(*)` row/role summary in the Supabase seed SQL).
5. **Update the reporting line maps** — `ORG_CHART.reports`, `ORG_CHART.teamsUnder`, `TEAM_GL` — in a single pass whenever a person's position, team, or seniority moves. Verify the other leaders are still under their real managers. Open the app and re-render the org chart and lanes to confirm: no double-listed names, no empty lane, correct tier colours.
6. **Report one line** — person, new role/team, files changed, verified on disk — matching the style of the request itself.

## Pitfalls

- Anchor by ID. A non-unique `team`+`pos` match is a bug waiting to overwrite a different employee.
- Reporting lines and leader maps are **organisational facts**, not derived fields. Change every map that moves, and verify the others' managers did not silently change — an editing pass must be end-to-end, not one-file.
- **Seed files and the app seed must not drift.** A change with no CSV/seed counterpart will re-propagate on the next pull. Do not fix a report in the app and leave the CSV stale.
- **Stale comments are lies the next agent will read.** Rewrite or delete them in the same pass; do not leave a comment that contradicts the code, either in the dashboard or in the Supabase migrations.
- **The `BASE_PEOPLE` copy of the seed must not share object identity with `PEOPLE`.** Editing a delta must never mutate the merge base, or the pristine seed is lost and the app reverts to the old roster.
- **Windows paths.** This session runs on Windows 10 (Hermes desktop app). Do not emit bare `C:\` or `D:\` paths; use `C:/Users/<user>/...` or `\\$env:USERPROFILE` style so that the Hermes desktop app and the terminal tool both consume them correctly.

## Scope

The project's AGENTS.md documents the structure and the data-model map; this skill covers the edit procedure and the pitfalls that cost a pass.