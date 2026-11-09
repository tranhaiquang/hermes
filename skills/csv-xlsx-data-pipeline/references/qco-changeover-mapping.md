# QCO Changeover Column Mapping: XLSX -> CSV

Applies to the `#11. QCO Data` sheet in QCO Changeover tracking workbooks:
- **HF MC** (`HF MC _Change over , 2026 - Daily Tracking Form Planned-Unplanned CO update 2026.xlsx`)
- **ATOM** (`ATOM_Change over , 2026 - Daily Tracking Form Planned-Unplanned CO update  11.2026.xlsx`)
- **SEMI** (`Semi_Change over , 2026 - Daily Tracking Form Planned-Unplanned CO update  11.2026 -_appended_corrected_fixed2.xlsx`)

All three workbooks share identical sheet structure and column layout.

| XLSX column | CSV column | Notes |
|---|---|---|
| A | Month | Month label (e.g., AUG, SEP) |
| B | Date | Excel serial -> ISO `YYYY-MM-DDT00:00:00` |
| C | Line # | Production line (e.g., HF 13.1); may be None/empty in SEMI |
| D | 1st Model | First model in changeover |
| E | 2nd Model | Second model in changeover |
| F | Upper Type | (from header row 4) |
| G | Sole Type | (from header row 4) |
| H | Plan_Unplan | `Planned` or `Unplanned` |
| I | Reasons | Unplanned reason text |
| J | Start | Excel serial (fraction of day) |
| O | COT | Change Over Time (minutes) — maps to CSV `COT` and `Labor cost` |
| P | COPT | Change Over Process Time (minutes) — maps to CSV `COPT` |
| Q | LC | Learning Curve (days) — maps to CSV `LC` |
| R | PPH Loss impact | Pairs per Hour loss — maps to CSV `PPH Loss impact` |
| X | Labor cost | Maps to CSV `Labor cost` (same as COT) |
| Y | FOB loss | Maps to CSV `FOB loss` |
| Z | OH | Overhead — maps to CSV `OH` |
| AA | Total | Total loss — maps to CSV `Total` |

## Date conversion

Column B contains Excel serial dates (days since 1899-12-30). Column J, Start contains fractional day serials.

```python
from datetime import datetime, timedelta
def excel_serial_to_iso(serial):
    base = datetime(1899, 12, 30)
    return (base + timedelta(days=float(serial))).strftime('%Y-%m-%dT%H:%M:%S')
```

## Column reference extraction

XLSX cell references include column + row (e.g., `AA7`, `AB12`). Extract the column letter group with regex:

```python
import re
col_match = re.match(r'^([A-Z]+)', cell_ref)
col = col_match.group(1) if col_match else cell_ref[0]
```

## Process assignment

The Excel definitions sheet (`#11. QCO Definition`) defines COT, COPT, LC for "Stitching Process area". Assign `Process` based on workbook source:
- HF workbook → `STITCHING`
- ATOM workbook → `ATOM`
- SEMI workbook → `SEMI`

## Header rows

The `#11. QCO Data` sheet has 6 header rows before data starts at row 7. Skip rows 1-6.

## Large file handling

For workbooks >50MB (ATOM ~75MB, SEMI ~75MB with 1M+ rows), `openpyxl` with `read_only=True` is significantly faster than `zipfile` + XML parsing:

```python
import openpyxl
wb = openpyxl.load_workbook(path, data_only=True, read_only=True)
ws = wb['#11. QCO Data']
for row in ws.iter_rows(min_row=7, values_only=True):
    # process row
```

## Verification

- After appending, verify row count: original rows + new rows = expected total
- Check date range: new data should continue chronologically from existing CSV end
- Confirm `Total` column (AA) is populated for all new rows
- SEMI workbook: Line # (col C) may be None; do not skip rows based on this