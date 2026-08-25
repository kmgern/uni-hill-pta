#!/usr/bin/env bash
# Serve the site locally over HTTP and open a page in the browser.
#
#   scripts/serve.sh [page.html] [port]
#   scripts/serve.sh stop
#
# Defaults: index.html on port 8000. If the port is taken by something
# else, the next free port is used and reported.
#
# Any preview server a previous run started is stopped first, so repeat
# runs never leave orphaned python processes behind.
#
# Set OPEN=0 to start the server without opening a browser window.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="${TMPDIR:-/tmp}"; TMP="${TMP%/}"
PIDFILE="$TMP/unihill-pta-preview.pid"
LOGFILE="$TMP/unihill-pta-preview.log"
# Distinctive argv so the sweep below only ever matches servers we started.
MARKER="http.server .*--directory $ROOT"

port_owner() { lsof -ti "tcp:$1" -sTCP:LISTEN 2>/dev/null || true; }

# Sets KILLED to the number of servers stopped.
stop_servers() {
  local pid
  KILLED=0
  if [[ -f "$PIDFILE" ]]; then
    pid="$(cat "$PIDFILE" 2>/dev/null || true)"
    if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null && KILLED=$((KILLED + 1))
    fi
    rm -f "$PIDFILE"
  fi
  # Strays from earlier runs whose pidfile was lost (crashed shell, reboot).
  while read -r pid; do
    [[ -n "$pid" ]] || continue
    kill "$pid" 2>/dev/null && KILLED=$((KILLED + 1))
  done < <(pgrep -f "$MARKER" 2>/dev/null || true)
  # Give the kernel a moment to release the listening socket.
  if (( KILLED > 0 )); then
    for _ in 1 2 3 4 5 6 7 8 9 10; do
      pgrep -f "$MARKER" >/dev/null 2>&1 || break
      sleep 0.2
    done
  fi
  return 0
}

if [[ "${1:-}" == "stop" ]]; then
  stop_servers
  if (( KILLED > 0 )); then
    echo "stopped $KILLED preview server(s)"
  else
    echo "no preview server was running"
  fi
  exit 0
fi

PAGE="${1:-index.html}"
PORT="${2:-8000}"

# Accept "meetings" as well as "meetings.html".
[[ "$PAGE" == *.* || "$PAGE" == */ ]] || PAGE="$PAGE.html"
if [[ ! -e "$ROOT/$PAGE" ]]; then
  echo "error: $PAGE not found in $ROOT" >&2
  exit 1
fi

stop_servers
if (( KILLED > 0 )); then echo "stopped $KILLED previous preview server(s)"; fi

# Pick a free port, starting at the requested one.
START_PORT="$PORT"
for _ in $(seq 0 9); do
  [[ -z "$(port_owner "$PORT")" ]] && break
  PORT=$((PORT + 1))
done
if [[ -n "$(port_owner "$PORT")" ]]; then
  echo "error: no free port in ${START_PORT}-$((START_PORT + 9))" >&2
  exit 1
fi
[[ "$PORT" == "$START_PORT" ]] || echo "port $START_PORT was busy; using $PORT"

nohup python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$ROOT" \
  >"$LOGFILE" 2>&1 &
SERVER_PID=$!
echo "$SERVER_PID" > "$PIDFILE"

URL="http://localhost:$PORT/$PAGE"

# Wait for it to accept connections before opening the browser.
for _ in $(seq 1 25); do
  if curl -fsS -o /dev/null "http://127.0.0.1:$PORT/" 2>/dev/null; then break; fi
  if ! kill -0 "$SERVER_PID" 2>/dev/null; then
    echo "error: server exited on startup:" >&2
    cat "$LOGFILE" >&2
    rm -f "$PIDFILE"
    exit 1
  fi
  sleep 0.2
done

echo "serving $ROOT at $URL (pid $SERVER_PID)"
echo "log: $LOGFILE"
echo "stop with: scripts/serve.sh stop"

if [[ "${OPEN:-1}" != "0" ]]; then
  if command -v open >/dev/null 2>&1; then open "$URL"
  elif command -v xdg-open >/dev/null 2>&1; then xdg-open "$URL" >/dev/null 2>&1 &
  else echo "note: no 'open' command; visit $URL yourself"
  fi
fi
