# Brand Image CDN Patterns

Quick-reference for extracting product images from specific brand sites when the
main product pages block automated access.

## New Balance

| Source | Pattern | Notes |
|--------|---------|-------|
| Newsroom/press | `https://preview.thenewsmarket.com/Previews/NBAS/StillAssets/1920x1080/<ID>.JPG` | 1920×1080 marketing stills; highest quality |
| Argentina CDN | `https://www.newbalance.com.ar/on/demandware.static/-/Sites-siteCatalog_NBEU/default/<path>/new_images/<CODE><COLOR>/IMAGE-1.jpeg` | Public product photos; search `site:newbalance.com.ar "<model>"` to find URLs |
| Running Warehouse | `https://img.runningwarehouse.com/watermark/rs.php?path=<PRODUCT_CODE>-<N>.jpg` | ~5 images per colorway; predictable sequence |

## Instagram carousel extraction (no login)

When you have specific Instagram post shortcodes from `web_search`, use
instaloader's `Post.from_shortcode()` to fetch metadata without credentials.
For sidecar posts, image URLs live in
`post._node['edge_sidecar_to_children']['edges'][i]['node']['display_url']`.
Filter with `node['is_video']` to drop video items. Download those URLs
directly with `requests.get` to avoid instaloader's .webp output on some
carousel items.

Instagram image CDN URLs follow the pattern:
`https://instagram.<region>.fbcdn.net/v/t39.30808-6/<IMAGE_ID>_n.jpg`
with cache-busting query params. These URLs are time-sensitive; download
immediately after extraction rather than storing the URL for later use.

## Extraction tips

- **Regional sites often leak CDN URLs in search-result snippets.** When `web_search` returns a regional brand site result, inspect the description text — it frequently contains the full `demandware.static` image URL.
- **Press stills have numeric IDs, not model codes.** Search `site:thenewsmarket.com <brand> <model>` and look for `StillAssets/1920x1080/` paths in result descriptions.
- **Product page HTML may be empty to curl** even when search snippets contain working image URLs. Prefer `web_search` → extract URLs from descriptions → `terminal` download over trying to parse product pages.
