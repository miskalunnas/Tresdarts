#!/usr/bin/env bash
# Aja tämä skripti RASPBERRY PI:llä. Päivittää repon, buildaa ja käynnistää kioskin.
# Ensin kerran: cd kansio-jossa-Tresdarts-repo && chmod +x scripts/update-and-run-on-pi.sh

set -e
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

echo "==> Päivitetään repo..."
git checkout -- tresdarts_kiosk/pubspec.lock 2>/dev/null || true
git checkout -- scripts/update-and-run-on-pi.sh 2>/dev/null || true
git pull origin main

echo "==> Buildataan kiosk..."
cd tresdarts_kiosk
flutter clean
flutter pub get
flutter build linux --target-platform linux-arm64

RELEASE="$REPO_ROOT/tresdarts_kiosk/build/linux/arm64/release"
if [ ! -x "$RELEASE/tresdarts_kiosk" ]; then
  echo "Virhe: binääriä ei löydy: $RELEASE/tresdarts_kiosk"
  exit 1
fi

echo "==> Sammutetaan vanha kiosk (jos käynnissä)..."
pkill -x tresdarts_kiosk 2>/dev/null || true
sleep 1

echo "==> Käynnistetään uusi versio Pi:n näytölle (DISPLAY=:0)..."
export DISPLAY=:0
nohup "$RELEASE/tresdarts_kiosk" > /tmp/tresdarts_kiosk.log 2>&1 &
echo "Kiosk käynnistetty. Lokit: /tmp/tresdarts_kiosk.log"
