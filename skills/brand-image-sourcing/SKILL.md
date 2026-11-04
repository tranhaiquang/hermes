---
name: brand-image-sourcing
description: Source official brand product images when scraping fails.
---

# Brand Image Sourcing

## When to Use

Use when the user needs official product poster/marketing images and direct scraping is blocked or empty.

For brand-specific CDN patterns and URL templates, see `references/image-cdns.md`.

## Procedure

1. **Clarify intent** — if the user mentions Instagram/social media first, verify whether they actually want official marketing assets instead. Two common signals:
   - "poster image" / "marketing image" / "the model my company are producing" → official press/product artwork.
   - A reference folder with Instagram-style filenames like `{shortcode}_{n}_{source}_{model}.jpg` → social carousel images from retailer/reviewer accounts.
2. **If official marketing/poster is the goal:**
   - Search `site:<brand>.newsmarket.com` or `site:news.<brand>.com` for model keywords. These host high-res marketing stills, often 1920×1080.
   - Search regional brand sites (e.g., `site:newbalance.com.ar "<model>"`). Many global brands route product images through regional CDNs that are publicly accessible. Image URLs often appear directly in search-result snippets.
   - Download from the discovered URLs with size validation.
3. **If social carousel images are the goal:**
   - Identify Instagram posts by searching `site:instagram.com "<model>" "<brand>"` or known retailer/reviewer accounts.
   - **Profile scraping without login fails** — instaloader hits 302/401 rate limits on graphql/query and returns 0 images for most posts when scraping entire accounts.
   - **Shortcode-level scraping without login does work** — when you have specific post shortcodes from web_search results, call `instaloader.Post.from_shortcode(L.context, shortcode)` directly. This avoids the graphql rate limit that breaks profile-level scraping. Use a 3–10 second delay between posts.
   - For each post, verify `post.is_video` and skip videos; verify `post.owner_username` against an official-account whitelist before downloading.
   - For sidecar posts (`GraphSidecar`), enumerate `post._node['edge_sidecar_to_children']['edges']` and filter `node['is_video']` to extract only image `display_url`s — instaloader may write .webp for some carousel items, so extract URLs directly and download via `requests.get` to control format.
   - If `instaloader.download_post` returns 0 files but URLs were found, do not retry the same post — switch to direct URL download. Empty folders are a known instaloader artifact on some posts.
4. **Try major authorized retailers as fallback** — Running Warehouse, Fleet Feet, etc. often serve 5–6 product photos per colorway via predictable CDN paths.
5. **Download with size validation** — save only files >10KB; treat 404/small responses as end-of-sequence.
6. **Organize by model then colorway** — folder structure should mirror `output/<model>/<colorway_code>_<desc>/` unless the user specifies a different layout or provides a reference folder to match.

## Tool Order

- `web_search` to discover image URLs and regional site patterns
- `web_extract` to read page content and confirm image URLs
- `terminal` with Python `instaloader` + `requests` to fetch post metadata, filter videos/accounts, and download images with format control
- `browser_exec` only when JS-rendered pages must be inspected; do not loop on empty results

## Pitfalls

- **Do not loop on empty browser extractions.** If `browser_exec` returns 0 images twice in a row, switch to `web_search` + `terminal` download. JS-rendered brand sites often serve no `<img>` tags to headless contexts.
- **Retailer CDNs are limited, not exhaustive.** Running Warehouse serves ~5 images per product and then 404s. Do not waste attempts trying to force more.
- **Official product pages may 403 or return empty.** `newbalance.com` and similar often block non-browser User-Agents. Regional sites are usually more permissive.
- **Validate by file size, not just HTTP status.** A 200 response with <10KB is usually a placeholder; break the sequence.
- **Instagram GraphQL hard-rate-limits without login.** Instaloader hits 401 "Please wait a few minutes before you try again" from `graphql/query` after a handful of profile/post lookups. Treat this as a hard block, not a transient error. **Shortcode-level scraping via `Post.from_shortcode()` bypasses this** and reliably returns post metadata and image URLs. Use a 3–10 second delay between posts.
- **Instaloader sidecar extraction may yield .webp files.** For carousel posts, instaloader's `download_post` sometimes saves .webp instead of .jpg. Always enumerate `post._node['edge_sidecar_to_children']['edges']`, filter out video nodes, and download image `display_url`s directly with `requests.get` to control the file format.
- **Empty folders are an instaloader artifact on some posts.** If `download_post` creates a folder but produces 0 image files, the post likely has download guards; do not retry — switch to direct URL download instead.
- **Model identification from social posts requires visual verification.** Instagram captions may mention multiple models (e.g., a comparison post covering 880 and 860). When organizing images by model, inspect the actual image content rather than relying solely on filenames or captions. Use `vision_analyze` on downloaded images when the model/version is not obvious from the filename.
- **Match the user's reference folder convention.** If the user provides an existing folder with Instagram-style filenames (`{shortcode}_{n}_{source}_{model}.jpg`), mirror that naming when adding new images rather than imposing a different structure.
- **Shortcodes can contain hyphens.** Some Instagram shortcodes include `-` characters (e.g., `DFVR-`, `DX-6`, `Dd6`). Do not split filenames on `_` and assume the first segment is always a clean shortcode; use a regex or explicit extractor that handles hyphens.
- **Instagram web search coverage is incomplete.** `site:instagram.com/p/` queries return only a fraction of relevant posts. When the user wants "more" images, switch to regional retailers, brand newsrooms, or direct product-page CDN extraction rather than retrying the same search with different keywords.
- **Verify folder state after bulk operations.** After long-running scrape scripts, list the output directory and check for empty shortcode folders, orphaned root files, or misnamed files before reporting completion.
- **Organize mixed-source images by model, not by source account.** When the user's goal is model coverage (880/860) rather than source coverage, flatten shortcode subfolders into model folders. Preserve the source account in the filename (`{shortcode}_{n}_{source}.jpg`) so provenance is not lost.

## Output Convention

- Save to the user-specified folder (commonly `C:\Users\LEAN15\Downloads\<brand>-images\` or `C:/Users/LEAN15/AppData/Local/hermes/cache/scratch/<brand>_<type>/`) unless instructed otherwise.
- Report exactly what was downloaded: model, source site, image count, and folder path.
- If fewer than 10 images are available for a model, say so explicitly rather than padding with unrelated content.
- When the user provides a reference folder with Instagram-style filenames, match the naming pattern `{shortcode}_{n}_{source}.jpg` and mirror the folder organization.
