---
name: csv-xlsx-data-pipeline
description: "Merge CSV + XLSX data into a single output CSV."
version: 1.0.0
author: Nous Research
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [csv, xlsx, spreadsheet, data-pipeline, productivity]
    category: productivity
    related_skills: [xlsx, synthetic-record-generation]
---
# spreadsheet-data-pipeline

Merge and transform CSV + XLSX data sources into a single output CSV.

## When to Use

Use when the user asks to combine, filter, or re-shape data across a .csv and an .xlsx file:
- Reading an .xlsx and merging its data into a .csv data feed.
- Filtering out specific rows (e.g., plant/type filters).
- Mapping or renaming columns between two sources.

For generating NEW synthetic batches into an existing governed CSV corpus (rather than transforming real data), see `synthetic-record-generation`.

## Procedure

1. Read the source CSV with `csv.DictReader` (UTF-8, `newline=''`).
2. Filter rows as needed (e.g., drop PLANT D rows).
3. Read the source XLSX via `zipfile` + `xml.etree.ElementTree`:
   - Read `xl/sharedStrings.xml`; resolve each `<si>` index to clean text.
   - For each sheet row, extract the **column letter only** from each `m:c` cell reference (`A4` → `A`), resolve shared-string indices to text.
4. Map XLSX columns to CSV columns per `references/column-mapping.md`.
5. Write the result CSV with `csv.DictWriter` (UTF-8, `newline=''`, `lineterminator='\\r\\n'`).

## User preferences

- Answer concisely and directly: working artifacts first, no filler, no restating the request.
- Rephrase the user's request with corrected grammar before acting, every time.
- Prefer working artifacts (files, rendered output) over prose descriptions.
- When something breaks, share the error log directly rather than reconstructing it.

## Pitfalls

- **Run the transformation exactly once.** Re-running appends a duplicate block of rows; keep only rows 0..30 (the 31 pre-existing rows) and re-append from scratch, always verifying row counts before and after.
- **XLSX cell references include the row number** (`A4`, `B4`), not just the column letter — normalize keys to the letter group, otherwise lookups by bare column letter return `None`.
- **XLSX dates are Excel serials** (days since 1899-12-31), not ISO dates — convert with `datetime.date(1899,12,31) + datetime.timedelta(days=n)`.
- **Empty cells stay empty** — a missing `PM Date` serial maps to an empty `due_date`, not an exception.
- **Large workbooks (>50MB): use `openpyxl` with `read_only=True`.** The `zipfile` + XML approach times out on 75MB files with 1M+ rows. `openpyxl.read_only` streams rows without loading the full sheet into memory.

## References

- `references/column-mapping.md` — Decision table for machine-data xlsx → CSV column mapping.
- `references/qco-changeover-mapping.md` — Column mapping and extraction rules for QCO changeover tracking workbooks (`#11. QCO Data` sheet).
