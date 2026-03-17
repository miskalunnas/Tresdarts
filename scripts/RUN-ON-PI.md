# Muutokset näkyviin Raspberryllä

Muutokset (screensaver-kuva, asetukset, leaderboard jne.) tulevat mukaan **vain uudelleen buildatusta sovelluksesta**. Pelkkä `git pull` Pi:llä ei riitä, jos sovellus ei ole buildattu uudestaan pullin jälkeen.

## Vaihtoehto A: Buildataan Windowsilla, kopioidaan Pi:lle

1. **Windows-koneella** (projektin juuressa):
   ```powershell
   .\scripts\build-for-pi.ps1
   ```
   Tai käsin:
   ```powershell
   cd tresdarts_kiosk
   flutter clean
   flutter pub get
   flutter build linux --target-platform linux-arm64
   ```

2. **Kopioi** kansio `tresdarts_kiosk\build\linux\arm64\release\` Pi:lle (esim. SCP, USB-tikku, verkkokansio):
   ```powershell
   scp -r tresdarts_kiosk\build\linux\arm64\release\* pi@RASPBERRY_IP:/home/pi/tresdarts_kiosk/
   ```
   (Korvaa `RASPBERRY_IP` Pi:n IP-osoitteella.)

3. **Pi:llä** (SSH tai suoraan Pi:llä):
   ```bash
   cd /home/pi/tresdarts_kiosk
   chmod +x tresdarts_kiosk
   ./tresdarts_kiosk
   ```

## Vaihtoehto B: Koodi suoraan Pi:lle ja build Pi:llä

1. **Pi:llä** (tai koneella josta deployataan Pi:lle):
   ```bash
   cd /polku/tresdarts   # tai missä repo on
   git pull origin main
   cd tresdarts_kiosk
   flutter clean
   flutter pub get
   flutter run -d linux --release
   ```
   Tai buildiksi ilman run:
   ```bash
   flutter build linux --target-platform linux-arm64
   ./build/linux/arm64/release/tresdarts_kiosk
   ```

## Tärkeää

- **flutter clean** – tyhjentää vanhan buildin, jotta uudet assetit (kuvat, playlist.json) tulevat mukaan.
- **flutter pub get** – varmistaa riippuvuudet.
- Aina kun koodia tai assetteja muutetaan, buildataan ja ajetaan/kopioidaan uusi versio – silloin muutokset näkyvät Raspilla.
