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
    r"""(?P<pre>(?:src|href|data-src)\s*=\s*["']|url\(\s*(?:["']|&quot;|&\#0?34;|&\#0?39;|&apos;)?)"""
    r"""(?P<url>(?:https?://(?:www\.)?pdxinsectarium\.org/)?/?(?:uploads|files/theme/files/images)/[^"'()\s&]+)""",
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


_KEEP_SCRIPT_RE = re.compile(r"squareup\.com/appointments|fareharbor\.com/embeds", re.I)


def strip_cruft(text):
    text = re.sub(
        r"<script\b[^>]*>.*?</script>",
        lambda m: m.group(0) if _KEEP_SCRIPT_RE.search(m.group(0)) else "",
        text, flags=re.S | re.I,
    )
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


CONTENT_RE = re.compile(r'<div id="wsite-content"[^>]*>(?P<body>.*?)\s*</div>\s*</div>\s*(?:<!--[^>]*-->\s*)?<div class="footer-wrap">', re.S)
BANNER_RE = re.compile(r'<div class="banner-wrap[^"]*">(?P<inner>.*?)</div>\s*<div class="main-wrap">', re.S)
# page-specific inline styles: every <style>...</style> in <head> keyed on the
# per-element UUID selector #element- (skip the Weebly framework typography block).
PAGE_STYLE_RE = re.compile(r"<style[^>]*>(?P<css>(?:(?!</style>).)*?#element-(?:(?!</style>).)*?)</style>", re.S | re.I)


def extract_one(slug):
    fn = PAGES[slug][0]
    raw = open(os.path.join(EXPORT, fn), encoding="utf-8", errors="ignore").read()

    m = CONTENT_RE.search(raw)
    if not m:
        raise SystemExit(f"{slug}: could not locate #wsite-content .. footer-wrap")
    body = m.group("body")

    bm = BANNER_RE.search(raw)
    if bm and bm.group("inner").strip():
        body = bm.group("inner") + "\n" + body

    styles = "\n".join(f"<style>{s.group('css').strip()}</style>" for s in PAGE_STYLE_RE.finditer(raw))

    frag = (styles + "\n" if styles else "") + body
    frag = strip_cruft(frag)
    frag = rewrite_links(frag)
    frag = tokenize_assets(frag)
    flag_placeholders(slug, frag)

    frag = frag.strip() + "\n"
    open(os.path.join(PAGES_OUT, f"{slug}.html"), "w", encoding="utf-8", newline="\n").write(frag)
    return len(frag)


def main():
    os.makedirs(PAGES_OUT, exist_ok=True)
    os.makedirs(MEDIA_OUT, exist_ok=True)
    for slug in BUILD_ORDER:
        n = extract_one(slug)
        print(f"  {slug:32} {n:>8} bytes")

    # copy referenced media, write manifest
    with open(MANIFEST, "w", encoding="utf-8", newline="\n") as mf:
        for orig, fn in sorted(media_map.items()):
            src = find_source_on_disk(orig)
            shutil.copyfile(src, os.path.join(MEDIA_OUT, fn))
            mf.write(f"media/{fn}\t@@MEDIA:{orig}@@\n")
    print(f"  media files: {len(media_map)}")

    open(REPORT, "w", encoding="utf-8", newline="\n").write("\n".join(report_lines) + "\n")
    print(f"  report: {REPORT} ({len(report_lines)} lines)")


if __name__ == "__main__":
    main()
