#!/usr/bin/env bash
# Task 9 Part 3 - static media-reference check.
#
# For every scripts/pages/*.html:
#   * every @@MEDIA:<path>@@ token must have a row in scripts/media-manifest.tsv
#     and the scripts/media/<file> it names must exist on disk;
#   * no remaining raw image ref (src="..." / url(...)) may point at /uploads
#     or files/  (those should all have been tokenised).
#
#   bash tools/check-media-refs.sh
# Exit 0 = PASS, non-zero = FAIL.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"
PAGES_DIR="scripts/pages"
MEDIA_DIR="scripts/media"
MANIFEST="scripts/media-manifest.tsv"

FAIL=0
pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

[ -f "$MANIFEST" ] || { echo "FAIL: $MANIFEST missing"; exit 1; }

# token -> media/<file>
declare -A TOK2FILE
while IFS=$'\t' read -r relfile token; do
	[ -z "${relfile:-}" ] && continue
	TOK2FILE["$token"]="$relfile"
done < "$MANIFEST"
echo "== manifest: ${#TOK2FILE[@]} rows =="

tok_total=0; tok_bad=0; rawbad_total=0
for page in "$PAGES_DIR"/*.html; do
	[ -f "$page" ] || continue
	base="$(basename "$page")"

	# --- @@MEDIA tokens ---
	while IFS= read -r tok; do
		[ -z "$tok" ] && continue
		tok_total=$((tok_total + 1))
		file="${TOK2FILE[$tok]:-}"
		if [ -z "$file" ]; then
			fail "$base: token has no manifest row -> $tok"
			tok_bad=$((tok_bad + 1)); continue
		fi
		if [ ! -f "scripts/$file" ]; then
			fail "$base: manifest row for $tok names scripts/$file which is missing on disk"
			tok_bad=$((tok_bad + 1))
		fi
	done < <(grep -oE '@@MEDIA:[^@]+@@' "$page" | sort -u)

	# --- raw (un-tokenised) image refs at /uploads or files/ ---
	while IFS= read -r ref; do
		[ -z "$ref" ] && continue
		case "$ref" in
			*'@@MEDIA:'*) continue ;;  # a token inside url("...") - fine
		esac
		if printf '%s' "$ref" | grep -qiE '/uploads|files/'; then
			fail "$base: raw un-tokenised image ref at /uploads or files/ -> $ref"
			rawbad_total=$((rawbad_total + 1))
		fi
	done < <(grep -oE '(src="[^"]+"|url\([^)]+\))' "$page" \
		| grep -iE '\.(jpe?g|png|gif|webp|svg)')
done

if [ "$tok_bad" -eq 0 ]; then
	pass "all $tok_total @@MEDIA token occurrences resolve to a manifest row + on-disk file"
fi
if [ "$rawbad_total" -eq 0 ]; then
	pass "no raw un-tokenised /uploads or files/ image refs in any fragment"
fi

# every media file referenced at least once? (informational, not fatal)
unref=0
for f in "$MEDIA_DIR"/*; do
	b="$(basename "$f")"
	grep -qF "media/$b" "$MANIFEST" || { echo "  NOTE  $b not in manifest"; unref=$((unref + 1)); }
done
[ "$unref" -eq 0 ] && pass "every file in scripts/media/ has a manifest row"

echo
if [ "$FAIL" -eq 0 ]; then
	echo "PART 3 RESULT: PASS"
	exit 0
else
	echo "PART 3 RESULT: FAIL ($FAIL failed assertion(s))"
	exit 1
fi
