# Build Tresdarts kiosk for Raspberry Pi (Linux arm64).
# After running, copy the folder build/linux/arm64/release/ to the Pi and run ./tresdarts_kiosk there.

Set-Location $PSScriptRoot\..\tresdarts_kiosk
flutter clean
flutter pub get
flutter build linux --target-platform linux-arm64

$out = "build\linux\arm64\release"
if (Test-Path $out) {
    Write-Host ""
    Write-Host "Build valmis. Kopioi koko kansio Pi:lle:" -ForegroundColor Green
    Write-Host "  $((Get-Location).Path)\$out"
    Write-Host ""
    Write-Host "Pi:llä aja: ./tresdarts_kiosk"
    Write-Host ""
} else {
    Write-Host "Build-kansiota ei löydy. Tarkista: flutter build linux --target-platform linux-arm64" -ForegroundColor Yellow
}
