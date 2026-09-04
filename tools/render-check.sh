#!/usr/bin/env bash
# Task 9 Part 2 - drive tools/render-check.php over key fragments and lint every
# theme PHP file. Requires a PHP CLI; override with PHP=/path/to/php.exe.
#
#   PHP=/c/.../scratchpad/php/php.exe bash tools/render-check.sh
#
# Exit 0 = PASS, non-zero = FAIL.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
PHP="${PHP:-php}"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/il-render.XXXXXX")"

FAIL=0
pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

command -v "$PHP" >/dev/null 2>&1 || { echo "FAIL: PHP CLI not found ('$PHP'). Set PHP=..."; exit 1; }
echo "== PHP: $($PHP -v | head -1) =="

# ---- common chrome every rendered page must carry -------------------------
COMMON=(
	'wsite-menu-default'
	'id="wsite-content"'
	'class="cento-header"'
	'class="footer-wrap"'
	'fareharbor.com/embeds/api/v1/?autolightframe=yes'
)

render_one() {  # $1 = slug
	local slug="$1"
	local frag="scripts/pages/$slug.html"
	local out="$WORK/$slug.html" err="$WORK/$slug.err"
	"$PHP" tools/render-check.php "$frag" > "$out" 2> "$err"
	local rc=$?
	echo "-- $slug --"
	if [ "$rc" -eq 0 ]; then pass "$slug: php exit 0"
	else fail "$slug: php exit $rc"; fi
	if [ ! -s "$err" ]; then pass "$slug: empty stderr (no warnings/notices/errors)"
	else fail "$slug: non-empty stderr:"; sed 's/^/      | /' "$err"; fi

	local needle
	for needle in "${COMMON[@]}"; do
		if grep -qF -- "$needle" "$out"; then pass "$slug: contains  $needle"
		else fail "$slug: MISSING  $needle"; fi
	done

	# wrapper chain must balance: header opens .wrapper + .main-wrap, page.php
	# opens #wsite-content, footer closes all three; the fragment must not skew it.
	local dopen dclose
	dopen="$(grep -o '<div' "$out" | wc -l | tr -d ' ')"
	dclose="$(grep -o '</div>' "$out" | wc -l | tr -d ' ')"
	if [ "$dopen" -eq "$dclose" ]; then pass "$slug: <div>/</div> balanced ($dopen each)"
	else fail "$slug: <div>/</div> IMBALANCE ($dopen open / $dclose close)"; fi

	case "$slug" in
		calendar)
			needle='calendar.google.com/calendar/embed?src=info%40pdxinsectarium.org&ctz=America%2FLos_Angeles'
			grep -qF -- "$needle" "$out" && pass "calendar: Google Calendar embed survives byte-for-byte" \
				|| fail "calendar: MISSING $needle" ;;
		public-events)
			grep -qE 'fareharbor\.com/embeds/book/pdxinsectarium/items/[0-9]+' "$out" \
				&& pass "public-events: >=1 fareharbor items/ booking URL" \
				|| fail "public-events: no fareharbor items/ booking URL" ;;
		shop)
			grep -qF -- '@@SHOP_STORE_URL@@' "$out" \
				&& pass "shop: @@SHOP_STORE_URL@@ owner placeholder present" \
				|| fail "shop: MISSING @@SHOP_STORE_URL@@"
			grep -qF -- 'fareharbor.com/embeds/book/pdxinsectarium/items/690480' "$out" \
				&& pass "shop: fareharbor items/690480 gift-card URL present" \
				|| fail "shop: MISSING fareharbor items/690480 URL" ;;
		private-events)
			grep -qF -- 'squareup.com/appointments/buyer/widget/l60stped6z2o1v' "$out" \
				&& pass "private-events: Square Appointments booking widget survives byte-for-byte" \
				|| fail "private-events: MISSING squareup.com/appointments/buyer/widget/l60stped6z2o1v" ;;
	esac
}

echo
echo "== render smoke test =="
for slug in home about-us calendar public-events shop care-sheets private-events; do
	render_one "$slug"
done

echo
echo "== php -l on every theme PHP file =="
THEME_DIR="wp-content/themes/insectarium-legacy"
while IFS= read -r php_file; do
	line="$("$PHP" -l "$php_file" 2>&1)"
	if printf '%s' "$line" | grep -q 'No syntax errors detected'; then
		pass "php -l  $php_file"
	else
		fail "php -l  $php_file  ->  $line"
	fi
done < <(find "$THEME_DIR" -maxdepth 2 -name '*.php' | sort)

echo
echo "  rendered output kept in: $WORK"
echo
if [ "$FAIL" -eq 0 ]; then
	echo "PART 2 RESULT: PASS"
	exit 0
else
	echo "PART 2 RESULT: FAIL ($FAIL failed assertion(s))"
	exit 1
fi
