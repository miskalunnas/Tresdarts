import 'package:flutter/material.dart';

import '../../leaderboard/game_result.dart';
import '../../games/game_mode.dart';
import '../game_rules.dart';
import '../throw_input_sheet.dart';
import '../darts_throw.dart';
import '../confirm_exit_game_dialog.dart';
import '../win_continue_dialog.dart';
import '../turn_order_spinner_dialog.dart';
import '../../leaderboard/leaderboard_repository.dart';
import 'x01_checkout.dart';
import 'x01_game.dart';
import 'x01_setup_view.dart';

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
  int? _firstWinnerIndex;
  bool _playOut = false;
  bool _winDialogOpen = false;
  final Set<int> _frozenPlayers = {};
  late List<int> _playOutScores;
  int _playOutActive = 0;
  int _playOutDartsInTurn = 0;
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
        Navigator.of(context).pushReplacementNamed(
          X01GameView.routeName,
          arguments: X01Setup(startScore: widget.startScore, players: order),
        );
      }
    });
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
    if (_playOut) {
      _applyThrowPlayOut(t);
      return;
    }

    if (_state.isFinished) return;
    setState(() {
      _throws.add(t);
      _state = _state.applyThrow(t.points);
    });
    if (_state.isFinished) {
      _handleFirstWinX01();
    }
  }

  Future<void> _handleFirstWinX01() async {
    final winnerIndex = _state.winnerIndex;
    if (winnerIndex == null) return;
    if (_firstWinnerIndex != null) return;
    if (_winDialogOpen) return;
    _winDialogOpen = true;

    final pd = _pointsAndDartsFromX01(_state);
    final result = GameResult(
      gameModeId: GameModeId.x01,
      winnerName: _state.players[winnerIndex],
      players: _state.players,
      scores: {
        'startScore': _state.startScore,
        'throws': _throws.length,
        'dartPointsByPlayer': pd.pointsByName,
        'dartCountByPlayer': pd.dartsByName,
      },
      playedAt: DateTime.now(),
    );

    final action = await showWinContinueDialog(
      context,
      winnerName: _state.players[winnerIndex],
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
      _firstWinnerIndex = winnerIndex;
      _playOut = true;
      _frozenPlayers.add(winnerIndex);
      _playOutScores = [..._state.scores];
      // Pick next active player after winner, skipping frozen.
      _playOutActive = _nextNonFrozen((winnerIndex + 1) % _state.players.length) ?? winnerIndex;
      _playOutDartsInTurn = 0;
    });
  }

  int? _nextNonFrozen(int start) {
    if (_state.players.isEmpty) return null;
    var idx = start;
    for (var i = 0; i < _state.players.length; i++) {
      if (!_frozenPlayers.contains(idx)) return idx;
      idx = (idx + 1) % _state.players.length;
    }
    return null;
  }

  void _applyThrowPlayOut(DartThrow t) {
    if (_frozenPlayers.contains(_playOutActive)) {
      setState(() {
        final next = _nextNonFrozen((_playOutActive + 1) % _state.players.length);
        if (next != null) _playOutActive = next;
        _playOutDartsInTurn = 0;
      });
      return;
    }

    final idx = _playOutActive;
    final before = _playOutScores[idx];
    final points = t.points.clamp(0, 180);
    final after = before - points;
    final isBust = after < 0;
    final didWin = !isBust && after == 0;
    final endsTurn = didWin || isBust || _playOutDartsInTurn >= 2;

    setState(() {
      _throws.add(t);
      _playOutScores[idx] = isBust ? before : after;

      if (didWin) {
        _frozenPlayers.add(idx);
      }

      if (endsTurn) {
        _playOutDartsInTurn = 0;
        final next = _nextNonFrozen((idx + 1) % _state.players.length);
        if (next != null) _playOutActive = next;
      } else {
        _playOutDartsInTurn = (_playOutDartsInTurn + 1).clamp(0, 2);
      }
    });

    final remaining = _state.players.length - _frozenPlayers.length;
    if (remaining <= 1 && mounted) {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Loppupeli ohi'),
          content: const Text('Loppupelin tuloksia ei tallenneta.'),
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.onExit();
              },
              child: const Text('Palaa valikkoon'),
            ),
          ],
        ),
      );
    }
  }

  _NamePointsDarts _pointsAndDartsFromX01(X01GameState state) {
    final pointsByIdx = <int, int>{};
    final dartsByIdx = <int, int>{};
    for (final h in state.history) {
      pointsByIdx[h.playerIndex] = (pointsByIdx[h.playerIndex] ?? 0) + h.points;
      dartsByIdx[h.playerIndex] = (dartsByIdx[h.playerIndex] ?? 0) + 1;
    }
    final pointsByName = <String, int>{};
    final dartsByName = <String, int>{};
    for (var i = 0; i < state.players.length; i++) {
      pointsByName[state.players[i]] = pointsByIdx[i] ?? 0;
      dartsByName[state.players[i]] = dartsByIdx[i] ?? 0;
    }
    return _NamePointsDarts(pointsByName: pointsByName, dartsByName: dartsByName);
  }

  void _addThrow() {
    final activeIdx = _playOut ? _playOutActive : _state.activePlayerIndex;
    final remaining = _playOut ? _playOutScores[activeIdx] : _state.scores[activeIdx];
    final checkout = suggestX01Checkout(remaining);
    ThrowInputSheet.show(
      context,
      title: 'Lisää heitto',
      maxPicks: _playOut ? (3 - _playOutDartsInTurn) : (3 - _state.dartsInTurn),
      onPick: _applyThrow,
      onPickMany: (list) {
        for (final t in list) {
          _applyThrow(t);
          if (!_playOut && _state.isFinished) break;
        }
      },
      remainingPoints: remaining,
      checkoutText: checkout,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = _playOut ? _playOutActive : _state.activePlayerIndex;
    final winner = _playOut ? _firstWinnerIndex : _state.winnerIndex;

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
                      _X01ThrowPanel(
                        state: _state,
                        activePlayerIndex: active,
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

class _X01ThrowPanel extends StatelessWidget {
  const _X01ThrowPanel({
    required this.state,
    required this.activePlayerIndex,
  });

  final X01GameState state;
  final int activePlayerIndex;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final history = state.history
        .where((h) => h.playerIndex == activePlayerIndex)
        .toList(growable: false);
    final last = history.reversed.take(9).toList(growable: false);
    final totalPoints =
        history.fold<int>(0, (sum, h) => sum + h.points);
    final darts = history.length;
    final avg3 = darts > 0 ? (totalPoints / darts) * 3.0 : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                state.players[activePlayerIndex],
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
              ),
              const Spacer(),
              Text(
                'AVG (3): ${avg3.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (last.isEmpty)
            Text(
              'Ei heittoja vielä.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final h in last)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outline),
                    ),
                    child: Text(
                      '${h.points}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _NamePointsDarts {
  const _NamePointsDarts({required this.pointsByName, required this.dartsByName});
  final Map<String, int> pointsByName;
  final Map<String, int> dartsByName;
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

