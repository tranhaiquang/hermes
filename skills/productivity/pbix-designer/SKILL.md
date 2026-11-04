---
name: pbix-designer
description: Decorate and modify Power BI .pbix report files.
version: 1.0.0
author: Hermes Agent
license: MIT
category: productivity
metadata:
  hermes:
    tags: [powerbi, pbix, report-design, visualization]
---

# pbix-designer

Decorate and modify Power BI `.pbix` report files — a binary ZIP archive containing JSON report definitions, themes, and visual containers. Produce a polished, cohesive redesign without breaking the report structure.

## When to Use

Use this skill when the user wants to improve the visual design of an existing Power BI report: add branding, custom color themes, decorative header bands, dividers, or enhance the visual polish of an existing dashboard without rebuilding the data model or visuals.

Use a file-based source (CSV/Excel folder) instead when:
- Power BI Desktop is not installed on the machine.
- The user needs daily refreshed data from an external system that cannot connect directly.
- The existing `.pbix` already sources from a local file path that can be updated in place.

## Procedure

1. **Extract the PBIX** — it is a ZIP archive. Unzip to a working folder.
2. **Inspect the report** — read `Report/definition/report.json` (theme, settings), `Report/definition/pages/pages.json` (page order), and `Report/definition/pages/<page_id>/page.json` (dimensions, display name).
3. **Read existing themes** — check `Report/StaticResources/SharedResources/BaseThemes/` for existing themes. Pick one as a base or create a custom one.
4. **Create / modify theme** — write a new theme JSON file (e.g., `LeanMetrics.json`) under the BaseThemes folder. Update `report.json`:
   - `themeCollection.baseTheme.name` → new theme name
   - `resourcePackages` → add an entry with the new theme as `BaseTheme`
5. **Enhance titles and add decorative elements** — modify existing visuals or adjust theme styling. **Do NOT add new visual container folders** (e.g., `visuals/hdr0/visual.json`): Power BI Desktop rejects `.pbix` files that contain new visual folders not originally present, even when ZIP structure and JSON are otherwise valid. Instead, reuse an existing visual folder by replacing its `visual.json` content, or adjust page-level styling through the theme.
6. **Validate all JSON and schema types** — every JSON file must parse. After any edit, grep all `visual.json` files for string-encoded booleans: `"show": "(true|false)"` inside `visualContainerObjects.title.properties.border.show` or `background.show`, and `"drillFilterOtherVisuals": "(true|false)"`. Convert any string booleans to native JSON booleans `true`/`false` before re-zipping.
7. **Re-zip preserving original entry order** — create a new `.pbix` (ZIP) with all original files plus modifications. Use Python `zipfile`, iterating over the **original zip's `infolist()`** and writing each member into the new archive so the central-directory entry order is unchanged. For new files, insert each one immediately after the last original entry that shares its parent directory path. Name it `<original>_decorated.pbix` (or new explicit name).
8. **Save output** — write to the same directory as the original.

## Always-on rules

- **Cohesive, professional result** — a cohesive color palette and consistent typography throughout, not random accents.
- **JSON must remain valid** — validate every file before creating the output.
- **Preserve all original files** — do not delete original binary files (DataModel, Connections, DiagramLayout, Metadata, SecurityBindings, etc.).
- **Save as a new file** — never overwrite the original `.pbix`.
- **Name the output clearly** — `<original>_decorated.pbix`.
- **Do not modify the BaseTheme registry unless explicitly requested** — adding new `BaseTheme` entries to `report.json` and the theme JSON file itself is risky. Prefer keeping the original theme unless the user explicitly asks for a new theme. This is the leading cause of `MashupValidationError` and "corrupted or was created by an unrecognized version" after decoration.

## Pitfalls

- **Do NOT add new visual container folders** — Power BI Desktop rejects `.pbix` files that contain new `visuals/<name>/visual.json` folders not originally present, even when ZIP structure and JSON are otherwise valid. Instead, modify existing visuals in place or adjust styling through the theme. This is the leading cause of "corrupted or was created by an unrecognized version" errors after decoration.
- **Single-line JSON files** — patch/write_file matching fails on single-line JSON. Use a Python script (via `execute_code` or `terminal`) to load → modify → dump JSON, or rewrite the whole file with `write_file`.
- **Visual container schema reference** — every visual.json must keep its `$schema` field. Modifying existing visual containers preserves the schema automatically.
- **Z-ordering** — header bands must have a lower `z` value than content visuals so they appear behind. Use `z: -100` or similar for background elements.
- **Header band background** — the theme's `visualStyles` controls card/chart backgrounds. A textbox background color also works but may need `background.solid.color`.
- **Do not invent new visual types** — only use existing visual types (textbox, card, columnChart, lineChart, tableEx, slicer, pageNavigator). Adding a shape/rectangle visual type is not supported in this schema version.
- **Pre-flight corruption check** — before editing, open the source `.pbix` with `zipfile` and confirm `namelist()` is readable and `[Content_Types].xml` is present. If the source itself is rejected by Power BI, fixes applied to it will still produce a rejected file; obtain an uncorrupted base first.
- **`drillFilterOtherVisuals` must be boolean** — when modifying existing visuals, set `drillFilterOtherVisuals` to a native JSON boolean `true` or `false`, not a string. Some existing visuals omit this field entirely; that is valid. Do not copy the string form from a bug-ridden source.
- **Re-zip preserves original entry order** — do not re-sort or glob the extracted folder back into a zip. Power BI validates the central-directory order; a different order causes "corrupted or unrecognized version" even when every file is present and valid. Iterate over the original zip's `infolist()` and copy entries one by one.
- **Shell glob `*` skips `[Content_Types].xml`** — in bash/MSYS, `*` does not match names beginning with `[`. A zip created with `zip -r .` or `zip -r *` will be missing this required entry.
- **String-encoded booleans in visual.json** — some decorator-generated files write `"show": "true"` or `"show": "false"` inside `visualContainerObjects.title.properties.border.show` or `background.show`. Power BI expects a native JSON boolean, not a string. After any edit, grep visual JSON for `"show": "(true|false)"` and convert to unquoted booleans before re-zipping.
- **Verify ZIP entry order before shipping** — after re-zipping, compare the new archive's `namelist()` against the original's. The original entries must appear in the same order; new entries may be appended. A mismatch is the leading cause of "corrupted or was created by an unrecognized version" errors after a cosmetic fix.
- **BaseTheme edits cause MashupValidationError** — adding new `BaseTheme` entries to `report.json` or the theme JSON file causes `MashupValidationError` on open in Power BI Desktop. Keep the original theme unless the user explicitly requests a theme change.

## References

- `references/pbix-structure.md` — PBIX file format structure reference
- `references/theme-customization.md` — Theme customization reference