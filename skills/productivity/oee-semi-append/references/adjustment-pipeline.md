OEE boost, AW cap, and AY>=52% adjustment method (per month's AGENTS.md).

## OEE boost (~72%)
1. Rank the month's machine-shifts by good-time (SUMIFS K, or AR) ascending;
   delete the lowest-output rows so the month's aggregate OEE reaches ~72%,
   capped per (Date, Shift) so no shift's SUMAR/SUMR exceeds 0.95.
2. Reassign the deleted shifts' production rows to receiver machines on the
   same Date & Shift, greedy-assigning each row to the receiver whose
   projected OEE (=(SUMI*CT)(SUMH/SUMI)/R) would be lowest.
3. Rebuild the sheet-2 block programmatically (never Excel COM Rows.Delete())
   and recalc via Excel COM. CT is unchanged (keyed by Model+Component).
4. Result: weighted OEE ~0.72; output preserved; 0 orphan rows.

## AW cap (performance <= 100%)
Per (Date, Shift): best-fit-decreasing repack of production chunks (col K,
which the AR formula sums via SUMIFS on K) into machine capacities at
floor losses (every filled loss cell >= 11 min), preferring home machine;
zero overflow. Trim losses on overloaded machines exactly enough so AS >= AR
(losses kept whole, >= 11). 0 rows > 100%; 0 orphan rows.

## AY >= 52%
1. Identify rows with AY < 52% (AY = AR*AT/(R*AU) collapses; the only lever
   is reassigning production chunks, since CT is Model+Component-keyed).
2. Greedy planner: fill the lowest-AY row first using the smallest chunk
   from the highest-AY same-Date donor that keeps the donor >= 52% and
   AW <= 100%. Run a clean per-block pass with a reuse guard.
3. Result: 0 rows < 52%; all AW <= 100% preserved.

## Changeover adjustment
- C1/C2/C3 (AC/AD/AE): random whole integers in requested ranges
  (per month, e.g. 3-10 / 5-10 / 8-12).
- Technical losses T1-T5/T9 (AG/AH/AI/AJ/AK/AO): non-empty rows whole
  integers 11-30.
- AY is unchanged (the changeover term cancels in AY =
  AR*AT/(R*AU)).