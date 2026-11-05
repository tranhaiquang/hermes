# Editing Google Sheets through the logged-in browser (no OAuth)

Fallback for Sheets when the google-workspace OAuth token is not set up and no
Google hosted connector is connected: drive the browser that holds the user's
Google session over CDP. Two non-obvious facts make this work:

1. `sheets.googleapis.com` rejects cookie-only callers
   (`403 "Method doesn't allow unregistered callers"`). Never call it from the
   page with `credentials:'include'`.
2. The same-origin **gviz** endpoint DOES accept the session cookie and is the
   reliable way to read a tab.

## Get a CDP-attached, signed-in browser

- `browser_exec(local=true)` drives the OS default browser. If that browser
  has no Google session, or its profile is locked because the browser process
  is running, attach to the browser that DOES hold the session (e.g. Chrome).
- Chrome 136+ refuses `--remote-debugging-port` on the DEFAULT user-data-dir.
  Workaround: make a junction to the real profile and point `--user-data-dir`
  at the junction, then launch with the debug port:
  `New-Item -ItemType Junction -Path <scratch>\chrome-ud -Target "$env:LOCALAPPDATA\Google\Chrome\User Data"`
  `chrome.exe --remote-debugging-port=9222 --user-data-dir=<scratch>\chrome-ud`
  Connect to `http://127.0.0.1:9222` (Python `requests` to list targets +
  `websockets` to the page `webSocketDebuggerUrl`).
- If the default browser is running and locking its profile, free it first
  (close/kill its processes) so the harness can use the real profile.

## Read a tab (gviz)

```
GET https://docs.google.com/spreadsheets/d/<ID>/gviz/tq?tqx=out:json&gid=<GID>
```
with `credentials:'include'`. Response is wrapped:
`/*O_o*/\ngoogle.visualization.Query.setResponse({...});` — parse by slicing
from the first `{` to the last `}`. `table.cols[].label` = header labels,
`table.rows` = data rows, `table.parsedNumHeaders` = number of header rows, so
the first empty row = `parsedNumHeaders + rows.length + 1` (1-based).

## Write rows by clipboard paste (UI path)

1. `Browser.grantPermissions` with `origin:"https://docs.google.com"` and
   permissions `clipboardReadWrite`, `clipboardSanitizedWrite`.
2. In the page: `await navigator.clipboard.writeText(<TSV>)` where TSV is
   tab-separated columns and newline-separated rows.
3. Select the target range via the Name Box: set `#t-name-box` value to e.g.
   `A31:B46` and dispatch `keydown`/`keypress`/`keyup` Enter on it.
4. Paste with `Input.dispatchKeyEvent` Ctrl+V (`modifiers:2`, `key`/`code`
   `v`, `windowsVirtualKeyCode:86`), then `Escape` to dismiss any dialog.
5. Verify by re-reading gviz — row count and the new cells must match what you
   intended to write.

## Map to the sheet's real schema

Read the header row first (gviz `cols[].label`) and append into the matching
columns. Do not assume a fixed Month/Slide/Link layout — the sheet's own
headers decide which column gets the file name and which gets the URL.
