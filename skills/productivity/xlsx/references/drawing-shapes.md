# Editing Excel flowchart shapes (drawing1.xml) via zip surgery

openpyxl cannot read or preserve spreadsheet drawings (`xl/drawings/drawing*.xml`):
loading and re-saving a workbook through openpyxl silently DELETES every flowchart
shape, textbox, and connector. To edit shapes, edit the XML in place inside the zip
and never let the file pass through openpyxl's save path.

## When to use

- Filling a template workbook whose sheet contains a shape-based flowchart
  (SMED diagrams, process maps, GBOS forms) with data from another file.
- Renaming/recoloring/moving shapes without touching anything else.

## Procedure

1. **Inspect with openpyxl for data only.** Read cell values, sheet structure,
   column widths, and row heights with openpyxl — but never save from that
   session. Shape inventory comes from the XML instead:

   ```python
   import zipfile, xml.etree.ElementTree as ET
   NS = {'xdr': 'http://schemas.openxmlformats.org/drawingml/2006/spreadsheetDrawing',
         'a':   'http://schemas.openxmlformats.org/drawingml/2006/main'}
   root = ET.fromstring(zipfile.ZipFile(f).read('xl/drawings/drawing1.xml'))
   for anc in root:
       for sp in anc.findall('.//xdr:sp', NS):
           name = sp.find('xdr:nvSpPr/xdr:cNvPr', NS).get('name')
           geom = sp.find('.//a:prstGeom', NS).get('prst')
           text = ' | '.join(t.text or '' for t in sp.findall('.//a:t', NS))
   ```

   `xdr:cxnSp` anchors are connectors (arrows); shapes are `xdr:sp`.
2. **Map template shapes to data.** Match existing shape names to the new
   content (steps, times, phases) and decide text per shape. Colors encode
   phase (e.g. fill `E3F4F0` external, `FBEEE3` internal, `FAE7B8` decision) —
   keep the template's color scheme, do not invent new fills.
3. **Edit by shape name, not position.** For each target shape, locate
   `name="Rectangle N"`, take the enclosing `<xdr:sp>...</xdr:sp>` span
   (`xml.rfind('<xdr:sp>', 0, idx)` / `xml.find('</xdr:sp>', idx)`), and
   replace only the paragraphs between `</a:lstStyle>` and `</xdr:txBody>`.
   Never touch `<a:xfrm>`, fills, or the lstStyle — that preserves geometry
   and formatting byte-for-byte.
4. **Build paragraphs with matching rPr.** Copy the color/font from the
   shape's existing runs so the edit is invisible in style. Multi-line = one
   `<a:p>` per line; shrink `sz` (1400 → 1100/1200) when the new text is
   longer than the original so it does not clip (`bodyPr` is usually
   `vertOverflow="clip"`).

   ```python
   def esc(t): return t.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')

   def P(text, color, sz=1400):
       fill = f'<a:solidFill><a:srgbClr val="{color}"/></a:solidFill>'
       rpr  = f'<a:rPr lang="en-US" sz="{sz}" b="1">{fill}</a:rPr>'
       end  = f'<a:endParaRPr lang="en-US" sz="{sz}" b="1">{fill}</a:endParaRPr>'
       return f'<a:p><a:pPr algn="ctr"/><a:r>{rpr}<a:t>{esc(text)}</a:t></a:r>{end}</a:p>'
   ```
5. **Rewrite the zip preserving entry order and metadata.** Iterate
   `z.infolist()`, pass the original `ZipInfo` object to `writestr`, and
   substitute only the changed entry's bytes. Rebuilding from filenames alone
   can reorder entries and corrupt the package for downstream consumers.
6. **Verify before reporting.**
   - `zipfile.ZipFile(out).testzip()` is `None`.
   - Entry list (order and count) identical to the source.
   - Exactly the intended entries differ in bytes.
   - Geometry check: strip all `<a:p>...</a:p>` blocks from old and new
     `drawing1.xml`; the remainder must be identical.
   - Re-parse the new XML with ElementTree; print each edited shape's text.
   - `openpyxl.load_workbook(out)` still opens (sheet names intact).

## Pitfalls

- **Never openpyxl-load-and-save a file with drawings** — shapes, textboxes,
  and connectors vanish (openpyxl only round-trips images and charts, not
  drawing shapes).
- **`endParaRPr` is its own tag**, not a copy of `<a:rPr>` with the element
  renamed only in the opening tag; a naive string replace leaves
  `<a:endParaRPr ...></a:rPr>` and the whole XML fails to parse. Build the
  closing tag separately.
- **XML-escape every text run** — task names routinely contain `&`, `<`, `>`.
- **Shape text lives split across multiple `<a:r>` runs** (Excel splits on
  IME edits); always replace the whole paragraph set, never patch a single
  run's text.
- **Plan long text against the box height.** Estimate lines × line-height vs
  the anchor's row span and reduce `sz` or shorten wording before writing,
  since clipped text is only visible when the file is opened in Excel.
- **For a visual check without LibreOffice**, render an approximate preview:
  parse anchors (`xdr:from`/`xdr:to` cell + offset), convert to pixels using
  the sheet's column widths and row heights, and draw the shapes with PIL.
  This verifies text fit and geometry, not Excel's exact rendering.
