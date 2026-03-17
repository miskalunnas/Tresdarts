#!/usr/bin/env bash
set -euo pipefail

LEVEL="${1:-patch}" # patch|minor|major

PUBSPEC="$(cd "$(dirname "$0")/../tresdarts_kiosk" && pwd)/pubspec.yaml"

line="$(grep -E '^version:\s*[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+\s*$' "$PUBSPEC" | head -n 1 || true)"
if [[ -z "$line" ]]; then
  echo "Version-riviä ei löytynyt pubspec.yaml:stä (odotettu muoto: x.y.z+build)." >&2
  exit 1
fi

ver="${line#version: }"
ver="${ver//[[:space:]]/}"
base="${ver%%+*}"
build="${ver##*+}"
IFS='.' read -r major minor patch <<<"$base"

case "$LEVEL" in
  major) major=$((major+1)); minor=0; patch=0;;
  minor) minor=$((minor+1)); patch=0;;
  patch) patch=$((patch+1));;
  *) echo "Käyttö: $0 [patch|minor|major]" >&2; exit 1;;
esac

build=$((build+1))
newline="version: ${major}.${minor}.${patch}+${build}"

tmp="$(mktemp)"
awk -v nl="$newline" '
  BEGIN{done=0}
  /^version:[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+\+[0-9]+[[:space:]]*$/{
    if(done==0){print nl; done=1; next}
  }
  {print}
' "$PUBSPEC" > "$tmp"
mv "$tmp" "$PUBSPEC"

echo "$newline"

