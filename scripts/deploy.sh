#!/usr/bin/env bash
# Commit, push to main, and watch the GitHub Pages build until it is live.
#
#   scripts/deploy.sh "commit message"
#   scripts/deploy.sh --watch            # skip commit/push, just watch
#
# Runs scripts/check.sh first and refuses to deploy if it fails
# (SKIP_CHECK=1 overrides).
#
# Watching happens in two phases:
#   1. the Pages build for *this commit* (via the gh CLI), which is what
#      reports a real build failure and GitHub's error message;
#   2. the public site actually serving the new bytes, checked by hashing
#      each changed file — a built deploy still has to reach the CDN.
# Without gh (or without auth) phase 1 is skipped and phase 2 alone
# decides, which still proves the deploy landed but cannot explain a
# failure.
#
# Env: TIMEOUT (seconds, default 420), POLL (seconds, default 5).
set -euo pipefail

cd "$(cd "$(dirname "$0")/.." && pwd)"
TIMEOUT="${TIMEOUT:-420}"
POLL="${POLL:-5}"

WATCH_ONLY=0
[[ "${1:-}" == "--watch" ]] && WATCH_ONLY=1
MESSAGE="${1:-}"

# --- where the site lives --------------------------------------------------
REMOTE="$(git remote get-url origin)"
SLUG="$(echo "$REMOTE" | sed -E 's#(git@github\.com:|https://github\.com/)##; s#\.git$##')"
OWNER="${SLUG%%/*}"
REPO="${SLUG##*/}"
if [[ -s CNAME ]]; then
  BASE="https://$(tr -d '[:space:]' < CNAME)"
else
  BASE="https://${OWNER}.github.io/${REPO}"
fi
ACTIONS_URL="https://github.com/$OWNER/$REPO/actions"

HAVE_GH=0
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  HAVE_GH=1
fi

branch="$(git rev-parse --abbrev-ref HEAD)"
if [[ "$branch" != "main" ]]; then
  echo "error: on branch '$branch'; deploy publishes main only" >&2
  exit 1
fi

git fetch --quiet origin main
BEFORE="$(git rev-parse origin/main)"

# --- commit & push ---------------------------------------------------------
if (( ! WATCH_ONLY )); then
  if [[ -n "$(git status --porcelain)" ]]; then
    if [[ -z "$MESSAGE" ]]; then
      echo "error: uncommitted changes; pass a commit message" >&2
      echo "usage: scripts/deploy.sh \"commit message\"" >&2
      exit 1
    fi
    if [[ "${SKIP_CHECK:-0}" != "1" ]]; then
      echo "--- scripts/check.sh ---"
      scripts/check.sh
      echo
    fi
    git add -A
    git commit -q -m "$MESSAGE"
    echo "committed $(git rev-parse --short HEAD): $MESSAGE"
  else
    echo "working tree clean; nothing new to commit"
  fi

  if [[ "$(git rev-parse HEAD)" == "$BEFORE" ]]; then
    echo "main is already up to date with origin; nothing to deploy"
    exit 0
  fi
  git push --quiet origin main
  echo "pushed $(git rev-parse --short "$BEFORE")..$(git rev-parse --short HEAD) to origin/main"
fi

AFTER="$(git rev-parse HEAD)"
START=$(date +%s)
elapsed() { echo $(( $(date +%s) - START )); }
if (( TIMEOUT >= 60 )); then WINDOW="$((TIMEOUT / 60)) min"; else WINDOW="${TIMEOUT}s"; fi

echo
if (( HAVE_GH )); then
  echo "watching the Pages build for $(git rev-parse --short "$AFTER") (up to $WINDOW)"
else
  echo "watching $BASE (up to $WINDOW) — gh not available, build status unknown"
fi

# --- phase 1: the Pages build for this exact commit ------------------------
# Prints "<status>\t<error message>", or nothing if GitHub has not
# registered a build for this commit yet.
gh_build_for() {
  SHA="$1" gh api "repos/$OWNER/$REPO/pages/builds?per_page=10" \
    --jq 'first(.[] | select(.commit == env.SHA)) | [.status, (.error.message // "")] | @tsv' \
    2>/dev/null || true
}

if (( HAVE_GH )); then
  while true; do
    line="$(gh_build_for "$AFTER")"
    state="$(printf '%s' "$line" | cut -f1)"
    case "$state" in
      built)
        echo "  build succeeded after $(elapsed)s"
        break
        ;;
      errored)
        error="$(printf '%s' "$line" | cut -f2)"
        echo
        echo "PAGES BUILD FAILED: ${error:-GitHub reported no message}" >&2
        echo "the commit is pushed but the site was not updated." >&2
        echo "details: $ACTIONS_URL" >&2
        exit 1
        ;;
      *)
        if (( $(elapsed) >= TIMEOUT )); then
          echo
          echo "TIMED OUT after $(elapsed)s waiting for the Pages build to finish." >&2
          echo "last status: ${state:-no build registered for this commit yet}" >&2
          echo "check: $ACTIONS_URL" >&2
          exit 1
        fi
        printf '  %3ds  build %s\n' "$(elapsed)" "${state:-queued}"
        sleep "$POLL"
        ;;
    esac
  done
fi

# --- phase 2: the public site is really serving the new bytes --------------
# Only files GitHub Pages actually serves, skipping deletions and repo docs.
# (bash 3.2 on macOS has no mapfile, hence the read loop)
CHANGED=()
while IFS= read -r f; do
  [[ -n "$f" ]] && CHANGED+=("$f")
done < <(
  git diff --name-only --diff-filter=d "$BEFORE" "$AFTER" -- \
    '*.html' '*.css' '*.js' 'img/*' 'fonts/*' \
    | grep -v '^templates/' | head -12
)

if (( ${#CHANGED[@]} == 0 )); then
  if (( HAVE_GH )); then
    echo
    echo "DEPLOYED — build succeeded; no served files changed, so there is"
    echo "nothing user-visible to verify at $BASE"
    exit 0
  fi
  echo "no served files changed in this push — nothing to verify on the live site."
  echo "the Pages build still runs; check $BASE in a minute if you expect a change."
  exit 0
fi
printf 'verifying live content: %s\n' "${CHANGED[*]}"

sha_local() { shasum -a 256 "$1" | cut -d' ' -f1; }
sha_live()  { curl -fsS --max-time 20 "$BASE/$1?_=$(date +%s)$RANDOM" 2>/dev/null | shasum -a 256 | cut -d' ' -f1; }

while true; do
  pending=()
  for f in "${CHANGED[@]}"; do
    [[ "$(sha_live "$f")" == "$(sha_local "$f")" ]] || pending+=("$f")
  done

  if (( ${#pending[@]} == 0 )); then
    echo
    echo "LIVE — $BASE is serving $(git rev-parse --short "$AFTER") ($(elapsed)s)"
    exit 0
  fi

  if (( $(elapsed) >= TIMEOUT )); then
    echo
    echo "TIMED OUT after $(elapsed)s — still stale: ${pending[*]}" >&2
    if (( HAVE_GH )); then
      echo "the Pages build succeeded, so this is a CDN lag, not a build failure." >&2
      echo "the change should appear shortly; re-check with: scripts/deploy.sh --watch" >&2
    else
      echo "the push succeeded, so this is either a slow or a failed Pages build." >&2
      echo "check: $ACTIONS_URL" >&2
    fi
    exit 1
  fi

  printf '  %3ds  waiting on %d file(s) at the CDN\n' "$(elapsed)" "${#pending[@]}"
  sleep "$POLL"
done
