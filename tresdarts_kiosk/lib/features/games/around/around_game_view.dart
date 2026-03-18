import 'dart:async';

import 'package:flutter/material.dart';

import '../../leaderboard/game_result.dart';
import '../../games/game_mode.dart';
import '../dart_throw_source.dart';
import '../darts_throw.dart';
import '../throw_history_sheet.dart';
import '../throw_input_sheet.dart';
import '../turn_timeline.dart';
import '../player_throw_panel.dart';
import '../confirm_exit_game_dialog.dart';
import 'around_engine.dart';

class AroundGameView extends StatefulWidget {
  const AroundGameView({
    super.key,
    required this.players,
    required this.onExit,
    required this.onFinished,
    this.throwSource = const NoopDartThrowSource(),
  });

  static const routeName = '/game/around/play';

  final List<String> players;
  final VoidCallback onExit;
  final void Function(GameResult result) onFinished;
  final DartThrowSource throwSource;

  @override
  State<AroundGameView> createState() => _AroundGameViewState();
}

class _AroundGameViewState extends State<AroundGameView> {
  late TurnTimeline _timeline;
  late AroundState _state;
  StreamSubscription<DartThrow>? _sub;

  @override
  void initState() {
    super.initState();
    _timeline = TurnTimeline.start(playerCount: widget.players.length);
    _recompute();
    _sub = widget.throwSource.stream.listen((t) {
      if (!mounted) return;
      _addThrow(t);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    widget.throwSource.dispose();
    super.dispose();
  }

  void _recompute() {
    _state = computeAround(players: widget.players, timeline: _timeline);
  }

  void _finishIfWinner() {
    final winner = _state.winnerIndex;
    if (winner == null) return;
    final pd = computePointsAndDartsByPlayer(_timeline);
    final pointsByPlayer = <String, int>{};
    final dartsByPlayer = <String, int>{};
    for (var i = 0; i < widget.players.length; i++) {
      pointsByPlayer[widget.players[i]] = pd.points[i] ?? 0;
      dartsByPlayer[widget.players[i]] = pd.darts[i] ?? 0;
    }
    widget.onFinished(
      GameResult(
        gameModeId: GameModeId.aroundTheClock,
        winnerName: widget.players[winner],
        players: widget.players,
        scores: {
          'progress': _state.progress,
          'throws': _timeline.flatThrows.length,
          'dartPointsByPlayer': pointsByPlayer,
          'dartCountByPlayer': dartsByPlayer,
        },
        playedAt: DateTime.now(),
      ),
    );
  }

  void _addThrow(DartThrow t) {
    setState(() {
      _timeline = _timeline.addThrow(t);
      _recompute();
    });
    _finishIfWinner();
  }

  void _manualAdd() {
    ThrowInputSheet.show(
      context,
      maxPicks: _timeline.remainingInActiveTurn,
      onPick: _addThrow,
      onPickMany: (list) {
        for (final t in list) {
          _addThrow(t);
          if (_state.winnerIndex != null) break;
        }
      },
    );
  }

  void _editThrows() {
    final flat = _timeline.flatThrows;
    ThrowHistorySheet.show(
      context,
      throws: flat,
      onReplace: (i, t) {
        setState(() {
          _timeline = _timeline.replaceThrowAt(i, t);
          _recompute();
        });
        _finishIfWinner();
      },
      onDelete: (i) {
        setState(() {
          _timeline = _timeline.deleteThrowAt(i);
          _recompute();
        });
        _finishIfWinner();
      },
    );
  }

  String _targetLabel(int t) {
    if (t >= 1 && t <= 20) return '$t';
    return 'BULL';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = _timeline.activePlayerIndex;
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
                    onPressed: () async {
                      if (await confirmExitGame(context)) {
                        widget.onExit();
                      }
                    },
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Takaisin'),
                  ),
                  const Spacer(),
                  Text(
                    'Around the Clock',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: List.generate(widget.players.length, (i) {
                  final isActive = i == active && winner == null;
                  final isWinner = winner == i;
                  return Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                          right: i == widget.players.length - 1 ? 0 : 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isWinner
                              ? cs.primary
                              : (isActive ? cs.onSurface : cs.outline),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.players[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Seuraava: ${_targetLabel(_state.progress[i])}',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
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
                            ? 'Voittaja: ${widget.players[winner]}'
                            : 'Vuoro: ${widget.players[active]}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: winner != null ? null : _manualAdd,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Lisää heitto'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _timeline.turns.isEmpty ? null : _editThrows,
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Muokkaa'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      PlayerThrowPanel(
                        timeline: _timeline,
                        activePlayerIndex: active,
                        playerName: widget.players[active],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            onPressed: _timeline.turns.isEmpty
                                ? null
                                : () => setState(() {
                                      _timeline = _timeline.undoLastThrow();
                                      _recompute();
                                    }),
                            icon: const Icon(Icons.undo, size: 18),
                            label: const Text('Undo'),
                          ),
                          const Spacer(),
                          Text(
                            'Heitot: ${_timeline.flatThrows.length}',
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

