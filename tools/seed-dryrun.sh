#!/usr/bin/env bash
# Task 9 Part 1 - stubbed-`wp` dry run of scripts/seed.sh
#
# Defines a shell `wp()` that logs every invocation and returns plausible values,
# then runs scripts/seed.sh to completion with no real WordPress. Asserts the
# structural facts the seeder is supposed to produce (29 page creates, parent
# ordering, front-page wiring, fully-resolved @@MEDIA tokens, redirect count).
#
# Usage:  bash tools/seed-dryrun.sh
# Exit 0 = PASS, non-zero = FAIL. Prints a PASS/FAIL summary.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/il-dryrun.XXXXXX")"
WP_LOG="$WORK/wp-calls.log"
SEED_OUT="$WORK/seed.out"
ATT_FILE="$WORK/att.counter"
PAGE_FILE="$WORK/page.counter"
export WP_LOG ATT_FILE PAGE_FILE

: > "$WP_LOG"
echo 1000 > "$ATT_FILE"
echo 2000 > "$PAGE_FILE"

# ---- the stub -------------------------------------------------------------
_wp_next() {  # $1 = counter file; prints current value, increments file
	local n
	n="$(cat "$1")"
	printf '%s\n' "$((n + 1))" > "$1"
	printf '%s\n' "$n"
}

wp() {
	# log the raw invocation, truncating oversized args (--post_content=...)
	{
		printf 'wp'
		local a s
		for a in "$@"; do
			s=${a//$'\n'/ }
			if [ "${#s}" -gt 100 ]; then s="${s:0:100}...<${#a}b>"; fi
			printf ' %s' "$s"
		done
		printf '\n'
	} >> "$WP_LOG"

	# positional (non-option) tokens, for dispatch
	local pos=() x
	for x in "$@"; do
		case "$x" in --*) ;; *) pos+=("$x") ;; esac
	done
	local cmd="${pos[0]:-}" sub="${pos[1]:-}"

	case "$cmd/$sub" in
		core/is-installed) return 0 ;;
		core/version)      printf '6.5.5\n'; return 0 ;;
		config/get)        return 0 ;;   # print nothing -> DISALLOW_UNFILTERED_HTML guard passes
		theme/activate)    return 0 ;;
		rewrite/*)         return 0 ;;
		option/update)     return 0 ;;
		post/list)         return 0 ;;   # print nothing -> seed.sh always takes the create branch
		post/update)       return 0 ;;
		media/import)
			local id name
			id="$(_wp_next "$ATT_FILE")"
			name="$(basename "${pos[1]:-?}")"
			printf 'RESOLVED att id=%s src=%s\n' "$id" "$name" >> "$WP_LOG"
			printf '%s\n' "$id"
			return 0 ;;
		post/create)
			local id slug=""
			id="$(_wp_next "$PAGE_FILE")"
			for x in "$@"; do
				case "$x" in --post_name=*) slug="${x#--post_name=}" ;; esac
			done
			printf 'RESOLVED page id=%s name=%s\n' "$id" "$slug" >> "$WP_LOG"
			printf '%s\n' "$id"
			return 0 ;;
		eval/*)
			local n
			n="$(printf '%s' "$sub" | grep -oE '[0-9]+' | head -1)"
			printf 'https://staging.example.test/wp-content/uploads/fake/%s.bin\n' "${n:-0}"
			return 0 ;;
		*) return 0 ;;
	esac
}
export -f wp _wp_next

# ---- run the seeder ----------------------------------------------------------
echo "== running: WP=wp ADMIN_USER=dryrun bash scripts/seed.sh =="
( cd "$REPO_ROOT" && WP=wp ADMIN_USER=dryrun bash scripts/seed.sh ) > "$SEED_OUT" 2>&1
SEED_RC=$?

RESOLVED_DIR="$REPO_ROOT/scripts/.pages-resolved"
REDIRECTS="$REPO_ROOT/scripts/redirects.txt"

EXPECTED_SLUGS="home about-us faq-about-the-insectarium faq-about-bugs calendar admission hourslocation summer-camp memberships public-events private-events off-site-events photo-shoots bug-club community shop services care-sheets jumping-spiders ghost-mantis isopods donate internships mma live-bugs tarantulas scorpions true-spiders other-arachnids"

FAIL=0
pass() { printf '  PASS  %s\n' "$1"; }
fail() { printf '  FAIL  %s\n' "$1"; FAIL=$((FAIL + 1)); }

echo
echo "== assertions =="

# 1. seed.sh exit 0
if [ "$SEED_RC" -eq 0 ]; then pass "seed.sh exited 0"
else fail "seed.sh exited $SEED_RC (see $SEED_OUT)"; sed 's/^/    | /' "$SEED_OUT"; fi

# 2. exactly 29 `wp post create`, for the 29 expected slugs
CREATE_N="$(grep -c 'post create' "$WP_LOG")"
if [ "$CREATE_N" -eq 29 ]; then pass "29 'wp post create' calls"
else fail "expected 29 'wp post create' calls, got $CREATE_N"; fi

GOT_SLUGS="$(grep -oE 'RESOLVED page id=[0-9]+ name=[a-z0-9-]+' "$WP_LOG" | sed 's/.*name=//' | sort -u)"
EXP_SORTED="$(printf '%s\n' $EXPECTED_SLUGS | sort -u)"
MISSING="$(comm -23 <(printf '%s\n' "$EXP_SORTED") <(printf '%s\n' "$GOT_SLUGS"))"
EXTRA="$(comm -13 <(printf '%s\n' "$EXP_SORTED") <(printf '%s\n' "$GOT_SLUGS"))"
if [ -z "$MISSING" ] && [ -z "$EXTRA" ]; then pass "created slug set == 29 expected slugs"
else fail "slug set mismatch  missing=[$(echo $MISSING)]  extra=[$(echo $EXTRA)]"; fi

# 3. parent-before-child ordering (line order in the log)
line_of() { grep -n "RESOLVED page id=[0-9]* name=$1\$" "$WP_LOG" | head -1 | cut -d: -f1; }
check_before() {  # $1 parent, rest children
	local parent="$1" pl cl c; shift
	pl="$(line_of "$parent")"
	for c in "$@"; do
		cl="$(line_of "$c")"
		if [ -n "$pl" ] && [ -n "$cl" ] && [ "$pl" -lt "$cl" ]; then
			pass "'$parent' (log line $pl) created before '$c' (log line $cl)"
		else
			fail "'$parent' NOT before '$c' (parent line='$pl' child line='$cl')"
		fi
	done
}
check_before care-sheets jumping-spiders ghost-mantis isopods
check_before live-bugs tarantulas scorpions true-spiders other-arachnids

# 4. `wp option update page_on_front <id>` with home's create id
HOME_ID="$(grep -oE 'RESOLVED page id=[0-9]+ name=home$' "$WP_LOG" | grep -oE '[0-9]+' | head -1)"
if [ -n "$HOME_ID" ] && grep -qE "option update page_on_front ${HOME_ID}\$" "$WP_LOG"; then
	pass "option update page_on_front $HOME_ID (== home create id)"
else
	fail "no 'option update page_on_front $HOME_ID' line (home id='$HOME_ID')"
	grep -n 'option update page_on_front' "$WP_LOG" | sed 's/^/    | /'
fi

# 5. .pages-resolved/ -> 29 files, zero surviving @@MEDIA: tokens
RES_N="$(find "$RESOLVED_DIR" -maxdepth 1 -name '*.html' 2>/dev/null | wc -l | tr -d ' ')"
if [ "$RES_N" -eq 29 ]; then pass "scripts/.pages-resolved/ has 29 .html files"
else fail "scripts/.pages-resolved/ has $RES_N .html files (expected 29)"; fi

SURVIVORS="$(grep -rl '@@MEDIA:' "$RESOLVED_DIR" 2>/dev/null)"
if [ -z "$SURVIVORS" ]; then
	pass "no surviving @@MEDIA: tokens in scripts/.pages-resolved/  (token contract + CRLF fix OK end-to-end)"
else
	fail "@@MEDIA: tokens SURVIVED resolution -- REAL BUG, stop for controller review:"
	echo "$SURVIVORS" | sed 's/^/    file: /'
	grep -rHoE '@@MEDIA:[^@]*@@' "$RESOLVED_DIR" | sort -u | sed 's/^/    tok:  /'
fi

# 6. redirects.txt -> 40 RewriteRule lines (29 page + 11 redirect-only)
if [ -f "$REDIRECTS" ]; then
	RR_N="$(grep -c 'RewriteRule' "$REDIRECTS")"
	if [ "$RR_N" -eq 40 ]; then pass "scripts/redirects.txt has 40 RewriteRule lines"
	else fail "scripts/redirects.txt has $RR_N RewriteRule lines (expected 40)"; fi
	RMISS=""
	for s in $EXPECTED_SLUGS; do
		src="$s"; [ "$s" = home ] && src="index"
		grep -qE "RewriteRule \^${src}\\\\\.html\\\$" "$REDIRECTS" || RMISS="$RMISS $s"
	done
	if [ -z "$RMISS" ]; then pass "every one of the 29 slugs has a RewriteRule"
	else fail "slugs with no RewriteRule:$RMISS"; fi
else
	fail "scripts/redirects.txt was not generated"
fi

# ---- summary ---------------------------------------------------------------
echo
echo "== info =="
echo "  media imports logged : $(grep -c 'RESOLVED att id=' "$WP_LOG")"
echo "  work dir (kept)      : $WORK"
echo "  wp call log          : $WP_LOG"
echo "  seed.sh output       : $SEED_OUT"
echo
if [ "$FAIL" -eq 0 ]; then
	echo "PART 1 RESULT: PASS"
	exit 0
else
	echo "PART 1 RESULT: FAIL ($FAIL failed assertion(s))"
	exit 1
fi
