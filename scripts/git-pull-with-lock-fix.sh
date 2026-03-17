#!/usr/bin/env bash
# If 'git pull' fails because of pubspec.lock, this script resets it and pulls.
cd "$(dirname "$0")/.."
git checkout -- tresdarts_kiosk/pubspec.lock
git pull origin main
cd tresdarts_kiosk && flutter pub get
cd ..
echo "Pull valmis. pubspec.lock päivitettiin ja flutter pub get ajettu."
