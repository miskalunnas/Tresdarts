import 'dart:async';

import 'darts_throw.dart';

/// External event source adapter for automatic dart hits.
/// Later: implement WebSocket/serial/native plugin.
abstract class DartThrowSource {
  Stream<DartThrow> get stream;
  Future<void> dispose();
}

class NoopDartThrowSource implements DartThrowSource {
  const NoopDartThrowSource();

  @override
  Stream<DartThrow> get stream => const Stream.empty();

  @override
  Future<void> dispose() async {}
}

class StreamDartThrowSource implements DartThrowSource {
  StreamDartThrowSource(this._stream);
  final Stream<DartThrow> _stream;

  @override
  Stream<DartThrow> get stream => _stream;

  @override
  Future<void> dispose() async {}
}

