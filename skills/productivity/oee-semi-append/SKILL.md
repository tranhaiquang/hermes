---
name: oee-semi-append
description: "Append production into the prior month OEE SEMI template."
tags: [oee, semi, monthly-append]
version: 1.0.0
author: Nous Research
license: MIT
platforms: [windows]
metadata:
  hermes:
    tags: [oee, semi, monthly-append, xlsx]
    category: productivity
    related_skills: [xlsx]
---

# OEE SEMI monthly append

Append a new month's production into the prior month's adjusted OEE template and produce `2026-<month>(SA1) NB OEE Template-Auto Travelling Head Cut.xlsx`.

## Always-on rules

1. **Stood-a-here full pipeline**, in this order: (A) append sheet 1 production rows, one per (Date, Shift, Machine, Model, Component) group, shift-3 merged into shift 2; (B) append sheet 5 Standard CT entries for new (Model, Component) combos; (C) append sheet 2 Input downtime rows, one per Date, Shift, Machine, formula-templated from a champion row; (D) OEE boost to ~72% (delete low-output machine-shifts, reassign their production to the same Date+Shift, greedy lowest-projected-OEE); (E) cap every machine-shift AW <= 100%; (F) raise every AY row < 52% up to >= 52%; (G) re-randomize changeover C1/C2/C3 and T1-T5/T9 to whole-number ranges; (H) sort sheet 1 by Date -> Shift -> Machine (stable chained sort); then save.
2. **Filename only**: `2026-{02digit}(SA1) NB OEE Template-Auto Travelling Head Cut`; no suffix labels.
3. **Answer concisely and directly**: lead with the output file path + key verification cells; do not narrate steps, no filler, no restating the request.
4. **Rephrase the request with corrected grammar before acting**, every time.
5. **Prefer working artifacts** (files, rendered output) over prose descriptions; when something breaks, share the error log directly rather than reconstructing it.
6. **Never overwrite the source template**: write to a new derived path, then reload to verify zip integrity + key cells + formulas.

## When to Use

- Continuing an OEE SEMI monthly append: base = prior month's adjusted `2026-<prev>(SA1) NB OEE Template-Auto Travelling Head Cut.xlsx`; source = `SemiCut_All_YYYYMM01_YYYYMM31.xlsx`.

## Procedure

1. **Setup tools.** Confirm openpyxl + pandas in the Hermes venv; install via `python -m ensurepip --default-pip` then `pip install openpyxl pandas` if needed. Load the prior template with openpyxl (keep it closed in Excel first; openpyxl raises PermissionError otherwise).
2. **Inspect base.** Dump sheet 1 headers/data extent, the sheet 2 champion row formula template, sheet 5 headers. Note the existing last No in sheet 5.
3. **Production aggregation (sheet 1).** From the DB, aggregate (Date, Shift, Machine, Model, Component) = SUM QTY; merge shift-3 into shift 2 of the same (Date, Machine). Verify totals match the DB.
4. **Append sheet 1 rows.** After the last data row; copy formulas from the prior last row. H = SUM QTY (value); I = H+U; J = VLOOKUP to sheet 5; K/L/M derived (operating/availability/performance time); N-T defect columns (Q1/Q2/Q3/Q4/Q7 only); U = SUM(N:T).
5. **Append sheet 5 CT entries.** For new (Model, Component) combos, derive CT via family+component mode (most common historical CT for the same model family + component); fall back to component mode or an analogue model's mode. Continue the sequential No.
6. **Append sheet 2 downtime rows.** One per Date, Shift, Machine. E=8 (plan hours), F = 30 (shift 1/2) or 45 (shift 3), R = E - Q = 7.5; C1/C2/C3 whole 11-45, T1-T5/T9 whole 11-30 at ~3% incidence, O1-O4/T6-T8 empty. Extend CF on AW/AY.
7. **Recalc via Excel COM** (win32com, CalculateFullRebuild + CalculateFull) so cached values (defect sums, OEE) are stored.
8. **Adjustments (D-G):** run the boost/AW-cap/AY>=52% optimization per references/adjustment-pipeline.md.
9. **Sort sheet 1** Date -> Shift -> Machine (stable chained sort, least significant first).
10. **Verify:** 0 error cells, sheet 1/2 totals match DB, 0 "No Matching", OEE ~72%, all AW <= 100%, all AY >= 52%, all losses whole >= 11, old Jan-Jun rows untouched.

## Pitfalls

- **Openpyxl does not calculate.** Always recalc via Excel COM after editing; reload with data_only=True only to inspect, never save a data_only=True load (it discards formulas).
- **Large .xlsx loads slowly in the Hermes terminal.** Loading a 3+ MB OEE template (sheet 1 = ~12 000 rows, sheet 2 = ~8 MB XML) can time out at 180 s even for a tiny query. Use `zipfile` + `re` to parse the sheet XML directly (fast, no openpyxl load), or load only the sheets you need and keep the process short. Read-only XML parse + targeted openpyxl cell reads is the pattern for verification.
- **Continue a task only after verifying current state.** A prior session may have built a partial file that is not consistent with the source data. Check totals, row counts, and key cells before assuming the append is done; a total that matches the source DB is the strongest single completeness signal.
- **openpyxl strips charts.** Do not round-trip a charted workbook through openpyxl for edits that touch charts; use Excel COM row/column edits only where a saved grid would corrupt.
- **Excel COM row deletion rewrites absolute-row formulas and produces #REF!.** Never use Excel COM Rows.Delete() on formula rows; rebuild the block programmatically instead (openpyxl rewrites + Excel COM recalc).
- **CT is keyed by Model+Component only** (VLOOKUP on E&F of sheet 5), so a production row moved between machines keeps its exact CT.
- **Shift-3 production is merged into shift 2** of the same (Date, Machine) before both sheet 1 and sheet 2 are built; sheet 2 therefore has no shift-3 rows.
- **Changeover math cancels:** AY = AV*AW*AX = AR*AT/(R*AU) cancels the changeover term, so re-randomizing AC/AD/AE only raises AS and lowers AW; it does not change AY.
- **Keep the base template's stale errors** (sheet 3 col AS #DIV/0! for months 7+ missing from 6. Support data; sheet 4 chart-source #N/A) intact - they are pre-existing and not part of the append.

## References

- references/template-formula.md - champion-row formula templates for sheets 1/2/5.
- references/adjustment-pipeline.md - OEE boost / AW cap / AY>=52% method.
