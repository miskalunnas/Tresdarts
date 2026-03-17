import '../darts_throw.dart';
import '../turn_timeline.dart';

class ShanghaiState {
  const ShanghaiState({
    required this.players,
    required this.scores,
    required this.round,
    required this.roundThrows,
    required this.shanghaiByPlayer,
    required this.winnerIndex,
  });

  final List<String> players;
  final List<int> scores;
  final int round; // 1..20
  final Map<int, List<DartThrow>> roundThrows; // playerIndex -> throws for current round (this player's current turn only)
  final List<bool> shanghaiByPlayer;
  final int? winnerIndex;
}

ShanghaiState computeShanghai({
  required List<String> players,
  required TurnTimeline timeline,
}) {
  final scores = List<int>.filled(players.length, 0);
  final shanghai = List<bool>.filled(players.length, false);
  var round = 1;

  // We approximate rounds by completed turns: every player turn advances the round after all players have taken a turn.
  // Round = 1 + floor(completedTurns / playerCount)
  final completedTurns = timeline.turns.where((t) => t.throws.length == 3).length;
  round = (completedTurns ~/ players.length) + 1;
  if (round > 20) round = 20;

  for (final turn in timeline.turns) {
    final target = ((timeline.turns.indexOf(turn) ~/ players.length) + 1).clamp(1, 20);
    for (final t in turn.throws) {
      if (t.segment.kind == DartSegmentKind.number && t.segment.value == target) {
        scores[turn.playerIndex] += t.points;
      }
    }
    // Detect shanghai in this turn for target
    final hasS = turn.throws.any((t) =>
        t.segment.kind == DartSegmentKind.number &&
        t.segment.value == target &&
        t.multiplier == DartMultiplier.single);
    final hasD = turn.throws.any((t) =>
        t.segment.kind == DartSegmentKind.number &&
        t.segment.value == target &&
        t.multiplier == DartMultiplier.double);
    final hasT = turn.throws.any((t) =>
        t.segment.kind == DartSegmentKind.number &&
        t.segment.value == target &&
        t.multiplier == DartMultiplier.triple);
    if (hasS && hasD && hasT) {
      shanghai[turn.playerIndex] = true;
    }
  }

  // Winner heuristic: if someone got shanghai, first one wins; else highest score after round 20.
  int? winner;
  final shWinner = shanghai.indexWhere((x) => x);
  if (shWinner >= 0) {
    winner = shWinner;
  } else if (round == 20 && completedTurns >= players.length * 20) {
    var best = 0;
    for (var i = 1; i < players.length; i++) {
      if (scores[i] > scores[best]) best = i;
    }
    winner = best;
  }

  // Current round throws: show last active player's current turn throws
  final roundThrows = <int, List<DartThrow>>{};
  if (timeline.turns.isNotEmpty) {
    final last = timeline.turns.last;
    roundThrows[last.playerIndex] = last.throws;
  }

  return ShanghaiState(
    players: players,
    scores: scores,
    round: round,
    roundThrows: roundThrows,
    shanghaiByPlayer: shanghai,
    winnerIndex: winner,
  );
}

