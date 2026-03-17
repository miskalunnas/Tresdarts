import 'package:flutter/foundation.dart';

enum DartMultiplier {
  single(1),
  double(2),
  triple(3);

  const DartMultiplier(this.value);
  final int value;
}

@immutable
class DartSegment {
  const DartSegment._(this.kind, this.value);

  final DartSegmentKind kind;
  final int? value; // 1-20 for numbered segments

  static const miss = DartSegment._(DartSegmentKind.miss, null);
  static const bull25 = DartSegment._(DartSegmentKind.bull25, null);
  static const bull50 = DartSegment._(DartSegmentKind.bull50, null);

  static DartSegment numbered(int n) {
    assert(n >= 1 && n <= 20);
    return DartSegment._(DartSegmentKind.number, n);
  }
}

enum DartSegmentKind { number, bull25, bull50, miss }

@immutable
class DartThrow {
  const DartThrow({
    required this.segment,
    required this.multiplier,
  });

  final DartSegment segment;
  final DartMultiplier multiplier;

  int get points => switch (segment.kind) {
        DartSegmentKind.miss => 0,
        DartSegmentKind.bull25 => 25,
        DartSegmentKind.bull50 => 50,
        DartSegmentKind.number => (segment.value ?? 0) * multiplier.value,
      };

  String get label {
    return switch (segment.kind) {
      DartSegmentKind.miss => 'MISS',
      DartSegmentKind.bull25 => 'BULL 25',
      DartSegmentKind.bull50 => 'BULL 50',
      DartSegmentKind.number => '${_m(multiplier)}${segment.value}',
    };
  }

  static String _m(DartMultiplier m) => switch (m) {
        DartMultiplier.single => 'S',
        DartMultiplier.double => 'D',
        DartMultiplier.triple => 'T',
      };
}

List<DartThrow> allPossibleThrows() {
  final throws = <DartThrow>[
    const DartThrow(segment: DartSegment.miss, multiplier: DartMultiplier.single),
    const DartThrow(segment: DartSegment.bull25, multiplier: DartMultiplier.single),
    const DartThrow(segment: DartSegment.bull50, multiplier: DartMultiplier.single),
  ];
  for (var n = 1; n <= 20; n++) {
    throws.add(DartThrow(segment: DartSegment.numbered(n), multiplier: DartMultiplier.single));
    throws.add(DartThrow(segment: DartSegment.numbered(n), multiplier: DartMultiplier.double));
    throws.add(DartThrow(segment: DartSegment.numbered(n), multiplier: DartMultiplier.triple));
  }
  return throws;
}

