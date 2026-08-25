---
name: preview
description: Serve the Uni Hill PTA site locally over HTTP and open a page in the browser. Use when the user wants to preview, view, serve, or run the site locally, or asks to "open the site", "see it in a browser", or "start a local server" — and when a change needs to be checked in a real browser rather than a screenshot. Also handles stopping a running preview server.
allowed-tools: Bash, Read
---

# Local preview

`scripts/serve.sh` runs Python's built-in `http.server` over the repo root
and opens a page. It stops any preview server a previous run started
before starting a new one, so orphaned servers don't pile up.

## Start it

```sh
scripts/serve.sh                    # index.html on http://localhost:8000
scripts/serve.sh meetings.html      # any page (".html" optional)
scripts/serve.sh whatsapp.html 8080 # explicit port
```

The page argument defaults to `index.html`. If the port is busy the
script moves to the next free one and prints the URL it settled on —
always report the URL it actually printed, not the one you asked for.

Run it in the background (`run_in_background: true`) — it daemonizes the
server with `nohup` and returns, but the browser launch can take a beat.
Then tell the user the URL and which page opened.

`OPEN=0 scripts/serve.sh` starts the server without opening a browser —
use that when you only need the server up (e.g. to fetch a page yourself),
not when the user asked to *look* at something.

## Stop it

```sh
scripts/serve.sh stop
```

Also worth running when the user is done, or says something is "stuck" or
"still running on 8000".

## Notes

- Serving over `http://` rather than `file://` is the point: it matches
  how GitHub Pages serves the site, and CSS `mask-image` (the tinted
  alebrije logos) works without the `--allow-file-access-from-files`
  workaround `scripts/screenshot.sh` needs.
- The site is static with no build step, so edits show up on reload —
  never restart the server just because a file changed.
- Server log: `$TMPDIR/unihill-pta-preview.log`. Check it if a page 404s.
- For a visual check *you* need to make rather than the user, prefer
  `scripts/screenshot.sh` — it needs no server.
