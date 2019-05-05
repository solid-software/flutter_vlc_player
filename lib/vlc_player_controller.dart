import 'dart:async';
import 'dart:typed_data';
import 'package:cryptoutils/cryptoutils.dart';
import 'package:flutter/services.dart';

class VlcPlayerController {

  MethodChannel _methodChannel;
  EventChannel _eventChannel;

  bool hasClients = false;

  List<Function> _eventHandlers;

  bool _initialized = false;
  get initialized => _initialized;

  int _currentTime;
  get currentTime => _currentTime;
  Future<void> setCurrentTime(int newCurrentTime) async {
    _methodChannel.invokeMethod("setCurrentTime", {
      "time": newCurrentTime
    });
  }

  int _totalTime;
  get totalTime => _totalTime;

  int _height;
  get height => _height;
  int _width;
  get width => _width;

  VlcPlayerController(){
    _eventHandlers = new List();
  }

  initView(int id) {
    _methodChannel = MethodChannel("flutter_video_plugin/getVideoView_$id");
    _eventChannel = EventChannel("flutter_video_plugin/getVideoEvents_$id");
    hasClients = true;
  }

  void addListener(Function listener){
    _eventHandlers.add(listener);
  }
  
  void removeListener(Function listener){
    _eventHandlers.remove(listener);
  }

  void clearListeners(){
    _eventHandlers.clear();
  }

  void _fireEventHandlers(){
    for(var handler in _eventHandlers) handler();
  }

  Future<void> initialize(String url) async {
    if(initialized) throw new Exception("Player already initialized!");

    var videoData = await _methodChannel.invokeMethod("initialize", {
      'url': url
    });

    _width = videoData['width'];
    _height = videoData['height'];
    _currentTime = 0;
    _totalTime = videoData['length'];

    _eventChannel.receiveBroadcastStream().listen((event){
      switch(event['name']){
        case 'timeChanged':
          _currentTime = event['value'];
          _fireEventHandlers();
          break;
      }
    });

    _initialized = true;
    _fireEventHandlers();
  }

  Future<void> setStreamUrl(String url) async {
    _initialized = false;
    _fireEventHandlers();

    await _methodChannel.invokeMethod("changeURL", {
      'url': url
    });

    _initialized = true;
    _fireEventHandlers();
  }

  Future<void> play() async {
    await _methodChannel.invokeMethod("setPlaybackState", {
      'playbackState': 'play'
    });
  }

  Future<void> pause() async {
    await _methodChannel.invokeMethod("setPlaybackState", {
      'playbackState': 'pause'
    });
  }

  Future<void> stop() async {
    await _methodChannel.invokeMethod("setPlaybackState", {
      'playbackState': 'stop'
    });
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _methodChannel.invokeMethod("setPlaybackSpeed", {
      'speed': speed.toString()
    });
  }

  Future<double> getPlaybackSpeed() async {
    String playbackSpeedResponse = await _methodChannel.invokeMethod("getPlaybackSpeed");
    return double.parse(playbackSpeedResponse);
  }

  Future<Uint8List> makeSnapshot() async {
    var result = await _methodChannel.invokeMethod("getSnapshot");
    var base64String = result['snapshot'];
    Uint8List imageBytes = CryptoUtils.base64StringToBytes(base64String);
    return imageBytes;
  }

  void dispose() {
    _methodChannel.invokeMethod("dispose");
  }

}
