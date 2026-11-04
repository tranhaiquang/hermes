# PM reschedule flow

## Data model

`pm_records.rescheduled` is a boolean column. It is append-only: once `true`, it stays `true`.

## Triggering the flag

The edit path (`editPM`) already sets the flag when the due date changes:
```js
if (dueDate !== rec.dueDate) payload[col("rescheduled", "rescheduled")] = true;
```

No separate reschedule API is needed.

## UI pattern

1. Add a Reschedule button (icon: `calendar-clock`) in the schedule table's action cell.
2. Show it only for PID users (same gate as Edit/Delete).
3. Wire its click handler to `openEditModal(id)` so it reuses the existing edit form and update flow.
4. Place it before Delete and after Edit in the action cell.

## Status precedence

Display status follows this order: `validated` > `completed` > `overdue` > `rescheduled` > `pending`. The `rescheduled` overlay only shows when the record is not already completed or validated.
