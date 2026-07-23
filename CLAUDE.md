# CLAUDE.md — Uni Hill PTA website

Static site for the University Hill Elementary (Uni Hill) PTA, Boulder CO.
Four pages of plain HTML/CSS/JS. **No framework, no build step, no npm, no
dependencies** — this is a hard constraint, not an accident. The PTA edits
this site by hand. Keep every change hand-editable and directly openable
via `file://` or any static host.

## File map

| Path | What it is |
| --- | --- |
| `index.html` | Home: hero, photo band, volunteering, donations, teasers |
| `whatsapp.html` | WhatsApp group directory + fake-but-editable chat preview |
| `meetings.html` | Meetings list (JS-rendered), calendar embed, topic form |
| `mission.html` | Mission statement, pillars, photo gallery |
| `css/styles.css` | The only stylesheet. Design tokens at top |
| `js/main.js` | Nav toggle + footer year. Keep tiny |
| `js/meetings-data.js` | `MEETINGS` array + renderer. The PTA edits the array |
| `templates/page.html` | Boilerplate for new pages (canonical header/footer) |
| `scripts/screenshot.sh` | Render a page to PNG (desktop + mobile) |
| `scripts/check.sh` | Preflight: broken local refs, chrome drift, TODOs |
| `img/` | Photos (`event-*` = PTA events, `school-*` = building) + logo |
| `fonts/` | Self-hosted Poppins woff2 (weights 200–600) |

## Design system ("Midnight" theme)

All colors live in the `:root` block at the top of `css/styles.css`.
Never hard-code a hex in HTML or elsewhere in the CSS — add a token.

- Backgrounds: `--ink` (page) → `--ink-raised` (sections/cards) →
  `--ink-accent` (rows) — three steps of the same deep navy.
- Headlines: Poppins weight 200 in `--powder`, with `<strong>` for the
  white weight-400 emphasis words: `<h2>Where your money <strong>actually
  goes.</strong></h2>`. Keep that pattern.
- Section labels: coral uppercase kicker, bilingual with a middle dot:
  `<p class="section-label">Donate · Donaciones</p>`. Every section gets one.
- Festive accents (`--yellow --pink --green --orange --purple --coral`)
  come from the brand deck's alebrije/papel picado art. Use them in small
  doses: logo tints, bar fills, the picado divider. Never as large fills.
- Fonts: self-hosted Poppins only. Do not add Google Fonts `<link>` tags
  or any external requests — the site must work fully offline.

### The alebrije logo

`img/logo-white.png` is a white cutout of the school's alebrije mark used
as a CSS mask, so it can be tinted with any background color:

```html
<span class="logo-mark" style="background-color: var(--pink)"></span>
```

Width is set per-context (`.logo-mark` has the aspect ratio). This is the
brand's core trick — the deck shows the mark recolored endlessly. Prefer a
tinted `logo-mark` over importing new icon art.

### Arches & papel picado

- Arch-topped photos (`border-radius: 999px 999px 14px 14px`) echo the
  school's 1906 brick arches. Used in the home photo band and donate
  section. Per the owner: arches on photos are good, but **not** on the
  hero — the hero belongs to the big logo.
- The papel picado divider is an inline SVG (`.picado`) in each page that
  uses it. If you edit the flags, keep the fills to token colors.

### Voice

Warm, funny, bilingual-lite. Key phrases from the brand deck: "We help
kids find their superpowers", "Soar beyond boundaries". CTAs echo Spanish
after a middle dot ("Volunteer · Sé voluntario"). School est. 1906,
Boulder's oldest bilingual school, 50/50 English/Spanish K–5.

## Duplicated page chrome (important)

The header, nav, footer, and picado SVG are **copied into every page** —
there is no include system. When you change any of them:

1. Update all four pages *and* `templates/page.html`.
2. Run `scripts/check.sh` — it diffs the chrome across pages and fails on
   drift.

New pages start from `templates/page.html` (copy, fill the TODOs, add the
page to the nav in every file).

## Placeholders

Unlaunched details (donation URL, WhatsApp invites, calendar ID, form
URL, contact email) are placeholder values marked with `<!-- TODO: ... -->`
comments and cataloged in `README.md` → "TODO before launch". If you add a
placeholder, add it in both places. If you resolve one, remove it from both.

## Previewing and verifying changes

There is no dev server; pages open directly. To verify visually:

```sh
scripts/screenshot.sh index.html        # desktop (1440) + mobile PNGs
scripts/screenshot.sh meetings.html out/  # optional output dir
```

Gotchas learned the hard way (both handled by the script):

- Headless Chromium blocks CSS `mask-image` from `file://` URLs unless
  launched with `--allow-file-access-from-files`. Without it every logo
  silently disappears from screenshots.
- Headless Chromium has a ~500px minimum layout width. A "390px" capture
  is actually a 500px layout cropped to 390 — so shoot mobile at 500px
  and trust the breakpoints (`960px` and `560px` in `styles.css`).

Before committing, run `scripts/check.sh`. It verifies every local
`src`/`href` target exists, the shared chrome matches across pages, and
lists remaining TODOs.

## Do not

- Add a build step, framework, npm, or CDN/external requests.
- Rotate UI elements (the owner explicitly dislikes rotated pills/photos).
- Overlap photos in layouts — side-by-side with gaps.
- Replace the photos with stock imagery; they're real Uni Hill photos
  (from the brand deck and the PTA's photo library).
- Commit screenshots or scratch output (`out/`, `*.png` at repo root).
