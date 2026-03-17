# Päivitä kiosk Raspberryllä

## Tapa 1: Aja yksi skripti Pi:llä (helpoin)

**Oletus:** Repo on jo Pi:llä (esim. `~/Tresdarts` tai `~/darts`).

1. **SSH Pi:lle** (tai avaa terminaali suoraan Pi:llä):
   ```bash
   ssh pi@IP_OSOITE
   ```

2. **Mene repon juureen ja aja skripti:**
   ```bash
   cd ~/Tresdarts
   chmod +x scripts/update-and-run-on-pi.sh
   ./scripts/update-and-run-on-pi.sh
   ```
   (Korvaa `~/Tresdarts` sillä polulla missä repo on.)

Skripti tekee: pull → clean → pub get → build → käynnistää sovelluksen. Kun haluat päivittää uudestaan, aja vain `./scripts/update-and-run-on-pi.sh` uudestaan.

---

## Tapa 2: Repo ei ole vielä Pi:llä

1. Pi:llä asenna Git ja Flutter (jos ei jo):
   ```bash
   sudo apt update
   sudo apt install -y git
   # Flutter: https://docs.flutter.dev/get-started/install/linux
   ```

2. Kloonaa repo Pi:lle:
   ```bash
   cd ~
   git clone https://github.com/miskalunnas/Tresdarts.git
   cd Tresdarts
   ```

3. Aja Tapa 1:n skripti:
   ```bash
   chmod +x scripts/update-and-run-on-pi.sh
   ./scripts/update-and-run-on-pi.sh
   ```

---

## Tapa 3: Buildataan Windowsilla, kopioidaan Pi:lle

Käy vain jos et halua asentaa Flutteria Pi:lle.

1. **Windows (PowerShell):**
   ```powershell
   cd c:\Users\miska\smart-tres\darts
   .\scripts\build-for-pi.ps1
   ```

2. **Kopioi kansio Pi:lle** (korvaa `PI_IP` Pi:n IP:llä):
   ```powershell
   scp -r tresdarts_kiosk\build\linux\arm64\release\* pi@PI_IP:~/tresdarts_run/
   ```

3. **Pi:llä:**
   ```bash
   cd ~/tresdarts_run
   chmod +x tresdarts_kiosk
   ./tresdarts_kiosk
   ```

---

## Yhteenveto

| Missä buildataan? | Mitä teet |
|-------------------|-----------|
| **Pi:llä**        | Pi:llä: `cd ~/Tresdarts && ./scripts/update-and-run-on-pi.sh` |
| **Windowsilla**   | Build-for-pi.ps1 → scp release-kansio Pi:lle → Pi:llä `./tresdarts_kiosk` |
