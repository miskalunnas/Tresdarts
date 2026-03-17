import 'dart:async';

class IdleController {
  IdleController({
    required this.timeout,
    required this.onTimeout,
  });

  final Duration timeout;
  final void Function() onTimeout;

  Timer? _timer;

  void start() {
    _reset();
  }

  void registerActivity() {
    _reset();
  }

  void _reset() {
    _timer?.cancel();
    _timer = Timer(timeout, onTimeout);
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}

