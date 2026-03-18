import 'package:flutter/material.dart';

enum WinContinueAction { endGame, continuePlayOut }

Future<WinContinueAction?> showWinContinueDialog(
  BuildContext context, {
  required String winnerName,
}) {
  final cs = Theme.of(context).colorScheme;
  return showDialog<WinContinueAction>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: Text('Voittaja: $winnerName'),
      content: Text(
        'Päätetäänkö peli nyt vai pelataanko loput pelaajat loppuun? '
        'Vain ensimmäinen voittaja tallennetaan tuloksiin.',
        style: Theme.of(ctx)
            .textTheme
            .bodyMedium
            ?.copyWith(color: cs.onSurfaceVariant),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(WinContinueAction.continuePlayOut),
          child: const Text('Jatketaanko loppuun'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(WinContinueAction.endGame),
          child: const Text('Päätetään peli'),
        ),
      ],
    ),
  );
}

