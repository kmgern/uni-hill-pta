#!/usr/bin/env bash
# Preflight checks for the site. Run before committing.
#
#   scripts/check.sh
#
# 1. Every local src/href target referenced by the HTML/CSS exists.
# 2. The duplicated page chrome (header/footer) hasn't drifted between pages.
# 3. Lists remaining TODO placeholders (informational, not a failure).
set -euo pipefail
cd "$(cd "$(dirname "$0")/.." && pwd)"

python3 - <<'PY'
import re, sys, pathlib

fail = False
pages = ["index.html", "whatsapp.html", "meetings.html", "mission.html"]
all_html = pages + ["templates/page.html"]

# --- 1. local references resolve -------------------------------------------
for f in all_html + ["css/styles.css"]:
    text = pathlib.Path(f).read_text()
    refs = re.findall(r'(?:src|href)="([^"]+)"', text)
    refs += re.findall(r'url\(([^)]+)\)', text)
    # templates/page.html is copied to the repo root before use, so its
    # root-relative refs are resolved against the root, not templates/
    base = pathlib.Path(".") if f.startswith("templates/") else pathlib.Path(f).parent
    for ref in refs:
        ref = ref.strip('\'"')
        if ref.startswith(("http", "mailto:", "#", "data:")):
            continue
        target = (base / ref.split("#")[0]).resolve()
        if not target.exists():
            print(f"BROKEN  {f}: {ref}")
            fail = True

# --- 2. shared chrome is identical across pages ----------------------------
def extract(text, tag):
    m = re.search(rf"<{tag}[^>]*>.*?</{tag}>", text, re.S)
    return m.group(0) if m else ""

def normalize(chunk):
    # Ignore per-page differences that are expected inside the chrome
    chunk = re.sub(r'\s*aria-current="page"', "", chunk)
    chunk = re.sub(r"<!--.*?-->", "", chunk, flags=re.S)  # comments may differ
    return re.sub(r"\s+", " ", chunk).strip()

ref_page = pathlib.Path(pages[0]).read_text()
for tag, label in [("header", "header"), ("footer", "footer")]:
    reference = normalize(extract(ref_page, tag))
    for f in all_html[1:]:
        other = normalize(extract(pathlib.Path(f).read_text(), tag))
        if other != reference:
            print(f"DRIFT   {f}: <{label}> differs from {pages[0]}")
            fail = True

# --- 3. TODO inventory (informational) -------------------------------------
todos = 0
for f in all_html:
    for i, line in enumerate(pathlib.Path(f).read_text().splitlines(), 1):
        if "TODO" in line:
            todos += 1
print(f"\n{todos} TODO placeholder(s) remain (see README.md launch checklist)")

sys.exit(1 if fail else 0)
PY

echo "check.sh: OK"
