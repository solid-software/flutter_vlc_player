import 'dart:io';
import 'dart:typed_data';
import 'package:cryptoutils/cryptoutils.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

typedef StatusChanged<T> = void Function(String status, T value);

class VlcPlayerController {
  MethodChannel _channel;
  EventChannel _eventChannel;

  StatusChanged<dynamic> onStatusChanged;

  bool hasClients = false;

  VlcPlayerController({
    Key key,
    this.onStatusChanged=null
  });

  initView(int id) {
    _channel = MethodChannel("flutter_video_plugin/getVideoView_$id");
    _eventChannel = EventChannel("flutter_video_plugin/event_$id");
    _eventChannel.receiveBroadcastStream().listen((dynamic event)
    {
      if (onStatusChanged!=null){

        String status=event['status'];
        onStatusChanged(status, event['value']);
      }
    }
    );

    hasClients = true;
  }

  Future<String> setStreamUrl(String url, bool isLocal, String subtitle,
      int defaultHeight, int defaultWidth) async {
    var result = await _channel.invokeMethod(
        "playVideo", {'url': url, 'isLocal': isLocal, 'subtitle': subtitle});
    return result['aspectRatio'];
  }

  Future<Uint8List> makeSnapshot() async {
    var result = await _channel.invokeMethod("getSnapshot");
    var base64String = result['snapshot'];
    Uint8List imageBytes = CryptoUtils.base64StringToBytes(base64String);
    return imageBytes;
  }

  Future<void> play() async {
    var result = await _channel.invokeMethod("play");
  }

  Future<void> pause() async {
    var result = await _channel.invokeMethod("pause");
  }

  Future<bool> isPlaying() async {
    var result = await _channel.invokeMethod("isPlaying");
    return result;
  }

  Future<int> getDuration() async {
    var result = await _channel.invokeMethod("getDuration");
    return result;
  }

  Future<int> getPosition() async {
    var result = await _channel.invokeMethod("getPosition");
    return result;
  }

  Future<void> setRate(double rate) async {
    var result = await _channel.invokeMethod("setRate", {
      'rate': rate,
    });
  }

  Future<double> getRate() async {
    var result = await _channel.invokeMethod("getRate");
    return result;
  }

  void dispose() {
    if (Platform.isIOS) {
      _channel.invokeMethod("dispose");
    }
  }
}
