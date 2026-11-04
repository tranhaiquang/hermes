---
name: changeover-video-production
description: Create changeover evidence videos from Excel standards (white/light-blue theme, New Balance + Vietnam Samho branding, per-step text overlays with standard times).
version: 2.0.0
author: Nous Research
license: MIT
platforms: [windows]
metadata:
  hermes:
    tags: [video, ffmpeg, video-editing, drawtext, concatenation]
    category: media
    related_skills: [creative, design]
---

# Changeover Evidence Video Production

Use when the user wants to create a customer-facing evidence video of a manufacturing changeover process, combining Excel standard data with already-shot footage, and needs one or two branded video deliverables.

- Use when the user asks to produce a SMED or changeover evidence video for a machine (e.g. a SEMI cutting machine) from an Excel changeover standard plus already-shot footage.
- Use when the deliverable needs: a branded intro (company logos + title), per-step text boxes with standard times, a total-time summary, and the output is a working MP4 file.
- Use when the user wants **two versions**: a slideshow-with-motion-graphics version and a motion-graphics version, both grounded in the same frame sequence.

## When to Use

- Use when the user asks to produce a SMED / changeover evidence video for a machine (e.g. a SEMI cutting machine) from an Excel changeover standard plus already-shot footage.
- Use when the deliverable needs a branded intro (logo + company name + title), per-step text boxes with standard times, and a total-time summary.
- The active theme for this user is white background + light-blue accent (#9DB0E6). Red appears only inside the New Balance logo area.

## Standing user preferences

- **Concise, direct communication** — no filler, no restating the request, no narrating tool calls. Match the length of the reply to the weight of the ask.
- **Corrected grammar before acting** — rephrase the user's request with corrected grammar first, then carry it out.
- **Design theme**: white background with a light-blue accent (#9DB0E6, "xanh dương nhạt"). Red is used only inside the New Balance logo area; it is NOT a brand accent.
- **Logos**: New Balance (top-left) and Vietnam Samho (top-right) on the SAME horizontal line. No red separator — use a thin light-blue divider instead. Logos are clean — no borders, no shadows.
- **Intro text**: "SMED APPLICATION VIDEO" + "Change Over Time Standard cho Máy Cắt SEMI" + "Thời gian chuẩn: 8.5 phút".
- **Steps**: every step from the Excel standard gets a step card ("BƯỚC" number, step title, detail, "THỜI GIAN CHUẨN" with duration). No outro section.
- **Footage for missing steps**: use segments of the final evidence video (`SEMI_Changeover_Evidence_Customer_Final.mp4`) for steps that have no dedicated clip.
- **Output**: `SEMI_Changeover_Evidence_Customer_Final.mp4` in the Video folder.
- **Backup**: copy the previous final to `Backup/SEMI_Changeover_Evidence_Customer_Final_Backup.mp4` before overwriting.

## Design & layout rules

- **All centered text**: use `(W//2 - text_w//2, cy - text_h//2)`; measure with `textbbox()` first. Never hardcode x positions for centered text.
- **Intro card** (1920×1080):
  - New Balance logo top-left at (x=90, y=120), max width ~360px
  - Vietnam Samho top-right at (x=W-90, y=120), same baseline as New Balance, max width ~260px
  - Thin light-blue divider under the brand row
  - "SMED APPLICATION VIDEO" (≈46–52pt bold, light blue), then "Change Over Time Standard cho Máy Cắt SEMI" (≈40–46pt bold), then "Thời gian chuẩn: 8.5 phút"
- **Step card** (1920×1080, to overlay on footage):
  - White rounded card, light-blue left accent tab, "BƯỚC 0X" badge, step title, "THỜI GIAN CHUẨN" label, duration "MM:SS" in light blue, tag pill (EXTERNAL/INTERNAL)
  - Position the card on the left ~55% of the frame; keep the right side for footage.

## Step standard times (from Excel)

| No. | Task | Time | Tag |
|-----|------|------|-----|
| 01 | Chuẩn bị file cắt theo quy chuẩn [Model]_[Size] | 1:00 | EXTERNAL |
| 02 | Chuẩn bị liệu mới, dao và mút EVA (gắn sẵn trên plate thay nhanh) | 1:00 | EXTERNAL |
| 03 | Dừng máy, tháo liệu cũ ra khỏi máy (cuộn gọn, dán băng niêm phong) | 1:00 | INTERNAL |
| 04 | Tải liệu xếp sẵn lên máy theo vạch định vị | 3:00 | INTERNAL |
| 05 | Thay plate dao + mút EVA (siết bộ lục giác) | 1:00 | INTERNAL |
| 06 | Cắt thử và kiểm tra mẫu đầu (thông số cắt lưu sẵn trong file) | 1:30 | INTERNAL |

Total: 8.5 phút.

## Procedure

1. Read `Tieu_chuan_thoi_gian_chuyen_doi_SEMI.xlsx` (sheet "Tiêu chuẩn TG chuyển đổi - SEMI") → steps in timeline order with standard durations (1:00 / 1:00 / 1:00 / 3:00 / 1:00 / 1:30; total 8.5 min). Use the Hermes tool python (it has Pillow + openpyxl). If openpyxl is missing, run `python -m pip install openpyxl` in that interpreter.
2. Enumerate the Video folder; match each clip to a step by filename. Keep the used-clip list. Sort same-step clips by number suffix (1), (2), ... and note the order.
   - Steps with dedicated clips: step 03 (Dừng máy...mp4), step 04 (Tải liệu...mp4 (1)+(2)), step 06 (Cắt thử...mp4 (1)+(2)).
   - Steps without dedicated clips: steps 01, 02, 05 → use segments of SEMI_Changeover_Evidence_Customer_Final.mp4.
3. Render intro PNG card with PIL: white background, light-blue top/bottom bars, New Balance logo top-left, "VIETNAM SAMHO" top-right (same baseline as New Balance), intro text. **Do NOT use PIL `anchor` parameter** — it causes `TypeError` in the installed Pillow version. Measure with `textbbox()` and compute x/y offsets manually.
4. Render one step overlay PNG card per step with PIL: white rounded card, light-blue left accent tab, "BƯỚC 0X" badge, step title, "THỜI GIAN CHUẨN" label, duration in "MM:SS" light blue, tag pill. Save as `card_step_0X.png`.
5. Render the total card (`card_total.png`): "TỔNG THỜI GIAN CHUYỂN ĐỔI", "THEO TIÊU CHUẨN SEMI", big "8.5 phút" in light blue, footer.
6. For each step, build a segment MP4: overlay the step plaque onto its footage clip (scale/pad to 1920×1080), fade-in. Use ffmpeg with the full system ffmpeg path.
   - Step 03: `Dừng máy, tháo liệu cũ ra khỏi máy.mp4` [0:00 → 8s]
   - Step 04: `Tải liệu xếp sẵn lên máy theo vạch định vị (1).mp4` + `(2).mp4` concatenated, first ~10s
   - Step 06: `Cắt thử... (1).mp4` + `(2).mp4` concatenated, first ~10s
   - Steps 01/02/05: segments of `SEMI_Changeover_Evidence_Customer_Final.mp4`
7. Concatenate all segments (intro + steps 01–06 + total) with the concat demuxer, `-c copy`, `-movflags +faststart`.
8. Backup: copy to `Backup/SEMI_Changeover_Evidence_Customer_Final_Backup.mp4`.

## Tooling

- **Python**: use the Hermes tool python (`C:\Users\LEAN15\AppData\Local\hermes\tools\python-3.14.9+202****1021-win32-x64\python.exe`) — it has Pillow and openpyxl. If openpyxl is missing, run `python -m pip install openpyxl` in that interpreter.
- ffmpeg: `C:\Users\LEAN15\AppData\Local\hermes\tools\ffmpeg-9.0.1-win32-x64\bin\ffmpeg`
- Fonts: `C:\Windows\Fonts\arial.ttf` (regular), `arialbd.ttf` (bold). **Do NOT use `arialn.ttf`** — it does not exist on Windows.
- Do NOT use `imageio-ffmpeg` module. Use the full system ffmpeg path directly.

## Path handling (CRITICAL)

- Terminal runs through bash (git-bash/MSYS), NOT cmd.exe.
- **Use `C:/Users/...` format (forward slashes) for all Windows binaries** (python, ffprobe, ffmpeg) — NOT `/c/Users/...` which only works in `find`/bash builtins.
- Example: `python "C:/Users/LEAN15/AppData/Local/hermes/tools/ffmpeg-9.0.1-win32-x64/bin/ffmpeg"` (correct) vs. `C:\c\Users\...` (broken).
- In `terminal()` tool calls, quote paths with spaces.

## ffmpeg concat demuxer pitfalls

- The concat demuxer on this ffmpeg build does NOT support glob patterns (`-pattern_type glob`). List every file explicitly in the `.txt` file.
- The concat demuxer has a known issue where a colon (`:`) in a path is misinterpreted as a format specifier. Avoid `C:` drive-relative paths; use forward-slash paths.
- If the concat demuxer reports "unknown keyword", the file list contains a malformed line (e.g. a quoted Windows path with `C:\`). Check each line starts with `file '` and ends with `'.`.

## Path handling (CRITICAL)

- Terminal runs through bash (git-bash/MSYS), NOT cmd.exe.
- **Use `C:/Users/...` format (forward slashes) for all Windows binaries** (python, ffprobe, ffmpeg) — NOT `/c/Users/...` which only works in `find`/bash builtins.
- In `terminal()` tool calls, quote paths with spaces.

## PIL unicode

- Use actual UTF-8 characters in strings, NOT `\uXXXX` escapes (they get truncated and cause SyntaxError).
- Example: use `"Dừng máy"` not `"D\u0111ng m\u01b5y"`.

## Image file reference

- Import `ImageFilter` separately: `from PIL import Image, ImageDraw, ImageFont, ImageFilter`. Do NOT use `Image.Filter` (wrong module).

## Output contract

- Intro: New Balance (top-left) + Vietnam Samho (top-right, same line) + "SMED APPLICATION VIDEO" + "Change Over Time Standard cho Máy Cắt SEMI" + "Thời gian chuẩn: 8.5 phút".
- Steps 01–06 with text overlays (step title + standard time).
- Total card: 8.5 phút.
- No outro section.

## References

- `references/positioning.md` — logo placement coordinates, text hierarchy, alignment formulas, and light-blue verification.
