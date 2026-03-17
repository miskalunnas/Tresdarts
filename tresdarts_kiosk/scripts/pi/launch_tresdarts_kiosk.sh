#!/usr/bin/env bash
set -euo pipefail

# Point this to your Linux release bundle directory.
# Example:
#   APP_DIR="$HOME/smart-tres/darts/tresdarts_kiosk/build/linux/arm64/release/bundle"
APP_DIR="${APP_DIR:-$HOME/smart-tres/darts/tresdarts_kiosk/build/linux/arm64/release/bundle}"

APP_BIN="$APP_DIR/tresdarts_kiosk"

# Hide cursor after 0.2s inactivity (optional).
if command -v unclutter >/dev/null 2>&1; then
  unclutter -idle 0.2 -root &
fi

cd "$APP_DIR"
exec "$APP_BIN"

