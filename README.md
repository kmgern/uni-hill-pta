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
- `templates/page.html` — boilerplate for new pages.

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
2. **Funding split** — the 45/35/20 breakdown in the donate section is
   illustrative; replace with the real budget split.
3. **Example meeting topics** — the "things families have asked about"
   list in `meetings.html` is plausible filler; swap in real questions.
4. **Mailing address** — confirm `956 16th Street, Boulder CO` in the
   footer of every page.

Contact goes to `unihillpta@gmail.com` throughout; each `mailto:` carries
a subject line matched to its context (general question, meeting topic
suggestion, photo album access).
