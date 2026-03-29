#!/bin/bash
# AI Browser — dedicated Chrome for AI agent testing
# Profile: ~/.ai-browser/chrome-profile
# Remote debugging: http://127.0.0.1:9224

PROFILE_DIR="$HOME/.ai-browser/chrome-profile"
DEBUGGING_PORT=9224

# If AI Browser is already running (port responds), bring it to front and exit
if curl -s "http://127.0.0.1:${DEBUGGING_PORT}/json/version" >/dev/null 2>&1; then
  echo "AI Browser already running on port ${DEBUGGING_PORT}"
  AI_PID=$(lsof -ti :"${DEBUGGING_PORT}" -sTCP:LISTEN 2>/dev/null | head -1)
  if [ -n "$AI_PID" ]; then
    osascript -e "tell application \"System Events\" to set frontmost of (first process whose unix id is $AI_PID) to true" 2>/dev/null
  fi
  exit 0
fi

mkdir -p "$PROFILE_DIR"

exec open -n -a "Google Chrome" --args \
  --user-data-dir="$PROFILE_DIR" \
  --remote-debugging-port="${DEBUGGING_PORT}" \
  --no-first-run \
  --no-default-browser-check \
  "$@"
