import 'package:flutter/foundation.dart';

import 'darts_throw.dart';

@immutable
class DartTurn {
  const DartTurn({
    required this.playerIndex,
    required this.throws,
  });

  final int playerIndex;
  final List<DartThrow> throws; // 0..3

  DartTurn copyWith({int? playerIndex, List<DartThrow>? throws}) => DartTurn(
        playerIndex: playerIndex ?? this.playerIndex,
        throws: throws ?? this.throws,
      );
}

@immutable
class TurnTimeline {
  const TurnTimeline({
    required this.playerCount,
    required this.turns,
  });

  final int playerCount;
  final List<DartTurn> turns;

  static TurnTimeline start({required int playerCount}) {
    return TurnTimeline(playerCount: playerCount, turns: const []);
  }

  int get activePlayerIndex {
    if (turns.isEmpty) return 0;
    final last = turns.last;
    if (last.throws.length < 3) return last.playerIndex;
    return (last.playerIndex + 1) % playerCount;
  }

  List<DartThrow> get flatThrows =>
      turns.expand((t) => t.throws).toList(growable: false);

  TurnTimeline addThrow(DartThrow t) {
    final nextTurns = [...turns];
    if (nextTurns.isEmpty) {
      nextTurns.add(DartTurn(playerIndex: 0, throws: [t]));
      return TurnTimeline(playerCount: playerCount, turns: nextTurns);
    }

    final last = nextTurns.last;
    if (last.throws.length < 3) {
      nextTurns[nextTurns.length - 1] =
          last.copyWith(throws: [...last.throws, t]);
      return TurnTimeline(playerCount: playerCount, turns: nextTurns);
    }

    final nextPlayer = (last.playerIndex + 1) % playerCount;
    nextTurns.add(DartTurn(playerIndex: nextPlayer, throws: [t]));
    return TurnTimeline(playerCount: playerCount, turns: nextTurns);
  }

  TurnTimeline replaceThrowAt(int globalThrowIndex, DartThrow t) {
    final map = _mapIndex(globalThrowIndex);
    if (map == null) return this;
    final nextTurns = [...turns];
    final turn = nextTurns[map.turnIndex];
    final nextThrows = [...turn.throws];
    nextThrows[map.throwIndex] = t;
    nextTurns[map.turnIndex] = turn.copyWith(throws: nextThrows);
    return TurnTimeline(playerCount: playerCount, turns: nextTurns);
  }

  TurnTimeline deleteThrowAt(int globalThrowIndex) {
    final map = _mapIndex(globalThrowIndex);
    if (map == null) return this;
    final nextTurns = [...turns];
    final turn = nextTurns[map.turnIndex];
    final nextThrows = [...turn.throws]..removeAt(map.throwIndex);
    if (nextThrows.isEmpty) {
      nextTurns.removeAt(map.turnIndex);
    } else {
      nextTurns[map.turnIndex] = turn.copyWith(throws: nextThrows);
    }
    return TurnTimeline(playerCount: playerCount, turns: nextTurns);
  }

  TurnTimeline undoLastThrow() {
    if (turns.isEmpty) return this;
    final nextTurns = [...turns];
    final last = nextTurns.last;
    final nextThrows = [...last.throws];
    if (nextThrows.isNotEmpty) nextThrows.removeLast();
    if (nextThrows.isEmpty) {
      nextTurns.removeLast();
    } else {
      nextTurns[nextTurns.length - 1] = last.copyWith(throws: nextThrows);
    }
    return TurnTimeline(playerCount: playerCount, turns: nextTurns);
  }

  _IndexMap? _mapIndex(int globalThrowIndex) {
    if (globalThrowIndex < 0) return null;
    var cursor = 0;
    for (var ti = 0; ti < turns.length; ti++) {
      final len = turns[ti].throws.length;
      if (globalThrowIndex < cursor + len) {
        return _IndexMap(turnIndex: ti, throwIndex: globalThrowIndex - cursor);
      }
      cursor += len;
    }
    return null;
  }
}

class _IndexMap {
  const _IndexMap({required this.turnIndex, required this.throwIndex});
  final int turnIndex;
  final int throwIndex;
}

