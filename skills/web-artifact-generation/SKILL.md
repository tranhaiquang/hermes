---
name: web-artifact-generation
description: Produce a working HTML data-viz chart with verification.
category: creative
version: 0.1.0
author: LEAN15
license: MIT
metadata:
  hermes:
    tags: [data-viz, chart, html, canvas, verification]
    related_skills: []
---

# web-artifact-generation

Produce a working, verifiable HTML/Canvas visualization artifact (line or bar chart) for a web page: fetch web data, convert units at the source, draw with plain Canvas 2D, verify the artifact actually renders, and deliver it as a file plus an inline preview.

## When to Use

Use this skill whenever the user asks for a data-driven chart, dashboard, or comparison graphic and wants a single working, verifiable HTML/Canvas artifact (line, bar, or dashboard) with data converted and units stated, rather than prose describing one. Use the plan-and-verify flow below for any such request; the steps apply to one-off HTML/Canvas files, dashboards, and PNG/HTML previews alike.

## Always-on rules
- Deliver working artifacts, not descriptions. The final result is a file path + confirm the render shows lines/bars and labels; never a prose-only summary.
- Keep final answers concise and direct; no process narration.
- Verify every chart before calling it done. After rendering, confirm the canvas frame and data layer with a real pixel/DOM check. If a chart is blank everywhere, re-dispatch to a plain Canvas redraw with no external library; never ship a chart declared complete without that check.
- State the basis of every unit conversion (rate + date/time) next to the converted numbers. Do not silently substitute a different exchange basis.

## Procedure
1. Identify the deliverable: file path/format and which series + units the user wants. Confirm once, don't guess.
2. Fetch the underlying data. If the primary endpoint is bot-gated or behind a paywall, pull what you can from search results and label each number with source + date.
3. Convert units at the source. State the rate and the time basis. Record the converted series (not a sentence about conversion).
4. Build the artifact: a single self-contained HTML file. Draw with plain Canvas 2D + inline script (no external visualization CDN). Keep labels in the user's language. Give the canvas an explicit pixel size via CSS + width/height attributes so it renders under any redraw.
5. Verify: open the artifact and confirm the canvas frame and data layer with a real pixel/DOM check; take a screenshot and look at it. If blank, re-dispatch to a plain redraw — never declare complete without it.
6. Render inline with the `::preview{file="..."}` directive on its own line, then confirm the widget shows the line/bars and labels. (This render step may not fire in every chat; deliver the file path alongside.)
7. Deliver: the file path + a short confirmation (units, date range, source, correct units and basis).

## Pitfalls
- **Sweep ids after removing markup.** If a `<canvas>`/`<div id>` is removed, every JS reference to that id stays and an init() pass throws on null. Always re-check every id the script touches after editing the markup.
- **Golden rule of verification:** blank is the only hard failure. Build for the "draw something" case with plain Canvas first; add polish after. A feature-loaded chart that never paints is still wrong.
- **Never convert units silently.** Show the rate and time basis with the numbers. A chart with a broken unit basis looks right and is worse than no chart.

## Support files
- `references/data-sources.md` — topical fuel-price and FX sources used when the direct API is bot-gated.
