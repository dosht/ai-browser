#!/bin/bash
# AI Browser installer
# Usage: curl -fsSL https://raw.githubusercontent.com/dosht/ai-browser/main/install.sh | bash
set -euo pipefail

DEBUGGING_PORT=9224
PROFILE_DIR="$HOME/.ai-browser/chrome-profile"
LAUNCHER_DIR="$HOME/.local/bin"
LAUNCHER_PATH="$LAUNCHER_DIR/ai-browser"
APP_PATH="/Applications/AI Browser.app"
CHROME_PATH="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# ── helpers ──────────────────────────────────────────────────────────────────

info()    { printf "  \033[34m-->\033[0m %s\n" "$*"; }
success() { printf "  \033[32m✓\033[0m  %s\n" "$*"; }
warn()    { printf "  \033[33m!\033[0m  %s\n" "$*"; }
die()     { printf "\n  \033[31mERROR:\033[0m %s\n\n" "$*" >&2; exit 1; }

# ── preflight ────────────────────────────────────────────────────────────────

echo
echo "==> Installing AI Browser..."
echo

[ -f "$CHROME_PATH" ] || die "Google Chrome not found at: $CHROME_PATH"

# ── launcher script content ──────────────────────────────────────────────────

LAUNCHER_CONTENT='#!/bin/bash
# AI Browser — dedicated Chrome for AI agent testing
# Profile: ~/.ai-browser/chrome-profile
# Remote debugging: http://127.0.0.1:'"${DEBUGGING_PORT}"'

PROFILE_DIR="$HOME/.ai-browser/chrome-profile"
DEBUGGING_PORT='"${DEBUGGING_PORT}"'

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
'

# ── 1. profile directory ─────────────────────────────────────────────────────

mkdir -p "$PROFILE_DIR"
success "Profile directory: $PROFILE_DIR"

# ── 2. CLI launcher ──────────────────────────────────────────────────────────

mkdir -p "$LAUNCHER_DIR"
printf '%s' "$LAUNCHER_CONTENT" > "$LAUNCHER_PATH"
chmod +x "$LAUNCHER_PATH"
success "CLI launcher: $LAUNCHER_PATH"

# Check if launcher dir is on PATH
if ! echo "$PATH" | tr ':' '\n' | grep -qx "$LAUNCHER_DIR"; then
  warn "$LAUNCHER_DIR is not on your PATH"
  warn "Add this to your shell profile: export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

# ── 3. macOS .app bundle ─────────────────────────────────────────────────────

create_app_bundle() {
  local contents="$APP_PATH/Contents"
  local macos="$contents/MacOS"
  local resources="$contents/Resources"

  mkdir -p "$macos" "$resources"

  # Info.plist
  cat > "$contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key>
  <string>AI Browser</string>
  <key>CFBundleDisplayName</key>
  <string>AI Browser</string>
  <key>CFBundleIdentifier</key>
  <string>com.dosht.ai-browser</string>
  <key>CFBundleVersion</key>
  <string>1.0.0</string>
  <key>CFBundleShortVersionString</key>
  <string>1.0.0</string>
  <key>CFBundleExecutable</key>
  <string>ai-browser</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleIconFile</key>
  <string>app</string>
  <key>LSMinimumSystemVersion</key>
  <string>10.15</string>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

  # Executable (same script as CLI launcher)
  printf '%s' "$LAUNCHER_CONTENT" > "$macos/ai-browser"
  chmod +x "$macos/ai-browser"

  # Borrow Chrome's icon
  local chrome_icon="/Applications/Google Chrome.app/Contents/Resources/app.icns"
  if [ -f "$chrome_icon" ]; then
    cp "$chrome_icon" "$resources/app.icns"
  fi
}

if create_app_bundle 2>/dev/null; then
  success "macOS app bundle: $APP_PATH"
else
  warn "Could not create $APP_PATH (permission denied?)"
  warn "Try: sudo bash install.sh"
  warn "The CLI launcher still works without the .app bundle."
fi

# ── done ─────────────────────────────────────────────────────────────────────

echo
echo "  AI Browser installed successfully."
echo
echo "  Usage:"
echo "    ai-browser               # launch from terminal"
echo "    open -a 'AI Browser'     # launch from shell"
echo "    # or find 'AI Browser' in Spotlight / Launchpad"
echo
echo "  Once running, connect your AI agent via:"
echo "    --browserUrl http://127.0.0.1:${DEBUGGING_PORT}"
echo
