#!/bin/bash
# AI Browser uninstaller
# Removes the .app bundle and CLI launcher.
# Preserves the browser profile at ~/.ai-browser/ so your AI testing data survives.
set -euo pipefail

LAUNCHER_PATH="$HOME/.local/bin/ai-browser"
APP_PATH="/Applications/AI Browser.app"
PROFILE_DIR="$HOME/.ai-browser"

success() { printf "  \033[32m✓\033[0m  %s\n" "$*"; }
info()    { printf "  \033[34m-->\033[0m %s\n" "$*"; }

echo
echo "==> Uninstalling AI Browser..."
echo

removed=0

if [ -d "$APP_PATH" ]; then
  rm -rf "$APP_PATH"
  success "Removed: $APP_PATH"
  removed=1
fi

if [ -f "$LAUNCHER_PATH" ]; then
  rm -f "$LAUNCHER_PATH"
  success "Removed: $LAUNCHER_PATH"
  removed=1
fi

if [ "$removed" -eq 0 ]; then
  info "AI Browser is not installed — nothing to remove."
else
  echo
  info "Profile preserved at: $PROFILE_DIR"
  info "To delete it too:  rm -rf $PROFILE_DIR"
fi

echo
