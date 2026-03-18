import 'dart:convert';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../../features/leaderboard/game_result.dart';
import '../../features/players/player_profile.dart';

const _legacyPlayersKey = 'tresdarts_players';
const _legacyResultsKey = 'tresdarts_leaderboard_results';

class SqliteDb {
  SqliteDb._();

  static final SqliteDb instance = SqliteDb._();

  Database? _db;

  Future<Database> get db async {
    _db ??= await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'tresdarts.db');
    final database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, _) async {
        await _createSchema(db);
      },
    );

    // Ensure schema exists even if DB was created elsewhere.
    await _createSchema(database);
    await _migrateFromLegacyIfNeeded(database);
    return database;
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS players (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  entry_song TEXT,
  photo_path TEXT,
  created_at_ms INTEGER NOT NULL
);
''');
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_players_name_ci ON players(LOWER(name));');

    await db.execute('''
CREATE TABLE IF NOT EXISTS game_results (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  game_mode_id TEXT NOT NULL,
  winner_name TEXT NOT NULL,
  players_json TEXT NOT NULL,
  scores_json TEXT NOT NULL,
  played_at_ms INTEGER NOT NULL
);
''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_results_mode_time ON game_results(game_mode_id, played_at_ms DESC);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_results_time ON game_results(played_at_ms DESC);');
  }

  Future<void> _migrateFromLegacyIfNeeded(Database db) async {
    final countPlayers = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM players'),
        ) ??
        0;
    final countResults = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM game_results'),
        ) ??
        0;

    // Only migrate if DB is empty (fresh install) to avoid duplicates.
    if (countPlayers > 0 || countResults > 0) return;

    final prefs = await SharedPreferences.getInstance();
    await db.transaction((txn) async {
      // Players
      final rawPlayers = prefs.getString(_legacyPlayersKey);
      if (rawPlayers != null && rawPlayers.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawPlayers);
          if (decoded is List) {
            for (final e in decoded) {
              final map = e is Map<String, dynamic>
                  ? e
                  : (e is Map ? Map<String, dynamic>.from(e) : null);
              final profile = PlayerProfile.fromJson(map);
              if (profile == null) continue;
              await txn.insert(
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
          }
        } catch (_) {
          // ignore
        }
      }

      // Results
      final rawResults = prefs.getString(_legacyResultsKey);
      if (rawResults != null && rawResults.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawResults);
          if (decoded is List) {
            for (final e in decoded) {
              final map = e is Map<String, dynamic>
                  ? e
                  : (e is Map ? Map<String, dynamic>.from(e) : null);
              final result = GameResult.fromJson(map);
              if (result == null) continue;
              await txn.insert('game_results', {
                'game_mode_id': result.gameModeId.name,
                'winner_name': result.winnerName,
                'players_json': jsonEncode(result.players),
                'scores_json': jsonEncode(result.scores),
                'played_at_ms': result.playedAt.millisecondsSinceEpoch,
              });
            }
          }
        } catch (_) {
          // ignore
        }
      }
    });
  }
}

