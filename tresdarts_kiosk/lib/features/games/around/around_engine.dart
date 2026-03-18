import '../darts_throw.dart';
import '../turn_timeline.dart';

class AroundState {
  const AroundState({
    required this.players,
    required this.progress, // 1..21 (21 == bull done)
    required this.winnerIndex,
  });

  final List<String> players;
  final List<int> progress;
  final int? winnerIndex;
}

AroundState computeAround({
  required List<String> players,
  required TurnTimeline timeline,
}) {
  final progress = List<int>.filled(players.length, 1);
  int? winner;

  bool hitTarget(DartThrow t, int target) {
    if (target >= 1 && target <= 20) {
      return t.segment.kind == DartSegmentKind.number &&
          t.segment.value == target;
    }
    // target 21 means bull
    if (target == 21) {
      return t.segment.kind == DartSegmentKind.bull25 ||
          t.segment.kind == DartSegmentKind.bull50;
    }
    return false;
  }

  for (final turn in timeline.turns) {
    final idx = turn.playerIndex;
    if (winner != null) break;
    int p = progress[idx];
    for (final t in turn.throws) {
      final target = p;
      if (hitTarget(t, target)) {
        final advance = t.multiplier.value; // single=1, double=2, triple=3
        p += advance;
        if (p >= 21) {
          p = 21;
          winner = idx;
          break;
        }
      }
    }
    progress[idx] = p;
  }

  return AroundState(
    players: players,
    progress: progress,
    winnerIndex: winner,
  );
}

