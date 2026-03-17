import 'package:flutter/widgets.dart';

import 'idle_controller.dart';

class IdleListener extends StatelessWidget {
  const IdleListener({
    super.key,
    required this.controller,
    required this.child,
  });

  final IdleController controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => controller.registerActivity(),
      onPointerMove: (_) => controller.registerActivity(),
      onPointerSignal: (_) => controller.registerActivity(),
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  }
}

