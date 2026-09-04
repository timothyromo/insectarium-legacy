#!/usr/bin/env bash
# Insectarium Legacy — one-shot, idempotent content seeder. Run on DreamPress:
#   cd ~/<site> && bash scripts/seed.sh
set -euo pipefail

# ---- config -----------------------------------------------------------------
# How to call WP-CLI. Priority:
#   WP_BIN  — path to one executable, kept intact even with spaces (a php.exe,
#             or a wp shim). Combine with WP_PHAR to run wp-cli.phar through it.
#   WP      — word-split fallback for the simple case (default: "wp").
#   WP_PHAR — optional wp-cli.phar, appended as its own arg.
#   WP_PATH — WordPress root when it is not the current directory (space-safe).
# On Windows + "Local"/LocalWP, the bundled `wp` shim can choke on its own
# unquoted PHP path ("'D:\Program' is not recognized"); bypass it with e.g.
#   WP_BIN='/c/Program Files/Local/.../php.exe' WP_PHAR='/c/path/wp-cli.phar' \
#   WP_PATH='/c/Users/you/Local Sites/site/app/public' bash scripts/seed.sh
if [[ -n "${WP_BIN:-}" ]]; then WP_CMD=("$WP_BIN"); else read -r -a WP_CMD <<< "${WP:-wp}"; fi
[[ -n "${WP_PHAR:-}" ]] && WP_CMD+=("$WP_PHAR")
[[ -n "${WP_PATH:-}" ]] && WP_CMD+=(--path="$WP_PATH")
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
faq.html|/faq-about-the-insectarium
private-eventsparties.html|/private-events
public-events1.html|/public-events
'

log() { printf '%s\n' "$*" >&2; }
wpq() { "${WP_CMD[@]}" --user="$ADMIN_USER" "$@"; }

# ---- 0. sanity ------------------------------------------------------------
command -v "${WP_CMD[0]}" >/dev/null || { log "wp-cli not found: ${WP_CMD[0]}"; exit 1; }
if ! wpq core is-installed; then
  log "WP-CLI could not reach a WordPress install."
  log "  Whatever wp-cli printed above this line (if anything) is the real error —"
  log "  read that first."
  log "  Exact argv passed to exec (one element per line, so quoting is unambiguous;"
  log "  this is NOT a space-joined re-quoted string):"
  i=0
  for arg in "${WP_CMD[@]}" "--user=$ADMIN_USER" core is-installed; do
    log "    argv[$i] = <$arg>"
    i=$((i + 1))
  done
  log "  - re-run that argv by hand, one arg per line above, to see the raw error"
  log "  - on Windows/Local, if you see \"'D:\\Program' is not recognized\", the"
  log "    bundled wp shim is broken: set WP_BIN=<php.exe> WP_PHAR=<wp-cli.phar> (see header)"
  log "  - if wp-cli's own error mentions the database, WP_PATH is fine and this is"
  log "    a DB-connection problem (Local's MySQL often uses a nonstandard socket/port)"
  log "  - otherwise check WP_PATH points at the WordPress root"
  exit 1
fi
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
    # Reuse a prior import keyed on the manifest relative filename (idempotent re-run).
    key="il-$(printf '%s' "$relfile" | tr -c 'A-Za-z0-9' '-')"
    id="$(wpq post list --post_type=attachment --meta_key=_il_media_key --meta_value="$key" --field=ID --posts_per_page=1 2>/dev/null || true)"
    if [[ -z "$id" ]]; then
      id="$(wpq media import "$src" --porcelain)"
      wpq post meta update "$id" _il_media_key "$key" >/dev/null
    fi
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

  existing="$(wpq post list --post_type=page --post_status=any --name="$slug" --field=ID --posts_per_page=1)"
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
