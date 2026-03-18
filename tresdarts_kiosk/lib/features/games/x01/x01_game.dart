class X01GameState {
  const X01GameState({
    required this.startScore,
    required this.players,
    required this.scores,
    required this.activePlayerIndex,
    required this.dartsInTurn,
    required this.history,
    required this.winnerIndex,
  });

  final int startScore;
  final List<String> players;
  final List<int> scores;
  final int activePlayerIndex;
  /// Kuinka monta heittoa aktiivisen pelaajan nykyisessä vuorossa on jo heitetty (0..2).
  final int dartsInTurn;
  final List<X01Throw> history;
  final int? winnerIndex;

  bool get isFinished => winnerIndex != null;

  static X01GameState start({
    required int startScore,
    required List<String> players,
  }) {
    return X01GameState(
      startScore: startScore,
      players: players,
      scores: List<int>.filled(players.length, startScore, growable: false),
      activePlayerIndex: 0,
      dartsInTurn: 0,
      history: const [],
      winnerIndex: null,
    );
  }

  X01GameState applyThrow(int points) {
    if (isFinished) return this;
    final clamped = points.clamp(0, 180);
    final idx = activePlayerIndex;
    final before = scores[idx];
    final after = before - clamped;
    final isBust = after < 0;
    final nextScores = [...scores];
    nextScores[idx] = isBust ? before : after;

    final didWin = !isBust && after == 0;
    final nextWinner = didWin ? idx : null;
    final endsTurn = didWin || isBust || dartsInTurn >= 2;
    final nextActive = didWin ? idx : (endsTurn ? ((idx + 1) % players.length) : idx);
    final nextDartsInTurn = didWin
        ? 0
        : (endsTurn ? 0 : (dartsInTurn + 1).clamp(0, 2));

    return X01GameState(
      startScore: startScore,
      players: players,
      scores: nextScores,
      activePlayerIndex: nextActive,
      dartsInTurn: nextDartsInTurn,
      history: [
        ...history,
        X01Throw(
          playerIndex: idx,
          points: clamped,
          wasBust: isBust,
          beforeScore: before,
          afterScore: nextScores[idx],
          beforeDartsInTurn: dartsInTurn,
        ),
      ],
      winnerIndex: nextWinner,
    );
  }

  X01GameState undo() {
    if (history.isEmpty) return this;
    final last = history.last;
    final nextScores = [...scores];
    nextScores[last.playerIndex] = last.beforeScore;
    return X01GameState(
      startScore: startScore,
      players: players,
      scores: nextScores,
      activePlayerIndex: last.playerIndex,
      dartsInTurn: last.beforeDartsInTurn,
      history: history.sublist(0, history.length - 1),
      winnerIndex: null,
    );
  }
}

class X01Throw {
  const X01Throw({
    required this.playerIndex,
    required this.points,
    required this.wasBust,
    required this.beforeScore,
    required this.afterScore,
    required this.beforeDartsInTurn,
  });

  final int playerIndex;
  final int points;
  final bool wasBust;
  final int beforeScore;
  final int afterScore;
  final int beforeDartsInTurn;
}

