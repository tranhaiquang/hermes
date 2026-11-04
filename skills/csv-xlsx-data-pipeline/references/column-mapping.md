# Column mapping: XLSX -> CSV

| XLSX column | CSV column | Notes |
|---|---|---|
| No. | id | New UUID per row |
| Machine Code | item_code | |
| Machine name | name_en | |
| Machine Name (detail) | section | |
| PM Date | due_date | Excel serial -> `YYYY-MM-DD` |
| Status | status | |
| Remarks | notes | |
| Không xóa | deleted | `Completed`/`Overdue` -> `true`, else `false` |
| (others) | empty | plant, pic, task_progress, task_validation, equipment, technician, created_at, updated_at, rescheduled |

## Excel serial dates

XLSX stores dates as serial numbers (days since 1899-12-31). Convert with:

```python
from datetime import date, timedelta
def excel_serial_to_date(serial):
    return (date(1899, 12, 31) + timedelta(days=int(serial))).isoformat()
```
