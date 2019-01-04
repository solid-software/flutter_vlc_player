import 'dart:async';

import 'package:flutter/services.dart';

class FlutterVlcPlayer {
  static const MethodChannel _channel =
  const MethodChannel('flutter_vlc_player');

  static MethodChannel get methodChannel => _channel;

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }
}
