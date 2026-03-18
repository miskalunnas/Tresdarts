import 'package:flutter/material.dart';

import '../../leaderboard/game_result.dart';
import '../../games/game_mode.dart';
import '../game_rules.dart';
import '../throw_input_sheet.dart';
import '../darts_throw.dart';
import 'x01_game.dart';

class X01GameView extends StatefulWidget {
  const X01GameView({
    super.key,
    required this.startScore,
    required this.players,
    required this.onExit,
    required this.onFinished,
  });

  static const routeName = '/game/x01/play';

  final int startScore;
  final List<String> players;
  final VoidCallback onExit;
  final void Function(GameResult result) onFinished;

  @override
  State<X01GameView> createState() => _X01GameViewState();
}

class _X01GameViewState extends State<X01GameView> {
  late X01GameState _state;
  final List<DartThrow> _throws = [];

  @override
  void initState() {
    super.initState();
    _state = X01GameState.start(
      startScore: widget.startScore,
      players: widget.players,
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _applyThrow(DartThrow t) {
    if (_state.isFinished) return;
    setState(() {
      _throws.add(t);
      _state = _state.applyThrow(t.points);
    });
    if (_state.isFinished) {
      final winnerIndex = _state.winnerIndex!;
      widget.onFinished(
        GameResult(
          gameModeId: GameModeId.x01,
          winnerName: _state.players[winnerIndex],
          players: _state.players,
          scores: {
            'startScore': _state.startScore,
            'throws': _throws.length,
          },
          playedAt: DateTime.now(),
        ),
      );
    }
  }

  void _addThrow() {
    ThrowInputSheet.show(
      context,
      title: 'Lisää heitto',
      maxPicks: 3 - _state.dartsInTurn,
      onPick: _applyThrow,
      onPickMany: (list) {
        for (final t in list) {
          _applyThrow(t);
          if (_state.isFinished) break;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = _state.activePlayerIndex;
    final winner = _state.winnerIndex;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: widget.onExit,
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Takaisin'),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Säännöt',
                    onPressed: () => GameRules.show(context, GameModeId.x01),
                    icon: Icon(Icons.info_outline, color: cs.onSurfaceVariant),
                  ),
                  Text(
                    'X01 ${_state.startScore}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _ScoreRow(
                players: _state.players,
                scores: _state.scores,
                activeIndex: active,
                winnerIndex: winner,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cs.outline),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        winner != null
                            ? 'Voittaja: ${_state.players[winner]}'
                            : 'Vuoro: ${_state.players[active]}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _state.isFinished ? null : _addThrow,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Lisää heitto'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _LastThrows(throws: _throws),
                      const Spacer(),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _throws.isEmpty
                                ? null
                                : () => setState(() {
                                      _throws.removeLast();
                                      _state = _state.undo();
                                    }),
                            icon: const Icon(Icons.undo, size: 18),
                            label: const Text('Undo'),
                          ),
                          const Spacer(),
                          Text(
                            'Heitot: ${_throws.length}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LastThrows extends StatelessWidget {
  const _LastThrows({required this.throws});

  final List<DartThrow> throws;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (throws.isEmpty) {
      return Text(
        'Ei heittoja vielä.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
      );
    }
    final last = throws.reversed.take(6).toList(growable: false);
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final t in last)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outline),
            ),
            child: Text(
              '${t.label} · ${t.points}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
      ],
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({
    required this.players,
    required this.scores,
    required this.activeIndex,
    required this.winnerIndex,
  });

  final List<String> players;
  final List<int> scores;
  final int activeIndex;
  final int? winnerIndex;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: List.generate(players.length, (i) {
        final isActive = i == activeIndex && winnerIndex == null;
        final isWinner = winnerIndex == i;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: i == players.length - 1 ? 0 : 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isWinner ? cs.primary : (isActive ? cs.onSurface : cs.outline)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  players[i],
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  '${scores[i]}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

