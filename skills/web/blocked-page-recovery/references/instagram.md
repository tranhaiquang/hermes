# Instagram-Blocked-Page Recovery

Deep reference for recovering Instagram profile data when the bot wall blocks
the standard fetch. Covers payload navigation, SPA lazy-loading, and the
`code` field pitfall.

## Payload structure

The embedded JSON is wrapped in a RelayPrefetchedStreamCache payload:

```json
[
  "RelayPrefetchedStreamCache",
  "next",
  [],
  [
    "adp_PolarisLoggedOutDesktopWWWProfilePostsTabContentQueryRelayPreloader_...",
    {
      "__bbox": {
        "complete": true,
        "result": {
          "data": {
            "xig_user_by_username": {
              "pk": "5566255",
              "polaris_ordered_timeline_connection": {
                "edges": [
                  {
                    "node": {
                      "__typename": "XIGPolarisVideoMedia",
                      "pk": "3844756144258959037",
                      "code": "DVbUVfCjka9",
                      "accessibility_caption": "Video by New Balance Running on March 03, 2026.",
                      "type": "XIGPolarisVideoMedia"
                    }
                  }
                ]
              }
            }
          }
        }
      }
    }
  ]
]
```

**Data path:** `payload["__bbox"]["result"]["data"]["xig_user_by_username"]["polaris_ordered_timeline_connection"]["edges"]`

## Key field guide

| Field | Type | Notes |
|-------|------|-------|
| `code` | string | Opaque hash (e.g. `DVbUVfCjka9`). **Does NOT contain product model numbers** like "880" or "860". Cannot be used to filter for products. |
| `accessibility_caption` | string | Caption text. Search this for keywords like "880", "860", "Nike", etc. |
| `type` | string | `XIGPolarisVideoMedia` or `XIGPolarisCarouselMedia`. Carousels may contain multiple images but only one `node` per edge. |
| `media` | object | Null in initial embed. Populated when the SPA loads more media details. |
| `display_url` | string | Null in initial embed. Populated when the SPA loads more media details. |
| `thumbnail_src` | string | Null in initial embed. Populated when the SPA loads more media details. |

## Loading more posts

The page has a "Show more posts from newbalancerunning" button. Clicking it
increases the total HTML size (the observed case went from ~863KB to
~892KB) but the `edges` array may stay at 12. Always:

1. Click the "Show more posts" / "Load More" button.
2. Re-extract `document.documentElement.innerHTML`.
3. Re-parse the JSON payload.
4. Verify the `edges` count increased before trusting the result.

If the count did not increase, the page may have reached the end of the feed
or the click did not trigger a re-render. Try scrolling down in addition to
clicking the button. **If the count stays at 12 after multiple attempts, the
SPA will not load additional posts without authentication.** Do not loop
further on the same profile; pivot to an alternative source.

## Fallback: when the embedded JSON is insufficient

If you need more than ~12 posts, or the 12 visible posts do not contain
the target content, pivot to an alternative source instead of looping on
Instagram:

1. **Stop after 2-3 failed Instagram attempts** — do not keep retrying the
   same profile.
2. **Identify the brand's own e-commerce or retail partner sites** — these
   often have structured product pages with high-quality images.
3. **Predictable image URL patterns** — many retail sites serve images via a
   URL template where you only need the product code. Example: Running
   Warehouse uses
   `https://img.runningwarehouse.com/watermark/rs.php?path={PRODUCT_CODE}-{N}.jpg`
   where `{PRODUCT_CODE}` is the retailer's SKU (e.g. `N880150` for New
   Balance 880v15) and `{N}` is the image index (1, 2, 3...). Stop when
   you hit 404 or files below ~10 KB.
4. **Batch the download by model** — if the user wants "10 images per
   code", download from 2 colorways of the same model, stopping once the
   model count reaches 10. Organize into folders by model and colorway.
5. **Provenance** — note that these are product images from a retailer, not
   Instagram posts. State this clearly if the user asked for Instagram content.

## Product code discovery

To find product codes for a given model:
- Search the retailer site: `site:runningwarehouse.com "880v15" descpage-...`
- The URL slug after `/descpage-` is the product code.
- If one code yields 5 images, move to the next colorway to reach 10 total.

## Limitations

- Instagram blocks all automated scraping; the embedded JSON is the only
  reliable source for profile feed data.
- The initial embed only contains the first ~12 posts. Older posts require
  clicking "Show more posts" repeatedly after the SPA loads.
- `code` cannot be used to identify products. Photos of specific products
  must be identified by examining captions, hashtags in captions, or visual
  content.
