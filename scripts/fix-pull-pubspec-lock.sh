#!/bin/bash
# Suorita repon juuresta (smart-tres), jos git pull valittaa pubspec.lock -muutoksista.

set -e
cd "$(dirname "$0")/.."   # darts/ -> yläkansio; säädä polku jos repo on muualla

# Vaihtoehto A: Hylkää paikallinen pubspec.lock ja ota remote
git checkout -- tresdarts_kiosk/pubspec.lock 2>/dev/null || true
git pull origin main

# Päivitä riippuvuudet
cd tresdarts_kiosk && flutter pub get

echo "Pull ja pub get valmis."
