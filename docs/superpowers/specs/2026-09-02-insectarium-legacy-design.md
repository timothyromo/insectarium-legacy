# Insectarium Legacy Replica — Design Spec

Date: 2026-09-02
Repo: `insectarium-legacy`
Status: approved design, ready for implementation plan. Authoritative content
source is now the full Weebly export in `reference/` — the earlier
content-blocked hold (Home, Hours/Location, Public Events) is lifted; all three
are fully present in the export.

## Purpose

Stand up a temporary "lift-and-shift" replica of the live Weebly site
`pdxinsectarium.org` on WordPress (DreamPress), so the org can move off Weebly
without waiting for the full rebuild happening in `insectarium-web`. This is a
faithful, near-pixel copy of the **current** site, not a redesign. It is
expected to be short-lived and eventually superseded by the `insectarium-web`
build.

Explicit non-goals: no custom post types, no ACF, no page builder, no new
features, no IA changes, no visual redesign. Plain WordPress Pages only.

## Deliverable

Two artifacts, both version-controlled in this repo:

1. A custom theme, slug `insectarium-legacy`, under
   `wp-content/themes/insectarium-legacy/`.
2. A WP-CLI seed script under `scripts/`, run once over SSH on DreamPress after
   the theme is deployed, that creates every Page with its real content.
   Idempotent — safe to re-run to pick up content updates.

No WXR file. No hand-entry through wp-admin. DreamPress is assumed to be
standard single-site WordPress, current WP, PHP 8.x, no multisite, no
pre-installed page builder.

## Source: the Weebly export

Authoritative source is the full site export extracted to
`reference/13100960266a98c399e06d8/`. It contains:

- Rendered HTML for every page (`*.html` at the export root).
- The theme stylesheet `files/main_style.css` (~37 KB), plus a large
  page-specific inline `<style>` block inside each page's HTML (colored-box
  callouts, per-element overrides — these must be captured per page, not just
  the global sheet).
- All images under `uploads/8/1/3/7/81376966/…` and theme images under
  `files/theme/files/images/`.
- Base-theme webfonts under `files/theme/files/fonts/` (`Cento-*`) — these are
  the stock theme font and are **overridden site-wide** by inline CSS; not used.

`legacy-site-content-reference.md` is now superseded by the export and kept only
as a secondary cross-check.

Export currency: newest dated asset is `screenshot-2026-01-13…`; Weebly strips
real build timestamps on export, so the exact date can't be pinned. Time-
sensitive content — Public Events listings above all — must be eyeballed
against the live site before deploy (see Go-live checklist).

Only the `pdxinsectarium.org` domain is behind the Cloudflare challenge. The
Weebly asset CDNs (`cdn11.editmysite.com`, `cdn2.editmysite.com`) and
`fh-kit.com` are **fully reachable** — verified 200 OK for `sites.css` (210 KB
Weebly base framework), `main.js`, the font CSS/files, and the FareHarbor
button CSS. These are vendored into the theme (see Theme design). No automated
diff against the live *page* is possible; the export is the single content
source and the Public Events pre-deploy check is manual.

## Content / page inventory

Slugs are the old path minus `.html`. Every page below has full content in the
export unless noted.

### Task-list pages — in the nav (21)

| Page | Slug | In nav under | Notes |
|---|---|---|---|
| Home | front page | Home | Source is `index.html` (NOT `home.html`/`home1.html`, which are stale "under construction" drafts). Tagline, address, FareHarbor gift-admission item embed, KIT mailing list, accessibility-survey callout. |
| About Us | `about-us` | Info | Intro/history, residents table, Contact block, team bios, press-mentions list. |
| FAQ about the insectarium | `faq-about-the-insectarium` | Info | Full Q&A. |
| FAQ about bugs | `faq-about-bugs` | Info | Full Q&A. |
| Calendar | `calendar` | Visit | Intro, cancellation policy, demo-schedule text, Google Calendar iframe, images. |
| Admission | `admission` | Visit | Booking guidance, cancellation policy, two pricing tables, notes, FareHarbor embed. |
| Hours/Location | `hourslocation` | Visit | Address, hours, directions, map. Full in export. |
| Summer Camp | `summer-camp` | Visit | Large page (~15 KB content). |
| Memberships | `memberships` | Visit | Tiers + benefits + purchase mechanics. Full in export. |
| Public Events | `public-events` | (top level) | Largest page (~240 KB) — many event cards, FareHarbor links. Verify against live before deploy. |
| Events at the Insectarium | `private-events` | Private Events and Field Trips | Square Appointments embed, "don't use the global Book Now" warning. |
| Off-site Events | `off-site-events` | Private Events and Field Trips | Full in export. |
| Photo Shoots | `photo-shoots` | Private Events and Field Trips | Full in export. |
| Bug Club | `bug-club` | Get involved | Full in export. |
| Community | `community` | Get involved | Full in export (page `<title>` says "FAQ", heading is "Community"). |
| Shop | `shop` | Other | **Storefront not in export** (Weebly Store app, client-rendered). See "Shop page" below. |
| Services | `services` | Other | Insect Pinning, Pet Bug Sitting, Tarantula Adoption Program + adoptable list (volatile), Tarantula Donation info. |
| Care Sheets | `care-sheets` | Other | Parent page, clickable. |
| Care Sheets: Jumping Spiders | `jumping-spiders` | Other ▸ Care Sheets | Child of `care-sheets`. |
| Care Sheets: Ghost Mantis | `ghost-mantis` | Other ▸ Care Sheets | Child of `care-sheets`. |
| Care Sheets: Isopods | `isopods` | Other ▸ Care Sheets | Child of `care-sheets`. |

### Orphan pages — build, NOT in the nav (8 pages, + 1 ignored duplicate)

These exist as real, content-bearing pages on live but are absent from the nav.
Replicate them as **published** Pages reachable by direct URL only, matching
live. Not added to the menu.

| Page | Slug | Notes |
|---|---|---|
| Donate | `donate` | Colored-box callout + FareHarbor embed. `donate1.html` is a near-duplicate (different length) — implementation picks the canonical one, ignores the other; decision logged in `CHANGES.md`. |
| Internships | `internships` | "Portland Insectarium Internship Program". |
| Mini Museum Alliance | `mma` | Cross-org project page. Contains "More info coming soon!" placeholder text — kept verbatim (it is live content, not our placeholder); noted in `CHANGES.md`. |
| Live Bug Directory | `live-bugs` | Parent of the four below. |
| Tarantulas | `tarantulas` | Child of `live-bugs`. |
| Scorpions | `scorpions` | Child of `live-bugs`. |
| True Spiders | `true-spiders` | Child of `live-bugs`. |
| Other Arachnids | `other-arachnids` | Child of `live-bugs`. |

`live-bugs` and its children have no in-content cross-links in the export; the
parent/child relationship is inferred from slug/topic and set via
`--post_parent` for tidy `/live-bugs/tarantulas` permalinks. If implementation
finds they were flat on live, keep them flat — log the choice.

### Ignore (Weebly artifacts in the export)

`home.html`, `home1.html` (stale homepage drafts); `info.html`, `visit.html`,
`get-involved.html`, `other.html`, `private-events-and-field-trips.html` (empty
40-byte auto-stubs Weebly generates for non-clickable parent menu items).

### Page hierarchy

- `care-sheets` → children `jumping-spiders`, `ghost-mantis`, `isopods`
- `live-bugs` → children `tarantulas`, `scorpions`, `true-spiders`,
  `other-arachnids`

Children created after parents with `--post_parent=<id>`. Permalinks become
`/care-sheets/jumping-spiders` etc.; the redirect list maps every old flat
`.html` URL onto the new path.

## Navigation (Version A — confirmed verbatim from `index.html`)

The nav is **hardcoded in `header.php`**, copied from the export's menu markup
with `href`s rewritten to clean slugs. Rationale: the earlier plan had a
WP-CLI-built menu, but with the real export in hand, a verbatim copy of
Weebly's `wsite-menu-default` markup is the surest route to a pixel-identical
header and dropdown behavior, and the site is temporary — a nav change during
its life is a one-file edit + redeploy. No `register_nav_menus`, no
`menu.sh`.

Structure:

- Home → `/`
- **Info** — non-clickable parent (`<a>` with no `href`, exactly as Weebly)
  - About us → `/about-us`
  - FAQ about the insectarium → `/faq-about-the-insectarium`
  - FAQ about bugs → `/faq-about-bugs`
- **Visit** — non-clickable parent
  - Calendar → `/calendar`
  - Admission → `/admission`
  - Hours/Location → `/hourslocation`
  - Summer Camp → `/summer-camp`
  - Memberships → `/memberships`
- Public Events → `/public-events`
- **Private Events and Field Trips** — non-clickable parent
  - Events at the Insectarium → `/private-events`
  - Off-site events → `/off-site-events`
  - Photo shoots → `/photo-shoots`
- **Get involved** — non-clickable parent
  - Bug Club → `/bug-club`
  - Community → `/community`
- **Other** — non-clickable parent
  - Shop → `/shop`
  - Services → `/services`
  - Care Sheets → `/care-sheets` (clickable)
    - Jumping Spiders → `/jumping-spiders`
    - Ghost Mantis → `/ghost-mantis`
    - Isopods → `/isopods`

Labels, capitalization ("Off-site events", "Get involved") and the `>` marker on
Care Sheets are reproduced as they appear in the export. The site-wide
FareHarbor "Book Now" button in the header is copied verbatim.

## Theme design

### Approach — port with the real Weebly runtime, vendored

The export gives us the real markup and the theme customization CSS
(`main_style.css`); the Weebly **base** framework (`sites.css`) and fonts are
downloadable from the still-open CDN. The theme therefore reproduces the live
presentation by vendoring those real assets, not by hand-reconstructing them:

- `assets/vendor/` holds copies of, fetched once during implementation and
  committed:
  - `sites.css` (`cdn11.editmysite.com/css/sites.css`) — Weebly base framework
    (grid, `.wsite-section`, `.wsite-multicol`, menu, forms)
  - `main_style.css` (from the export) — this site's theme customization layer
  - `fh-kit.css` (`fh-kit.com/buttons/v2/?pop=ae40a5`) — FareHarbor button CSS
  - supporting: `social-icons.css`, `fancybox.css` (from CDN) if the visual
    diff shows they matter
  - fonts: Amaranth, Montserrat, Gentium Basic, Open Sans — the `font.css` +
    referenced font files from `cdn2.editmysite.com/fonts/…`, rehosted under
    `assets/vendor/fonts/` with URLs rewritten to local paths
- `header.php` / `footer.php` reproduce the Weebly chrome — `.wrapper >
  .cento-header` (logo + hardcoded Version A nav), `.footer-wrap > .footer`
  (search form rewired to WordPress search), `#navMobile` — verbatim from the
  export with `href`s and asset URLs rewritten.
- `page.php` / `front-page.php` output `the_content()` inside the exact wrapper
  chain Weebly uses: `.main-wrap > #wsite-content.wsite-elements.wsite-not-footer
  > .wsite-section-wrap > .wsite-section > .wsite-section-content > .container >
  .wsite-section-elements`, so the vendored CSS applies unchanged.
- Page content in `scripts/pages/<slug>.html` is the extracted inner HTML of
  `.wsite-section-elements` for that page, **including its page-specific
  `<style>` block**, lightly cleaned (see "Content extraction").
- JavaScript: Weebly's `main.js` is **not** loaded (it needs Weebly's full
  bootstrap and would throw). The theme ships a small `assets/js/nav.js`
  (~40 lines) for the dropdown hover/focus behavior and the mobile hamburger
  toggle. The FareHarbor `embeds/api/v1/?autolightframe=yes` script **is**
  loaded verbatim site-wide — it renders the floating "Book Now" tab (there is
  no "Book Now" button in the header markup; FareHarbor injects it).
  If the visual diff reveals behavior that genuinely needs `main.js` (fancybox
  image lightbox, multicol height equalization), vendor `main.js` as a
  fallback and revisit — noted as a known risk, not the default.
- `style.css` is the WordPress theme header plus `@import`s / enqueues of the
  vendored sheets in load order: `sites.css` → fonts → `main_style.css` →
  `fh-kit.css` → `theme.css` (our small header/nav/footer/mobile rules).

### File layout

```
wp-content/themes/insectarium-legacy/
  style.css                WP theme header (metadata only)
  functions.php            enqueue vendored CSS/JS in order; allow unfiltered_html
                           for administrators; set $content_width; no register_nav_menus,
                           no widgets, no comments
  header.php               <!doctype>, <head>, wp_head(), .wrapper open,
                           .cento-header (logo + hardcoded Version A nav)
  footer.php               .footer-wrap (search rewired to WP), #navMobile,
                           FareHarbor autolightframe script, wp_footer()
  front-page.php           Home — wrapper chain + the_content()
  page.php                 all other pages — same wrapper chain + the_content()
  index.php                fallback (required by WP) — delegates to page.php layout
  404.php                  minimal 404 in the same chrome
  theme.css                our header/nav/footer/mobile-nav rules only
  assets/js/nav.js         dropdown + hamburger behavior (~40 lines)
  assets/vendor/sites.css          Weebly base framework (from CDN)
  assets/vendor/main_style.css     this site's theme layer (from export)
  assets/vendor/fh-kit.css         FareHarbor button CSS (from CDN)
  assets/vendor/fonts/             Amaranth / Montserrat / Gentium Basic / Open Sans
  assets/img/                      logo + any chrome images from the export
```

### Fonts

Effective fonts on live (from inline CSS, which overrides `main_style.css`):

- **Amaranth** — body copy and nav
- **Georgia** — headlines (`.wsite-headline`, content titles); websafe, no file
- **Gentium Basic**, **Montserrat**, **Open Sans** — used in spots

Amaranth, Montserrat, Gentium Basic, Open Sans each have a `font.css` at
`cdn2.editmysite.com/fonts/<Name>/font.css` plus their font files on the same
open CDN. Vendor those verbatim into `assets/vendor/fonts/<name>/`, rewriting
the relative `url(./…)` references to local paths. Georgia stays a system
stack. No runtime dependency on any CDN.

### Palette (from the export CSS)

`#005b47` primary green (links), `#e0bf5c` / `#e9cf76` gold (hover, callout
backgrounds), `#2a2a2a` near-black text. Full values taken from `main_style.css`
and inline blocks during implementation.

### Content extraction (per page)

For each page, from its export HTML:

1. Take the inner HTML of the main content region (`#wsite-content` /
   `.wsite-section` wrapper).
2. Keep the page-specific `<style>` block that precedes it.
3. Rewrite internal links: `foo.html` → `/foo`; flat Care Sheet / Live Bug
   links → nested paths.
4. Rewrite asset URLs: `uploads/...` and `files/...` → the WordPress media URL
   (`/wp-content/uploads/...`) for files imported by the seed script, or a
   theme-asset path for chrome images.
5. Keep every embed (FareHarbor, Google Calendar iframe, Square, KIT) exactly
   as-is.
6. Strip Weebly runtime cruft: `<script>` tags, `data-*` editor attributes,
   `id="wsite-com-*"` app mounts that won't hydrate, empty editor wrappers.
7. Fix in-place the things the brief calls out — dead "More Info" links,
   leftover "More info soon" text — and log each in `CHANGES.md`. (The MMA
   page's "More info coming soon!" is live body copy, not a placeholder — it
   stays.)

Output is a clean HTML fragment per page in `scripts/pages/<slug>.html`.

### Embeds — kept byte-for-byte

- FareHarbor inline booking embeds — the exact anchor/URL/params from each
  page's export (Admission, Home gift item `items/564068`, Shop item
  `items/690480`, plus per-event item IDs on Public Events: `564169`, `564377`,
  `564471`, `566067`, `582363`, `621549`, …)
- FareHarbor `embeds/api/v1/?autolightframe=yes` script — loaded once site-wide
  in `footer.php`; renders the floating "Book Now" tab
- `fh-kit.com/buttons/v2/?pop=ae40a5` — vendored as `fh-kit.css`
- Google Calendar iframe (Calendar):
  `calendar.google.com/calendar/embed?src=info%40pdxinsectarium.org&ctz=America%2FLos_Angeles`
- Square Appointments embed (Events at the Insectarium)
- KIT mailing-list links/buttons (`kit.com/74fb3ad6f8`, `fh-kit.com/…`,
  `kit.com/buttons/v2/?pop=ae40a5`)

`unfiltered_html` for admins + creating posts as an admin user via WP-CLI keeps
this markup intact.

### Shop page

The Weebly storefront is a client-rendered app and is not in the export.
Replicate `shop.html` as a static Page:

- Reproduce whatever static intro copy is in the export's `shop.html`.
- Keep the FareHarbor gift-card embeds that ARE in the export
  (`items/690480` and any others).
- Add a single prominent button/link to the external store, URL supplied by the
  owner; until then a placeholder `#` link with an HTML comment. Logged in
  `CHANGES.md`.

No WooCommerce.

## Seed script design

```
scripts/
  seed.sh              orchestrator, run on DreamPress via SSH
  pages/<slug>.html    extracted, cleaned content fragment per page (source of truth)
  media/               the subset of export images actually referenced (tracked)
  media-manifest.tsv   <scripts/media path>\t<original uploads/... URL>
  redirects.txt        generated .htaccess redirect block, .html -> clean slug
```

The raw 90 MB export in `reference/` is **git-ignored**; the implementation
plan's extraction step copies only the images pages actually reference into
`scripts/media/`, so the repo stays self-contained for `git pull` on DreamPress
without carrying the whole export.

### `seed.sh` behavior

- Bash, uses `wp` (WP-CLI). `set -euo pipefail`.
- Config vars at top: admin user login, site URL, theme slug.
- Activates the `insectarium-legacy` theme.
- Sets permalink structure to `/%postname%/`, flushes rewrites.
- Imports media first: for each `media-manifest.tsv` row,
  `wp media import scripts/media/<file> --porcelain`, recording old→new URL for
  the link-rewrite step. Missing source → warn, continue.
- For each page (driven by an ordered list in the script): resolve by slug
  (`wp post list --post_type=page --field=ID --name=<slug>`). Found →
  `wp post update`; absent → `wp post create`. Always
  `--post_status=publish --post_author=<admin id> --post_type=page`,
  `--post_content` from `pages/<slug>.html`.
- Parents (`care-sheets`, `live-bugs`) created before their children; children
  passed `--post_parent=<parent ID>`.
- Home: create/update `home` page from `pages/home.html`, then
  `wp option update show_on_front page` and `wp option update page_on_front
  <ID>`.
- Every page has a real content file — there are no skip/sentinel cases.
- Writes `scripts/redirects.txt`.
- Prints a summary table: page | slug | action | post ID | parent.

### URL compatibility

- Clean slugs (`/about-us`).
- `redirects.txt` contains an Apache 301 block mapping every old
  `/<slug>.html` (including flat `/jumping-spiders.html`,
  `/tarantulas.html`, `/donate1.html` → `/donate`, etc.) to the new path. Owner
  pastes it into DreamPress `.htaccess` above `# BEGIN WordPress`. Not
  auto-applied.

## Fixing broken things while replicating

In scope: dead "More Info" / "More info soon" links and placeholder text —
remove or point at the right page; broken internal links found during
extraction; the `donate1` duplicate; the missing Shop store link.

Out of scope: any change to layout, copy tone, IA, or content not on live.
Volatile lists (adoptable tarantulas, demo schedule, event listings) are copied
as-is with an HTML comment marking them owner-owned and time-sensitive.

Every deviation from live is logged in `CHANGES.md` at repo root.

## Testing / verification

1. `bash -n` + `shellcheck` clean on `seed.sh`.
2. Theme activates with no PHP notices under `WP_DEBUG`.
3. Dry run of `seed.sh` on a local WP or DreamPress staging: all 21 nav pages +
   8 orphan pages created (29 total); summary table correct; re-run reports
   "update" everywhere, no duplicates.
4. Page-by-page visual diff against the export HTML opened in a browser —
   header, nav dropdowns (three levels under Other ▸ Care Sheets), footer,
   fonts, palette, colored-box callouts, tables.
5. Embeds present byte-for-byte (grep rendered HTML for the FareHarbor item
   IDs, `calendar.google.com/calendar/embed`, Square, `kit.com`).
6. All `uploads/…` images resolve (no broken `src`).
7. `redirects.txt` covers every old `.html` URL including flat care-sheet /
   live-bug paths and `donate1`.
8. Public Events page content matches the current live site (manual check).

## Go-live checklist

Ordered; each item explicitly checked off:

1. [ ] All `scripts/pages/*.html` fragments extracted and reviewed.
2. [ ] Public Events fragment reconciled against the live site (listings
   current) — **before deploy**.
3. [ ] Owner-supplied external Shop URL wired into `pages/shop.html` (or the
   placeholder consciously accepted).
4. [ ] Media imported; `media-manifest.tsv` complete.
5. [ ] Theme deployed to DreamPress
   (`wp-content/themes/insectarium-legacy/`).
6. [ ] `scripts/seed.sh` run over SSH; summary table reviewed; every page
   created.
7. [ ] `scripts/seed.sh` re-run; idempotent ("update", no duplicates).
8. [ ] Nav renders full Version A tree; three-level Care Sheets dropdown works
   on hover + keyboard; "Book Now" button present.
9. [ ] Embeds verified byte-for-byte on rendered pages.
10. [ ] **Apply `scripts/redirects.txt` to DreamPress `.htaccess`** above
    `# BEGIN WordPress`; spot-check old `/about-us.html`, a flat
    `/jumping-spiders.html`, `/tarantulas.html`, and `/donate1.html` all 301
    correctly.
11. [ ] Orphan pages (`/donate`, `/internships`, `/mma`, `/live-bugs` + 4)
    reachable by direct URL, absent from nav.
12. [ ] `CHANGES.md` reviewed with the owner.

## Open items owned by the site owner

None blocking the build. Before/at deploy:

- Confirm Public Events listings are current vs. live (manual check at deploy).
- Supply the external Shop store URL (else placeholder ships).
- Confirm `donate` vs `donate1` is the canonical Donate page (implementation
  will propose one).

## Attribution

Commits: `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`.
