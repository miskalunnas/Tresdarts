import 'dart:convert';

import '../../core/db/sqlite_db.dart';
import '../games/game_mode.dart';
import 'game_result.dart';

const _maxResults = 500;

/// Käyttäjäkohtainen ranking: nimi + voittojen määrä + pelatut + viimeisin peli.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.playerName,
    required this.wins,
    required this.played,
    this.lastPlayed,
  });

  final String playerName;
  final int wins;
  final int played;
  final DateTime? lastPlayed;

  double get winRate => played > 0 ? wins / played : 0.0;
}

/// Käyttäjäkohtaiset tilastot (yhteenveto + per pelimuoto).
class UserStats {
  const UserStats({
    required this.playerName,
    required this.totalWins,
    required this.totalPlayed,
    required this.totalPoints,
    required this.totalDarts,
    required this.byMode,
    this.lastPlayed,
  });

  final String playerName;
  final int totalWins;
  final int totalPlayed;
  final int totalPoints;
  final int totalDarts;
  final Map<GameModeId, ModeStats> byMode;
  final DateTime? lastPlayed;

  double get winRate => totalPlayed > 0 ? totalWins / totalPlayed : 0.0;
  double get avg3 => totalDarts > 0 ? (totalPoints / totalDarts) * 3.0 : 0.0;
}

class ModeStats {
  const ModeStats({
    required this.wins,
    required this.played,
    required this.points,
    required this.darts,
  });

  final int wins;
  final int played;
  final int points;
  final int darts;

  double get winRate => played > 0 ? wins / played : 0.0;
  double get avg3 => darts > 0 ? (points / darts) * 3.0 : 0.0;
}

/// Pelimuotokohtainen yhteenveto.
class GameModeStats {
  const GameModeStats({
    required this.modeId,
    required this.gamesPlayed,
    required this.uniquePlayers,
    required this.topPlayers,
  });

  final GameModeId modeId;
  final int gamesPlayed;
  final int uniquePlayers;
  final List<LeaderboardEntry> topPlayers;
}

class LeaderboardRepository {
  LeaderboardRepository();

  Future<void> saveResult(GameResult result) async {
    final db = await SqliteDb.instance.db;
    await db.insert('game_results', {
      'game_mode_id': result.gameModeId.name,
      'winner_name': result.winnerName,
      'players_json': jsonEncode(result.players),
      'scores_json': jsonEncode(result.scores),
      'played_at_ms': result.playedAt.millisecondsSinceEpoch,
    });

    // Keep last _maxResults only.
    final rows = await db.query(
      'game_results',
      columns: const ['id'],
      orderBy: 'played_at_ms DESC, id DESC',
      offset: _maxResults,
    );
    if (rows.isNotEmpty) {
      final ids = rows.map((r) => r['id'] as int).toList();
      await db.delete(
        'game_results',
        where: 'id IN (${List.filled(ids.length, '?').join(',')})',
        whereArgs: ids,
      );
    }
  }

  Future<List<GameResult>> getResults({
    GameModeId? mode,
    int? limit,
  }) async {
    final db = await SqliteDb.instance.db;
    final where = mode != null ? 'game_mode_id = ?' : null;
    final whereArgs = mode != null ? [mode.name] : null;
    final rows = await db.query(
      'game_results',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'played_at_ms DESC, id DESC',
      limit: limit,
    );
    return rows.map((r) {
      final modeStr = (r['game_mode_id'] as String?) ?? '';
      GameModeId? modeId;
      for (final e in GameModeId.values) {
        if (e.name == modeStr) {
          modeId = e;
          break;
        }
      }
      modeId ??= GameModeId.cricket;
      final playersJson = (r['players_json'] as String?) ?? '[]';
      final scoresJson = (r['scores_json'] as String?) ?? '{}';
      final players = (jsonDecode(playersJson) as List<dynamic>?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const <String>[];
      final scoresRaw = jsonDecode(scoresJson);
      final scores = scoresRaw is Map
          ? Map<String, dynamic>.from(
              scoresRaw.map((k, v) => MapEntry(k.toString(), v)),
            )
          : <String, dynamic>{};
      return GameResult(
        gameModeId: modeId,
        winnerName: (r['winner_name'] as String?) ?? '',
        players: players,
        scores: scores,
        playedAt: DateTime.fromMillisecondsSinceEpoch(
          (r['played_at_ms'] as int?) ?? 0,
        ),
      );
    }).toList(growable: false);
  }

  Future<void> anonymizePlayer(String oldName, {String replacement = 'Poistettu käyttäjä'}) async {
    final key = oldName.trim().toLowerCase();
    if (key.isEmpty) return;
    final db = await SqliteDb.instance.db;
    final rows = await db.query(
      'game_results',
      columns: const ['id', 'winner_name', 'players_json'],
    );
    await db.transaction((txn) async {
      for (final r in rows) {
        final id = r['id'] as int?;
        if (id == null) continue;
        final winnerName = (r['winner_name'] as String?) ?? '';
        final playersJson = (r['players_json'] as String?) ?? '[]';
        List<dynamic> playersRaw;
        try {
          playersRaw = jsonDecode(playersJson) as List<dynamic>? ?? [];
        } catch (_) {
          playersRaw = const [];
        }
        final players = playersRaw.map((e) => e.toString()).toList(growable: false);

        final nextWinner = winnerName.trim().toLowerCase() == key ? replacement : winnerName;
        final nextPlayers = players
            .map((p) => p.trim().toLowerCase() == key ? replacement : p)
            .toList(growable: false);

        if (nextWinner == winnerName && _listEquals(nextPlayers, players)) continue;

        await txn.update(
          'game_results',
          {
            'winner_name': nextWinner,
            'players_json': jsonEncode(nextPlayers),
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Käyttäjäkohtainen ranking: eniten voittoja ensin. Pysyvä lista = kaikki tulokset.
  Future<List<LeaderboardEntry>> getLeaderboardByWins({
    GameModeId? mode,
    int? limit,
  }) async {
    final results = await getResults(mode: mode, limit: null);
    final winsByName = <String, int>{};
    final playedByName = <String, int>{};
    final lastPlayed = <String, DateTime>{};
    final displayNameByKey = <String, String>{};
    for (final r in results) {
      final winnerKey = r.winnerName.trim().toLowerCase();
      if (winnerKey.isNotEmpty) {
        winsByName[winnerKey] = (winsByName[winnerKey] ?? 0) + 1;
        final dn = r.winnerName.trim();
        displayNameByKey[winnerKey] = dn;
      }
      for (final p in r.players) {
        final key = p.trim().toLowerCase();
        if (key.isEmpty) continue;
        playedByName[key] = (playedByName[key] ?? 0) + 1;
        final existing = lastPlayed[key];
        if (existing == null || r.playedAt.isAfter(existing)) {
          lastPlayed[key] = r.playedAt;
        }
        displayNameByKey[key] = p.trim();
      }
    }
    final names = winsByName.keys.toSet().union(playedByName.keys.toSet()).toList();
    names.sort((a, b) => (winsByName[b] ?? 0).compareTo(winsByName[a] ?? 0));
    var list = names.map((key) {
      final displayName = displayNameByKey[key] ?? key;
      return LeaderboardEntry(
        playerName: displayName,
        wins: winsByName[key] ?? 0,
        played: playedByName[key] ?? 0,
        lastPlayed: lastPlayed[key],
      );
    }).toList();
    if (limit != null && list.length > limit) {
      list = list.sublist(0, limit);
    }
    return list;
  }

  /// Keskinäiset ottelut 1v1: pelit joissa pelaajat ovat täsmälleen nämä kaksi.
  Future<List<GameResult>> getHeadToHead(String name1, String name2) async {
    final n1 = name1.trim().toLowerCase();
    final n2 = name2.trim().toLowerCase();
    if (n1 == n2) return [];
    final results = await getResults(limit: null);
    return results.where((r) {
      if (r.players.length != 2) return false;
      final p1 = r.players[0].trim().toLowerCase();
      final p2 = r.players[1].trim().toLowerCase();
      return (p1 == n1 && p2 == n2) || (p1 == n2 && p2 == n1);
    }).toList();
  }

  /// Käyttäjäkohtaiset tilastot: voitot ja pelit yhteensä + per pelimuoto.
  Future<UserStats> getUserStats(String playerName) async {
    final key = playerName.trim().toLowerCase();
    if (key.isEmpty) {
      return UserStats(
        playerName: playerName,
        totalWins: 0,
        totalPlayed: 0,
        totalPoints: 0,
        totalDarts: 0,
        byMode: {},
      );
    }
    final results = await getResults(limit: null);
    var totalWins = 0;
    var totalPlayed = 0;
    var totalPoints = 0;
    var totalDarts = 0;
    DateTime? lastPlayed;
    final byMode = <GameModeId, ModeStats>{};
    for (final r in results) {
      final participates = r.players.any((p) => p.trim().toLowerCase() == key);
      if (!participates) continue;
      totalPlayed++;
      if (r.winnerName.trim().toLowerCase() == key) totalWins++;
      if (lastPlayed == null || r.playedAt.isAfter(lastPlayed)) {
        lastPlayed = r.playedAt;
      }
      var addPoints = 0;
      var addDarts = 0;
      final s = r.scores;
      final pMap = s['dartPointsByPlayer'];
      final dMap = s['dartCountByPlayer'];
      if (pMap is Map && dMap is Map) {
        dynamic pv;
        dynamic dv;
        for (final e in pMap.entries) {
          if (e.key.toString().trim().toLowerCase() == key) {
            pv = e.value;
            break;
          }
        }
        for (final e in dMap.entries) {
          if (e.key.toString().trim().toLowerCase() == key) {
            dv = e.value;
            break;
          }
        }
        if (pv is num) addPoints = pv.toInt();
        if (dv is num) addDarts = dv.toInt();
      }
      totalPoints += addPoints;
      totalDarts += addDarts;

      final modeStats = byMode[r.gameModeId] ??
          const ModeStats(wins: 0, played: 0, points: 0, darts: 0);
      byMode[r.gameModeId] = ModeStats(
        wins: modeStats.wins + (r.winnerName.trim().toLowerCase() == key ? 1 : 0),
        played: modeStats.played + 1,
        points: modeStats.points + addPoints,
        darts: modeStats.darts + addDarts,
      );
    }
    final candidates = results
        .expand((r) => r.players)
        .map((p) => p.trim())
        .where((n) => n.isNotEmpty && n.toLowerCase() == key)
        .toList();
    final displayName = candidates.isNotEmpty ? candidates.first : playerName;
    return UserStats(
      playerName: displayName,
      totalWins: totalWins,
      totalPlayed: totalPlayed,
      totalPoints: totalPoints,
      totalDarts: totalDarts,
      byMode: byMode,
      lastPlayed: lastPlayed,
    );
  }

  /// Pelimuotokohtaiset tilastot: pelien määrä, pelaajien määrä, top-pelaajat.
  Future<GameModeStats> getGameModeStats(GameModeId modeId) async {
    final results = await getResults(mode: modeId, limit: null);
    final top = await getLeaderboardByWins(mode: modeId, limit: 10);
    final unique = results.expand((r) => r.players.map((p) => p.trim().toLowerCase())).toSet();
    return GameModeStats(
      modeId: modeId,
      gamesPlayed: results.length,
      uniquePlayers: unique.length,
      topPlayers: top,
    );
  }

  /// Kaikki pelimuodot: tilastot.
  Future<List<GameModeStats>> getAllGameModeStats() async {
    final list = <GameModeStats>[];
    for (final id in GameModeId.values) {
      list.add(await getGameModeStats(id));
    }
    return list;
  }
}
