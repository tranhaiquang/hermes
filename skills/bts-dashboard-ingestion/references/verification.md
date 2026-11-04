# Verification Checklist

After writing the new BTS_data.csv, run these checks before handing it off.

## 1. Mix rule compliance
```python
import pandas as pd

df = pd.read_csv('BTS_data.csv', dtype=str, keep_default_na=False)
oct23 = df[df['Date'] == '23-10-26']  # adjust date

mismatches = 0
for _, r in oct23.iterrows():
    pq, aq = int(r['PlanTotalprs']), int(r['ActualTotalprs'])
    po_match = r['PlanPO'] == r['ActualPO'] and r['PlanPO'] != ''
    expected = min(pq, aq) if po_match else 0
    if expected != int(r['Mix']):
        mismatches += 1
print('Mix mismatches:', mismatches)
```
Expect 0.

## 2. Aggregates
```python
print('Plan:', oct23['PlanTotalprs'].astype(int).sum())
print('Actual:', oct23['ActualTotalprs'].astype(int).sum())
print('Mix:', oct23['Mix'].astype(int).sum())
```
Plan ≥ Mix. Actual may be less than Plan.

## 3. File format
```bash
file BTS_data.csv    # expect: CSV Unicode text, UTF-8 (with BOM)
```

## 4. No orphaned rows
```python
print(oct23['Factory'].unique())   # should be ['VS'] for plan/actual rows
print(sorted(oct23['Line'].unique()))  # should be A01-A14, B01-B11, F01-F02
```

## 5. Header preservation
```python
with open('BTS_data.csv', 'rb') as f:
    first = f.read(200)
print(first)
```
Expect BOM (`EF BB BF`) and the full 12-column header, plus any trailing empty
columns that were in the original.

## 6. Data quality
```python
new = df[df['Date'] == '24-10-26']  # adjust date
for col in ['Factory', 'Line', 'PlanPO', 'PlanSize', 'PlanTotalprs']:
    print(col, 'empty:', (new[col] == '').sum())

keys = ['Date', 'Line', 'PlanPO', 'PlanSize']
print('dup keys:', new.duplicated(subset=keys, keep=False).sum())
```
Zero empties in critical fields. Duplicate keys within the new date are expected
when a PO is split across plan rows — compare the count against prior days' counts
instead of requiring zero.

## 7. Earlier dates untouched
Keep the pre-append CSV; after the append, every row whose date is not the target
must be identical and in the same order:
```python
old = pd.read_csv('BTS_data_before.csv', dtype=str, keep_default_na=False)
new = pd.read_csv('BTS_data.csv', dtype=str, keep_default_na=False)
t = '27-10-26'  # adjust date
assert old[old['Date'] != t].reset_index(drop=True).equals(
    new[new['Date'] != t].reset_index(drop=True))
```
