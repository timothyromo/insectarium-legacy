# Insectarium Legacy Replica — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reproduce the live Weebly site `pdxinsectarium.org` as a temporary WordPress theme + a repeatable WP-CLI seed script, from the full Weebly export in `reference/`.

**Architecture:** A custom classic theme (`insectarium-legacy`) that vendors Weebly's real base CSS/fonts (from the still-open `editmysite.com` CDN) and this site's `main_style.css` (from the export), reproduces the Weebly page chrome (header, hardcoded Version A nav, footer) in PHP templates, and renders each page's extracted content HTML verbatim inside the same `.wsite-*` wrapper chain Weebly uses. A Python tool extracts per-page content fragments + a media manifest from the export; a Bash seed script imports the media and creates all 29 Pages (21 in-nav + 8 orphan) idempotently over SSH on DreamPress.

**Tech Stack:** WordPress (classic theme, PHP 8.x), WP-CLI, Bash, Python 3 (stdlib only), vendored Weebly CSS/JS assets. Local verification via `npx @wp-now/wp-now` (Node ≥ 20) or any local WordPress with `wp` CLI.

**Spec:** `docs/superpowers/specs/2026-09-02-insectarium-legacy-design.md` — read it alongside this plan.

## Global Constraints

- Theme slug / directory: `insectarium-legacy`. Theme name: `Insectarium Legacy`.
- No custom post types, no ACF, no page builder, no WooCommerce, no `register_nav_menus`, no widgets, no comments. Plain Pages only.
- Nav is **Version A**, hardcoded in the theme, exactly as in the export's `index.html` menu markup. Group headers (`Info`, `Visit`, `Private Events and Field Trips`, `Get involved`, `Other`) are non-clickable `<a>` with no `href`. Labels/casing verbatim: `About us`, `FAQ about the insectarium`, `FAQ about bugs`, `Off-site events`, `Photo shoots`, `Get involved`, `Care Sheets` (with a `<span class="wsite-menu-arrow">&gt;</span>`).
- Page slugs = old path minus `.html`. Care Sheet children nest under `care-sheets`; Live Bug children nest under `live-bugs`. Everything else is top-level.
- All FareHarbor / Google Calendar / Square / KIT embed markup is preserved **byte-for-byte**. The FareHarbor `https://fareharbor.com/embeds/api/v1/?autolightframe=yes` script is loaded once site-wide (renders the floating "Book Now" tab; there is no Book-Now button in the header markup).
- `the_content` runs with `wpautop` and `wptexturize` **removed** so content HTML is emitted unchanged.
- Pages are created via WP-CLI as an administrator (`--user=<admin>`) so embed markup is not KSES-stripped. Verify the host does not `define('DISALLOW_UNFILTERED_HTML', true)`.
- Every deviation from live (dead links removed, placeholder text, search form rewire, `donate1` dedupe, missing Shop store URL, stand-in logo) is appended to `CHANGES.md` at repo root.
- Attribution on every commit: `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`.
- The raw export under `reference/` stays git-ignored. Generated artifacts that DO get committed: `wp-content/themes/insectarium-legacy/assets/vendor/**`, `scripts/pages/*.html`, `scripts/media/*`, `scripts/media-manifest.tsv`.

### Canonical slug map (old file → WordPress path)

Used by the nav, the content-link rewriter, and the redirect generator.

```
index.html                          → /
about-us.html                       → /about-us
faq-about-the-insectarium.html      → /faq-about-the-insectarium
faq-about-bugs.html                 → /faq-about-bugs
calendar.html                       → /calendar
admission.html                      → /admission
hourslocation.html                  → /hourslocation
summer-camp.html                    → /summer-camp
memberships.html                    → /memberships
public-events.html                  → /public-events
private-events.html                 → /private-events
off-site-events.html                → /off-site-events
photo-shoots.html                   → /photo-shoots
bug-club.html                       → /bug-club
community.html                      → /community
shop.html                           → /shop
services.html                       → /services
care-sheets.html                    → /care-sheets
jumping-spiders.html                → /care-sheets/jumping-spiders
ghost-mantis.html                   → /care-sheets/ghost-mantis
isopods.html                        → /care-sheets/isopods
donate.html                         → /donate
donate1.html                        → /donate          (duplicate; redirect only)
internships.html                    → /internships
mma.html                            → /mma
live-bugs.html                      → /live-bugs
tarantulas.html                     → /live-bugs/tarantulas
scorpions.html                      → /live-bugs/scorpions
true-spiders.html                   → /live-bugs/true-spiders
other-arachnids.html                → /live-bugs/other-arachnids
info.html                           → /about-us        (Weebly stub; redirect only)
visit.html                          → /calendar        (Weebly stub; redirect only)
get-involved.html                   → /bug-club        (Weebly stub; redirect only)
other.html                          → /shop            (Weebly stub; redirect only)
private-events-and-field-trips.html → /private-events  (Weebly stub; redirect only)
home.html                           → /                (stale draft; redirect only)
home1.html                          → /                (stale draft; redirect only)
```

The 29 built pages are every row above **except** the 9 marked "redirect only".

### Page build order (parents before children)

```
home, about-us, faq-about-the-insectarium, faq-about-bugs, calendar, admission,
hourslocation, summer-camp, memberships, public-events, private-events,
off-site-events, photo-shoots, bug-club, community, shop, services,
care-sheets, jumping-spiders, ghost-mantis, isopods,
donate, internships, mma,
live-bugs, tarantulas, scorpions, true-spiders, other-arachnids
```

`home` maps to export file `index.html`; every other page's export file is `<slug>.html`.

---

## File Structure

```
.gitignore                                   reference/ + local junk
CHANGES.md                                   running deviations log
DEPLOY.md                                    DreamPress deploy runbook (Task 12)

tools/
  fetch-vendor.sh                            download Weebly CDN CSS/fonts into the theme
  extract.py                                 export HTML → scripts/pages/*.html + media manifest
  slugmap.py                                 the canonical slug map, imported by extract.py

wp-content/themes/insectarium-legacy/
  style.css                                  WP theme header (metadata only)
  functions.php                              enqueues, wpautop removal, title, content width
  header.php                                 <head>, .wrapper open, .cento-header + desktop nav
  footer.php                                 .footer-wrap, #navMobile, FareHarbor script, .wrapper close
  page.php                                   wrapper chain + the_content()
  front-page.php                             require page.php
  index.php                                  require page.php
  404.php                                    same chrome, "page not found"
  template-parts/site-nav.php                the <ul class="wsite-menu-default"> markup (shared)
  theme.css                                  our header/nav/footer/mobile rules only
  assets/js/nav.js                           dropdown + hamburger behaviour
  assets/img/                                logo + default section bg
  assets/vendor/sites.css                    Weebly base framework (CDN)
  assets/vendor/main_style.css               this site's theme layer (export)
  assets/vendor/fh-kit.css                   FareHarbor button CSS (CDN)
  assets/vendor/fonts/<name>/font.css + files

scripts/
  seed.sh                                    orchestrator (run on DreamPress via SSH)
  pages/<slug>.html                          29 extracted content fragments (committed)
  media/                                     referenced images copied from the export (committed)
  media-manifest.tsv                         media/<file> <TAB> @@MEDIA token path (committed)
  redirects.sample.txt                       committed example; seed.sh regenerates redirects.txt at runtime
```

---

## Task 1: Repo scaffold + vendor asset fetch

**Files:**
- Create: `.gitignore`, `CHANGES.md`
- Create: `tools/fetch-vendor.sh`
- Create (by running the script): `wp-content/themes/insectarium-legacy/assets/vendor/**`

**Interfaces:**
- Produces: `assets/vendor/sites.css`, `assets/vendor/main_style.css`, `assets/vendor/fh-kit.css`, `assets/vendor/fonts/{amaranth,montserrat,gentium-basic,open-sans}/font.css` (+ font files), all with URLs rewritten to theme-relative paths. Consumed by `functions.php` (Task 2).

- [ ] **Step 1: Create `.gitignore`**

```gitignore
/reference/
*.log
.DS_Store
Thumbs.db
/scripts/redirects.txt
/scripts/.pages-resolved/
/scripts/.media-map.sed
node_modules/
```

- [ ] **Step 2: Create `CHANGES.md`**

```markdown
# Deviations from the live site

Every change made while replicating `pdxinsectarium.org` that is not a
byte-for-byte copy of the export is logged here.

| # | Page / area | Change | Reason |
|---|---|---|---|
```

- [ ] **Step 3: Write `tools/fetch-vendor.sh`**

```bash
#!/usr/bin/env bash
# Download the Weebly base assets this site depends on (only the apex domain
# pdxinsectarium.org is Cloudflare-blocked; the editmysite.com / fh-kit.com
# CDNs are open). Rewrites font URLs to local paths. Idempotent.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR="$REPO_ROOT/wp-content/themes/insectarium-legacy/assets/vendor"
EXPORT_DIR="$REPO_ROOT/reference/13100960266a98c399e06d8"
UA='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0 Safari/537.36'

mkdir -p "$VENDOR/fonts"

echo "sites.css"
curl -fsSL -A "$UA" 'https://cdn11.editmysite.com/css/sites.css?buildtime=1234' -o "$VENDOR/sites.css"

echo "fh-kit.css"
curl -fsSL -A "$UA" 'https://fh-kit.com/buttons/v2/?pop=ae40a5' -o "$VENDOR/fh-kit.css"

echo "main_style.css (from export)"
cp "$EXPORT_DIR/files/main_style.css" "$VENDOR/main_style.css"

# Fonts: font.css lives at cdn2.editmysite.com/fonts/<Name>/font.css and
# references sibling files by relative url(./x). Download the css, then every
# file it names, into fonts/<slug>/, and rewrite url(./x) -> url(x).
fetch_font () {
  local name="$1" slug="$2"
  local base="https://cdn2.editmysite.com/fonts/${name}"
  local dir="$VENDOR/fonts/${slug}"
  mkdir -p "$dir"
  curl -fsSL -A "$UA" "${base}/font.css?2" -o "$dir/font.css"
  # collect referenced files (strip ./ and querystrings)
  grep -oE "url\(['\"]?\.?/?[A-Za-z0-9_.-]+\.(woff2|woff|ttf|eot|svg)" "$dir/font.css" \
    | sed -E "s/^url\(['\"]?\.?\/?//" | sort -u | while read -r f; do
      curl -fsSL -A "$UA" "${base}/${f}" -o "$dir/${f}" || echo "  WARN missing ${name}/${f}"
    done
  # rewrite references to bare local filenames
  sed -i -E "s#url\((['\"]?)\.?/?([A-Za-z0-9_.-]+\.(woff2|woff|ttf|eot|svg))#url(\1\2#g" "$dir/font.css"
}

fetch_font "Amaranth"      "amaranth"
fetch_font "Montserrat"    "montserrat"
fetch_font "Gentium_Basic" "gentium-basic"
fetch_font "Open_Sans"     "open-sans"

echo "done. vendored into $VENDOR"
```

- [ ] **Step 4: Run it**

Run: `bash tools/fetch-vendor.sh`
Expected: prints `sites.css`, `fh-kit.css`, `main_style.css (from export)`, each font name, then `done.`. No `curl: (22)` errors. `WARN missing` lines for `.svg`/`.eot` fallbacks are acceptable.

- [ ] **Step 5: Verify the vendored files**

Run:
```bash
ls -la wp-content/themes/insectarium-legacy/assets/vendor/
wc -c wp-content/themes/insectarium-legacy/assets/vendor/sites.css        # expect ~200000+
wc -c wp-content/themes/insectarium-legacy/assets/vendor/main_style.css   # expect ~37000
head -c 80 wp-content/themes/insectarium-legacy/assets/vendor/fonts/amaranth/font.css
grep -c 'url(' wp-content/themes/insectarium-legacy/assets/vendor/fonts/amaranth/font.css   # >= 1
grep -R 'cdn2.editmysite.com\|cdn11.editmysite.com' wp-content/themes/insectarium-legacy/assets/vendor/fonts/ || echo "no CDN refs left in font css — good"
```
Expected: `sites.css` > 200 KB, `main_style.css` ≈ 37 KB, each `fonts/<slug>/font.css` present with local `url(...)` refs and no `editmysite.com` left in the font CSS.

- [ ] **Step 6: Commit**

```bash
git add .gitignore CHANGES.md tools/fetch-vendor.sh wp-content/themes/insectarium-legacy/assets/vendor
git commit -m "Scaffold repo; vendor Weebly base CSS + fonts from the open CDN

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 2: Theme metadata, functions.php, index/404

**Files:**
- Create: `wp-content/themes/insectarium-legacy/style.css`
- Create: `wp-content/themes/insectarium-legacy/functions.php`
- Create: `wp-content/themes/insectarium-legacy/index.php`
- Create: `wp-content/themes/insectarium-legacy/page.php` (temporary stub; fleshed out in Task 5)
- Create: `wp-content/themes/insectarium-legacy/front-page.php`
- Create: `wp-content/themes/insectarium-legacy/404.php` (temporary stub; fleshed out in Task 5)

**Interfaces:**
- Produces: enqueue handles `il-sites`, `il-main-style`, `il-fh-kit`, `il-fonts`, `il-theme`, `il-nav` (CSS/JS), loaded in that order on every front-end view. `functions.php` defines no PHP functions other tasks call except `il_asset( $rel )` returning `get_template_directory_uri() . '/' . ltrim($rel,'/')`.

- [ ] **Step 1: Write `style.css`**

```css
/*
Theme Name: Insectarium Legacy
Theme URI: https://www.pdxinsectarium.org/
Description: Temporary lift-and-shift replica of the pre-WordPress Weebly site. Not the long-term theme.
Version: 1.0.0
Requires at least: 6.0
Requires PHP: 8.0
Text Domain: insectarium-legacy
*/
```

- [ ] **Step 2: Write `functions.php`**

```php
<?php
/**
 * Insectarium Legacy — temporary Weebly replica theme.
 *
 * Loads the vendored Weebly base CSS + this site's theme CSS, then our small
 * chrome layer. No menus, widgets, or comments. Content is pre-formatted HTML,
 * so wpautop/wptexturize are disabled to keep it byte-exact.
 */

if ( ! defined( 'ABSPATH' ) ) { exit; }

if ( ! isset( $content_width ) ) {
	$content_width = 1140;
}

function il_asset( $rel ) {
	return get_template_directory_uri() . '/' . ltrim( $rel, '/' );
}

function il_theme_setup() {
	add_theme_support( 'title-tag' );
	add_theme_support( 'automatic-feed-links' );
	// Deliberately NOT adding: post-thumbnails UI, custom-logo, editor-styles,
	// align-wide, responsive-embeds. This theme renders raw imported HTML.
}
add_action( 'after_setup_theme', 'il_theme_setup' );

function il_enqueue_assets() {
	$ver = wp_get_theme()->get( 'Version' );

	wp_enqueue_style( 'il-fonts',      il_asset( 'assets/vendor/fonts/amaranth/font.css' ),   array(), $ver );
	wp_enqueue_style( 'il-fonts-mont', il_asset( 'assets/vendor/fonts/montserrat/font.css' ), array(), $ver );
	wp_enqueue_style( 'il-fonts-gent', il_asset( 'assets/vendor/fonts/gentium-basic/font.css' ), array(), $ver );
	wp_enqueue_style( 'il-fonts-os',   il_asset( 'assets/vendor/fonts/open-sans/font.css' ),  array(), $ver );

	wp_enqueue_style( 'il-sites',      il_asset( 'assets/vendor/sites.css' ),      array( 'il-fonts' ), $ver );
	wp_enqueue_style( 'il-main-style', il_asset( 'assets/vendor/main_style.css' ), array( 'il-sites' ), $ver );
	wp_enqueue_style( 'il-fh-kit',     il_asset( 'assets/vendor/fh-kit.css' ),     array( 'il-main-style' ), $ver );
	wp_enqueue_style( 'il-theme',      il_asset( 'theme.css' ),                    array( 'il-fh-kit' ), $ver );

	wp_enqueue_script( 'il-nav', il_asset( 'assets/js/nav.js' ), array(), $ver, true );
}
add_action( 'wp_enqueue_scripts', 'il_enqueue_assets' );

// Content is imported, pre-formatted HTML — emit it unchanged.
remove_filter( 'the_content', 'wpautop' );
remove_filter( 'the_content', 'wptexturize' );
remove_filter( 'the_excerpt', 'wpautop' );

// Kill block-library front-end CSS (this is a classic theme; imported content
// carries its own styles).
function il_dequeue_block_css() {
	wp_dequeue_style( 'wp-block-library' );
	wp_dequeue_style( 'wp-block-library-theme' );
	wp_dequeue_style( 'global-styles' );
	wp_dequeue_style( 'classic-theme-styles' );
}
add_action( 'wp_enqueue_scripts', 'il_dequeue_block_css', 100 );

// Document title: "<Page> - PORTLAND INSECTARIUM" (matches the export).
function il_document_title( $parts ) {
	if ( is_front_page() ) {
		$parts['title'] = 'Portland Insectarium';
	}
	$parts['site']    = 'PORTLAND INSECTARIUM';
	$parts['tagline'] = '';
	return $parts;
}
add_filter( 'document_title_parts', 'il_document_title' );
add_filter( 'document_title_separator', function () { return '-'; } );
```

- [ ] **Step 3: Write `index.php`, `front-page.php`**

`index.php`:
```php
<?php require __DIR__ . '/page.php';
```

`front-page.php`:
```php
<?php require __DIR__ . '/page.php';
```

- [ ] **Step 4: Write temporary `page.php` and `404.php` stubs**

`page.php` (replaced in Task 5 — this stub only lets the theme activate):
```php
<?php get_header(); ?>
<div class="main-wrap">
	<div id="wsite-content" class="wsite-elements wsite-not-footer">
		<?php while ( have_posts() ) : the_post(); the_content(); endwhile; ?>
	</div>
</div>
<?php get_footer();
```

`404.php` (replaced in Task 5):
```php
<?php get_header(); ?>
<div class="main-wrap">
	<div id="wsite-content" class="wsite-elements wsite-not-footer">
		<div class="container"><p>Page not found. <a href="<?php echo esc_url( home_url( '/' ) ); ?>">Return home</a>.</p></div>
	</div>
</div>
<?php get_footer();
```

- [ ] **Step 5: Lint all PHP**

Run: `for f in wp-content/themes/insectarium-legacy/*.php; do php -l "$f"; done`
Expected: `No syntax errors detected` for every file.

- [ ] **Step 6: Commit**

```bash
git add wp-content/themes/insectarium-legacy/
git commit -m "Theme metadata, functions.php enqueues, index/front-page/404 stubs

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 3: Shared nav markup + header.php

**Files:**
- Create: `wp-content/themes/insectarium-legacy/template-parts/site-nav.php`
- Create: `wp-content/themes/insectarium-legacy/header.php`
- Create: `wp-content/themes/insectarium-legacy/assets/img/insectarium-logo-1.png` (stand-in — see Step 3)

**Interfaces:**
- Consumes: `il_asset()` (Task 2).
- Produces: `get_header()` renders `<!doctype html>` … `<div class="wrapper"><div class="cento-header">…desktop nav…</div>` and leaves `.wrapper` open for the footer to close. `template-parts/site-nav.php` echoes the `<ul class="wsite-menu-default">…</ul>` used by both header and footer (Task 4).

- [ ] **Step 1: Write `template-parts/site-nav.php`**

This is the export's menu markup verbatim, with `href`s swapped to the canonical slug map and Weebly `id="pg…"` attributes dropped. Non-clickable parents keep `<a class="wsite-menu-item">` with no `href`.

```php
<?php
/**
 * Version A primary navigation — hardcoded, matches the export's index.html.
 * Shared by header.php (desktop) and footer.php (#navMobile).
 */
if ( ! defined( 'ABSPATH' ) ) { exit; }
$home = esc_url( home_url( '/' ) );
?>
<ul class="wsite-menu-default">
	<li class="wsite-menu-item-wrap"><a href="<?php echo $home; ?>" class="wsite-menu-item">Home</a></li>

	<li class="wsite-menu-item-wrap">
		<a class="wsite-menu-item">Info</a>
		<div class="wsite-menu-wrap"><ul class="wsite-menu">
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>about-us" class="wsite-menu-subitem"><span class="wsite-menu-title">About us</span></a></li>
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>faq-about-the-insectarium" class="wsite-menu-subitem"><span class="wsite-menu-title">FAQ about the insectarium</span></a></li>
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>faq-about-bugs" class="wsite-menu-subitem"><span class="wsite-menu-title">FAQ about bugs</span></a></li>
		</ul></div>
	</li>

	<li class="wsite-menu-item-wrap">
		<a class="wsite-menu-item">Visit</a>
		<div class="wsite-menu-wrap"><ul class="wsite-menu">
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>calendar" class="wsite-menu-subitem"><span class="wsite-menu-title">Calendar</span></a></li>
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>admission" class="wsite-menu-subitem"><span class="wsite-menu-title">Admission</span></a></li>
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>hourslocation" class="wsite-menu-subitem"><span class="wsite-menu-title">Hours/Location</span></a></li>
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>summer-camp" class="wsite-menu-subitem"><span class="wsite-menu-title">Summer Camp</span></a></li>
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>memberships" class="wsite-menu-subitem"><span class="wsite-menu-title">Memberships</span></a></li>
		</ul></div>
	</li>

	<li class="wsite-menu-item-wrap"><a href="<?php echo $home; ?>public-events" class="wsite-menu-item">Public Events</a></li>

	<li class="wsite-menu-item-wrap">
		<a class="wsite-menu-item">Private Events and Field Trips</a>
		<div class="wsite-menu-wrap"><ul class="wsite-menu">
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>private-events" class="wsite-menu-subitem"><span class="wsite-menu-title">Events at the Insectarium</span></a></li>
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>off-site-events" class="wsite-menu-subitem"><span class="wsite-menu-title">Off-site events</span></a></li>
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>photo-shoots" class="wsite-menu-subitem"><span class="wsite-menu-title">Photo shoots</span></a></li>
		</ul></div>
	</li>

	<li class="wsite-menu-item-wrap">
		<a class="wsite-menu-item">Get involved</a>
		<div class="wsite-menu-wrap"><ul class="wsite-menu">
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>bug-club" class="wsite-menu-subitem"><span class="wsite-menu-title">Bug Club</span></a></li>
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>community" class="wsite-menu-subitem"><span class="wsite-menu-title">Community</span></a></li>
		</ul></div>
	</li>

	<li class="wsite-menu-item-wrap">
		<a class="wsite-menu-item">Other</a>
		<div class="wsite-menu-wrap"><ul class="wsite-menu">
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>shop" class="wsite-menu-subitem"><span class="wsite-menu-title">Shop</span></a></li>
			<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>services" class="wsite-menu-subitem"><span class="wsite-menu-title">Services</span></a></li>
			<li class="wsite-menu-subitem-wrap">
				<a href="<?php echo $home; ?>care-sheets" class="wsite-menu-subitem"><span class="wsite-menu-title">Care Sheets</span><span class="wsite-menu-arrow">&gt;</span></a>
				<div class="wsite-menu-wrap"><ul class="wsite-menu">
					<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>care-sheets/jumping-spiders" class="wsite-menu-subitem"><span class="wsite-menu-title">Jumping Spiders</span></a></li>
					<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>care-sheets/ghost-mantis" class="wsite-menu-subitem"><span class="wsite-menu-title">Ghost Mantis</span></a></li>
					<li class="wsite-menu-subitem-wrap"><a href="<?php echo $home; ?>care-sheets/isopods" class="wsite-menu-subitem"><span class="wsite-menu-title">Isopods</span></a></li>
				</ul></div>
			</li>
		</ul></div>
	</li>
</ul>
```

- [ ] **Step 2: Write `header.php`**

```php
<?php
if ( ! defined( 'ABSPATH' ) ) { exit; }
?><!doctype html>
<html <?php language_attributes(); ?>>
<head>
	<meta charset="<?php bloginfo( 'charset' ); ?>" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />
	<meta name="description" content="Portland's first zoo and museum dedicated entirely to insects and arachnids!" />
	<meta name="keywords" content="insects, museum, travel, bugs, arachnids, spiders, beetles, bug zoo, crawlers, flies, wings, tentacles, ants, butterflies, moths, caterpillar" />
	<?php wp_head(); ?>
</head>
<body <?php body_class(); ?>>
<?php wp_body_open(); ?>
<div class="wrapper">
	<div class="cento-header">
		<div class="nav-wrap">
			<div class="container">
				<a class="hamburger" aria-label="Menu" href="#"><span></span></a>
				<div class="logo">
					<span class="wsite-logo">
						<a href="<?php echo esc_url( home_url( '/' ) ); ?>">
							<img src="<?php echo esc_url( il_asset( 'assets/img/insectarium-logo-1.png' ) ); ?>" alt="PORTLAND INSECTARIUM" />
						</a>
					</span>
				</div>
				<div class="nav desktop-nav">
					<div class="container">
						<?php require get_template_directory() . '/template-parts/site-nav.php'; ?>
					</div>
				</div>
			</div>
		</div>
	</div>
	<div class="main-wrap">
```

Note: `header.php` opens `.wrapper` **and** `.main-wrap`; `footer.php` (Task 4) closes `.main-wrap` before the footer and `.wrapper` at the end. `page.php` (Task 5) opens `#wsite-content` inside `.main-wrap`.

- [ ] **Step 3: Provide a stand-in logo**

The Weebly export omits `uploads/8/1/3/7/81376966/published/insectarium-logo-1.png` and it is not fetchable (apex is Cloudflare-blocked, CDN returns 404). Use a sibling-repo copy as a stand-in and flag it:

```bash
cp ../bug-trivia/admin/public/assets/images/insectarium-logo.png \
   wp-content/themes/insectarium-legacy/assets/img/insectarium-logo-1.png
```

Append to `CHANGES.md`:
```
| N | Header | Logo image is a stand-in from bug-trivia repo | Real Weebly header logo (`insectarium-logo-1.png`) not in export, apex domain blocked. Owner to supply exact file. |
```

- [ ] **Step 4: Lint**

Run: `php -l wp-content/themes/insectarium-legacy/header.php && php -l wp-content/themes/insectarium-legacy/template-parts/site-nav.php`
Expected: `No syntax errors detected` for both.

- [ ] **Step 5: Grep the rendered nav (static check)**

Run:
```bash
php -r 'define("ABSPATH",1); function esc_url($s){return $s;} function home_url($p=""){return "/".ltrim($p,"/");} require "wp-content/themes/insectarium-legacy/template-parts/site-nav.php";' > /tmp/il-nav.html
grep -c 'wsite-menu-subitem-wrap' /tmp/il-nav.html    # expect 19
grep -c 'wsite-menu-item-wrap'    /tmp/il-nav.html    # expect 7  (Home + 6 top groups)
grep -c 'wsite-menu-arrow'        /tmp/il-nav.html    # expect 1  (Care Sheets)
grep -o 'href="[^"]*"' /tmp/il-nav.html | sort -u     # every href is "/" or a clean slug, none ending .html
```
Expected: 19 subitems (About us, 2× FAQ, Calendar, Admission, Hours/Location, Summer Camp, Memberships, Events at the Insectarium, Off-site events, Photo shoots, Bug Club, Community, Shop, Services, Care Sheets, + Jumping Spiders, Ghost Mantis, Isopods); 7 top-level item wraps; 1 arrow; no `.html` hrefs.

- [ ] **Step 6: Commit**

```bash
git add wp-content/themes/insectarium-legacy/ CHANGES.md
git commit -m "header.php + shared Version A nav markup + stand-in logo

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 4: footer.php, mobile nav, nav.js, theme.css

**Files:**
- Create: `wp-content/themes/insectarium-legacy/footer.php`
- Create: `wp-content/themes/insectarium-legacy/assets/js/nav.js`
- Create: `wp-content/themes/insectarium-legacy/theme.css`

**Interfaces:**
- Consumes: `template-parts/site-nav.php`, `il_asset()`.
- Produces: `get_footer()` closes `.main-wrap`, renders `.footer-wrap` + `#navMobile` + the FareHarbor `autolightframe` script, calls `wp_footer()`, closes `.wrapper`. `nav.js` toggles `body.mobile-nav-open` and, on touch, `.wsite-menu-item-wrap.open`.

- [ ] **Step 1: Write `footer.php`**

```php
<?php
if ( ! defined( 'ABSPATH' ) ) { exit; }
?>
	</div><!-- /.main-wrap -->

	<div class="footer-wrap">
		<div class="footer">
			<div class="wsite-elements wsite-footer">
				<div class="wsite-search-element-outer">
					<div class="wsite-search-element-align-center" style="padding: 10px 0 10px 0">
						<form class="wsite-search-element-form" action="<?php echo esc_url( home_url( '/' ) ); ?>" method="get">
							<div class="wsite-search-element">
								<input class="wsite-input wsite-search-element-input" type="text" name="s" placeholder="Search" autocomplete="off" aria-label="Search" />
								<button class="wsite-search-element-submit" title="Search" type="submit"></button>
							</div>
						</form>
					</div>
				</div>
				<div class="paragraph" style="text-align:center;">
					<span style="color:rgb(42, 42, 42); font-weight:400">&#8203;&copy;2018 Portland Insectarium</span>
				</div>
			</div>
		</div>
	</div>

	<div id="navMobile" class="nav mobile-nav">
		<a class="hamburger" aria-label="Menu" href="#"><span></span></a>
		<?php require get_template_directory() . '/template-parts/site-nav.php'; ?>
	</div>

</div><!-- /.wrapper -->

<script src="https://fareharbor.com/embeds/api/v1/?autolightframe=yes"></script>
<?php wp_footer(); ?>
</body>
</html>
```

The search `<form>` `action`/`name` are changed from Weebly's dead `/apps/search`+`q` to WordPress search (`home_url('/')` + `s`). Log it:
```
| N | Footer | Search form rewired from /apps/search?q= to WP search (?s=) | Weebly search endpoint does not exist on WordPress. |
```

- [ ] **Step 2: Write `assets/js/nav.js`**

```js
/* Insectarium Legacy — minimal nav behaviour. Weebly's main.js is not loaded. */
(function () {
	'use strict';

	// Mobile: hamburger toggles the slide-in menu.
	document.addEventListener('click', function (e) {
		var burger = e.target.closest('.hamburger');
		if (burger) {
			e.preventDefault();
			document.body.classList.toggle('mobile-nav-open');
			return;
		}
		// Touch / no-hover: tapping a parent item with a submenu opens it
		// instead of navigating (parent <a> has no href).
		var parentLink = e.target.closest('.mobile-nav .wsite-menu-item, .mobile-nav .wsite-menu-subitem');
		if (parentLink && parentLink.parentNode.querySelector('.wsite-menu-wrap')) {
			if (!parentLink.getAttribute('href')) {
				e.preventDefault();
				parentLink.parentNode.classList.toggle('open');
			}
		}
	});

	// Close mobile menu on resize up to desktop.
	var mq = window.matchMedia('(min-width: 768px)');
	mq.addEventListener('change', function (ev) {
		if (ev.matches) { document.body.classList.remove('mobile-nav-open'); }
	});
})();
```

- [ ] **Step 3: Write `theme.css`**

Base layout (grid, `.container`, `.wsite-section`) comes from vendored `sites.css` + `main_style.css`. This file only covers the header/nav/footer chrome and the desktop dropdown reveal (Weebly did that in JS; we do it in CSS).

```css
/* ---- Header ---- */
.cento-header { background: #fff; }
.cento-header .nav-wrap > .container { display: flex; align-items: center; justify-content: space-between; flex-wrap: wrap; }
.cento-header .logo img { display: block; max-height: 90px; width: auto; }
.cento-header .hamburger { display: none; }

/* ---- Desktop nav ---- */
.desktop-nav .wsite-menu-default { display: flex; list-style: none; margin: 0; padding: 0; flex-wrap: wrap; }
.desktop-nav .wsite-menu-default > li { position: relative; }
.desktop-nav .wsite-menu-item,
.desktop-nav .wsite-menu-subitem { display: block; padding: 10px 14px; text-decoration: none; white-space: nowrap; }
.desktop-nav .wsite-menu-item-wrap > a:not([href]) { cursor: default; }

.desktop-nav .wsite-menu-wrap { position: absolute; left: 0; top: 100%; min-width: 220px; background: #fff; box-shadow: 0 2px 8px rgba(0,0,0,.15); display: none; z-index: 100; }
.desktop-nav li:hover > .wsite-menu-wrap,
.desktop-nav li:focus-within > .wsite-menu-wrap { display: block; }
.desktop-nav .wsite-menu { list-style: none; margin: 0; padding: 0; }
.desktop-nav .wsite-menu .wsite-menu-wrap { left: 100%; top: 0; }  /* third level: Care Sheets */
.desktop-nav .wsite-menu-arrow { margin-left: 6px; }

/* ---- Mobile nav ---- */
.mobile-nav { display: none; }
@media (max-width: 767px) {
	.desktop-nav { display: none; }
	.cento-header .hamburger { display: inline-block; }
	.mobile-nav { display: block; position: fixed; top: 0; right: 0; bottom: 0; width: 80%; max-width: 320px;
		background: #fff; transform: translateX(100%); transition: transform .2s ease; overflow-y: auto; z-index: 999; }
	body.mobile-nav-open .mobile-nav { transform: translateX(0); }
	.mobile-nav .wsite-menu-default,
	.mobile-nav .wsite-menu { list-style: none; margin: 0; padding: 0; }
	.mobile-nav .wsite-menu-item,
	.mobile-nav .wsite-menu-subitem { display: block; padding: 12px 16px; text-decoration: none; border-bottom: 1px solid #eee; }
	.mobile-nav .wsite-menu-wrap { display: none; padding-left: 12px; }
	.mobile-nav .wsite-menu-item-wrap.open > .wsite-menu-wrap,
	.mobile-nav .wsite-menu-subitem-wrap.open > .wsite-menu-wrap { display: block; }
}

/* ---- Footer ---- */
.footer-wrap { margin-top: 40px; }
.footer .wsite-search-element-form { text-align: center; }
.footer .wsite-search-element-input { padding: 6px 10px; }
```

- [ ] **Step 4: Lint**

Run: `php -l wp-content/themes/insectarium-legacy/footer.php`
Expected: `No syntax errors detected`.

Run: `node --check wp-content/themes/insectarium-legacy/assets/js/nav.js`
Expected: no output (valid). If Node unavailable, skip — it is checked live in Task 10.

- [ ] **Step 5: Commit**

```bash
git add wp-content/themes/insectarium-legacy/ CHANGES.md
git commit -m "footer.php, mobile nav, nav.js, chrome CSS

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 5: page.php / front-page.php / 404.php final

**Files:**
- Modify: `wp-content/themes/insectarium-legacy/page.php` (replace the Task 2 stub)
- Modify: `wp-content/themes/insectarium-legacy/404.php` (replace the Task 2 stub)

**Interfaces:**
- Consumes: `get_header()` leaves `.wrapper > .main-wrap` open; `get_footer()` closes `.main-wrap` then `.wrapper`.
- Produces: the `#wsite-content` wrapper chain that the vendored CSS targets. `front-page.php` and `index.php` already `require page.php` (Task 2) — no change.

- [ ] **Step 1: Write final `page.php`**

The wrapper chain mirrors the export: `#wsite-content.wsite-elements.wsite-not-footer` is the only fixed wrapper; each imported fragment already begins with its own `<style>` block and `.wsite-section-wrap` / `.wsite-section` (with the page's background-image inline style) as extracted in Task 6.

```php
<?php
if ( ! defined( 'ABSPATH' ) ) { exit; }
get_header();
?>
<div id="wsite-content" class="wsite-elements wsite-not-footer">
	<?php
	while ( have_posts() ) :
		the_post();
		the_content();
	endwhile;
	?>
</div>
<?php
get_footer();
```

- [ ] **Step 2: Write final `404.php`**

```php
<?php
if ( ! defined( 'ABSPATH' ) ) { exit; }
get_header();
?>
<div id="wsite-content" class="wsite-elements wsite-not-footer">
	<div class="wsite-section-wrap">
		<div class="wsite-section wsite-body-section">
			<div class="wsite-section-content"><div class="container"><div class="wsite-section-elements">
				<div class="paragraph" style="text-align:center;">
					<h2>Page not found</h2>
					<p>Try the menu above, or <a href="<?php echo esc_url( home_url( '/' ) ); ?>">return to the home page</a>.</p>
				</div>
			</div></div></div>
		</div>
	</div>
</div>
<?php
get_footer();
```

- [ ] **Step 3: Lint**

Run: `for f in page.php front-page.php index.php 404.php; do php -l "wp-content/themes/insectarium-legacy/$f"; done`
Expected: `No syntax errors detected` ×4.

- [ ] **Step 4: Commit**

```bash
git add wp-content/themes/insectarium-legacy/page.php wp-content/themes/insectarium-legacy/404.php
git commit -m "Final page.php / 404.php wrapper chain

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 6: Content extraction tool

**Files:**
- Create: `tools/slugmap.py`
- Create: `tools/extract.py`
- Create (by running): `scripts/pages/*.html` (29), `scripts/media/*`, `scripts/media-manifest.tsv`, `scripts/pages/_report.txt`

**Interfaces:**
- Consumes: `reference/13100960266a98c399e06d8/<file>.html`.
- Produces: for each of the 29 build slugs, `scripts/pages/<slug>.html` = the page-specific `<style>` block(s) + the inner HTML of `<div id="wsite-content" …>`, with: internal `*.html` links rewritten via the slug map; every `uploads/…` / `files/theme/files/images/…` reference (in `src=`, `href=`, `srcset=`, and CSS `url(...)`) rewritten to a `@@MEDIA:<path>@@` token; `<script>` tags and Weebly editor `data-*`/empty app-mount cruft removed; embeds untouched. Referenced media copied into `scripts/media/` (flattened names) with `scripts/media-manifest.tsv` mapping `media/<file>` → `@@MEDIA:<original path>@@`. `_report.txt` lists dead "More Info" links and "More info soon" strings for Task 7.

- [ ] **Step 1: Write `tools/slugmap.py`**

```python
"""Canonical old-file -> WordPress-path map. Imported by extract.py and (via a
generated file) by seed.sh."""

# slug -> (export filename, wp path, parent slug or None)
PAGES = {
    "home":        ("index.html",                          "/",                              None),
    "about-us":    ("about-us.html",                        "/about-us",                      None),
    "faq-about-the-insectarium": ("faq-about-the-insectarium.html", "/faq-about-the-insectarium", None),
    "faq-about-bugs": ("faq-about-bugs.html",               "/faq-about-bugs",                None),
    "calendar":    ("calendar.html",                        "/calendar",                      None),
    "admission":   ("admission.html",                       "/admission",                     None),
    "hourslocation": ("hourslocation.html",                 "/hourslocation",                 None),
    "summer-camp": ("summer-camp.html",                     "/summer-camp",                   None),
    "memberships": ("memberships.html",                     "/memberships",                   None),
    "public-events": ("public-events.html",                 "/public-events",                 None),
    "private-events": ("private-events.html",               "/private-events",                None),
    "off-site-events": ("off-site-events.html",             "/off-site-events",               None),
    "photo-shoots": ("photo-shoots.html",                   "/photo-shoots",                  None),
    "bug-club":    ("bug-club.html",                        "/bug-club",                      None),
    "community":   ("community.html",                       "/community",                     None),
    "shop":        ("shop.html",                            "/shop",                          None),
    "services":    ("services.html",                        "/services",                      None),
    "care-sheets": ("care-sheets.html",                     "/care-sheets",                   None),
    "jumping-spiders": ("jumping-spiders.html",             "/care-sheets/jumping-spiders",   "care-sheets"),
    "ghost-mantis": ("ghost-mantis.html",                   "/care-sheets/ghost-mantis",      "care-sheets"),
    "isopods":     ("isopods.html",                         "/care-sheets/isopods",           "care-sheets"),
    "donate":      ("donate.html",                          "/donate",                        None),
    "internships": ("internships.html",                     "/internships",                   None),
    "mma":         ("mma.html",                             "/mma",                           None),
    "live-bugs":   ("live-bugs.html",                       "/live-bugs",                     None),
    "tarantulas":  ("tarantulas.html",                      "/live-bugs/tarantulas",          "live-bugs"),
    "scorpions":   ("scorpions.html",                       "/live-bugs/scorpions",           "live-bugs"),
    "true-spiders": ("true-spiders.html",                   "/live-bugs/true-spiders",        "live-bugs"),
    "other-arachnids": ("other-arachnids.html",             "/live-bugs/other-arachnids",     "live-bugs"),
}

BUILD_ORDER = [
    "home", "about-us", "faq-about-the-insectarium", "faq-about-bugs", "calendar",
    "admission", "hourslocation", "summer-camp", "memberships", "public-events",
    "private-events", "off-site-events", "photo-shoots", "bug-club", "community",
    "shop", "services", "care-sheets", "jumping-spiders", "ghost-mantis", "isopods",
    "donate", "internships", "mma", "live-bugs", "tarantulas", "scorpions",
    "true-spiders", "other-arachnids",
]

# extra redirect-only sources (old file -> wp path)
REDIRECT_ONLY = {
    "donate1.html": "/donate",
    "info.html": "/about-us",
    "visit.html": "/calendar",
    "get-involved.html": "/bug-club",
    "other.html": "/shop",
    "private-events-and-field-trips.html": "/private-events",
    "home.html": "/",
    "home1.html": "/",
}

def html_to_path(name):
    """foo.html (any of the known files) -> wp path, or None if unknown."""
    name = name.strip().lstrip("/").split("?")[0].split("#")[0]
    for slug, (fn, path, _parent) in PAGES.items():
        if fn == name:
            return path
    return REDIRECT_ONLY.get(name)
```

- [ ] **Step 2: Write `tools/extract.py`**

```python
#!/usr/bin/env python3
"""Extract per-page content fragments + media manifest from the Weebly export.

Output:
  scripts/pages/<slug>.html      content fragment (style block + #wsite-content inner)
  scripts/media/<flat-name>      every referenced upload/theme image
  scripts/media-manifest.tsv     media/<flat-name>\t@@MEDIA:<original path>@@
  scripts/pages/_report.txt      dead-link / placeholder findings for manual fixup
"""
import html
import os
import re
import shutil
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from slugmap import PAGES, BUILD_ORDER, html_to_path  # noqa: E402

REPO = os.path.dirname(HERE)
EXPORT = os.path.join(REPO, "reference", "13100960266a98c399e06d8")
PAGES_OUT = os.path.join(REPO, "scripts", "pages")
MEDIA_OUT = os.path.join(REPO, "scripts", "media")
MANIFEST = os.path.join(REPO, "scripts", "media-manifest.tsv")
REPORT = os.path.join(PAGES_OUT, "_report.txt")

# original export asset path -> @@MEDIA token; also records the on-disk source.
media_map = {}   # original_path -> flat_name
report_lines = []


def find_source_on_disk(orig):
    """Map a referenced path like
    uploads/8/1/3/7/81376966/background-images/1434191316.jpg
    to a real file in the export (the export double-nests background-images/)."""
    candidates = [orig]
    if "/background-images/" in orig and "/background-images/background-images/" not in orig:
        candidates.append(orig.replace("/background-images/", "/background-images/background-images/"))
    for c in candidates:
        p = os.path.join(EXPORT, c)
        if os.path.isfile(p):
            return p
    return None


def flat_name(orig):
    return re.sub(r"[^A-Za-z0-9._-]", "_", orig.lstrip("/"))


ASSET_RE = re.compile(
    r"""(?P<pre>(?:src|href|data-src)\s*=\s*["']|url\(\s*["']?)"""
    r"""(?P<url>(?:https?://(?:www\.)?pdxinsectarium\.org/)?/?(?:uploads|files/theme/files/images)/[^"')\s]+)""",
    re.I,
)


def tokenize_assets(text):
    def repl(m):
        raw = m.group("url")
        orig = re.sub(r"^https?://(?:www\.)?pdxinsectarium\.org/", "", raw).lstrip("/")
        orig = html.unescape(orig).split("?")[0]
        src = find_source_on_disk(orig)
        if src is None:
            report_lines.append(f"MISSING ASSET: {orig}")
            return m.group(0)
        fn = flat_name(orig)
        media_map[orig] = fn
        return f"{m.group('pre')}@@MEDIA:{orig}@@"
    return ASSET_RE.sub(repl, text)


LINK_RE = re.compile(r'href\s*=\s*(["\'])(?P<u>[^"\']+)\1', re.I)


def rewrite_links(text):
    def repl(m):
        u = m.group("u")
        bare = re.sub(r"^https?://(?:www\.)?pdxinsectarium\.org/", "", u)
        if bare.lower().endswith(".html") or bare.split("#")[0].lower().endswith(".html"):
            path = html_to_path(bare)
            if path:
                frag = ""
                if "#" in bare:
                    frag = "#" + bare.split("#", 1)[1]
                return f'href={m.group(1)}{path}{frag}{m.group(1)}'
            report_lines.append(f"UNMAPPED LINK: {u}")
        return m.group(0)
    return LINK_RE.sub(repl, text)


def strip_cruft(text):
    text = re.sub(r"<script\b[^>]*>.*?</script>", "", text, flags=re.S | re.I)
    text = re.sub(r"<noscript\b[^>]*>.*?</noscript>", "", text, flags=re.S | re.I)
    # Weebly editor bookkeeping attributes (safe to drop; never on embeds)
    text = re.sub(r'\s+data-(?:element-type|node-type|editor[\w-]*|rte[\w-]*|widget[\w-]*)="[^"]*"', "", text, flags=re.I)
    # empty store/app mount points that will never hydrate
    text = re.sub(r'<div id="wsite-com-[^"]*"[^>]*>\s*</div>', "", text, flags=re.I)
    return text


def flag_placeholders(slug, text):
    for m in re.finditer(r".{0,40}(More Info soon|More info soon|More Info Soon|coming soon).{0,40}", text, re.I):
        snippet = re.sub(r"\s+", " ", m.group(0))
        report_lines.append(f"PLACEHOLDER [{slug}]: …{snippet}…")
    for m in re.finditer(r'<a\b[^>]*href=(["\'])(#|)\1[^>]*>\s*(?:<[^>]+>\s*)*More Info', text, re.I):
        report_lines.append(f"DEAD 'More Info' LINK [{slug}]: {re.sub(chr(10),' ',m.group(0))[:120]}")


CONTENT_RE = re.compile(r'<div id="wsite-content"[^>]*>(?P<body>.*?)\s*</div>\s*(?:<!--[^>]*-->\s*)?<div class="footer-wrap">', re.S)
# page-specific inline styles: every <style>...</style> in <head> that targets
# #element- / #wsite-content / .colored-box (skip the Weebly framework blocks).
PAGE_STYLE_RE = re.compile(r"<style[^>]*>(?P<css>(?:(?!</style>).)*?(?:#element-|#wsite-content|\.colored-box)(?:(?!</style>).)*?)</style>", re.S | re.I)


def extract_one(slug):
    fn = PAGES[slug][0]
    raw = open(os.path.join(EXPORT, fn), encoding="utf-8", errors="ignore").read()

    m = CONTENT_RE.search(raw)
    if not m:
        raise SystemExit(f"{slug}: could not locate #wsite-content .. footer-wrap")
    body = m.group("body")

    styles = "\n".join(f"<style>{s.group('css').strip()}</style>" for s in PAGE_STYLE_RE.finditer(raw))

    frag = (styles + "\n" if styles else "") + body
    frag = strip_cruft(frag)
    frag = rewrite_links(frag)
    frag = tokenize_assets(frag)
    flag_placeholders(slug, frag)

    frag = frag.strip() + "\n"
    open(os.path.join(PAGES_OUT, f"{slug}.html"), "w", encoding="utf-8").write(frag)
    return len(frag)


def main():
    os.makedirs(PAGES_OUT, exist_ok=True)
    os.makedirs(MEDIA_OUT, exist_ok=True)
    for slug in BUILD_ORDER:
        n = extract_one(slug)
        print(f"  {slug:32} {n:>8} bytes")

    # copy referenced media, write manifest
    with open(MANIFEST, "w", encoding="utf-8") as mf:
        for orig, fn in sorted(media_map.items()):
            src = find_source_on_disk(orig)
            shutil.copyfile(src, os.path.join(MEDIA_OUT, fn))
            mf.write(f"media/{fn}\t@@MEDIA:{orig}@@\n")
    print(f"  media files: {len(media_map)}")

    open(REPORT, "w", encoding="utf-8").write("\n".join(report_lines) + "\n")
    print(f"  report: {REPORT} ({len(report_lines)} lines)")


if __name__ == "__main__":
    main()
```

- [ ] **Step 3: Compile-check**

Run: `python3 -m py_compile tools/slugmap.py tools/extract.py`
Expected: no output.

- [ ] **Step 4: Run the extractor**

Run: `python3 tools/extract.py`
Expected: 29 `  <slug>  <n> bytes` lines, all `n` > 200 (calendar and shop will be the smallest, a few hundred bytes — that is correct, those pages are mostly embeds); a `media files: <N>` line with N ≥ 20; a `report: … lines` line.

- [ ] **Step 5: Verify the fragments**

Run:
```bash
ls scripts/pages/*.html | wc -l                         # 29
grep -l '\.html"' scripts/pages/*.html || echo "no raw .html links remain"
grep -l '<script' scripts/pages/*.html || echo "no <script> remains"
grep -rl 'pdxinsectarium.org' scripts/pages/*.html || echo "no absolute apex URLs remain"
grep -c '@@MEDIA:' scripts/pages/*.html | grep -v ':0' | head
grep -c '' scripts/media-manifest.tsv                   # == media files count
awk -F'\t' '{print $1}' scripts/media-manifest.tsv | while read f; do test -f "scripts/$f" || echo "MISSING $f"; done
```
Expected: `29`; "no raw .html links remain"; "no `<script>` remains"; "no absolute apex URLs remain"; several pages with `@@MEDIA:` tokens; every manifest file present on disk.

- [ ] **Step 6: Commit**

```bash
git add tools/slugmap.py tools/extract.py scripts/pages scripts/media scripts/media-manifest.tsv
git commit -m "Content extraction tool + generated page fragments and media

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 7: Manual content fixups (dead links, placeholders, Shop, donate dedupe)

**Files:**
- Modify: specific `scripts/pages/*.html` fragments (per `_report.txt`)
- Modify: `scripts/pages/shop.html`
- Modify: `CHANGES.md`
- Modify: `tools/slugmap.py` **only if** `_report.txt` shows an unmapped link that should map somewhere

**Interfaces:** none new — this task only edits generated fragments and the log.

- [ ] **Step 1: Read the report**

Run: `cat scripts/pages/_report.txt`
Work through every line:
- `PLACEHOLDER [mma]: …More info coming soon!…` — **leave as-is** (live body copy). Note in CHANGES.md that it was reviewed and kept.
- `PLACEHOLDER [<other slug>]: …More info soon…` — delete the containing element/sentence in that fragment.
- `DEAD 'More Info' LINK [<slug>]` — open the fragment, find the `<a href="#">More Info</a>` (or similar), and either point it at the correct page (if unambiguous from context) or unwrap it to plain text.
- `UNMAPPED LINK` / `MISSING ASSET` — investigate each; add to `slugmap.py` `REDIRECT_ONLY` or fix the reference. Re-run `python3 tools/extract.py` if you change `slugmap.py`.

For each change, append a `CHANGES.md` row: page, what changed, why.

- [ ] **Step 2: Shop page external-store link**

Open `scripts/pages/shop.html`. Keep the export's intro copy and the FareHarbor gift embeds already present. Immediately after the intro, add:

```html
<div class="paragraph" style="text-align:center; margin: 20px 0;">
  <a class="wsite-button wsite-button-large" href="@@SHOP_STORE_URL@@" target="_blank" rel="noopener">
    <span class="wsite-button-inner">Visit our shop</span>
  </a>
  <!-- TODO(owner): replace @@SHOP_STORE_URL@@ with the real external store URL.
       Weebly storefront is a client-rendered app and is not in the export. -->
</div>
```

Append to `CHANGES.md`:
```
| N | Shop | Storefront replaced with intro copy + gift embeds + external "Visit our shop" link | Weebly Store app markup is not in the static export. |
```

- [ ] **Step 3: donate vs donate1**

Run: `diff <(python3 -c "import re,sys;t=open('reference/13100960266a98c399e06d8/donate.html',encoding='utf-8',errors='ignore').read();print(re.sub(r'<[^>]+>',' ',t))") <(python3 -c "import re,sys;t=open('reference/13100960266a98c399e06d8/donate1.html',encoding='utf-8',errors='ignore').read();print(re.sub(r'<[^>]+>',' ',t))") | head -60`

Pick the one with the fuller / more current copy as canonical `donate` (already extracted). `donate1` is redirect-only (already in `slugmap.REDIRECT_ONLY`). Append a `CHANGES.md` row stating which was chosen and the visible difference.

- [ ] **Step 4: Live Bug hierarchy sanity**

Open `reference/13100960266a98c399e06d8/live-bugs.html` in a browser. If it visibly links to Tarantulas/Scorpions/True Spiders/Other Arachnids as sub-pages, the nested structure in `slugmap.py` is correct. If they were flat siblings, change their `wp path` in `slugmap.py` to `/tarantulas` etc. and their parent to `None`, re-run `extract.py`, and log the decision. (Default: keep nested.)

- [ ] **Step 5: Re-verify**

Run:
```bash
grep -rn 'More info soon\|More Info soon' scripts/pages/ | grep -v _report.txt || echo "clean"
grep -n '@@SHOP_STORE_URL@@' scripts/pages/shop.html      # exactly one line
grep -c '' CHANGES.md                                     # grew since Task 1
```
Expected: "clean" (MMA's "More info coming soon!" is a different string and stays); one `@@SHOP_STORE_URL@@`; CHANGES.md has multiple rows.

- [ ] **Step 6: Commit**

```bash
git add scripts/pages CHANGES.md tools/slugmap.py
git commit -m "Manual content fixups: dead links, placeholders, Shop link, donate dedupe

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 8: seed.sh

**Files:**
- Create: `scripts/seed.sh`
- Create: `scripts/redirects.sample.txt` (committed reference copy; `seed.sh` regenerates `scripts/redirects.txt` at runtime)

**Interfaces:**
- Consumes: `scripts/pages/*.html`, `scripts/media/*`, `scripts/media-manifest.tsv`, the theme directory.
- Produces: on the target WP — the activated theme, 29 published Pages (correct parents, `home` set as the static front page), imported media, and `scripts/redirects.txt`.

- [ ] **Step 1: Write `scripts/seed.sh`**

```bash
#!/usr/bin/env bash
# Insectarium Legacy — one-shot, idempotent content seeder. Run on DreamPress:
#   cd ~/<site> && bash scripts/seed.sh
set -euo pipefail

# ---- config -----------------------------------------------------------------
WP="${WP:-wp}"                       # override to e.g. 'wp --path=/srv/wp'
ADMIN_USER="${ADMIN_USER:-admin}"    # an administrator login (for unfiltered_html)
THEME_SLUG="insectarium-legacy"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PAGES_DIR="$REPO_ROOT/scripts/pages"
MEDIA_DIR="$REPO_ROOT/scripts/media"
MANIFEST="$REPO_ROOT/scripts/media-manifest.tsv"
RESOLVED_DIR="$REPO_ROOT/scripts/.pages-resolved"
REDIRECTS="$REPO_ROOT/scripts/redirects.txt"

# slug|export-file|wp-parent-slug   (parents before children; must match slugmap.py)
PAGES_TABLE='
home|Portland Insectarium|
about-us|About Us|
faq-about-the-insectarium|FAQ about the insectarium|
faq-about-bugs|FAQ about bugs|
calendar|Calendar|
admission|Admission|
hourslocation|Hours/Location|
summer-camp|Summer Camp|
memberships|Memberships|
public-events|Public Events|
private-events|Events at the Insectarium|
off-site-events|Off-site events|
photo-shoots|Photo shoots|
bug-club|Bug Club|
community|Community|
shop|Shop|
services|Services|
care-sheets|Care Sheets|
jumping-spiders|Jumping Spiders|care-sheets
ghost-mantis|Ghost Mantis|care-sheets
isopods|Isopods|care-sheets
donate|Donate|
internships|Internships|
mma|Mini Museum Alliance|
live-bugs|Live Bug Directory|
tarantulas|Tarantulas|live-bugs
scorpions|Scorpions|live-bugs
true-spiders|True Spiders|live-bugs
other-arachnids|Other Arachnids|live-bugs
'

# redirect-only sources (old .html path -> new path)
REDIRECT_ONLY='
donate1.html|/donate
info.html|/about-us
visit.html|/calendar
get-involved.html|/bug-club
other.html|/shop
private-events-and-field-trips.html|/private-events
home.html|/
home1.html|/
'

log() { printf '%s\n' "$*" >&2; }
wpq() { "$WP" --user="$ADMIN_USER" "$@"; }

# ---- 0. sanity ------------------------------------------------------------
command -v "$WP" >/dev/null || { log "wp-cli not found"; exit 1; }
wpq core is-installed || { log "WordPress not installed at target"; exit 1; }
if wpq config get DISALLOW_UNFILTERED_HTML 2>/dev/null | grep -qi '^1\|^true'; then
  log "ERROR: DISALLOW_UNFILTERED_HTML is set — embed markup would be stripped. Aborting."
  exit 1
fi

# ---- 1. theme + permalinks ---------------------------------------------------
wpq theme activate "$THEME_SLUG"
wpq rewrite structure '/%postname%/' --hard
wpq rewrite flush --hard

# ---- 2. media import: build @@MEDIA:<path>@@ -> URL map ----------------------
log "== media =="
: > "$REPO_ROOT/scripts/.media-map.sed"
if [[ -f "$MANIFEST" ]]; then
  while IFS=$'\t' read -r relfile token; do
    [[ -z "${relfile:-}" ]] && continue
    src="$REPO_ROOT/scripts/$relfile"
    if [[ ! -f "$src" ]]; then log "  WARN missing $relfile"; continue; fi
    id="$(wpq media import "$src" --porcelain)"
    url="$(wpq eval "echo wp_get_attachment_url($id);")"
    esc_token="$(printf '%s' "$token" | sed -e 's/[\/&|]/\\&/g')"
    esc_url="$(printf '%s' "$url" | sed -e 's/[\/&|]/\\&/g')"
    printf 's|%s|%s|g\n' "$esc_token" "$esc_url" >> "$REPO_ROOT/scripts/.media-map.sed"
  done < "$MANIFEST"
fi
log "  imported $(grep -c '' "$REPO_ROOT/scripts/.media-map.sed") files"

# ---- 3. resolve tokens in page fragments -----------------------------------
rm -rf "$RESOLVED_DIR"; mkdir -p "$RESOLVED_DIR"
for f in "$PAGES_DIR"/*.html; do
  [[ "$(basename "$f")" == _report.txt ]] && continue
  if [[ -s "$REPO_ROOT/scripts/.media-map.sed" ]]; then
    sed -f "$REPO_ROOT/scripts/.media-map.sed" "$f" > "$RESOLVED_DIR/$(basename "$f")"
  else
    cp "$f" "$RESOLVED_DIR/$(basename "$f")"
  fi
done
# any unresolved tokens are a hard error
if grep -rl '@@MEDIA:' "$RESOLVED_DIR" >/dev/null 2>&1; then
  log "ERROR: unresolved @@MEDIA tokens:"; grep -ro '@@MEDIA:[^@]*@@' "$RESOLVED_DIR" | sort -u >&2; exit 1
fi

# ---- 4. pages -------------------------------------------------------------
log "== pages =="
declare -A ID_BY_SLUG
printf '%-34s %-8s %-9s %s\n' PAGE ACTION ID PARENT >&2
while IFS='|' read -r slug title parent; do
  [[ -z "${slug:-}" ]] && continue
  body_file="$RESOLVED_DIR/$slug.html"
  [[ -f "$body_file" ]] || { log "  MISSING fragment for $slug"; exit 1; }

  existing="$(wpq post list --post_type=page --name="$slug" --field=ID --posts_per_page=1)"
  parent_id=0
  if [[ -n "$parent" ]]; then parent_id="${ID_BY_SLUG[$parent]:-0}"; fi

  if [[ -n "$existing" ]]; then
    wpq post update "$existing" \
      --post_title="$title" --post_name="$slug" --post_status=publish \
      --post_parent="$parent_id" --post_content="$(cat "$body_file")" >/dev/null
    pid="$existing"; action="update"
  else
    pid="$(wpq post create \
      --post_type=page --post_title="$title" --post_name="$slug" --post_status=publish \
      --post_parent="$parent_id" --post_content="$(cat "$body_file")" --porcelain)"
    action="create"
  fi
  ID_BY_SLUG[$slug]="$pid"
  printf '%-34s %-8s %-9s %s\n' "$slug" "$action" "$pid" "${parent:-–}" >&2
done <<< "$PAGES_TABLE"

# ---- 5. front page --------------------------------------------------------
wpq option update show_on_front page
wpq option update page_on_front "${ID_BY_SLUG[home]}"

# ---- 6. redirects.txt ---------------------------------------------------------
log "== redirects =="
{
  echo "# Generated by scripts/seed.sh — paste ABOVE '# BEGIN WordPress' in .htaccess"
  echo "<IfModule mod_rewrite.c>"
  echo "RewriteEngine On"
  while IFS='|' read -r slug title parent; do
    [[ -z "${slug:-}" ]] && continue
    src="$slug"; [[ "$slug" == home ]] && src="index"
    # nested children: old flat file still redirects to the nested path
    dest="/$slug/"; [[ "$slug" == home ]] && dest="/"
    case "$slug" in
      jumping-spiders|ghost-mantis|isopods) dest="/care-sheets/$slug/";;
      tarantulas|scorpions|true-spiders|other-arachnids) dest="/live-bugs/$slug/";;
    esac
    echo "RewriteRule ^${src}\\.html$ ${dest} [R=301,L]"
  done <<< "$PAGES_TABLE"
  while IFS='|' read -r oldf dest; do
    [[ -z "${oldf:-}" ]] && continue
    echo "RewriteRule ^${oldf%.html}\\.html$ ${dest} [R=301,L]"
  done <<< "$REDIRECT_ONLY"
  echo "</IfModule>"
} > "$REDIRECTS"
log "  wrote $REDIRECTS ($(grep -c RewriteRule "$REDIRECTS") rules)"

log ""
log "DONE. Next: paste scripts/redirects.txt into .htaccess (see DEPLOY.md step 6)."
```

- [ ] **Step 2: Lint**

Run: `bash -n scripts/seed.sh && shellcheck scripts/seed.sh`
Expected: `bash -n` silent; `shellcheck` clean (SC2016 on the single-quoted heredoc tables is acceptable — they are intentionally literal).

- [ ] **Step 3: Create the placeholder sample redirects file**

`seed.sh` regenerates `scripts/redirects.txt` at run time (Task 9 replaces the sample with the real output). For now:
```bash
printf '# Placeholder. scripts/seed.sh regenerates scripts/redirects.txt at run time;\n# Task 9 copies the real output over this file. See DEPLOY.md step 6.\n' > scripts/redirects.sample.txt
```

- [ ] **Step 4: Commit**

```bash
git add scripts/seed.sh scripts/redirects.sample.txt
git commit -m "seed.sh: idempotent media import + 29-page create + redirect generator

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 9: Local end-to-end run + visual verification

**Files:**
- Modify: `CHANGES.md` (any newly found deviations)
- Modify: `scripts/redirects.sample.txt` (replace with the real generated file)
- Possibly Modify: `theme.css`, specific `scripts/pages/*.html` (fidelity fixes found here)

**Interfaces:** none new.

**Environment prerequisite:** a local WordPress install reachable by `wp` CLI.
Set it up by whatever means you know. Two low-friction options:
- **wp-now** (needs Node ≥ 20): `npx --yes @wp-now/wp-now start --path=/tmp/il-wp --port=8881`
  in one terminal (SQLite, zero config), then in another terminal run
  `wp` commands with `WP='npx --yes @wp-now/wp-now run --path=/tmp/il-wp --'`.
  Symlink the theme in first:
  `mkdir -p /tmp/il-wp/wp-content/themes && ln -s "$PWD/wp-content/themes/insectarium-legacy" /tmp/il-wp/wp-content/themes/`.
- **Plain local WP:** `wp core download && wp config create … && wp core install …`
  in a scratch dir; symlink the theme as above; use `WP='wp --path=/that/dir'`.

Create an admin user if the install doesn't have one and note its login for `ADMIN_USER`.

- [ ] **Step 1: Confirm the theme is visible**

Run: `$WP theme list --format=csv | grep insectarium-legacy`
Expected: one row, status `inactive` (seed.sh will activate it).

- [ ] **Step 2: Run the seeder against it**

```bash
WP="$WP" ADMIN_USER="<your-admin-login>" bash scripts/seed.sh
```
Expected: `== media ==` imports N files (N = line count of `scripts/media-manifest.tsv`); the `PAGE ACTION ID PARENT` table lists all 29 rows as `create`; `== redirects ==` reports ~37 rules; `DONE.` and no `ERROR:` lines.

- [ ] **Step 3: Idempotency check**

Re-run the exact same command from Step 2.
Expected: all 29 rows now say `update`; no new pages.

Run (using the same `WP` value):
```bash
$WP post list --post_type=page --format=count                                  # 29
$WP post list --post_type=page --fields=post_name,post_parent --format=csv
$WP option get page_on_front
```
Expected: count `29`; `jumping-spiders,ghost-mantis,isopods` have `post_parent` = the `care-sheets` page ID; `tarantulas,scorpions,true-spiders,other-arachnids` = the `live-bugs` page ID; `page_on_front` = the `home` page ID.

- [ ] **Step 4: Page-by-page visual diff**

For each of the 29 slugs, open the WordPress page and the matching export file side by side:
- WP: `http://localhost:8881/<path>` (front page for `home`)
- Export: `reference/13100960266a98c399e06d8/<file>.html` (open with `file://`)

Check: header logo + nav position, the three-level `Other ▸ Care Sheets` dropdown on hover, footer, body fonts (Amaranth) and headline font (Georgia), the gold/green palette, `.colored-box` callouts, multi-column blocks, tables (Admission pricing, About residents). Note any material mismatch and fix in `theme.css` (chrome) or the specific fragment (content). Log fidelity fixes in `CHANGES.md` only if they change content; pure CSS chrome fixes need no log entry.

- [ ] **Step 5: Embed + asset checks**

```bash
BASE=http://localhost:8881
for p in admission public-events calendar private-events shop donate; do
  echo "== $p =="; curl -s "$BASE/$p" | grep -oE 'fareharbor\.com/embeds/[^"'\'' ]+|calendar\.google\.com/calendar/embed[^"'\'' ]+|squareup\.com[^"'\'' ]*|kit\.com[^"'\'' ]*' | sort -u
done
curl -s "$BASE/" | grep -c 'fareharbor.com/embeds/api/v1/?autolightframe=yes'   # 1
# no broken images
for p in $($WP post list --post_type=page --field=post_name); do
  curl -s "$BASE/$p/" | grep -oE 'src="[^"]+\.(jpg|jpeg|png|gif)"' | sed 's/src="//;s/"//'
done | sort -u | while read -r u; do
  code=$(curl -s -o /dev/null -w '%{http_code}' "$u"); [ "$code" = 200 ] || echo "BROKEN $code $u"
done
```
Expected: Admission shows the FareHarbor `?full-items=yes&u=248be6ab…` URL; Public Events shows multiple `items/<id>` URLs; Calendar shows the `calendar.google.com/calendar/embed?src=info%40pdxinsectarium.org…` iframe URL; Private Events shows the Square URL; every page shows the `autolightframe` script exactly once (from the footer); **no `BROKEN` image lines**.

- [ ] **Step 6: Capture the real redirects sample + commit**

```bash
cp scripts/redirects.txt scripts/redirects.sample.txt
git add -A
git commit -m "Local end-to-end run: verified 29 pages, embeds, media, nav; fidelity fixes

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 10: Public Events reconciliation + Shop URL

**Files:**
- Modify: `scripts/pages/public-events.html`
- Modify: `scripts/pages/shop.html`
- Modify: `CHANGES.md`

**Interfaces:** none new.

- [ ] **Step 1: Reconcile Public Events against live**

The export can lag. The live page cannot be fetched by tooling (Cloudflare), so this is a human check: open `https://www.pdxinsectarium.org/public-events.html` in a real browser and compare event-by-event with `scripts/pages/public-events.html`.
- Remove events that no longer appear live.
- Add events present live but missing from the export, copying the exact FareHarbor `items/<id>` embed markup pattern already used on that page.
- Keep the "READ BEFORE PURCHASING" policy block.
Append a `CHANGES.md` row summarising what changed (or "verified, no change").

If the owner has not provided the live check yet, STOP and request it — do not deploy Public Events from a possibly-stale export (Global Constraints / spec Go-live item 2).

- [ ] **Step 2: Wire the Shop URL**

When the owner supplies the external store URL, replace `@@SHOP_STORE_URL@@` in `scripts/pages/shop.html` with it. If not yet available, leave the token and the `TODO(owner)` comment; note in `CHANGES.md` that Shop ships with a placeholder link pending the URL.

- [ ] **Step 3: Re-run + re-verify locally**

Run the seeder again (Task 9 Step 2) and reload `/public-events` and `/shop`.
Expected: updated content renders; FareHarbor item embeds intact; Shop button points at the real URL (or still the token, consciously).

- [ ] **Step 4: Commit**

```bash
git add scripts/pages/public-events.html scripts/pages/shop.html CHANGES.md
git commit -m "Reconcile Public Events with live; wire external Shop URL

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 11: DEPLOY.md runbook

**Files:**
- Create: `DEPLOY.md`

- [ ] **Step 1: Write `DEPLOY.md`**

```markdown
# Deploying the Insectarium Legacy replica to DreamPress

Prerequisites: SSH access to the DreamPress site, `wp` on the PATH there,
an administrator login, and this repo checked out on the server (or rsynced).

1. **Get the code onto the server**
   - `git clone <repo>` (or `git pull`) into the site's home, e.g. `~/pdxinsectarium.org`.
   - Ensure `wp-content/themes/insectarium-legacy/` from the repo is in the live
     `wp-content/themes/` (symlink or copy). `assets/vendor/**` must be present
     (it is committed — no need to re-run `tools/fetch-vendor.sh` on the server).

2. **Pre-deploy content gate**
   - Confirm `scripts/pages/public-events.html` was reconciled against the live
     site today (Task 10 / spec Go-live item 2).
   - Confirm `scripts/pages/shop.html` has the real store URL, or that shipping
     the placeholder is accepted.

3. **Seed the content**
   ```bash
   cd ~/pdxinsectarium.org
   ADMIN_USER=<your-admin-login> bash scripts/seed.sh
   ```
   Review the `PAGE ACTION ID PARENT` table: 29 rows, correct parents.
   Re-run once; every row should say `update`.

4. **Set the front page** — `seed.sh` already does this; verify:
   `wp option get show_on_front` → `page`; `wp option get page_on_front` → the `home` ID.

5. **Smoke-test** the live URLs: `/`, `/about-us`, `/care-sheets/jumping-spiders`,
   `/public-events`, `/admission` (FareHarbor loads), `/calendar` (Google embed),
   `/private-events` (Square embed), `/live-bugs/tarantulas`, `/donate`. Confirm the
   floating "Book Now" tab appears (FareHarbor `autolightframe`).

6. **Apply redirects** — open `scripts/redirects.txt` (regenerated by step 3) and
   paste its block into the site's `.htaccess` **above** `# BEGIN WordPress`.
   Then verify:
   ```bash
   for u in about-us.html jumping-spiders.html tarantulas.html donate1.html info.html; do
     curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" "https://www.pdxinsectarium.org/$u"
   done
   ```
   Expect `301` and the clean target for each.

7. **Post-deploy** — review `CHANGES.md` with the owner. Hand over the list of
   orphan URLs (`/donate`, `/internships`, `/mma`, `/live-bugs` + 4 children):
   live, reachable by direct link, intentionally not in the nav.
```

- [ ] **Step 2: Cross-check against seed.sh**

Verify every path/option name in `DEPLOY.md` matches `scripts/seed.sh` (theme slug, `show_on_front`, `page_on_front`, `redirects.txt` location).

- [ ] **Step 3: Commit**

```bash
git add DEPLOY.md
git commit -m "DreamPress deploy runbook

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Task 12: Final self-check against the spec

**Files:**
- Modify: `CHANGES.md` (final review pass)

- [ ] **Step 1: Walk the spec's Go-live checklist**

Open `docs/superpowers/specs/2026-09-02-insectarium-legacy-design.md` → "Go-live checklist". For each item 1–12, confirm this plan produced the artifact or the DEPLOY.md step that satisfies it. Note anything only satisfiable at deploy time (items 2, 3, 5, 6, 7, 10) as owner/deploy actions in `DEPLOY.md`.

- [ ] **Step 2: Verify the deviation log is complete**

`cat CHANGES.md` — there should be rows for at least: stand-in logo, footer search rewire, Shop storefront replacement, donate/donate1 dedupe, every dead-"More Info" link removed, every "More info soon" removed, MMA "More info coming soon!" reviewed-and-kept, Public Events reconciliation outcome.

- [ ] **Step 3: Full clean re-run from scratch**

```bash
rm -rf scripts/pages scripts/media scripts/media-manifest.tsv scripts/.pages-resolved scripts/.media-map.sed
python3 tools/extract.py
# then Task 7's manual fixups are lost — so instead verify the committed
# fragments still regenerate cleanly EXCEPT for the intentional manual edits:
git status --porcelain scripts/pages | head
```
Expected: `extract.py` runs clean; `git status` shows only the fragments where Task 7/10 made intentional manual edits (dead links, Shop, Public Events) as modified — restore them with `git checkout scripts/pages`. This confirms the tool is deterministic and the manual edits are known.

- [ ] **Step 4: Final commit**

```bash
git checkout scripts/pages   # restore intentional manual edits
git add CHANGES.md
git commit -m "Final spec cross-check; deviation log complete

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Self-Review (plan author)

**Spec coverage:**
- Deliverable = theme + WP-CLI seed script → Tasks 2–5 (theme), 8 (seed.sh). ✓
- Weebly export as source, vendored CDN assets → Task 1. ✓
- 21 nav pages + 8 orphan pages, hierarchy → Tasks 6 (extract), 8 (create with parents). ✓
- Version A nav hardcoded, non-clickable parents, verbatim labels → Task 3 `site-nav.php`. ✓
- Ports `sites.css` + `main_style.css` + fonts; own `nav.js` not Weebly `main.js`; FareHarbor `autolightframe` → Tasks 1, 4. ✓
- Content extraction rules (style block + `#wsite-content` inner, link rewrite, media tokenisation, cruft strip, embed preservation) → Task 6. ✓
- Fix dead "More Info" / "More info soon"; keep MMA's live copy → Task 7. ✓
- Shop = static + gift embeds + external link → Task 7 Step 2, Task 10 Step 2. ✓
- donate/donate1 dedupe → Task 7 Step 3. ✓
- Clean slugs + generated `.htaccess` redirect block incl. flat child paths + `donate1` + Weebly stubs → Task 8 Step 1 section 6. ✓
- Idempotent seed (`create`→`update`, no dupes) → Task 8, verified Task 9 Step 3. ✓
- `unfiltered_html` via `--user`, `DISALLOW_UNFILTERED_HTML` guard → Task 8 Step 1 sections 0 & 4. ✓
- `wpautop`/`wptexturize` removed → Task 2 `functions.php`. ✓
- Front page = `home` page via `page_on_front` → Task 8 section 5. ✓
- Media: only referenced images committed under `scripts/media/`, raw export git-ignored → Task 1 `.gitignore`, Task 6. ✓
- CHANGES.md deviation log → Tasks 1, 3, 4, 7, 9, 10, 12. ✓
- Public Events reconciled vs live before deploy → Task 10 Step 1, DEPLOY.md step 2. ✓
- Verification (lint, dry run, visual diff, embed grep, redirects) → Tasks 2–9, 12. ✓
- Go-live checklist → Task 11 DEPLOY.md + Task 12 Step 1. ✓
- Attribution trailer on commits → every commit step. ✓
- Stand-in logo (export gap) → Task 3 Step 3, logged. ✓

**Placeholder scan:** `@@MEDIA:…@@` and `@@SHOP_STORE_URL@@` are deliberate runtime tokens with defined resolution (seed.sh section 3; Task 10 Step 2), not plan placeholders. Every code step contains complete, runnable content. No "TBD"/"similar to"/"add error handling" left.

**Type / name consistency:** `il_asset()` defined Task 2, used Tasks 2–4. Enqueue handles `il-sites`/`il-main-style`/`il-fh-kit`/`il-theme`/`il-nav` consistent Task 2 ↔ 4. `@@MEDIA:<orig>@@` token format identical in `extract.py` (Task 6) and `seed.sh` sed builder (Task 8). Slug map identical in `tools/slugmap.py` (Task 6) and `PAGES_TABLE`/`REDIRECT_ONLY` in `seed.sh` (Task 8) — both list parents before children, same 29 slugs + same 8 redirect-only sources. `body.mobile-nav-open` / `.wsite-menu-item-wrap.open` classes consistent `nav.js` ↔ `theme.css` (Task 4). Wrapper chain: `header.php` opens `.wrapper`+`.main-wrap`, `page.php` opens `#wsite-content`, `footer.php` closes `.main-wrap` then `.wrapper` — consistent Tasks 3/4/5.
