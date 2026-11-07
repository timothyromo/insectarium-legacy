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
