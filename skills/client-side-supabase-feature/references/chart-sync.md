# Chart.js in filtered pages

## Setup

1. Add the CDN script in the page `<head>` after lucide:
   `https://cdn.jsdelivr.net/npm/chart.js@4.4.7/dist/chart.umd.min.js`
2. Add a `<canvas>` in a new `<section>` before or after existing panels.
3. Add CSS for the new section matching the app's panel conventions.

## Render pattern

```js
const renderMyChart = (records) => {
  const canvas = document.getElementById("myCanvas");
  if (!canvas || typeof window.Chart === "undefined") return;
  const ctx = canvas.getContext("2d");

  if (window.myChartInstance) {
    window.myChartInstance.destroy();
    window.myChartInstance = null;
  }

  window.myChartInstance = new window.Chart(ctx, { /* config */ });
};
```

## Hook points

Call `renderMyChart` from:
- The main tab/render function after data loads.
- The filter-change handler (pass `getVisibleRecords()`).
- The `samho:langchange` listener (pass `getVisibleRecords()`).

This keeps the chart consistent with the table, calendar, and stats cards.

## Labels

Build month labels with the page's existing i18n keys, e.g. `` `${t(`pm.month.${MONTH_KEYS[idx]}`)} ${y}` ``. Do not hardcode month names in the chart renderer.

## Calendar-driven charts: year cache

If the chart is tied to a calendar navigator, pre-fetch the full year's records once and cache them by year. Add a `loadYearRecords()` helper that queries `YYYY-01-01` → `YYYY-12-31`, stores results in a module-scoped cache, and returns the cached array when the year hasn't changed. Pass the cache to the chart renderer so ◀/▶ navigation updates the chart immediately without extra network calls.

## Design-token matching

Charts must use the app's existing design tokens, not Chart.js defaults:
- Font family: match the app's primary font (e.g. `Be Vietnam Pro`).
- Colors: reuse the app's semantic colors (completed = `#16a34a`, pending = `#f6ba12`, etc.).
- Grid lines: use the app's subtle line color (e.g. `#e7edf6`).
- Bar radius: match nearby UI (e.g. `4px`).
- Tooltip bg: use the app's dark ink color (e.g. `#172538`).

Hardcoding Chart.js defaults makes the chart look imported and breaks visual consistency.

## Click-based detail cards (replaces hover)

When a chart bar/cluster needs to open a detail view with multiple charts, use click, not hover:

1. Attach a `click` handler to the container; find the target via `event.target.closest('.cluster')` and read `dataset.plant`/`dataset.label`.
2. Toggle: if the card is already open for the same key, close it. Otherwise populate and show.
3. Close on: clicking outside the card, pressing Escape, window resize, or a close button inside the card header.
4. The card must have `pointer-events: auto` (not `none`) so the close button is clickable, and `cursor: pointer` on the clickable chart elements.
5. When the card shows multiple related charts (e.g. downtime + MTBF + MTTR), build a generic line-chart renderer that accepts `(points, year, valueKey, color)` so each chart reuses the same SVG builder with a different data key and color.

Hover cards that disappear on mouseleave cannot host interactive content — always use click for multi-chart detail popups.
