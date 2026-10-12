import 'dart:async';

/// Avisa a UI que a sessão não pôde ser renovada (refresh recusado) — o AuthBloc escuta e desloga.
class SessionEvents {
  final _controller = StreamController<void>.broadcast();
  Stream<void> get expired => _controller.stream;
  void notifyExpired() => _controller.add(null);
}
