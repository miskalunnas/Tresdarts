import '../darts_throw.dart';
import '../turn_timeline.dart';

const cricketNumbers = <int>[15, 16, 17, 18, 19, 20];

class CricketState {
  const CricketState({
    required this.players,
    required this.scores,
    required this.marks,
    required this.winnerIndex,
  });

  final List<String> players;
  final List<int> scores;
  final Map<int, List<int>> marks; // key: 15..20, 25(bull) => per player marks 0..3
  final int? winnerIndex;
}

CricketState computeCricket({
  required List<String> players,
  required TurnTimeline timeline,
}) {
  final scores = List<int>.filled(players.length, 0);
  final marks = <int, List<int>>{
    for (final n in cricketNumbers) n: List<int>.filled(players.length, 0),
    25: List<int>.filled(players.length, 0),
  };

  void applyHit(int playerIndex, int key, int hitCount, int pointsPerHit) {
    final myMarks = marks[key]!;
    final oppClosed = _allOpponentsClosed(marks[key]!, playerIndex);
    var remaining = hitCount;
    while (remaining > 0) {
      if (myMarks[playerIndex] < 3) {
        myMarks[playerIndex] = myMarks[playerIndex] + 1;
      } else {
        // already closed; score if opponent not closed
        if (!oppClosed) {
          scores[playerIndex] += pointsPerHit;
        }
      }
      remaining--;
    }
  }

  for (final turn in timeline.turns) {
    for (final t in turn.throws) {
      final idx = turn.playerIndex;
      switch (t.segment.kind) {
        case DartSegmentKind.number:
          final v = t.segment.value;
          if (v == null) break;
          if (!cricketNumbers.contains(v)) break;
          applyHit(idx, v, t.multiplier.value, v);
          break;
        case DartSegmentKind.bull25:
          applyHit(idx, 25, 1, 25);
          break;
        case DartSegmentKind.bull50:
          applyHit(idx, 25, 2, 25);
          break;
        case DartSegmentKind.miss:
          break;
      }
    }
  }

  int? winner;
  for (var i = 0; i < players.length; i++) {
    if (_allClosedForPlayer(marks, i)) {
      final bestOther = scores
          .asMap()
          .entries
          .where((e) => e.key != i)
          .map((e) => e.value)
          .fold<int>(0, (a, b) => a > b ? a : b);
      if (scores[i] >= bestOther) {
        winner = i;
        break;
      }
    }
  }

  return CricketState(
    players: players,
    scores: scores,
    marks: marks,
    winnerIndex: winner,
  );
}

bool _allOpponentsClosed(List<int> marksForKey, int playerIndex) {
  for (var i = 0; i < marksForKey.length; i++) {
    if (i == playerIndex) continue;
    if (marksForKey[i] < 3) return false;
  }
  return true;
}

bool _allClosedForPlayer(Map<int, List<int>> marks, int playerIndex) {
  for (final e in marks.entries) {
    if (e.value[playerIndex] < 3) return false;
  }
  return true;
}

