import 'dart:convert';

import 'package:flutter/services.dart';

class ScreensaverPlaylist {
  const ScreensaverPlaylist({
    required this.imageAssets,
    required this.imageInterval,
  });

  final List<String> imageAssets;
  final Duration imageInterval;

  static const defaultInterval = Duration(seconds: 8);

  static Future<ScreensaverPlaylist> loadFromAssets(
    String assetPath,
  ) async {
    final raw = await rootBundle.loadString(assetPath);
    final json = jsonDecode(raw);
    if (json is! Map) {
      return const ScreensaverPlaylist(
        imageAssets: <String>[],
        imageInterval: defaultInterval,
      );
    }

    final imagesRaw = json['images'];
    final images = imagesRaw is List
        ? imagesRaw.whereType<String>().toList(growable: false)
        : const <String>[];

    final intervalSecondsRaw = json['imageIntervalSeconds'];
    final intervalSeconds = intervalSecondsRaw is num
        ? intervalSecondsRaw.toInt()
        : defaultInterval.inSeconds;

    return ScreensaverPlaylist(
      imageAssets: images,
      imageInterval: Duration(
        seconds: intervalSeconds <= 0 ? defaultInterval.inSeconds : intervalSeconds,
      ),
    );
  }
}

