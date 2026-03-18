import 'package:flutter/material.dart';

Future<bool> confirmExitGame(BuildContext context) async {
  final cs = Theme.of(context).colorScheme;
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Poistutaanko pelistä?'),
      content: Text(
        'Jos poistut nyt, tämän pelin tuloksia ei tallenneta.',
        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Jatka peliä'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Poistu pelistä'),
        ),
      ],
    ),
  );
  return res ?? false;
}

