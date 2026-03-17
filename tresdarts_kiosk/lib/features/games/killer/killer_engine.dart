import '../darts_throw.dart';
import '../turn_timeline.dart';
import 'killer_setup_view.dart';

class KillerState {
  const KillerState({
    required this.players,
    required this.numbers,
    required this.lives,
    required this.kills,
    required this.isKiller,
    required this.winnerIndex,
  });

  final List<String> players;
  final Map<int, int> numbers; // playerIndex -> number
  final List<int> lives;
  final List<int> kills;
  final List<bool> isKiller;
  final int? winnerIndex;
}

KillerState computeKiller({
  required List<String> players,
  required KillerSetup setup,
  required TurnTimeline timeline,
}) {
  final lives = List<int>.filled(players.length, setup.lives);
  final kills = List<int>.filled(players.length, 0);
  final isKiller = List<bool>.filled(players.length, false);
  int? winner;

  int? hitNumber(DartThrow t) {
    if (t.segment.kind != DartSegmentKind.number) return null;
    return t.segment.value;
  }

  int aliveCount() => lives.where((l) => l > 0).length;

  for (final turn in timeline.turns) {
    final pIdx = turn.playerIndex;
    if (lives[pIdx] <= 0) continue;
    for (final t in turn.throws) {
      if (winner != null) break;
      final n = hitNumber(t);
      if (n == null) continue;

      // Own number -> build killer
      if (n == setup.playerNumbers[pIdx]) {
        kills[pIdx] += t.multiplier.value;
        if (kills[pIdx] >= setup.killsToBecomeKiller) {
          isKiller[pIdx] = true;
        }
        continue;
      }

      // If killer, can reduce others by hitting their number
      if (isKiller[pIdx]) {
        final target = setup.playerNumbers.entries
            .firstWhere(
              (e) => e.value == n,
              orElse: () => const MapEntry(-1, -1),
            )
            .key;
        if (target >= 0 && target != pIdx && lives[target] > 0) {
          lives[target] = (lives[target] - t.multiplier.value).clamp(0, setup.lives);
          if (aliveCount() == 1) {
            winner = lives.indexWhere((l) => l > 0);
            break;
          }
        }
      }
    }
  }

  return KillerState(
    players: players,
    numbers: setup.playerNumbers,
    lives: lives,
    kills: kills,
    isKiller: isKiller,
    winnerIndex: winner,
  );
}

