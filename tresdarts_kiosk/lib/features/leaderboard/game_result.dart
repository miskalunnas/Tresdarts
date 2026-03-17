import '../games/game_mode.dart';

class GameResult {
  const GameResult({
    required this.gameModeId,
    required this.winnerName,
    required this.players,
    this.scores = const {},
    required this.playedAt,
  });

  final GameModeId gameModeId;
  final String winnerName;
  final List<String> players;
  final Map<String, dynamic> scores;
  final DateTime playedAt;

  Map<String, dynamic> toJson() {
    return {
      'gameModeId': gameModeId.name,
      'winnerName': winnerName,
      'players': players,
      'scores': scores,
      'playedAt': playedAt.toIso8601String(),
    };
  }

  static GameResult? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final gameModeIdStr = json['gameModeId'] as String?;
    if (gameModeIdStr == null) return null;
    GameModeId? gameModeId;
    for (final e in GameModeId.values) {
      if (e.name == gameModeIdStr) {
        gameModeId = e;
        break;
      }
    }
    if (gameModeId == null) return null;
    final playersRaw = json['players'];
    final players = playersRaw is List
        ? playersRaw.whereType<String>().toList(growable: false)
        : <String>[];
    final scoresRaw = json['scores'];
    final scores = scoresRaw is Map
        ? Map<String, dynamic>.from(
            scoresRaw.map((k, v) => MapEntry(k.toString(), v)),
          )
        : <String, dynamic>{};
    final playedAtStr = json['playedAt'] as String?;
    final playedAt =
        playedAtStr != null ? DateTime.tryParse(playedAtStr) : null;
    if (playedAt == null) return null;
    final winnerName = json['winnerName'] as String? ?? '';
    return GameResult(
      gameModeId: gameModeId,
      winnerName: winnerName,
      players: players,
      scores: scores,
      playedAt: playedAt,
    );
  }
}
