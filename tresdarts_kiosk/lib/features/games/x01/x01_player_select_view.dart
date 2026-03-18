import 'package:flutter/material.dart';

import '../../players/player_profile.dart';
import '../../players/player_select_view.dart';

class X01PlayerSelectView extends StatefulWidget {
  const X01PlayerSelectView({
    super.key,
    required this.onBack,
    required this.onSelected,
    required this.onCreateNew,
    required this.startScore,
  });

  static const routeName = '/game/x01/players';

  final VoidCallback onBack;
  final void Function(List<PlayerProfile> players) onSelected;
  final Future<PlayerProfile?> Function() onCreateNew;
  final int startScore;

  @override
  State<X01PlayerSelectView> createState() => _X01PlayerSelectViewState();
}

class _X01PlayerSelectViewState extends State<X01PlayerSelectView> {
  @override
  Widget build(BuildContext context) {
    return PlayerSelectView(
      title: 'X01 ${widget.startScore}',
      minPlayers: 1,
      maxPlayers: 8,
      onBack: widget.onBack,
      onContinue: widget.onSelected,
      onCreateNew: widget.onCreateNew,
    );
  }
}

