# Actual File Schema (ASS PROD actuals xls)

The actuals file (`ASS PROD(DETAIL STATUS)... (YYYY-MM-DD).xls`) is a legacy BIFF
workbook in one of two layouts:

- Older exports: a single sheet named `TMU`.
- Newer exports: one sheet per day, named by day number (`'26'`, `'27'`, ...);
  sheet N holds the status as of day N of the month. The filename date is the
  export date, not the data date — pick the sheet by TARGET day, never by filename.

The sheet layout below (legend rows 0-6, data from row 7) is identical in both.

## Legend rows 0-6
Rows 0 through 6 encode the size column mapping per model:

- Row 0 is the header row; column 7 holds `M` (the model legend key).
- Columns 8 onward hold size codes (`01M`, `03M`, `03T`, etc.).
- Rows 1-6 repeat the column layout for different model prefixes (`W`, `GS`, `PS`,
  `TD`, `LM`, `U`).

Build a dict: `model_prefix -> {column_index: size_code}`. When reading a data
row, look up the model prefix (column 7) and use that dict to translate column
indices to size codes.

## Data rows (row 7+)
- Column 0: line code (`P101`, `P201`, etc.)
- Column 2: style code
- Column 3: PO number (xlrd returns this as float if stored as numeric; strip `.0`)
- Column 5: commit date `CXFD` as string `YYYY-MM-DD`
- Column 6: total quantity
- Column 7: model prefix (`M`, `W`, `GS`, `PS`, `TD`, `LM`, `U`)
- Columns 8+: size quantities, interpreted via the legend

Only rows where column 0 is non-blank are data rows.
