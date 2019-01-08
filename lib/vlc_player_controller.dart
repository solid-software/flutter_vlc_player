import 'dart:io';
import 'dart:typed_data';
import 'package:cryptoutils/cryptoutils.dart';
import 'package:flutter/services.dart';

class VlcPlayerController {
  MethodChannel _channel;
  bool hasClients = false;

  initView(int id) {
    _channel = MethodChannel("flutter_video_plugin/getVideoView_$id");
    hasClients = true;
  }

  Future<String> setStreamUrl(String url, int defaultHeight, int defaultWidth) async {
    var result = await _channel.invokeMethod("playVideo", {
      'url': url,
    });
    return result['aspectRatio'];
  }

  Future<Uint8List> makeSnapshot() async {
    var result = await _channel.invokeMethod("getSnapshot");
    var base64String = result['snapshot'];
    Uint8List imageBytes = CryptoUtils.base64StringToBytes(base64String);
    return imageBytes;
  }

  void dispose() {
    if (Platform.isIOS){
      _channel.invokeMethod("dispose");
    }
  }

}
