# Raspberry Pi 5 kiosk-asennus (Raspberry Pi OS Desktop)

Tämä projekti on Flutter “Linux desktop” -appi, joka ajetaan Raspberry Pi OS Desktopissa full-screen kiosk-tilassa.

## 1) Raspberry Pi OS
- Suositus: **Raspberry Pi OS (64-bit) Desktop** (Bookworm).
- Kytke virallinen 7" näyttö ja varmista että kosketus toimii.

## 2) Riippuvuudet (Pi:llä)

Asenna Flutterin Linux-desktop build -työkalut:

```bash
sudo apt update
sudo apt install -y git curl unzip xz-utils zip \
  clang cmake ninja-build pkg-config \
  libgtk-3-dev liblzma-dev
```

Kiosk-mukavuudet:

```bash
sudo apt install -y unclutter
```

## 3) Flutter Pi:lle

Helpointa on asentaa Flutter suoraan Pi:lle:

```bash
cd ~
git clone https://github.com/flutter/flutter.git -b stable
echo 'export PATH="$PATH:$HOME/flutter/bin"' >> ~/.bashrc
source ~/.bashrc

flutter doctor
flutter config --enable-linux-desktop
```

## 4) Projektin build (Pi:llä)

Kloonaa projekti Pi:lle ja buildaa release:

```bash
cd ~
git clone <REPO_URL> smart-tres
cd smart-tres/darts/tresdarts_kiosk

flutter pub get
flutter build linux --release
```

Buildin tulos löytyy yleensä:
- `build/linux/*/release/bundle/`

Binary on bundle-kansion sisällä nimellä `tresdarts_kiosk`.

## 5) Autostart (kiosk)

Tässä repossa on valmiit pohjat:
- `scripts/pi/launch_tresdarts_kiosk.sh`
- `scripts/pi/autostart/tresdarts_kiosk.desktop`

Kopioi ne Pi:llä ja muokkaa polut kohdilleen:

```bash
cd ~/smart-tres/darts/tresdarts_kiosk

chmod +x scripts/pi/launch_tresdarts_kiosk.sh
mkdir -p ~/.config/autostart
cp scripts/pi/autostart/tresdarts_kiosk.desktop ~/.config/autostart/
```

Säädä `scripts/pi/launch_tresdarts_kiosk.sh` muuttuja `APP_DIR` osoittamaan sinun bundle-polkuun, esim:
- `.../build/linux/arm64/release/bundle`

Käynnistä Pi uudelleen. Appin pitäisi aueta automaattisesti ja mennä full-screen.

## 6) Huomio Windows-kehityksestä

Windowsilla pluginien build voi vaatia **Developer Mode** (symlinkit). Jos saat virheen:
“Building with plugins requires symlink support”, ota käyttöön:

```powershell
start ms-settings:developers
```

## 7) Screensaver-kuvat

Muokkaa `assets/config/playlist.json` ja listaa kuvat:

```json
{
  "imageIntervalSeconds": 8,
  "images": [
    "assets/images/oma1.jpg",
    "assets/images/oma2.jpg"
  ]
}
```

Lisää tiedostot kansioon `assets/images/` ja aja:

```bash
flutter pub get
```

