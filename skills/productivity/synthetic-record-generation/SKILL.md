---
name: synthetic-record-generation
description: "Generate synthetic records into a governed data corpus."
version: 1.0.0
author: Nous Research
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [csv, data-generation, synthetic-data, validation, productivity]
    category: productivity
    related_skills: [csv-xlsx-data-pipeline]
---
# synthetic-record-generation

Generate a new batch of synthetic records that conform to an existing governed data corpus (schema, banned-value lists, encoding conventions, collision rules).

## When to Use

Use when the user asks to "generate data" for a date range or batch in a data workspace that already contains historical records, a governing AGENTS.md/conventions file, and prior generated batches (e.g. a repair-record or event-log corpus):
- Extending a corpus with a new dated batch of synthetic rows.
- Rebuilding a generator when the workspace's documented scripts have gone missing.
- Regenerating a batch after a rule or vocabulary change.

NOT for merging/transforming existing real data (see `csv-xlsx-data-pipeline`) or filling a report template.

## Procedure

1. **Read the workspace's conventions file first** (AGENTS.md or equivalent). It is the spec: record schema, hard rules (date window, per-entity caps, banned lists, plant/section filters), encoding conventions, naming convention, and where generators live. Never rediscover these by guessing.
2. **Profile the existing batches** — row counts, per-day distribution, plant/entity scope, field distributions — and replicate the established batch convention (e.g. N rows per plant per day) unless the user says otherwise.
3. **Derive every value pool from the corpus itself**, never from invented literals:
   - Entity catalog (e.g. machine_info): filter by the status column the conventions specify (e.g. `Use`/`USE`).
   - Technician/value pools: from history plus prior generated batches; apply banned-value filters at generation time, splitting multi-name fields and rejecting if ANY part is banned.
   - Categorical vocabularies (issue/reason/solve/other): from the previously generated files only, so the new batch's vocabulary matches prior batches rather than the rawer historical file.
4. **Load the collision set** from ALL existing CSVs (historical + every prior generated batch) using the canonical key the conventions define (commonly `item_code|start floored to minute`). Exclude the output file from this read.
5. **Generate with invariants enforced inline**: row ordering (start ≤ fix ≤ end), `total_downtime = end − start`, same-day/same-month containment, per-entity-per-day caps and minimum spacing, and retry-on-collision against the canonical key (including within the batch itself). Use a fixed random seed for reproducibility.
6. **Write byte-conformant output**: the corpus's encoding (BOM or none), line endings, and no-trailing-newline rule. Write via a csv writer into a buffer, prepend/strip bytes manually, then write bytes.
7. **Validate with an independent check script** — re-read the written file and verify every hard rule (schema, window, ordering, downtime arithmetic, distribution of categorical fields, self-dupes, collisions vs history, catalog consistency). Iterate until the check reports zero errors before declaring done.

## Always-on rules

- **Never overwrite historical/source files.** Produce only a new dated file following the corpus naming convention; generators live at the location the conventions doc names.
- **Rephrase the user's request with corrected grammar before acting**, then answer concisely with the artifact path and a validation summary — no filler, no restating the request.
- If the conventions doc references generator scripts that no longer exist, rebuild the generator per the documented rules and keep it at the documented location.

## Pitfalls

- **Build value pools from the corpus, not hardcoded literals.** Corpora carry codepoint and case quirks (e.g. Vietnamese solve values using uppercase-horn codepoints like `S\u1eecA CH\u1eeeA`); a literal typed from memory silently drops the category from the pool. Sample the file's exact strings; if a whitelist is unavoidable, compare case-folded but emit the corpus's exact bytes.
- **Exclude the output file from every input read.** Batch glob patterns (e.g. `generated_*_2026-*.csv`) also match the new output, so a rerun ingests its own rows, polluting pools and the collision set. Filter by basename.
- **Clamp derived times inside their bounds.** A fix/repair offset sampled without regard to total duration produces `fix > end` ordering violations; sample the offset from `[min, min(max_offset, duration - margin)]`.
- **Containment is a generation-time constraint, not a post-filter.** When the rules require same-day or same-month start/end, cap the start hour and total duration so the event can never cross the boundary.
- **Verify encoding at byte level, never by console rendering.** Terminals mangle non-ASCII (mojibake/boxes) and cp1252 consoles raise `UnicodeEncodeError`; decode the written file and compare bytes instead. Match the corpus's BOM and trailing-newline conventions exactly — Excel-class consumers depend on them.
- **On Windows MSYS shells, pass native `C:/...` paths to native tools.** A `/c/...` path handed to python gets mangled into `C:\\c\\...` and fails with 'file not found'.
- **Independent validation is its own pass.** A generator that 'looks right' is not evidence — re-read the output and check the rules mechanically, including cross-file collisions.
