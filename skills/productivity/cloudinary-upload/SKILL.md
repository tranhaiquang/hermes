---
name: cloudinary-upload
description: Upload local files to Cloudinary, return delivery URLs.
version: 1.0.0
author: Nous Research
license: MIT
platforms: [linux, macos, windows]
metadata:
  hermes:
    tags: [cloudinary, upload, media, mcp, images, assets]
    category: productivity
---

# Cloudinary Upload

## When to Use

- The user wants to push local files (images, videos, PDFs) to Cloudinary and
  get back public delivery URLs, or to fill a "Cloudinary URL" column in a
  sheet/tracker with links to freshly exported assets.
- Do not use for remote-URL ingestion (use `upload_asset` directly) or for
  files > ~100 MB (use the Cloudinary CLI/SDK).

Upload LOCAL files to a Cloudinary product environment and return each asset's
public delivery URL. Uses the official Cloudinary MCP server (hosted, OAuth) —
the API secret is never handled in chat.

## Connect

`manage_connections(action="install", connectors=[{"name":"cloudinary","mcp":true}])`.
If the first install settles as `not_connected`, run `install` again — the
second run registers the server and exposes its tools
(`mcp__cloudinary__upload_asset`, `mcp__cloudinary__sign_upload`,
`mcp__cloudinary__list_resources`, …).

## Workflow for local files

`mcp__cloudinary__upload_asset` accepts only remote HTTP/S3/FTP URLs — it
cannot read local paths. For local files:

1. Batch-sign ALL uploads in ONE `mcp__cloudinary__sign_upload` call:
   `uploads: [{public_id:"folder/name-01"}, {public_id:"folder/name-02"}, ...]`
   (add `folder`, `tags`, `context`, … per entry as needed). It returns one
   credential object per entry, in order, each with `upload_params` (includes
   `timestamp` plus any preset/overwrite/audit fields the account injects),
   `api_key`, `signature`, `host`, `cloud_name`.
2. For each file, POST `multipart/form-data` to
   `https://<host>/v1_1/<cloud_name>/<resource_type>/upload`
   (`resource_type` = `image`/`video`/`raw`/`auto` goes in the URL, NOT in the
   signed params) with form fields: `file=@<path>`, `api_key`, `signature`,
   and EVERY key from that entry's `upload_params` verbatim, each as its own
   field.
3. Collect `secure_url` (https) from each JSON response — that is the public
   link to return / store.

Multipart sketch (curl; note the two quoting layers on `file=`):

```bash
curl https://<host>/v1_1/<cloud>/image/upload \
  -F 'file=@"C:\path\slide-01.png"' \
  -F 'api_key=<api_key>' -F 'signature=<signature>' \
  -F 'timestamp=<ts>' -F 'public_id=<pid>'   # one -F per upload_params key
```

In Python, build the multipart body manually (stdlib `urllib` + a boundary)
and POST it — don't rely on an HTTP helper re-serializing the fields.

## Pitfalls

- The signature covers the EXACT serialized `upload_params`. Adding, dropping,
  renaming, or re-serializing any field invalidates it → 401. Echo every
  `upload_params` key unchanged as its own form field; do not fold them into a
  structure the HTTP client may re-encode.
- `public_id` must be unique per asset. Identical filenames across source
  folders collide — prefix with a folder/month path, e.g.
  `giay-khen/thang-5/slide-01`.
- Signed upload defaults `overwrite:true`, so re-uploading the same
  `public_id` replaces the asset (the URL gains a new version segment).
- `sign_upload` is for files up to ~100 MB; for larger or bulk uploads use the
  Cloudinary CLI/SDK, which chunk and retry.
- Keep `api_key`/`signature` in the tool result and feed them straight to the
  POST — do not paste them into chat, files, or logs.

## Verify

Any response containing `secure_url` is a success. Optionally confirm delivery
with `curl -I <secure_url>` (expect 200). Persist the
`public_id -> secure_url` mapping to a JSON file so downstream steps (e.g.
appending links to a sheet) can read it without re-uploading.
