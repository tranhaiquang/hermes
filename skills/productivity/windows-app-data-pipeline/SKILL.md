---
name: windows-app-data-pipeline
description: Wire a legacy Windows app to PBI via scheduled file sync.
version: 1.0.0
author: Hermes Agent
license: MIT
category: productivity
metadata:
  hermes:
    tags: [windows, powerbi, etl, scheduled-task, vb6, legacy]
---

# windows-app-data-pipeline

Wire a legacy Windows desktop app (VB6, VB.NET, Win32) to Power BI or other
BI tools when direct DB access is not viable. Build a daily file-sync pipeline
that copies the app's output files (Excel, CSV) into a watched folder, then
optionally transforms and appends rows into a master source file.

## When to Use

- The app is a deployed runtime folder (EXE + OCX/DLL + Excel templates),
  not a source repository.
- You need daily refreshed data in PBI but Power BI Desktop is not installed,
  or the app's Oracle/SQL Server connection is not reachable from the PBI
  service.
- The user already has an existing PBIX that sources from a local file path
  (CSV/Excel).
- You need to schedule the pipeline with Windows Task Scheduler.

## Procedure

1. **Explore the app folder** — list the top-level dirs, find the launcher
   EXE (often in `DOWNLOAD.INI` as `SHELL=`), and identify data output
   folders (`ExcelDown/`, `EXCELFORM/`, `Download/`). These contain the
   `.xls`/`.xlsx`/`.csv` reports the app generates.
2. **Check for existing scripts** — look for `.ps1`, `.py`, `.bat` in the
   sa2/project folder that already transform or append data. Reuse them;
   do not rewrite logic from scratch.
3. **Choose the integration shape** — either broad sync or targeted extraction:
   - **Broad sync**: copy all app outputs to a watched folder. Use when
     multiple reports feed the PBIX.
   - **Targeted extraction**: write a focused extractor for a single report
     (e.g. `TMU2150` real-time monitor). Use when only one report is needed.
     The extractor reads the latest file from `Downloads`, parses it, and
     writes a clean CSV to `Desktop\\sa2\\MES_Data\\`. See
     `references/tmu2150-extraction.md`.
4. **Build the extractor/sync script** — write a Python script that:
   - For targeted extraction: locates the latest file by regex/date in
     `Downloads`, parses with `pandas.read_excel(engine='xlrd')` for `.xls`,
     filters to data rows, coerces numerics, adds audit columns, writes CSV.
   - For broad sync: walks app output folders with `pathlib.Path.rglob('*')`,
     filters by extension, copies to the PBI-watched folder, uses size
     comparison for idempotency, logs to the app folder.
5. **Test the script** — run it directly. Confirm the output file appears and
   contains the expected row count. A second run should skip unchanged files
   or re-extract cleanly.
6. **Build the PowerShell pipeline** — write a `.ps1` that runs the Python
   script. Use `param()` with `[switch]` flags so steps can be skipped
   independently.
7. **Schedule it** — write a one-time `schedule_pipeline.ps1` that registers
   a Windows Scheduled Task via `New-ScheduledTaskAction` +
   `New-ScheduledTaskTrigger`. Run it once as Administrator. The task runs
   `powershell.exe` with `-ExecutionPolicy Bypass -File` daily at a
   business-appropriate hour (e.g. 06:00).
8. **Wire PBI to the destination** — in Power BI Desktop, set the source of
   the master CSV/Excel to the watched folder path. If the PBIX already
   sources from `BTS_data.csv` in `sa2\\`, update that file in place.

## Always-on rules

- **Reuse existing transform scripts** — if the user has `generate_rows.py`
  or `append.ps1`, call them from the pipeline instead of duplicating their
  logic.
- **Idempotent sync** — the copy step must be safe to run repeatedly without
  duplicating data or overwriting unchanged files unnecessarily.
- **Write scripts to disk, do not inline complex Python** — in MSYS bash,
  `python -c` with quotes, parens, or backslashes frequently fails due to
  shell quoting rules. Write a `.py` file with `write_file`, then execute
  it with `python <path>`.
- **Use forward-slash native paths for Python file operations** — Python's
  `zipfile`, `os`, and `open` accept `C:/MES/...` or `C:\\MES\\...` but
  bash/MSYS path translation can mangle backslashes in arguments. Pass
  forward-slash paths to Python.
- **Log to the app folder, not the project folder** — the sync log belongs
  with the MES data (e.g. `C:\\MES\\sync_to_pbi.log`) so it is easy to find
  when troubleshooting the machine.
- **Verify the Python interpreter has required packages before relying on
  it** — on Windows with Hermes, `python` may resolve to a bundled
  interpreter without `pandas`/`xlrd`. Probe with `python -c "import pandas, xlrd"` and fall back to a known-good interpreter (e.g.
  `C:/Users/<user>/AppData/Local/Microsoft/WindowsApps/python.exe`) when
  the default lacks data-science packages.

## Pitfalls

- **MSYS quoting destroys complex `python -c`** — single quotes, double
  quotes, parens, and backslashes interact unpredictably in MSYS bash.
  Always write a `.py` file and run it as `python path/to/script.py`.
- **PowerShell `param()` must be at the top** — any blank line or comment
  before `param()` causes a parse error. If the script is dot-sourced (`.\`),
  `param()` also fails; run it by path instead.
- **Scheduled Task needs highest privileges** — set `-RunLevel Highest` in
  `New-ScheduledTaskPrincipal` or the task will silently fail on locked
  workstations.
- **PowerShell exit codes mask Python failures** — `& python ...` in
  PowerShell does not propagate the Python exit code when `$ErrorActionPreference`
  is `Stop`. Check `$LASTEXITCODE` after each Python call, or set
  `$ErrorActionPreference = 'Continue'`.
- **Do not assume the app has source code** — legacy VB6 deploy folders
  contain EXE, OCX, DLL, and Excel templates, not `.bas`/`.frm`/`.vbp`.
  Treat them as black-box output generators.
- **Oracle tnsnames is not the integration path** — the app may have an
  Oracle client and `tnsnames.ora`, but do not try to reverse-engineer
  credentials or replicate its DB connection unless the user explicitly asks
  for direct DB access. File sync is safer and easier.
- **PBI Desktop absence blocks PBIX modification** — if Power BI Desktop is
  not installed, do not attempt to build or decorate `.pbix` programmatically.
  Use a file-based CSV/Excel source that the user can refresh when PBI
  Desktop is available.
- **`python -c` heredoc is also fragile** — even `python << 'PYEOF'` can
  fail depending on MSYS version. The reliable path is `write_file` then
  `terminal(command="python <path>")`.
- **Existing script paths are hardcoded** — the user's `generate_rows.py`
  may expect files in `C:\Users\LEAN15\Downloads\`. Do not move or
  rename those files without updating the script. Either bridge the files
  into Downloads before running it, or patch the script to read from the
  sync destination.

- **Targeted extractors need a row filter for header junk** — some MES
  exports include style rows where `LINE` is NaN (e.g. W, GS, PS, TD, LM,
  U). Always filter `df['LINE'].notna()` before treating rows as data.
  Otherwise the parser ingests column headers as data rows.

## References

- `references/legacy-app-exploration.md` — How to inventory a deployed VB6
  app folder and identify data output locations.
- `references/powershell-scheduled-task.md` — Windows Scheduled Task
  registration patterns and common privilege pitfalls.
- `references/tmu2150-extraction.md` — Focused extraction pattern for VSMES
  TMU2150 real-time monitor reports: filename regex, row filtering, and
  CSV output schema.