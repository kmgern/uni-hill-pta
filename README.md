# Uni Hill PTA Website

Static website for the University Hill Elementary (Uni Hill) PTA, Boulder CO.
Plain HTML, CSS and JavaScript — no framework, no build step. Open
`index.html` in a browser, or host the folder on any static host
(GitHub Pages, Netlify, etc.).

## Pages

| File | Purpose |
| --- | --- |
| `index.html` | Home — volunteer opportunities and donations |
| `whatsapp.html` | WhatsApp group directory + example chat |
| `meetings.html` | When meetings happen, shared calendar, topic suggestions |
| `mission.html` | Mission, pillars, photo gallery |

## For AI agents / developers

`CLAUDE.md` documents the design system, conventions, and gotchas.
Helper scripts (need only a Chromium binary and Python 3):

- `scripts/screenshot.sh [page] [outdir]` — render a page to desktop +
  mobile PNGs for visual verification.
- `scripts/check.sh` — preflight: broken local links, header/footer drift
  between pages, remaining TODO placeholders. Run before committing.
- `scripts/serve.sh [page] [port]` — serve the site at
  `http://localhost:8000` and open a page; `scripts/serve.sh stop` to stop.
- `scripts/deploy.sh "message"` — commit, push to `main`, and watch until
  the change is live at www.unihillpta.com. Uses the `gh` CLI to report
  build failures; without it, falls back to polling the live site.
- `templates/page.html` — boilerplate for new pages.

The site is hosted on GitHub Pages straight from the `main` branch, so
pushing to `main` publishes it. Claude Code skills for both helpers live
in `.claude/skills/` (`/preview` and `/deploy`).

## Editing guide

- **Colors / theme** — everything lives in the `:root` block at the top of
  `css/styles.css`. Change `--ink` (and friends) to re-theme the site.
- **Meetings** — dates live on the shared Google Calendar embedded in
  `meetings.html`; add them there, not in the HTML.
- **The logo** — `img/logo-white.png` is a white version of the alebrije
  mark used as a CSS mask, so it can be tinted any color:
  `<span class="logo-mark" style="background-color: var(--pink)"></span>`
- **WhatsApp chat preview** — plain HTML bubbles in `whatsapp.html`;
  edit the text to keep it feeling current.
- **Photos** — all in `img/`. `event-*` photos came from PTA events,
  `school-*` are the building. Swap freely; keep alt text accurate.

## TODO before launch

Search the HTML for `TODO` comments. Placeholders that need real values:

1. **Volunteer stats** — the numbers on the home page (1,200+ hours, 14
   events) are illustrative; replace with real figures.
2. **Example meeting topics** — the "things families have asked about"
   list in `meetings.html` is plausible filler; swap in real questions.
3. **Mailing address** — confirm `956 16th Street, Boulder CO` in the
   footer of every page.
4. **Second 5th-grade WhatsApp group** — all seven grade links in
   `whatsapp.html` were verified in Aug 2026 against the group name each
   invite page shows. A second 5th-grade group, "UniHill 5to/th
   Families/ias" (`chat.whatsapp.com/GZDWYDjGEkv9sNQ2cjlX7y`), is not
   linked anywhere — confirm whether it replaces or supplements the 5th
   grade link.

The funding breakdown in the donate section is real: the five bars are
actual spend, and the percentages are each category's share of the five
totalled ($181,733). Update the dollar amounts, the `width:` on each bar
and the `%` at the end of the row together when new figures come in.

Contact goes to `unihillpta@gmail.com` throughout; each `mailto:` carries
a subject line matched to its context (general question, meeting topic
suggestion, photo album access).
