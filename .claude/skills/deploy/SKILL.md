---
name: deploy
description: Publish the Uni Hill PTA site — commit, push to main, and watch the GitHub Pages build until the change is live at www.unihillpta.com. Use when the user wants to deploy, publish, ship, push live, or "put it on the site", or asks whether a pushed change has gone live yet or why a deploy failed.
allowed-tools: Bash, Read, Grep
---

# Deploy

The site is GitHub Pages served straight from `main` — pushing to main is
the deploy. `scripts/deploy.sh` runs preflight, commits, pushes, then
watches the build for that exact commit and confirms the live site is
serving it.

## Before pushing

Pushing publishes to a real public site for a real school community, so:

1. Show the user what will ship: `git status --short` and `git diff --stat`.
2. Propose a commit message in the style of recent commits
   (`git log --oneline -5` — short, imperative, plain English).
3. **Get the user's explicit go-ahead** before running the script. Asking
   for a deploy in general is not a yes to a specific diff — confirm the
   diff and message, unless they already told you both.

## Deploy

```sh
scripts/deploy.sh "Fix the 5th grade WhatsApp link"
```

The script, in order:

- refuses to run anywhere but `main`;
- runs `scripts/check.sh` and aborts on failure (broken local refs or
  header/footer drift) — fix the failure, don't set `SKIP_CHECK=1`;
- `git add -A`, commits, pushes to `origin main`;
- watches, then prints `LIVE` / `DEPLOYED`, or fails.

Run it in the background (`run_in_background: true`). Builds have been
taking 35–55s; add CDN propagation and a normal deploy finishes in about
a minute. Report the result when it finishes.

To watch a push someone already made: `scripts/deploy.sh --watch`.

## How the watch works

Two phases, because "the build succeeded" and "the site serves it" are
different claims:

1. **Build status** — via the `gh` CLI, polling
   `repos/unihillpta/uni-hill-pta/pages/builds` for the entry whose
   `.commit` equals the pushed SHA. Keying on the SHA matters: it means a
   stale failure from an earlier push is never reported as this deploy's,
   and it surfaces GitHub's own `error.message` on a real build failure.
2. **Live content** — each changed file is fetched from
   `https://www.unihillpta.com` with a cache-buster and its SHA-256
   compared to the local copy, so `LIVE` means the public site is really
   serving the new bytes.

If `gh` is ever missing or unauthenticated the script says so and falls
back to phase 2 alone — still proof the deploy landed, but it can't
explain a failure.

## Reporting back

- **`LIVE`** — say so, with the URL and the page(s) that changed.
- **`DEPLOYED`** — build succeeded but the push touched only docs or
  scripts, so there was nothing user-visible to verify. Say that plainly.
- **`PAGES BUILD FAILED`** — the commit is on main but the site was not
  updated. Relay GitHub's message. To dig in:
  `gh run list --workflow=pages-build-deployment --limit 3` and
  `gh run view <id> --log-failed`. Fixing forward means another commit
  and another deploy — main already has the bad commit.
- **`TIMED OUT`** — read which phase. Waiting on the *build* means it
  never finished (check `gh run list`). Still stale at the *CDN* after a
  successful build is propagation lag, not a failure: say the build
  succeeded, and re-check with `scripts/deploy.sh --watch`.

Never report a deploy as live on the strength of the push alone.
