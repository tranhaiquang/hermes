# TMU2150 Real-Time Monitor Extraction

VSMES REALTIME MONITOR exports to `Downloads` with a predictable filename
pattern. A focused extractor is preferable to broad sync when only this
report feeds Power BI.

## Source file pattern

| Component | Value |
|---|---|
| Base name | `ASS PROD(DETAIL STATUS)` |
| Form code | `frmTMU2150_05` (sometimes suffixed with digits) |
| Date stamp | `(YYYY-MM-DD)` in parentheses at end of filename |
| Extension | `.xls` (xlrd engine) |
| Example | `ASS PROD(DETAIL STATUS)[frmTMU2150_05] (2026-10-24).xls` |

## Regex for latest-file discovery

```python
pattern = re.compile(r'frmTMU2150[_\d].*?\((\d{4}-\d{2}-\d{2})\)', re.IGNORECASE)
```

Extract the embedded date, sort candidates descending, and take the first.
If no embedded date is found, fall back to `file.stat().st_mtime`.

## Data shape

- **Header junk rows**: first ~6 rows have `LINE = NaN` and `M = W/GS/PS/TD/LM/U`.
  These are style/group headers, not production records.
- **Data rows**: `LINE` values like `P101`, `P102`, ..., `P6xx`.
- **Columns**: `LINE`, `MODEL`, `STYLE`, `PO NUM`, `ORD #`, `CXFD`, `QTY`, `M`,
  then size breakdowns `01M`..`22M` and `01T`..`22T`.
- **CXFD**: plan/delivery date (YYYY-MM-DD).

## Row filter rule

Always filter with `df = df[df['LINE'].notna()].copy()` before any other
processing. Do not rely on `skiprows` in `pd.read_excel` because the number
of header rows can vary between files.

## Numeric coercion

`ORD #`, `QTY`, and every `\d{2}[MT]` column should be coerced to numeric:

```python
num_cols = ['ORD #', 'QTY'] + [c for c in df.columns if re.match(r'^\d{2}[MT]$', c)]
for col in num_cols:
    df[col] = pd.to_numeric(df[col], errors='coerce')
```

## Audit columns to add

| Column | Source | Purpose |
|---|---|---|
| `snapshot_date` | Embedded date from filename | Which production day the report covers |
| `source_file` | `filepath.name` | Traceability to original export |
| `extracted_at` | `datetime.now().isoformat()` | ETL pipeline timestamp |

## Output

Write to `Desktop\sa2\MES_Data\TMU2150_latest.csv` with
`index=False, encoding='utf-8-sig'` so Excel and Power BI read it cleanly.

## Interpreter

This extractor needs `pandas` and `xlrd`. On Windows with Hermes, `python`
may point to a bundled interpreter without those packages. Use the
interpreter at `C:/Users/<user>/AppData/Local/Microsoft/WindowsApps/python.exe`
or probe first with `python -c "import pandas, xlrd"`.
