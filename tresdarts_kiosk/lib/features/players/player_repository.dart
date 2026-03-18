import '../../core/db/sqlite_db.dart';
import 'package:sqflite/sqflite.dart';
import 'player_profile.dart';

const _maxPlayers = 500;

class PlayerRepository {
  PlayerRepository();

  Future<List<PlayerProfile>> getPlayers() async {
    final db = await SqliteDb.instance.db;
    final rows = await db.query(
      'players',
      orderBy: 'LOWER(name) ASC',
      limit: _maxPlayers,
    );
    return rows
        .map(
          (r) => PlayerProfile(
            id: (r['id'] as String?) ?? '',
            name: (r['name'] as String?) ?? '',
            entrySong: r['entry_song'] as String?,
            photoPath: r['photo_path'] as String?,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              (r['created_at_ms'] as int?) ?? 0,
            ),
          ),
        )
        .where((p) => p.id.isNotEmpty && p.name.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> upsert(PlayerProfile profile) async {
    final db = await SqliteDb.instance.db;
    await db.insert(
      'players',
      {
        'id': profile.id,
        'name': profile.name,
        'entry_song': profile.entrySong,
        'photo_path': profile.photoPath,
        'created_at_ms': profile.createdAt.millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<PlayerProfile> upsertByName({
    required String name,
    String? entrySong,
    String? photoPath,
  }) async {
    final trimmed = name.trim();
    final db = await SqliteDb.instance.db;
    final rows = await db.query(
      'players',
      where: 'LOWER(name) = ?',
      whereArgs: [trimmed.toLowerCase()],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      final r = rows.first;
      final existing = PlayerProfile(
        id: (r['id'] as String?) ?? '',
        name: (r['name'] as String?) ?? trimmed,
        entrySong: r['entry_song'] as String?,
        photoPath: r['photo_path'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          (r['created_at_ms'] as int?) ?? 0,
        ),
      );
      final updated = PlayerProfile(
        id: existing.id,
        name: existing.name,
        entrySong: entrySong ?? existing.entrySong,
        photoPath: photoPath ?? existing.photoPath,
        createdAt: existing.createdAt,
      );
      await upsert(updated);
      return updated;
    }

    final created = PlayerProfile(
      id: _newId(),
      name: trimmed,
      entrySong: entrySong,
      photoPath: photoPath,
      createdAt: DateTime.now(),
    );
    await upsert(created);
    return created;
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();
}
