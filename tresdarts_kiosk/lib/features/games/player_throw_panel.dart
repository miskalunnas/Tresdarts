import 'package:flutter/material.dart';

import 'darts_throw.dart';
import 'turn_timeline.dart';

PointsAndDarts computePointsAndDartsByPlayer(TurnTimeline timeline) {
  final points = <int, int>{};
  final darts = <int, int>{};
  for (final turn in timeline.turns) {
    darts[turn.playerIndex] = (darts[turn.playerIndex] ?? 0) + turn.throws.length;
    points[turn.playerIndex] = (points[turn.playerIndex] ?? 0) +
        turn.throws.fold<int>(0, (sum, t) => sum + t.points);
  }
  return PointsAndDarts(points: points, darts: darts);
}

class PointsAndDarts {
  const PointsAndDarts({required this.points, required this.darts});
  final Map<int, int> points;
  final Map<int, int> darts;
}

class PlayerThrowPanel extends StatelessWidget {
  const PlayerThrowPanel({
    super.key,
    required this.timeline,
    required this.activePlayerIndex,
    required this.playerName,
  });

  final TurnTimeline timeline;
  final int activePlayerIndex;
  final String playerName;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final throws = <DartThrow>[];
    for (final turn in timeline.turns.reversed) {
      if (turn.playerIndex != activePlayerIndex) continue;
      for (final t in turn.throws.reversed) {
        throws.add(t);
        if (throws.length >= 9) break;
      }
      if (throws.length >= 9) break;
    }

    final allPoints = _pointsForPlayer(timeline, activePlayerIndex);
    final allDarts = _dartsForPlayer(timeline, activePlayerIndex);
    final avg3 = allDarts > 0 ? (allPoints / allDarts) * 3.0 : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                playerName,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
              ),
              const Spacer(),
              Text(
                'AVG (3): ${avg3.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (throws.isEmpty)
            Text(
              'Ei heittoja vielä.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in throws)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outline),
                    ),
                    child: Text(
                      '${t.label} (${t.points})',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  int _pointsForPlayer(TurnTimeline tl, int playerIndex) {
    var sum = 0;
    for (final turn in tl.turns) {
      if (turn.playerIndex != playerIndex) continue;
      for (final t in turn.throws) {
        sum += t.points;
      }
    }
    return sum;
  }

  int _dartsForPlayer(TurnTimeline tl, int playerIndex) {
    var count = 0;
    for (final turn in tl.turns) {
      if (turn.playerIndex != playerIndex) continue;
      count += turn.throws.length;
    }
    return count;
  }
}

