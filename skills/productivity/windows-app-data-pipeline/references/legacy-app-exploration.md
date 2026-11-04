# Legacy App Folder Exploration

A deployed legacy Windows desktop app (VB6, VB.NET, Win32) is a runtime
folder, not a source repo. It contains an EXE launcher, OCX/DLL runtime
dependencies, Excel templates, and generated report files.

## What to look for

| File / folder | What it tells you |
|---|---|
| `DOWNLOAD.INI` | `SHELL=` is the launcher EXE path; `SYSTEM=` is the module code. |
| `*.exe` | The app modules (e.g. `SharpTmu.exe`, `SharpAss.exe`). |
| `OCX` / `DLL` | VB6 runtime dependencies (`COMDLG32.OCX`, `RICHTX32.OCX`). |
| `ExcelDown/`, `EXCELFORM/` | Daily generated reports (`.xls`/`.xlsx`). |
| `COMMON/`, `SOUND/` | Shared assets (WAV, AVI, fonts, images). |
| `sqlnet.log` | Oracle SQL*Net client version and connection errors. |
| `BootLog/*.TXT` | Boot timestamps; confirms the app is still running. |
| `ErrLog/*.txt` | Scan/error records; shows data fields and formats. |
| `MesVersion.ver` | Simple version marker; not useful for integration. |
| `Language.ini` | Locale (`LANG=KR` for Korean, Vietnamese audio cues). |

## Data output discovery

1. Read `DOWNLOAD.INI` to map module codes to launcher EXEs.
2. List files by extension under each module folder. The data files are
   almost always `.xls` / `.xlsx` (sometimes `.csv`).
3. Check `ExcelDown/` first — this is where the app saves downloaded reports.
   `EXCELFORM/` usually contains templates and static exports.
4. Do not treat the EXE or OCX files as data sources. They are black-box
   binaries.
5. Do not attempt to reverse-engineer credentials from `sqlnet.log` or
   `tnsnames.ora` unless the user explicitly asks for direct DB access.

## Naming conventions

Report files often embed the module code and a timestamp:
- `TRACKING OF PRODUCTION PROGRESS_(TMU3235)(20261022 091413)_NB.xls`
- `PO_PRODUCTION_PLAN_(TMU3678)_.xlsx`
- `ALL_SCAN_HISTORY.xlsx`
- `MTRL_Daily_Out_Analysis_Summary.xlsx`

The parenthetical module code (e.g. `TMU3235`) is a stable identifier even
when the timestamp changes daily.
