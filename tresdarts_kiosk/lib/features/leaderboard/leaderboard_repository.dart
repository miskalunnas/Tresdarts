import 'dart:convert';

import '../../core/storage/key_value_storage.dart';
import '../../core/storage/shared_preferences_storage.dart';
import '../games/game_mode.dart';
import 'game_result.dart';

const _key = 'tresdarts_leaderboard_results';
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
    required this.byMode,
    this.lastPlayed,
  });

  final String playerName;
  final int totalWins;
  final int totalPlayed;
  final Map<GameModeId, ModeStats> byMode;
  final DateTime? lastPlayed;

  double get winRate => totalPlayed > 0 ? totalWins / totalPlayed : 0.0;
}

class ModeStats {
  const ModeStats({required this.wins, required this.played});

  final int wins;
  final int played;

  double get winRate => played > 0 ? wins / played : 0.0;
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
  LeaderboardRepository([KeyValueStorage? storage])
      : _storage = storage ?? SharedPreferencesStorage();

  final KeyValueStorage _storage;

  Future<void> saveResult(GameResult result) async {
    final list = await getResults(limit: _maxResults + 1);
    list.insert(0, result);
    final trimmed =
        list.length > _maxResults ? list.sublist(0, _maxResults) : list;
    final encoded = jsonEncode(trimmed.map((e) => e.toJson()).toList());
    await _storage.set(_key, encoded);
  }

  Future<List<GameResult>> getResults({
    GameModeId? mode,
    int? limit,
  }) async {
    final raw = await _storage.get(_key);
    if (raw == null || raw.isEmpty) return [];
    List<dynamic> decoded;
    try {
      decoded = jsonDecode(raw) as List<dynamic>? ?? [];
    } catch (_) {
      return [];
    }
    var results = decoded
        .map((e) => GameResult.fromJson(
            e is Map<String, dynamic> ? e : (e is Map ? Map<String, dynamic>.from(e) : null)))
        .whereType<GameResult>()
        .toList();
    if (mode != null) {
      results = results.where((r) => r.gameModeId == mode).toList();
    }
    if (limit != null && results.length > limit) {
      results = results.sublist(0, limit);
    }
    return results;
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
        byMode: {},
      );
    }
    final results = await getResults(limit: null);
    var totalWins = 0;
    var totalPlayed = 0;
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
      final modeStats = byMode[r.gameModeId] ?? const ModeStats(wins: 0, played: 0);
      byMode[r.gameModeId] = ModeStats(
        wins: modeStats.wins + (r.winnerName.trim().toLowerCase() == key ? 1 : 0),
        played: modeStats.played + 1,
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
