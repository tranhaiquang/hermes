---
name: static-html-dashboard-edit
description: Restructure a static HTML dashboard's section layout.
version: 1.0.0
author: Hermes Agent
license: MIT
platforms: [linux, macos, windows]
category: software-development
metadata:
  hermes:
    tags: [frontend, html, dashboard]
    related_skills: [codebase-inspection, dogfood]
---

# Static HTML dashboard editing

Procedure for restructuring the section layout of a static single-page dashboard (HTML + inline CSS + vanilla JS) that ships in multiple theme variants.

## When to Use
- Reordering, adding, or removing a section (`<!-- NAME -->` block) in `index.html` or a sibling theme file.
- Moving a section to a different grid class (`g2` to `g3`, etc.) or wrapping it in a `.card`.

## Procedure
1. Read the target file end to end (`index.html` first). Do not edit from memory; the inline `<style>` and JS are long.
2. Enumerate the top-level section markers in document order: `<!-- NAME -->` lines. Each is a section anchor.
3. For the section being moved, locate its start marker and its closing tag. Sections are wrapped in `<div class="card">` or `<div class="grid gN">`; the close tag is that wrapper's matching `</div>`.
4. Remove the section wholesale (marker to closing tag). Leave exactly one blank line where the two neighbours meet.
5. Choose the target anchor. Insert the removed section immediately after that anchor's following blank line, keeping the same wrapper classes.
6. Re-read the marker list in order to confirm the new document order. Do not hand-count indentation.

## Pitfalls
- **Wrappers differ.** `Thị Trường` is the only section not wrapped in `<div class="card">` — it is a bare `<div class="grid g3">`. Check the wrapper before you move it.
- **Skeleton is duplicated, not shared.** Four theme HTML files (`editorial`, `technical`, `utilitarian`, `austere`) are near-identical skeletons with their own inline `<style>`. An edit in one is a parallel edit in all four; do not assume CSS is shared and do not treat one file as canonical.
- **Move the block, not the marker line.** Cutting only the `<!-- NAME -->` line leaves an empty card and breaks wrapper balance.
- **Grid classes change sizing.** A 3-card section in a `g2`/`g4` grid changes column behaviour: keep `g3` for three market cards, `g2` for two-column analysis.
- **Blank lines carry readability.** Empty lines are not semantic here, but section comments and these long files depend on them. Do not collapse whitespace beyond the required one blank line on a move.
