import 'dart:convert';

import '../../core/storage/key_value_storage.dart';
import '../../core/storage/shared_preferences_storage.dart';
import 'player_profile.dart';

const _playersKey = 'tresdarts_players';
const _maxPlayers = 500;

class PlayerRepository {
  PlayerRepository([KeyValueStorage? storage])
      : _storage = storage ?? SharedPreferencesStorage();

  final KeyValueStorage _storage;

  Future<List<PlayerProfile>> getPlayers() async {
    final raw = await _storage.get(_playersKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .map((e) => PlayerProfile.fromJson(
              e is Map<String, dynamic> ? e : (e is Map ? Map<String, dynamic>.from(e) : null)))
          .whereType<PlayerProfile>()
          .toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } catch (_) {
      return [];
    }
  }

  Future<void> upsert(PlayerProfile profile) async {
    final players = await getPlayers();
    final idx = players.indexWhere((p) => p.id == profile.id);
    if (idx >= 0) {
      players[idx] = profile;
    } else {
      players.add(profile);
    }
    await _save(players);
  }

  Future<PlayerProfile> upsertByName({
    required String name,
    String? entrySong,
    String? photoPath,
  }) async {
    final trimmed = name.trim();
    final players = await getPlayers();
    final idx = players.indexWhere(
      (p) => p.name.toLowerCase() == trimmed.toLowerCase(),
    );

    final profile = idx >= 0
        ? PlayerProfile(
            id: players[idx].id,
            name: players[idx].name,
            entrySong: entrySong ?? players[idx].entrySong,
            photoPath: photoPath ?? players[idx].photoPath,
            createdAt: players[idx].createdAt,
          )
        : PlayerProfile(
            id: _newId(),
            name: trimmed,
            entrySong: entrySong,
            photoPath: photoPath,
            createdAt: DateTime.now(),
          );

    await upsert(profile);
    return profile;
  }

  Future<void> _save(List<PlayerProfile> players) async {
    final trimmed = players.length > _maxPlayers
        ? players.sublist(players.length - _maxPlayers)
        : players;
    final encoded = jsonEncode(trimmed.map((e) => e.toJson()).toList());
    await _storage.set(_playersKey, encoded);
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
