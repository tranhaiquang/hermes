---
name: ffmpeg-video-composition
description: Combine video clips with text overlays and effects
version: 1.0.0
author: Nous Research
license: MIT
platforms: [windows, linux, macos]
metadata:
  hermes:
    tags: [video, ffmpeg, video-editing, drawtext, concatenation]
    category: media
    related_skills: [creative]
---

# ffmpeg Video Composition

Combine per-step video clips into one complete customer-facing video with text overlays showing the current step.

## When to Use

Use this skill when the user wants to:
- Combine multiple video clips into one complete video
- Add text overlays showing which work step the viewer is currently on
- Add title screens, step indicators, and summary screens
- Create a customer-facing demo video from individual clips

## Always-on Rules

- **Deliver working artifacts, not descriptions.** The final result is a file path + duration confirmation.
- **Staged approach over complex filter_complex.** Break the build into sequential steps: title screen -> per-step clips with overlays -> summary -> concat. Complex filter_complex quoting leads to shell/escaping errors.
- **Use `textfile` for drawtext text.** Single quotes inside filter strings break shell/quote parsing. Write the text to a file with `echo 'text' > /tmp/step4.txt`, then reference `textfile='/tmp/step4.txt'` in the filter.
- **Use `concat` demuxer for assembly.** Build a text file listing all clips (`file 'name.mp4'` per line), then `ffmpeg -f concat -safe 0 -i list.txt -c copy output.mp4 -y`.
- **Preserve yuv420p pixel format.** Use `-pix_fmt yuv420p` on every ffmpeg call to ensure compatibility.
- **Verify duration.** Check each intermediate and final output with `ffprobe` before proceeding.
- **Match framerates.** Use `setpts=PTS-STARTPTS` after trim to ensure consistent timebase.

## Procedure

1. **Analyze source clips** with `ffprobe -v quiet -print_format json -show_format -show_streams <clip>` to get durations, resolution, and codecs.
2. **Create title screen** from the intro clip: `ffmpeg -i <intro>.mp4 -filter_complex "[0:v]trim=0:2.8,setpts=PTS-STARTPTS,format=yuv420p[t1]" -map "[t1]" -c:v libx264 -pix_fmt yuv420p Title_Screen.mp4 -y`
3. **Create per-step clips** one at a time:
   - Write step text to a file: `echo 'Cog doan 4: Tai lieu' > /tmp/step4.txt`
   - Run ffmpeg with drawtext using textfile:
     `ffmpeg -i '<clip name>.mp4' -filter_complex "[0:v]trim=0:6.6,setpts=PTS-STARTPTS,drawtext=textfile='/tmp/step4.txt':fontsize=48:x=(w-text_w)/2:y=80,format=yuv420p[t4a]" -map "[t4a]" -c:v libx264 -pix_fmt yuv420p Step4a.mp4 -y`
4. **Create summary screen** with total time text.
5. **Assemble** with concat demuxer:
   - Write `concat_list.txt` with `file 'Step4a.mp4'` etc. per line
   - Run: `ffmpeg -y -f concat -safe 0 -i concat_list.txt -c copy SEMI_Changeover_Standard.mp4 -y`
6. **Verify** the final output with ffprobe (duration, resolution, codec).

## Pitfalls

- **drawtext quote escaping.** Single quotes inside the filter string are stripped by the shell, breaking the filter chain. Always use the `textfile` parameter instead of `text='...'`.
- **Complex filter_complex fails.** Long filter chains with multiple drawtext filters produce cryptic errors (e.g., "No option name near..."). Split into separate ffmpeg calls per step.
- **Newline characters in textfile.** Avoid trailing newlines in text files; write with `echo -n` or `printf` to prevent stray newline characters from appearing in the overlay.
- **Encrypted/conclusion screen.** After the last clip, render a summary screen with total time and duration. Use a black color source (`color=c=black:d=X:s=1920x1080`) so the final video has context.
- **Font rendering.** drawtext uses a default font; complex Vietnamese text may render with missing glyphs. Test with a small sample before processing all clips.
- **Concat requires same codec profile.** All clips must use the same codec and profile (libx264, High profile, yuv420p) to allow `-c copy` in the concat step.
- **Staged output directory.** Create intermediate clips in the same directory as the final output to avoid path confusion.
- **Duration overflow.** The total output duration should approximately equal the sum of all clips (title + step clips + summary). Verify with ffprobe.

## Technical Pitfalls (cross-tool)

- **PIL 12.x removed `font.getsize()`. Use `font.getlength(text)`** which returns an integer width (no `[1]` indexing). Rebuild card-drawing code for the new API.
- **`ImageDraw.Draw(draw, "RGBA")` on a separate image object fails on PIL 12.x.** Draw directly on the target `ImageDraw.Draw(img)` instead of creating a throwaway RGBA image.
- **Do not hardcode Vietnamese filenames with `\u` escape codes** — wrong code points (e.g., `\u00F0` for `ð` instead of `\u0111` for `đ`) silently break matching. Match files by suffix (`(1)`/`(2)`), ASCII substrings (`"v"` for `vạch`, `"C"` for `Cắt`), or other unambiguous patterns, or exclude intermediate/final outputs from the match set.
- **Exclude intermediate/final output files from source-clip matching.** A prior run's output (e.g., `outro.mp4`, final `.mp4`) will match the "no `(1)`/`(2)` suffix" rule for step 3 and corrupt the overlay step. Maintain an explicit exclusion set of filenames to skip.

## User Preferences

- Keep final answers concise and direct; no process narration.
- Deliver working artifacts (file paths, durations, resolution) over prose descriptions.
- Use Vietnamese text in overlays for customer-facing content.
- Wrap file paths as MEDIA: or deliver as plain text with clear path information.
- Rephrase the user's request with corrected grammar before acting on it; the rephrasing must be a direct improvement, not a preamble.

## User-Specific Rules (This User's Specifications)

- **Logo source is disk files** (`New_Balance-Logo.wine.png`, `Vietnam Samho.png` in the project folder), NOT extracted from the Excel workbook. Read logos directly from disk with PIL `convert("RGBA")` for alpha compositing.
- **Output filename** follows the convention `<project>_<purpose>.mp4`. For this user's SEMI changeover evidence video, the output is `SEMI_SOP.mp4` in the `Video/` subfolder.
- **Step order follows the Excel changeover standard timeline** (not the order of files on disk). Map each video to its step number, then order clips by step number: 03 → 04 → 06.
- **Overlay content includes**: step number badge ("BƯỚC 0X"), step title, detail line, standard time, machine state, and a 3-dot progress indicator (dots are filled up to the current step's progress).
- **Excluded footage** is listed explicitly in the clips list; never include it in the output.
- **Professional design** for intro/outro: gradient background (dark blue #071b31 → deep blue #030c16), logo with shadow + red border, red accent bar top, bottom info bar, larger bold typography.
- **Intro/outro text**: intro uses "SEMI CUTTING MACHINE" + "SINGLE MINUTE CHANGE OF DIE (SMED)" + "STANDARD TIME: 8.5 MINUTES"; outro uses "THANK YOU" + "CẢM ƠN QUÝ KHÁCH ĐÃ THEO DÕI" + "SMED CHANGEOVER PROCESS".
- **Backup**: copy final video to `Backup/SEMI_SOP_Backup.mp4` in the New folder root.
