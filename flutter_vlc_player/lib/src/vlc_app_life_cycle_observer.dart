import 'package:flutter/widgets.dart';
import 'package:flutter_vlc_player/src/vlc_player_controller.dart';

class VlcAppLifeCycleObserver extends Object with WidgetsBindingObserver {
  bool _wasPlayingBeforePause = false;
  final VlcPlayerController _controller;

  VlcAppLifeCycleObserver(this._controller);

  void initialize() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.paused:
        _wasPlayingBeforePause = _controller.value.isPlaying;
        _controller.pause();
      case AppLifecycleState.resumed:
        if (_wasPlayingBeforePause) {
          _controller.play();
        }
      default:
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
  }
}
