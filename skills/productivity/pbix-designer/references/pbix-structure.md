# PBIX ZIP packaging rules

A `.pbix` is a ZIP archive that Power BI opens with strict validation. The following must hold or the file is rejected as corrupted:

- **Entry order is significant.** Power BI expects the central directory order to match the original export. Do not re-sort entries alphabetically when re-zipping.
- **All original entries must be present.** The most commonly missed entry is `[Content_Types].xml` because shell globs like `*` skip files whose names start with `[`.
- **Binary files must not be altered.** `DataModel`, `Metadata`, `SecurityBindings`, `Connections`, `DiagramLayout`, `Settings`, `Version`, and `[Content_Types].xml` must be copied byte-for-byte from the original.

## Adding new files while preserving order

If decoration requires adding new files (themes, images), build a map of new content keyed by normalized archive path, then:

1. Iterate over the original zip's `infolist()` and write each entry into the new archive.
2. Collect any new files not in the original, sort them, and append them after all original entries.

```python
import zipfile, os

orig = r"<path>"
out = r"<path>_decorated.pbix"
work_dir = r"<work>"

new_content = {}
for root, dirs, files in os.walk(work_dir):
    for f in files:
        full = os.path.join(root, f)
        arc = os.path.relpath(full, work_dir).replace(os.sep, '/')
        with open(full, 'rb') as fh:
            new_content[arc] = fh.read()

with zipfile.ZipFile(orig, 'r') as zin:
    with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as zout:
        for info in zin.infolist():
            data = new_content.get(info.filename, zin.read(info.filename))
            zout.writestr(info, data)
        for arc, data in sorted(new_content.items()):
            if arc not in [i.filename for i in zin.infolist()]:
                info = zipfile.ZipInfo(filename=arc)
                info.compress_type = zipfile.ZIP_DEFLATED
                zout.writestr(info, data)
```

Do **not** insert new files into the middle of the archive — Power BI expects new entries at the end.

## Verified re-zip method

Use Python `zipfile` and iterate over the **original zip's `infolist()`**, reading each member by name and writing it into the new archive. This preserves the original entry order and guarantees `[Content_Types].xml` is included.

```python
import zipfile, re

orig = r"<path>"
out = r"<path>_decorated.pbix"
targets = {"Report/definition/pages/.../visual.json", ...}

with zipfile.ZipFile(orig, "r") as zin:
    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as zout:
        for info in zin.infolist():
            data = zin.read(info.filename)
            if info.filename in targets:
                text = data.decode("utf-8")
                text = re.sub(r'"show":\s*"(true|false)"',
                              lambda m: f'"show": {m.group(1)}', text)
                data = text.encode("utf-8")
            zout.writestr(info, data)
```

Do **not** use shell `zip -r .` or `zip -r *` — both lose `[Content_Types].xml` and may reorder entries.
