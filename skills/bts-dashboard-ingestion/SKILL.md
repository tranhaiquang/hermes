---
name: bts-dashboard-ingestion
description: Ingest plan/actual Excel into BTS dashboard CSV.
version: 1.0.0
author: Hermes
license: MIT
---

# BTS Dashboard Data Ingestion

## When to Use
When the user asks to append, update, or rebuild BTS_data.csv from plan workbooks
(Book*.xlsx / Plant*.xlsx / A.xlsx, B.xlsx, F.xlsx — duplicate-download names like
`A (1).xlsx` are the same workbooks) and the ASS PROD actuals xls.

## Procedure
1. Inspect source files to confirm schema, sheet layout, and date coverage —
   see `references/source-schemas.md` and `references/actual-file-schema.md`.
2. Choose `TARGET` from the data, not the actuals filename: plan sheet names and
   actuals sheet names are day numbers, and an export dated D can serve a target
   earlier than D.
3. Copy the most recent date-specific script in `build/` (e.g. `append_bts_24oct.py`)
   rather than the original `append_bts_22oct.py`; it carries the latest fixes.
4. Edit these fields in the new script:
   - `PLANT_FILES` — list of plan workbook filenames
   - `ACTUAL_FILE` — full path to the actuals xls
   - `DL` — directory containing the source files
   - `TARGET` — ISO date, e.g. `2026-10-27`
   - `TARGET_DDMMYY` — same date in `dd-MM-yy`, e.g. `27-10-26`
   - `PLAN_SHEET` / `ACTUAL_SHEET` — the day-numbered sheet matching TARGET
     (older single-sheet exports: first sheet / `TMU`)
   - `OUT_CSV` — output path (keep in `dist/data/`)
5. Run the script from the `build/` directory with the system Python launcher —
   the Hermes venv `python` has no pip. One-time setup, then run:
   `py -3 -m pip install xlrd openpyxl`, then `py -3 append_bts_XXoct.py`
6. The script writes a new CSV; copy it over `dist/data/BTS_data.csv`.
7. Verify per `references/verification.md`: 0 Mix mismatches for the new date,
   correct aggregates, earlier-date rows byte-identical to the input CSV.

## Always-On Rules
- Mix rule: `Mix = MIN(Plan, Actual) if PlanPO == ActualPO else 0`
- BTS: `BTS = Volume * Mix / 100`, Volume is always 100
- Line codes: canonicalize to padded form (P101 → A01, P201 → B01, P601 → F01/F02)
- Date output: dd-MM-yy, matching the existing file's serialisation
- CSV format: UTF-8 with BOM, CRLF line endings, exactly 12 columns (no trailing empties)
- Never modify BTS_data.csv in place; write to a new file then copy

## Pitfalls
- Plan workbooks may carry one sheet per day (named by day number) with no header
  row. Read only the sheet named for TARGET — scanning every sheet duplicates
  orders that appear in several day-sheets.
- Plan size columns are dynamic and may start later than column 12. Scan from
  column 12 to the row end, skip blanks and the literal `PLAN QTY`, and map each
  column to a size via the model-prefix shift table — never a fixed index.
- Actuals exports come in two layouts: older ones have a single sheet `TMU`;
  newer ones have one sheet per day named by day number (`'26'`, `'27'`, ...),
  sheet N = status as of day N. Detect the layout, then read the sheet matching
  TARGET.
- Actual xls size mapping depends on the legend in rows 0-6 (model → column → size).
  Read the legend before parsing data rows.
- `xlrd` returns numeric cells as floats; PO numbers stored as integers come back as
  `7889057.0` and must be stripped to `7889057` before matching.
- Days 01-12 in dd-MM-yy are ambiguous with MM-dd-yy; the file is consistent but parsers
  need explicit format hints.
- The `DL` path must point to the directory holding the source files; it varies by session
  (`Downloads`, `AppData\Local\hermes\attachments`, etc.). Wrong path = file-not-found.
