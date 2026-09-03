# Deploying the Insectarium Legacy replica to DreamPress

This is the single, complete runbook for putting the WordPress replica of the
Weebly site live on DreamPress. Work the sections in order:

1. **A. Owner pre-deploy gate** — nothing ships until this is cleared
2. **B. Optional pre-flight** — fast local sanity checks (no server needed)
3. **C. Deploy** — get the code on the server and seed the content
4. **D. Mandatory post-seed verification on the live site**
5. **E. Redirects** — paste the generated rules into `.htaccess`, verify 301s
6. **F. Post-deploy handover** — review changes, hand over the orphan-URL list

**Prerequisites for C–E:** SSH access to the DreamPress site, `wp` (WP-CLI) on
the `PATH` there, an administrator login for that WordPress, and this repo
(branch `insectarium-legacy-build`) checked out on the server or rsynced to it.

> Note: the raw Weebly export under `reference/` is **git-ignored** and is *not*
> on the deploy server. That is fine — `scripts/seed.sh` reads the committed
> `scripts/media/` directory, never `reference/`. You still need a local copy of
> the export for the visual diff in step D5, so do that step from your laptop.

---

## A. Owner pre-deploy gate (DEPLOY-BLOCKERS.md)

**Do not run any deploy step until both items in `DEPLOY-BLOCKERS.md` are
resolved.** These need the site owner, not the deployer:

1. **Reconcile the Public Events page.** `scripts/pages/public-events.html` was
   extracted from the Weebly export and event listings are time-sensitive. The
   owner must open `https://www.pdxinsectarium.org/public-events.html`, compare
   it against the local `scripts/pages/public-events.html`, **remove** events no
   longer running, **add** any new live events using the FareHarbor embed
   pattern already in the file
   (`<a href='https://fareharbor.com/embeds/book/pdxinsectarium/items/<id>/?...'>`),
   and **keep** the "READ BEFORE PURCHASING" policy block intact. This is a hard
   gate — all ticket-purchase traffic routes through this page.

2. **Supply the real Shop store URL.** `scripts/pages/shop.html` line 12 still
   has the placeholder token `@@SHOP_STORE_URL@@` in the "Visit our shop" button.
   The owner must provide the real external storefront URL and replace the token
   with it. If shipped as-is the button is broken.

**Deploy only when both are done — or when the owner has explicitly accepted
shipping the Shop button with its placeholder.** Record that decision.

---

## B. Optional pre-flight (local, before pushing)

These three harnesses (added in Task 9) run from the **repo root** and need
neither a server nor a WordPress. They catch regressions before you touch
DreamPress. All three print a `PASS`/`FAIL` summary and exit non-zero on failure.

```bash
# 1. Stubbed dry run of seed.sh — no real WordPress.
#    Asserts: 29 pages, parent-before-child ordering, front-page wiring,
#    zero unresolved @@MEDIA: tokens, 40 redirect rules.
bash tools/seed-dryrun.sh

# 2. Portable-PHP render of 6 representative pages through the theme templates.
#    Point PHP= at a PHP CLI binary.
PHP=<path-to-php> bash tools/render-check.sh

# 3. Every media reference in scripts/pages/*.html resolves to a manifest row
#    and an on-disk file in scripts/media/.
bash tools/check-media-refs.sh
```

Green here is not a substitute for section D — the live-only checks below still
have to be done on the server.

---

## C. Deploy

### C1. Get the code onto the server

- `git clone <repo>` (or `git pull` on branch `insectarium-legacy-build`) into
  the site's home, e.g. `~/pdxinsectarium.org`.
- Ensure the theme directory `wp-content/themes/insectarium-legacy/` from the
  repo is present in the **live** `wp-content/themes/` (symlink or copy).
- `wp-content/themes/insectarium-legacy/assets/vendor/**` must be present. It is
  committed, so a clean checkout already has it — no need to run
  `tools/fetch-vendor.sh` on the server.

### C2. Seed the content

```bash
cd ~/pdxinsectarium.org
ADMIN_USER=<your-admin-login> bash scripts/seed.sh
```

`seed.sh` is idempotent. It activates the `insectarium-legacy` theme, sets
permalinks to `/%postname%/`, imports the 53 media files, resolves `@@MEDIA:`
tokens, creates/updates the 29 pages, wires the front page, and regenerates
`scripts/redirects.txt`. (Config vars at the top of the script: `WP` defaults to
`wp`, `ADMIN_USER` defaults to `admin`, `THEME_SLUG=insectarium-legacy`. The
`ADMIN_USER` must be a real administrator so `unfiltered_html` is granted and the
third-party embeds survive.) The script aborts early if
`DISALLOW_UNFILTERED_HTML` is set.

### C3. Review the seed summary table

`seed.sh` prints a `PAGE  ACTION  ID  PARENT` table. Confirm:

- **29 rows.**
- On this first run every `ACTION` is `create`.
- Parents are correct: `jumping-spiders`, `ghost-mantis`, `isopods` under
  `care-sheets`; `tarantulas`, `scorpions`, `true-spiders`, `other-arachnids`
  under `live-bugs`.

### C4. Verify the front page

`seed.sh` already sets this. Confirm:

```bash
wp option get show_on_front     # → page
wp option get page_on_front     # → the numeric ID of the "home" page from the table
```

---

## D. Mandatory post-seed verification on the live site

These could **not** be checked locally in Task 9 and are required before you
call the deploy done. Replace `<url>` with the real live URLs.

### D1. Idempotent re-run

Run the seeder a **second** time:

```bash
ADMIN_USER=<your-admin-login> bash scripts/seed.sh
```

- Every one of the 29 rows must now say `update` (not `create`).
- `wp post list --post_type=page --format=count` must stay **29** — no
  duplicates.

### D2. Embeds survived KSES

The administrator `unfiltered_html` path must have held (i.e.
`DISALLOW_UNFILTERED_HTML` is not set). On the rendered live pages confirm the
third-party markup is actually present:

```bash
curl -s https://www.pdxinsectarium.org/admission/       | grep -c fareharbor    # FareHarbor booking embed / script
curl -s https://www.pdxinsectarium.org/public-events/   | grep -c fareharbor    # FareHarbor booking links
curl -s https://www.pdxinsectarium.org/calendar/        | grep -c 'calendar.google.com'   # Google Calendar <iframe>
curl -s https://www.pdxinsectarium.org/private-events/  | grep -ci square       # Square embed (Events at the Insectarium)
```

Each count must be non-zero. Also confirm the floating FareHarbor "Book Now" tab
(`autolightframe`) appears on the pages that use it.

### D3. Media imported and resolving

`wp media import` ran for all **53** files during the seed. Spot-check 5–6
images across different pages and confirm each returns HTTP 200 (no broken
`src`):

```bash
for u in <image-url-1> <image-url-2> <image-url-3> <image-url-4> <image-url-5>; do
  curl -s -o /dev/null -w "%{http_code}  $u\n" "$u"
done
```

Pull the `src` values straight from the rendered home page, an About page, a
Care Sheet, and a Live Bug page so the sample spans templates.

### D4. Page hierarchy

```bash
wp post list --post_type=page --fields=post_name,post_parent
```

Confirm the 3 Care Sheet children (`jumping-spiders`, `ghost-mantis`,
`isopods`) have `post_parent` = the `care-sheets` ID, and the 4 Live Bug
children (`tarantulas`, `scorpions`, `true-spiders`, `other-arachnids`) have
`post_parent` = the `live-bugs` ID.

### D5. Human page-by-page visual diff (needs a browser)

This is the real fidelity check. Open the Weebly export locally and walk **all
29** live pages against their source file at
`reference/13100960266a98c399e06d8/<file>.html`. For each page check:

- header logo and nav position
- the three-level `Other ▸ Care Sheets` hover dropdown
- footer
- Amaranth / Georgia fonts
- gold / green palette
- `.colored-box` callouts
- multi-column blocks
- pricing / resident tables

Note any drift; small cosmetic differences are expected, structural ones are not.

---

## E. Redirects

The `scripts/seed.sh` run in step C2 regenerated `scripts/redirects.txt` (a
40-rule Apache `mod_rewrite` block; the committed `scripts/redirects.sample.txt`
shows what it looks like). This file is git-ignored — use the one the run just
produced on the server.

1. Open `scripts/redirects.txt`.
2. Paste its entire block into the DreamPress site's `.htaccess`, **above** the
   `# BEGIN WordPress` line.
3. Verify a sample of 301s:

```bash
for u in about-us.html jumping-spiders.html tarantulas.html donate1.html info.html faq.html; do
  curl -s -o /dev/null -w "%{http_code} %{redirect_url}\n" "https://www.pdxinsectarium.org/$u"
done
```

Expect `301` plus the clean target for each, e.g.
`about-us.html` → `/about-us/`, `jumping-spiders.html` → `/care-sheets/jumping-spiders/`,
`tarantulas.html` → `/live-bugs/tarantulas/`, `donate1.html` → `/donate`,
`info.html` → `/about-us`, `faq.html` → `/faq-about-the-insectarium`.

---

## F. Post-deploy handover

- Walk `CHANGES.md` with the owner (9 rows) so they know every intentional
  deviation from the Weebly original.
- Hand over the **orphan-URL list**: `/donate`, `/internships`, `/mma`,
  `/live-bugs` and its 4 children (`/live-bugs/tarantulas`,
  `/live-bugs/scorpions`, `/live-bugs/true-spiders`,
  `/live-bugs/other-arachnids`). These pages are live and reachable by direct
  link but are **intentionally not in the site navigation** — the owner should
  link to them from wherever they want them found.
