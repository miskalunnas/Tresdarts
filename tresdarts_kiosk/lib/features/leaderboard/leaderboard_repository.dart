import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../games/game_mode.dart';
import 'game_result.dart';

const _key = 'tresdarts_leaderboard_results';
const _maxResults = 500;

class LeaderboardRepository {
  LeaderboardRepository([SharedPreferences? prefs]) : _prefs = prefs;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> saveResult(GameResult result) async {
    final prefs = await _getPrefs();
    final list = await getResults(limit: _maxResults + 1);
    list.insert(0, result);
    final trimmed =
        list.length > _maxResults ? list.sublist(0, _maxResults) : list;
    final encoded = jsonEncode(trimmed.map((e) => e.toJson()).toList());
    await prefs.setString(_key, encoded);
  }

  Future<List<GameResult>> getResults({
    GameModeId? mode,
    int? limit,
  }) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_key);
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
}
