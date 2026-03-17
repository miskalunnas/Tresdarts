# If 'git pull' fails because of pubspec.lock, this script resets it and pulls.
Set-Location $PSScriptRoot\..
git checkout -- tresdarts_kiosk/pubspec.lock
git pull origin main
Set-Location tresdarts_kiosk
flutter pub get
Set-Location ..
Write-Host "Pull valmis. pubspec.lock paivitettiin ja flutter pub get ajettu." -ForegroundColor Green
