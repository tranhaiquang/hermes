---
name: xlsx-changeover-filling
description: Fill SEMI changeover workbook from production Excel data
version: 1.0.0
author: Nous Research
license: MIT
platforms: [windows, linux, macos]
metadata:
  hermes:
    tags: [excel, spreadsheet, xlsx, openpyxl, template-filling]
    category: productivity
    related_skills: [xlsx]
---

# Filling changeover plan templates from production data

This reference covers the specific pattern used to fill a SEMI changeover plan workbook (`Checklist_doi_ma_Atom (1).xlsx`) with production data from a source file (`SemiCut_All_20261001_20261030.xlsx`).

## Output convention

- Output filename: `<original>_decorated.pbix` (or for xlsx: `<template>_<machine>.xlsx`)
- Always write to a new derived file; never overwrite the source template.

## Source-to-template column mapping

| Production column | Template column | Notes |
|---|---|---|
| `SEQ` | `STT` | Sequence number |
| `DATETIME` | `Ngày` | Convert from `YYYYMMDDHHMMSS` string to `datetime` |
| `C_SHIFT` | `Ca` | Shift number |
| `A_MACHINE` | `Máy` | Machine serial number (text) |
| `MES_GROUP_SUM` | `Model cũ` / `Model mới` | Fill both model columns with the same value |
| `CYCLETIME` | `Phút KH` | Cycle time |
| `TOTAL_CYCLETIME` / `CYCLETIME` | `Phút thực tế` | Actual cycle time |
| `FULL_NAME` | `Người phụ trách` | Foreman name |
| `REMARK` | `Ghi chú` | Notes |

## Template structure notes

- Template file `Checklist_doi_ma_Atom (1).xlsx` has sheets: `Kế hoach chuyen doi`, `Sơ đồ quy trình`, `Checklist`, `Các bước đổi mã`, `Danh mục`.
- The `Kế hoach chuyen doi` sheet has:
  - Row 1: Title (merged A1:P1)
  - Row 2: Subtitle (merged A2:P2)
  - Row 3: Week info (merged B3:D3)
  - Row 5: Header row
  - Rows 6–18: 13 sample data rows
  - Rows 37–43: Summary rows (some merged cells in columns I–L)

## When to Use

Use this skill when the user needs to fill a SEMI changeover plan workbook (`Checklist_doi_ma_Atom (1).xlsx`) with production data from a source Excel file (`SemiCut_All_<date>.xlsx`). The task requires:
- Mapping production columns (SEQ, DATETIME, C_SHIFT, A_MACHINE, MES_GROUP_SUM, CYCLETIME, etc.) to template columns (STT, Ngày, Ca, Máy, Model cũ, Model mới, Phút KH, etc.).
- Preserving template formulas, merged cells, styles, and dropdown lists.
- Outputting to a new file with the convention `<template>_decorated.pbix` (or `<template>_<machine>.xlsx`).

## Fill procedure

1. **Read the template** with `openpyxl.load_workbook(path, data_only=False)` — keep formulas intact.
2. **Read the production data** with `openpyxl.load_workbook(path, data_only=True)`.
3. **Build a mapping** from production columns to template columns.
4. **Clear sample data rows** (typically rows 6–18) — but check each cell first:
   - Before writing, check `isinstance(cell, openpyxl.cell.cell.MergedCell)`. If `True`, skip writing to that cell (its value cannot be changed via `ws.cell(r, c).value = ...`).
   - Also check if the cell coordinate is in any merged range: `cell.coordinate in [str(mc) for mc in ws.merged_cells.ranges]`.
5. **Write data rows** starting from the first data row (row 6 in the template).
6. **Set summary values** in the summary rows. Check `isinstance(cell, openpyxl.cell.cell.MergedCell)` before setting summary values.
7. **Apply formatting** (yellow fill on input cells, etc.).
8. **Verify** before reporting: reload the output, check zip integrity, confirm key cells hold reference values, and confirm formulas are still present.

## Common pitfalls

- **Merged cells are read-only**: `ws.cell(r, c).value = ...` raises `AttributeError: 'MergedCell' object attribute 'value' is read-only'`. Always check for merged cells before writing.
- **Sheet names with Vietnamese diacritics**: the sheet name is `Kế hoach chuyen doi` (not `Kế Hoạch Chuyển Đổi`). Use exact string matching when loading.
- **Preserve formulas**: the template has formulas in columns N (chênh lệch) and O (kết quả). Write formulas only for the first few rows, or the file may lose them.
- **Data validations are stripped**: openpyxl does not support preserving data validations on load/save (it prints a warning). Accept this limitation.
- **Summary rows**: the template has summary rows at rows 37–43 with merged cells in columns I–L. Write summary values only to the top-left cell (column I) of each merged range.
- **Runtime warning**: openpyxl prints a warning about unsupported data validations. This is benign and does not affect the output file.
