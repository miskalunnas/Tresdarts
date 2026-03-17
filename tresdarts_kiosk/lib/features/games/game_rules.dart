import 'package:flutter/material.dart';

import 'game_mode.dart';

class GameRules {
  static String title(GameModeId id) => switch (id) {
        GameModeId.x01 => 'X01 – säännöt',
        GameModeId.cricket => 'Cricket – säännöt',
        GameModeId.aroundTheClock => 'Around the Clock – säännöt',
        GameModeId.shanghai => 'Shanghai – säännöt',
        GameModeId.killer => 'Killer – säännöt',
      };

  static String summary(GameModeId id) => switch (id) {
        GameModeId.x01 =>
          '- Aloita: 101 / 201 / 301 / 501 / 701\n'
          '- Tavoite: nollaa oma pisteet ensimmäisenä\n'
          '- Jokainen vuoro: vähennä heitetyt pisteet (0–180)\n'
          '- Bust: jos menisi alle 0 → vuoro ei muuta pistettä\n',
        GameModeId.cricket =>
          '- Sulje numerot: 15–20 ja Bull (3 osumaa per numero)\n'
          '- Kun numero on sinulla suljettu, voit kerätä siitä pisteitä jos vastustaja ei ole sulkenut\n'
          '- Voitto: suljet kaikki ja sinulla on vähintään yhtä paljon pisteitä kuin muilla\n',
        GameModeId.aroundTheClock =>
          '- Osu järjestyksessä 1 → 20 → Bull\n'
          '- Yksi osuma siirtää seuraavaan numeroon\n'
          '- Voitto: ensimmäinen joka osuu Bulliin\n',
        GameModeId.shanghai =>
          '- Kierrokset 1 → 20\n'
          '- Kierroksella haetaan kyseinen numero\n'
          '- Shanghai = single + double + triple samasta numerosta samassa kierroksessa\n'
          '- Voitto: eniten pisteitä lopussa / Shanghai ratkaisee (sovitaan pelissä)\n',
        GameModeId.killer =>
          '- Pelaajilla on oma numero (sovitaan alussa)\n'
          '- Kerää “killer” osumalla omaan numeroon (yleensä 3 osumaa)\n'
          '- Kun olet killer, voit vähentää muiden elämiä osumalla heidän numeroihinsa\n'
          '- Voitto: viimeinen elossa\n',
      };

  static Future<void> show(BuildContext context, GameModeId id) {
    final cs = Theme.of(context).colorScheme;
    return showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cs.surface,
          surfaceTintColor: cs.surface,
          title: Text(
            title(id),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Text(
              summary(id),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Sulje'),
            ),
          ],
        );
      },
    );
  }
}

