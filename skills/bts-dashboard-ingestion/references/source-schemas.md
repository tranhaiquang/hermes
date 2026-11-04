# Plan File Schema

Plan workbooks (Book1.xlsx, Book2.xlsx, Book3.xlsx, Plant A/B/F.xlsx, and
duplicate-download copies like `A (1).xlsx`) share one layout. Older exports
have a header in row 0; newer exports have one sheet per day (named by day
number) with row 0 already data — read only the sheet named for TARGET:

- Column 0: line code in P-form (`P101`, `P201`, `P601`).
- Column 1: order number (numeric; matches `ORD #` in the actuals file).
- Column 2: PO number (may be integer or string; this is the match key).
- Column 3: style / model code (e.g. `M8801D-5HV`; matches STYLE in the actuals).
- Column 4: destination / vendor (often `NB-United State`, `NB-Canada`, etc.).
- Column 5: date as Excel serial integer (`20261023` = 2026-10-23).
- Column 6: total order quantity.
- Column 7: `SOLID` (no fixed plan date) or a date string.
- Columns 8-9: may hold descriptive text or numeric values; ignore.
- Column 10: literal `PLAN QTY`.
- Column 11: total planned quantity for this row.
- Columns 12+: size buckets, one column per size; in headerless day-sheets the
  first size column can be later than 12.

Size columns must be found dynamically: scan from column 12 to the row end,
skip blank cells and `PLAN QTY`, and map each column to a size through the
model-prefix shift table in the append script (`plant_col_to_size`). Do not rely
on a fixed column index or on header cells — day-sheets have no header row.

D-PLAN date handling:
- If column 7 is a 5-digit integer, it is an Excel serial (days since 1899-12-30).
- If it is an 8-digit integer, it is `YYYYMMDD`.
- If it is a 10-character string with hyphens, it is already ISO.
- If it is the literal `SOLID`, the order has no fixed plan date.
- Empty / None means no plan date.
