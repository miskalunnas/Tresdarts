# Tietojen tallennus – TRES Darts -kioski

## Mihin data tallentuu nyt (käytännössä)

Kaikki sovellusdata on **laitteen paikallista** eikä synkkaudu mihinkään pilveen. Tallennuspaikat:

| Data | Missä | Avain / polku | Muoto |
|------|--------|----------------|--------|
| **Pelaajaprofiilit** | SharedPreferences | `tresdarts_players` | JSON-taulukko (max 500 kpl). Kentät: id, name, entrySong, photoPath, createdAt. |
| **Pelitulokset (leaderboard)** | SharedPreferences | `tresdarts_leaderboard_results` | JSON-taulukko (max 500 peliä). Kentät: gameModeId, winnerName, players, scores, playedAt. |
| **Pelaajakuvat** | Tiedostojärjestelmä | Polku tallessa `PlayerProfile.photoPath` | Tavallinen kuva (esim. JPEG). Polku on laitteen paikallinen (esim. sovelluksen documents/temp -kansio). |

- **SharedPreferences** = käyttöjärjestelmän tarjoama key-value -tallennus sovelluksen omaan kansioon (esim. Android: `/data/data/<package>/shared_prefs/`). Data säilyy kunnes sovellus poistetaan tai sovellusdata tyhjennetään.
- **Kuvat** = tavalliset tiedostot. Jos lisäät kameran/kuvanvalinnan, tallennus tapahtuu yleensä `path_provider`-paketin `getApplicationDocumentsDirectory()` tai `getTemporaryDirectory()` -polkuun.

## Säilyvyys kun muokkaat sovellusta

- **Sovelluspäivitys (APK/build uusiksi):** SharedPreferences ja sovelluksen dokumenttikansio säilyvät. Data pysyy.
- **Sovellus poistetaan / data tyhjennetään:** Kaikki paikallinen data katoaa.
- **Uusi laite / factory reset:** Data ei ole uudella laitteella, ellei ole varmuuskopiota tai pilvitallennusta.

Jos haluat dataa säilyvän myös sovellusta raskaasti muokatessa tai laitetta vaihtaessa, kannattaa lisätä **pilvitallennus** tai **varmuuskopiointi** (export/import tiedostoon).

---

## Pilvitallennuksen integrointi

Arkkitehtuuri on tehty niin, että tallennus on **abstrahoitu rajapinnan taakse** (`KeyValueStorage`). Voit vaihtaa paikallisen tallennuksen pilvipalveluun ilman, että muutat pelaaja- tai tulostilojen logiikkaa.

### Nykyinen rakenne

```
lib/core/storage/
  key_value_storage.dart              # abstrakti rajapinta (get/set merkkijonoille)
  shared_preferences_storage.dart     # nykyinen toteutus (SharedPreferences)
```

`PlayerRepository` ja `LeaderboardRepository` käyttävät `KeyValueStorage`-instanssia. Jos et anna konstruktorissa storagea, käytetään oletuksena `SharedPreferencesStorage()`, joten nykyinen käyttäytyminen säilyy. Pilvipalvelua varten luot uuden toteutuksen ja annat sen repositorioille (esim. Provider, get_it tai konstruktoriparametri).

### Suositus: mitä käyttää pilveen

| Vaihtoehto | Edut | Huomiot |
|------------|------|--------|
| **Firebase Firestore** | Hyvä Flutter-tuki, offline-välimuisti, reaaliaika, helppo aloittaa. | Google-tili, maksullinen isoilla datamäärillä. |
| **Supabase** | Open source, PostgreSQL, REST + Realtime, Flutter-paketti. | Oma palvelin tai Supabase Cloud. |
| **Oma REST-API + backend** | Täysi kontrolli, ei riippuvuutta pilvipalvelusta. | Sinun pitää hostata API ja tietokanta. |

**Kioski-/offline-skenaariossa** järkevä valinta on **Firestore** tai **Supabase**, koska molemmat tukevat offline-tallennusta: data kirjoitetaan ensin paikallisesti ja synkataan pilveen kun yhteys on. Näin pelit toimivat myös ilman verkkoa.

### Vaiheet pilvi-integraatioon (esimerkki: Firestore)

1. Lisää projektiin `firebase_core` ja `cloud_firestore`.
2. Luo `lib/core/storage/firestore_storage.dart`, joka toteuttaa `KeyValueStorage`:
   - `get(key)`: lue dokumentti (esim. `tresdarts/data/{key}`) ja palauta kentän arvo.
   - `set(key, value)`: kirjoita dokumenttiin kenttä.
3. Sovelluksen käynnistyksessä: valitse tallennus (esim. ympäristö tai asetus: paikallinen vs. Firestore). Anna valittu `KeyValueStorage` repositorioille.
4. (Valinnainen) Käytä **samat avaimet** kuin nyt: `tresdarts_players`, `tresdarts_leaderboard_results`, jotta voit tehdä yhden kerran migraation: lue paikallisesta, kirjoita pilveen, sitten vaihda oletustallennus pilveen.

Pelaajakuvat kannattaa tallentaa **Firebase Storage** -bucketiin (tai vastaavaan) ja säilyttää `photoPath`-kentässä pilvi-URL tai storage-polku.

---

## Yhteenveto

- **Kaikki data** = SharedPreferences (kaksi avainta) + mahdolliset kuvatiedostot polussa, jota `photoPath` viittaa.
- **Säilyvyys:** Data kestää sovelluspäivitykset; poistuu kun sovellus tai data poistetaan.
- **Pilvi:** Helppo lisätä vaihtamalla `KeyValueStorage`-toteutus (esim. Firestore tai Supabase). Suositus: Firestore tai Supabase offline-tuesta kioskiä varten.
