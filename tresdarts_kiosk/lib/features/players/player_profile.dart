import 'package:flutter/foundation.dart';

@immutable
class PlayerProfile {
  const PlayerProfile({
    required this.id,
    required this.name,
    this.entrySong,
    this.photoPath,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? entrySong;
  final String? photoPath;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'entrySong': entrySong,
        'photoPath': photoPath,
        'createdAt': createdAt.toIso8601String(),
      };

  static PlayerProfile? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    final id = json['id'] as String?;
    final name = json['name'] as String?;
    final createdAtStr = json['createdAt'] as String?;
    final createdAt =
        createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;
    if (id == null || name == null || createdAt == null) return null;
    return PlayerProfile(
      id: id,
      name: name,
      entrySong: json['entrySong'] as String?,
      photoPath: json['photoPath'] as String?,
      createdAt: createdAt,
    );
  }
}

