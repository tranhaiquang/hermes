# Changeover Video Logo & Frame Positioning Reference

Guidelines for positioning logos and text in changeover evidence videos (white + light-blue theme).

## Logo placement (intro & outro)

| Logo | Position | Max width | Notes |
|------|----------|-----------|-------|
| New Balance | Top-left (x=90, y=120) | ~360px | Leftmost logo |
| Vietnam Samho | Top-right (x=W-90, y=120) | ~260px | Rightmost logo, same horizontal baseline as New Balance |
| Light-blue divider | y≈130–150, between logos | — | Thin 4–6px light-blue line (no red) |

**Rules:**
- Logos are at the **TOP** of the canvas, never bottom.
- Logos are clean — no borders, no shadows, no decorative frames.
- Light blue is the only brand accent (red appears only inside the New Balance logo area).
- Horizontal spacing: New Balance on left, Vietnam Samho on right, with a thin light-blue divider between them.

## Intro text hierarchy

| Text | Y position | Size | Color | Notes |
|------|-----------|------|-------|
| "SMED APPLICATION VIDEO" | y≈160 | 46–52pt bold | Light blue (#9DB0E6) | Centered at x=960 |
| "Change Over Time Standard cho Máy Cắt SEMI" | y≈220 | 40–46pt bold | Black (#1B2A41) | Centered at x=960 |
| "Thời gian chuẩn: 8.5 phút" | y≈280 | 34–40pt bold | Muted grey (#828CA0) | Centered at x=960 |

**Rules:**
- Each text row is spaced ~60px apart for clean hierarchy (the white/light-blue theme has no 120px grid).
- All centered at x=960 (canvas center).
- Text must have sufficient contrast against the white/light-blue card or pale background.

## Step overlay text positioning

| Element | Position | Size | Color | Notes |
|---------|----------|------|-------|-------|
| BƯỚC number badge | card inner, left | 36–40pt bold | Light blue (#9DB0E6) | Rounded square |
| Step title | card left, below badge | 40–46pt bold | Black (#1B2A41) | Card text |
| "THỜI GIAN CHUẨN" label | below divider | 24–26pt bold | Grey (#828CA0) | Card text |
| Duration | card right, near label | 76–86pt bold | Light blue (#9DB0E6) | Card text |
| Tag pill | top-right of card | 22–24pt bold | Black on light blue | EXTERNAL / INTERNAL |

- Step card is a white rounded rectangle (~62% height), positioned on the left ~55% of the frame; footage is visible on the right.

## Text alignment formula

Use `textbbox()` to measure text dimensions, then:

```python
text_w, text_h = draw.textbbox((0, 0), text, font=font(size, bold))[2:4]
x = cx - text_w // 2
y = cy - text_h // 2
draw.text((x, y), text, font=font(size, bold), fill=fill)
```

**Never use PIL `anchor` parameter** — the installed Pillow version raises `TypeError`. Always measure with `textbbox()` and compute x/y manually.

## Light-blue verification

After rendering, scan for light-blue pixels to verify the accent color is present:

```python
count = 0
for y in range(0, 1080, 5):
    for x in range(0, 1920, 5):
        r, g, b = px[x, y]
        if 70 < r < 130 and 140 < g < 210 and 200 < b < 250:
            count += 1
print("light-blue pixels:", count)
```

Expected: the light-blue accent (#9DB0E6) appears in top/bottom bars, left accent tab, time text, and dividers.