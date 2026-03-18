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
import '../win_continue_dialog.dart';
import '../turn_order_spinner_dialog.dart';
import '../../leaderboard/leaderboard_repository.dart';
import 'killer_engine.dart';
import 'killer_setup_view.dart';

class KillerGameView extends StatefulWidget {
  const KillerGameView({
    super.key,
    required this.players,
    required this.setup,
    required this.onExit,
    required this.onFinished,
    this.throwSource = const NoopDartThrowSource(),
  });

  static const routeName = '/game/killer/play';

  final List<String> players;
  final KillerSetup setup;
  final VoidCallback onExit;
  final void Function(GameResult result) onFinished;
  final DartThrowSource throwSource;

  @override
  State<KillerGameView> createState() => _KillerGameViewState();
}

class _KillerGameViewState extends State<KillerGameView> {
  late TurnTimeline _timeline;
  late KillerState _state;
  StreamSubscription<DartThrow>? _sub;
  int? _firstWinnerIndex;
  bool _playOut = false;
  bool _winDialogOpen = false;
  final Set<int> _frozenPlayers = {};
  final _leaderboardRepo = LeaderboardRepository();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final order = await showTurnOrderSpinnerDialog(
        context,
        players: widget.players,
      );
      if (!mounted) return;
      if (order != null) {
        final oldPlayers = widget.players;
        final oldNumbers = widget.setup.playerNumbers;
        final nextNumbers = <int, int>{};
        for (var newIndex = 0; newIndex < order.length; newIndex++) {
          final name = order[newIndex];
          final oldIndex = oldPlayers.indexOf(name);
          if (oldIndex >= 0) {
            nextNumbers[newIndex] = oldNumbers[oldIndex] ?? 0;
          }
        }
        Navigator.of(context).pushReplacementNamed(
          KillerGameView.routeName,
          arguments: <String, dynamic>{
            'players': order,
            'setup': <String, dynamic>{
              'numbers': nextNumbers.map((k, v) => MapEntry('$k', v)),
              'lives': widget.setup.lives,
              'killsToBecomeKiller': widget.setup.killsToBecomeKiller,
            },
          },
        );
      }
    });
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
    _state = computeKiller(
      players: widget.players,
      setup: widget.setup,
      timeline: _timeline,
    );
  }

  bool _isEliminated(int idx) => _state.lives[idx] <= 0;

  void _skipFrozenTurnsIfNeeded() {
    var guard = 0;
    while (_playOut &&
        _timeline.turns.isNotEmpty &&
        _frozenPlayers.contains(_timeline.activePlayerIndex) &&
        guard < widget.players.length + 2) {
      _timeline = _timeline.addThrow(
        const DartThrow(segment: DartSegment.miss, multiplier: DartMultiplier.single),
      );
      _timeline = _timeline.addThrow(
        const DartThrow(segment: DartSegment.miss, multiplier: DartMultiplier.single),
      );
      _timeline = _timeline.addThrow(
        const DartThrow(segment: DartSegment.miss, multiplier: DartMultiplier.single),
      );
      _recompute();
      guard++;
    }
  }

  Future<void> _handleFirstWinIfNeeded() async {
    if (_firstWinnerIndex != null) return;
    final winner = _state.winnerIndex;
    if (winner == null) return;
    if (_winDialogOpen) return;
    _winDialogOpen = true;

    final pd = computePointsAndDartsByPlayer(_timeline);
    final pointsByPlayer = <String, int>{};
    final dartsByPlayer = <String, int>{};
    for (var i = 0; i < widget.players.length; i++) {
      pointsByPlayer[widget.players[i]] = pd.points[i] ?? 0;
      dartsByPlayer[widget.players[i]] = pd.darts[i] ?? 0;
    }

    final result = GameResult(
      gameModeId: GameModeId.killer,
      winnerName: widget.players[winner],
      players: widget.players,
      scores: {
        'lives': _state.lives,
        'kills': _state.kills,
        'numbers': _state.numbers,
        'throws': _timeline.flatThrows.length,
        'dartPointsByPlayer': pointsByPlayer,
        'dartCountByPlayer': dartsByPlayer,
      },
      playedAt: DateTime.now(),
    );

    final action = await showWinContinueDialog(
      context,
      winnerName: widget.players[winner],
    );
    if (!mounted) return;
    _winDialogOpen = false;
    if (action == null) return;

    if (action == WinContinueAction.endGame) {
      widget.onFinished(result);
      return;
    }

    await _leaderboardRepo.saveResult(result);
    if (!mounted) return;
    setState(() {
      _firstWinnerIndex = winner;
      _playOut = true;
      _frozenPlayers.add(winner);
      for (var i = 0; i < widget.players.length; i++) {
        if (_isEliminated(i)) _frozenPlayers.add(i);
      }
      _skipFrozenTurnsIfNeeded();
    });
  }

  void _addThrow(DartThrow t) {
    if (_playOut && _frozenPlayers.contains(_timeline.activePlayerIndex)) {
      setState(() => _skipFrozenTurnsIfNeeded());
      return;
    }
    setState(() {
      _timeline = _timeline.addThrow(t);
      _recompute();
      if (_playOut) {
        for (var i = 0; i < widget.players.length; i++) {
          if (_isEliminated(i)) _frozenPlayers.add(i);
        }
        _skipFrozenTurnsIfNeeded();
      }
    });
    _handleFirstWinIfNeeded();
  }

  void _manualAdd() {
    ThrowInputSheet.show(
      context,
      maxPicks: _timeline.remainingInActiveTurn,
      onPick: _addThrow,
      onPickMany: (list) {
        for (final t in list) {
          _addThrow(t);
          if (!_playOut && _state.winnerIndex != null) break;
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
          if (_playOut) {
            _frozenPlayers.clear();
            if (_firstWinnerIndex != null) _frozenPlayers.add(_firstWinnerIndex!);
            for (var p = 0; p < widget.players.length; p++) {
              if (_isEliminated(p)) _frozenPlayers.add(p);
            }
            _skipFrozenTurnsIfNeeded();
          }
        });
        _handleFirstWinIfNeeded();
      },
      onDelete: (i) {
        setState(() {
          _timeline = _timeline.deleteThrowAt(i);
          _recompute();
          if (_playOut) {
            _frozenPlayers.clear();
            if (_firstWinnerIndex != null) _frozenPlayers.add(_firstWinnerIndex!);
            for (var p = 0; p < widget.players.length; p++) {
              if (_isEliminated(p)) _frozenPlayers.add(p);
            }
            _skipFrozenTurnsIfNeeded();
          }
        });
        _handleFirstWinIfNeeded();
      },
    );
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
                    'Killer',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              PlayerThrowPanel(
                timeline: _timeline,
                activePlayerIndex: active,
                playerName: winner != null ? widget.players[winner] : widget.players[active],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: widget.players.length,
                  itemBuilder: (context, i) {
                    final isActive = i == active && winner == null;
                    final isWinner = winner == i;
                    final number = widget.setup.playerNumbers[i] ?? 0;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
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
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.players[i],
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
                                  'Numero: $number · Lives: ${_state.lives[i]} · Kills: ${_state.kills[i]}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: cs.onSurfaceVariant),
                                ),
                                if (_state.isKiller[i])
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      'KILLER',
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelLarge
                                          ?.copyWith(
                                            color: cs.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
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
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

