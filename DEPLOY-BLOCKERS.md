# Deploy Blockers

The following items **must** be resolved by the site owner before the live deployment:

## 1. Public Events Content Reconciliation

**Status:** Pending owner action.

The `scripts/pages/public-events.html` file was extracted from the Weebly export (newest dated asset: `screenshot-2026-01-13`; Weebly does not preserve exact build dates). Event listings are time-sensitive and may have changed since the export was captured.

**Before deploying**, the owner must:
- Open `https://www.pdxinsectarium.org/public-events.html` in a browser
- Compare it page-by-page against the local `scripts/pages/public-events.html`
- **Remove** events that are no longer running on the live site
- **Add** any new events present live but missing from the export, using the exact FareHarbor embed pattern already present on the page: `<a href='https://fareharbor.com/embeds/book/pdxinsectarium/items/<id>/?...'>...</a>`
- **Keep** the "READ BEFORE PURCHASING" policy block intact

This is a hard gate — the Public Events page is where all ticket-purchase traffic routes.

## 2. Shop External Store URL

**Status:** Pending owner action.

The `scripts/pages/shop.html` file contains a placeholder token `@@SHOP_STORE_URL@@` in the "Visit our shop" button (line 12). The Weebly storefront is a client-rendered app and was not included in the export; the owner must supply the real external store URL.

**Before deploying**, the owner must:
- Provide the real external shop/storefront URL
- Replace `@@SHOP_STORE_URL@@` in `scripts/pages/shop.html` with the actual URL

If shipped without this, the "Visit our shop" button will be broken.
