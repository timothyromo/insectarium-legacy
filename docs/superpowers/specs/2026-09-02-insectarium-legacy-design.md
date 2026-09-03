# Insectarium Legacy Replica — Design Spec

Date: 2026-09-02
Repo: `insectarium-legacy`
Status: approved design, pending implementation plan

## Purpose

Stand up a temporary "lift-and-shift" replica of the live Weebly site
`pdxinsectarium.org` on WordPress (DreamPress), so the org can move off Weebly
without waiting for the full rebuild happening in `insectarium-web`. This is a
faithful copy of the **current** site, not a redesign. It is expected to be
short-lived and eventually superseded by the `insectarium-web` build.

Explicit non-goals: no custom post types, no ACF, no page builder, no new
features, no IA changes, no visual redesign. Plain WordPress Pages only.

## Deliverable

Two artifacts, both version-controlled in this repo:

1. A custom theme, slug `insectarium-legacy`, under
   `wp-content/themes/insectarium-legacy/`.
2. A WP-CLI seed script under `scripts/`, run once over SSH on DreamPress after
   the theme is deployed, that creates every Page with its real content and
   builds the nav menu. Idempotent — safe to re-run to pick up content updates.

No WXR file. No hand-entry through wp-admin. DreamPress is assumed to be
standard single-site WordPress, current WP, PHP 8.x, no multisite, no
pre-installed page builder.

## Source-content constraint (important context)

The live site and its Weebly/Editmysite CDN are behind a Cloudflare bot
challenge; `curl` and the fetch tooling both get HTTP 403. The Wayback Machine
has a full 2026-06-06 snapshot but is rate-limiting hard and is not reachable
through the fetch tool. Lowering Cloudflare on the production site was
considered and rejected (real payment traffic, not worth the exposure for a
temporary build).

Consequences that shape this spec:

- Page content comes from `legacy-site-content-reference.md` (hand-compiled,
  partial) plus content the site owner relays directly.
- The real Weebly CSS and image assets cannot be retrieved right now. The theme
  ships a faithful **approximation** of the standard Weebly theme layout, to be
  refined from screenshots later. Only `assets/css/site.css` and the media
  library are affected by this; everything else is final.
- ~10–12 pages have no usable content yet and ship as visible
  "content coming soon" placeholders (see Page Inventory).

## Content / page inventory

Slugs are the old path minus `.html`.

### Real content available now (11)

| Page | Slug | Source status | Notes |
|---|---|---|---|
| Home | `/` (front-page) | partial | Old Weebly homepage layout, not the `insectarium-web` version. Must include the accessibility-survey callout. Body largely TODO. |
| About Us | `about-us` | full | Intro, history, residents table, Contact block, team bios (Red Armstrong bio cut off — TODO marker), press-mentions link list. |
| FAQ about the insectarium | `faq-about-the-insectarium` | partial | Hours/prices, masks, wheelchair access (cut off), handling fees (cut off). TODO markers inline. |
| FAQ about bugs | `faq-about-bugs` | partial | Oregon spiders Q&A, mantis-egg-case Q&A (cut off). More Q&A exists — TODO marker. |
| Calendar | `calendar` | full | Intro, cancellation policy, demonstration-schedule intro + full static demo list (legacy text version, deliberately kept), Google Calendar iframe embed, two images (`calendar-41_orig.png`, `calendar-42_orig.png`). |
| Admission | `admission` | full | Address, booking guidance, cancellation policy, two pricing tables (online / walk-in), notes, FareHarbor embed. |
| Memberships | `memberships` | partial | Purchase mechanics + price range only. Tier/benefit text is TODO. |
| Public Events | `public-events` | partial | "READ BEFORE PURCHASING" policy text, "Free Library Events" example. Current event listings are TODO (time-sensitive — owner to supply near build time). |
| Shop | `shop` | partial | Description of what's sold (digital downloads, donation product via Square, FareHarbor gift cards). Actual store markup TODO. |
| Services | `services` | full | Insect Pinning, Pet Bug Sitting, Tarantula Adoption Program (+ current adoptable list, flagged volatile), Tarantula Donation info. |
| Bug Club | `bug-club` | mostly full | Volunteer-law explanation, perks list (tail cut off), participation requirement (cut off). TODO markers. |

### Placeholder pages, awaiting content (10, +2 conditional)

Created as **published** pages with a visible "Content coming soon" line and an
HTML comment listing what the reference file says the page needs. Keeps nav
links from 404ing.

`hourslocation`, `summer-camp`, `private-events` (menu label "Events at the
Insectarium"), `off-site-events`, `photo-shoots`, `community`, `care-sheets`
(parent), `jumping-spiders`, `ghost-mantis`, `isopods`.

Conditional, pending owner confirmation they exist on live: `donate`,
`internships`. If created, they are published but **excluded from the nav menu**
until confirmed (Version A nav has neither).

### Care Sheets hierarchy

`care-sheets` is the parent Page. `jumping-spiders`, `ghost-mantis`, `isopods`
are children (`--post_parent` set by the seed script). This yields
`/care-sheets/jumping-spiders` style permalinks; the redirect list maps the old
flat `/jumping-spiders.html` URLs onto them.

## Navigation (Version A — confirmed structure)

One WP menu named `Primary`, assigned to theme location `primary`. Built by the
seed script.

- Home → front page
- **Info** (custom link `#`, group header)
  - About Us
  - FAQ about the insectarium
  - FAQ about bugs
- **Visit** (custom link `#`)
  - Calendar
  - Admission
  - Hours/Location
  - Summer Camp
  - Memberships
- Public Events → page
- **Private Events and Field Trips** (custom link `#`)
  - Events at the Insectarium (→ `private-events` page)
  - Off-site Events
  - Photo Shoots
- **Get Involved** (custom link `#`)
  - Bug Club
  - Community
- **Other** (custom link `#`)
  - Shop
  - Services
  - Care Sheets (→ `care-sheets` page)
    - Jumping Spiders
    - Ghost Mantis
    - Isopods

Group headers that are not real pages are `#` custom links (matches Weebly's
non-navigating parent behavior). Where a parent is also a real page (Care
Sheets, Events at the Insectarium) the parent item links to that page. The
theme's nav CSS must support the three-level nesting under Other → Care Sheets.

## Theme design

### File layout

```
wp-content/themes/insectarium-legacy/
  style.css                WordPress theme header + CSS reset / base typography
  functions.php            enqueue site.css + fonts, register 'primary' menu
                           location, add_image_size if needed, allow
                           unfiltered_html for administrators
  header.php               <head>, skip link, site logo, primary nav,
                           site-wide FareHarbor "Book Now" button (verbatim
                           Weebly markup)
  footer.php               footer content, wp_footer
  front-page.php           Home
  page.php                 all other pages; renders the_title() as <h1> then
                           the_content()
  index.php                fallback (required by WP)
  404.php                  simple 404
  assets/css/site.css      the replica stylesheet (approximation)
  assets/img/              logo, any structural images (populated later)
  assets/fonts/            self-hosted fonts (populated later)
  template-parts/          optional shared content blocks
```

No `functions.php` feature bloat: no widgets, no sidebars, no comments support,
no block patterns, no theme.json beyond what's needed to disable the block
editor's default wide/full styles from interfering.

### Styling approach (approximation)

Standard Weebly single-column theme conventions:

- Centered content column ~960–1000px, white on a light body background
- Top-of-page centered/left logo, horizontal primary nav below or beside it
- Pure-CSS hover/focus dropdown menus, three-level capable
- System/Google-ish font stack approximating Weebly defaults until real fonts
  are localized
- Page renders `<h1>` title + WYSIWYG content; tables get light borders to
  match the reference's pricing/residents tables
- Mobile: nav collapses to a simple toggled list; single column throughout

`site.css` is the only file expected to change materially when screenshots /
real CSS arrive.

### Embeds

Pasted verbatim into page content HTML, never wrapped or shortcode-d:

- FareHarbor booking embeds — full URL with tracking params where the reference
  provides it (Admission), simplified `?full-items=yes` form elsewhere as seen
  on live
- FareHarbor site-wide "Book Now" button — in `header.php` exactly as Weebly
  emits it
- Google Calendar iframe (Calendar page)
- Square Appointments embed (Private Events page, when content arrives)
- KIT mailing-list link (About page)

`unfiltered_html` for admins + creating posts as an admin user via WP-CLI
ensures none of this markup is stripped.

## Seed script design

```
scripts/
  seed.sh              orchestrator, run on DreamPress via SSH
  pages/<slug>.html    one hand-authored HTML body per page (content source of truth)
  menu.sh              builds the Primary menu (invoked by seed.sh)
  media-manifest.tsv   <original-url>\t<local-filename>  (for wp media import)
  redirects.txt        generated .htaccess redirect block, .html -> clean slug
```

### `seed.sh` behavior

- Bash, uses `wp` (WP-CLI). Fails fast (`set -euo pipefail`).
- Config vars at top: admin user login, site URL, theme slug.
- Activates the `insectarium-legacy` theme (`wp theme activate`).
- Sets permalink structure to `/%postname%/` and flushes rewrites.
- For each page: resolve by slug (`wp post list --post_type=page
  --name=<slug>`). If found, `wp post update`; else `wp post create`. Always
  `--post_status=publish`, `--post_author=<admin id>`, `--post_type=page`,
  `--post_content` from the matching `pages/<slug>.html`.
- Care Sheets children created after the parent, with `--post_parent=<id>`.
- Home: create/update the page holding old homepage content, then
  `wp option update show_on_front page` + `page_on_front` to that page's ID so
  `front-page.php` + the static front page both resolve.
- Media: for each row in `media-manifest.tsv`, `wp media import <url or local
  path> --porcelain`; the script tolerates missing sources (warn, continue)
  so it runs before assets are available.
- Calls `menu.sh`.
- Prints a summary table: page | slug | action taken | post ID | status.

### `menu.sh` behavior

- `wp menu create "Primary"` if absent (idempotent check first).
- `wp menu item add-post` for real-page items, `wp menu item add-custom` for
  `#` group headers, capturing returned IDs to set `--parent-id` for nesting.
- Rebuild strategy for idempotency: delete existing items on the Primary menu
  and re-add from scratch each run (simplest correct approach; menu is small).
- `wp menu location assign Primary primary`.

### URL compatibility

- Clean slugs (`/about-us`).
- `seed.sh` writes `scripts/redirects.txt` containing an Apache rewrite block
  mapping every old `/<slug>.html` (and the flat Care Sheet URLs) to the new
  clean path, 301. Site owner pastes it into DreamPress `.htaccess` above the
  WordPress block. Not auto-applied.

## Fixing broken things while replicating

In scope (the reference/live site's existing bugs):

- Dead "More Info" / "More info soon" links and placeholder text — remove, or
  point at the correct page where obvious.
- Broken internal links surfaced during content transcription.

Out of scope: any change that alters layout, copy tone, IA, or adds content not
on the live site. Livestock-status lists (adoptable tarantulas, demo schedule
dates, event listings) are copied as-is from the reference with an HTML comment
noting they are volatile and owner-owned.

Every deviation from live is logged in `CHANGES.md` at repo root.

## Testing / verification

No unit-test framework (theme + shell). Verification is:

1. `bash -n` on `seed.sh` and `menu.sh`; `shellcheck` clean.
2. Theme activates with no PHP notices (`wp` under `WP_DEBUG`).
3. Local or DreamPress-staging dry run of `seed.sh`: all pages created, summary
   table correct, re-run produces "updated" not "duplicate".
4. Manual page-by-page check against `legacy-site-content-reference.md`: every
   captured block present, every TODO marker where the reference notes a cutoff.
5. Nav renders the full Version A tree; three-level Care Sheets dropdown works
   on hover and keyboard focus.
6. Embeds present byte-for-byte (grep the rendered HTML for the FareHarbor /
   Google Calendar / Square strings).
7. `redirects.txt` covers every old `.html` URL.

## Open items owned by the site owner

- Confirm Version A nav is current (Bug Club evidence supports it).
- Confirm whether `donate.html` / `internships.html` exist on live.
- Supply content for the 10 placeholder pages + the partial-page cutoffs.
- Supply current Public Events listings near build time.
- Supply screenshots or saved CSS so `site.css` can be tightened to pixel-close.
- Supply / approve localized image + font assets.

## Attribution

Commits: `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`.
