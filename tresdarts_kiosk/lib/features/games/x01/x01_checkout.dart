import '../darts_throw.dart';

/// Returns a valid checkout suggestion for X01, or null if none.
///
/// - Finish must end on a double (D1..D20) or double bull (DB=50).
/// - Bogey numbers (159, 162, 163, 165, 166, 168, 169) return null.
String? suggestX01Checkout(int remaining) {
  if (remaining < 2 || remaining > 170) return null;
  if (const {159, 162, 163, 165, 166, 168, 169}.contains(remaining)) return null;

  final all = allPossibleThrows()
      .where((t) => t.points > 0)
      .toList(growable: false);

  bool isFinisher(DartThrow t) {
    if (t.segment.kind == DartSegmentKind.bull50) return true;
    return t.segment.kind == DartSegmentKind.number && t.multiplier == DartMultiplier.double;
  }

  String label(DartThrow t) {
    return switch (t.segment.kind) {
      DartSegmentKind.bull50 => 'DB',
      DartSegmentKind.bull25 => '25',
      DartSegmentKind.miss => 'MISS',
      DartSegmentKind.number => '${switch (t.multiplier) {
          DartMultiplier.single => 'S',
          DartMultiplier.double => 'D',
          DartMultiplier.triple => 'T',
        }}${t.segment.value}',
    };
  }

  // 1-dart finishes
  for (final a in all) {
    if (!isFinisher(a)) continue;
    if (a.points == remaining) return label(a);
  }

  // 2-dart finishes
  for (final a in all) {
    final left = remaining - a.points;
    if (left <= 0) continue;
    for (final b in all) {
      if (!isFinisher(b)) continue;
      if (b.points == left) return '${label(a)} ${label(b)}';
    }
  }

  // 3-dart finishes
  for (final a in all) {
    final left1 = remaining - a.points;
    if (left1 <= 0) continue;
    for (final b in all) {
      final left2 = left1 - b.points;
      if (left2 <= 0) continue;
      for (final c in all) {
        if (!isFinisher(c)) continue;
        if (c.points == left2) return '${label(a)} ${label(b)} ${label(c)}';
      }
    }
  }

  return null;
}
