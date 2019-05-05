import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:cryptoutils/cryptoutils.dart';
import 'package:flutter/services.dart';

class VlcPlayer extends StatefulWidget {
  final double aspectRatio;
  final String url;
  final Widget placeholder;
  final VlcPlayerController controller;

  const VlcPlayer({
    Key key,
    @required this.controller,
    @required this.aspectRatio,
    @required this.url,
    this.placeholder,
  });

  @override
  _VlcPlayerState createState() => _VlcPlayerState();
}

class _VlcPlayerState extends State<VlcPlayer> {
  VlcPlayerController _controller;
  int videoRenderId;
  bool playerInitialized = false;


  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Stack(
        children: <Widget>[
          Offstage(offstage: playerInitialized, child: widget.placeholder ?? Container()),
          Offstage(
            offstage: !playerInitialized,
            child: _createPlatformView(),
          ),
        ],
      ),
    );
  }

  Widget _createPlatformView() {
    if (Platform.isIOS) {
      return UiKitView(
          viewType: "flutter_video_plugin/getVideoView",
          onPlatformViewCreated: _onPlatformViewCreated);
    } else if (Platform.isAndroid) {
      return AndroidView(
          viewType: "flutter_video_plugin/getVideoView",
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          onPlatformViewCreated: _onPlatformViewCreated);
    }
    return Container();
  }

  void _onPlatformViewCreated(int id) async {
    _controller = widget.controller;
    _controller.initView(id);

    _controller.addListener((){
      if(playerInitialized != _controller.initialized){
        setState(() {
          playerInitialized = _controller.initialized;
        });
      }
    });

    if (_controller.hasClients) {
      await _controller._initialize(widget.url);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class VlcPlayerController {

  MethodChannel _methodChannel;
  EventChannel _eventChannel;

  bool hasClients = false;

  List<Function> _eventHandlers;

  bool _initialized = false;
  bool get initialized => _initialized;

  bool _playing = false;
  bool get playing => _playing;

  bool _buffering = false;
  bool get buffering => _buffering;

  int _currentTime;
  int get currentTime => _currentTime;

  int _totalTime;
  int get totalTime => _totalTime;

  int _height;
  int get height => _height;
  int _width;
  int get width => _width;

  double _aspectRatio;
  double get aspectRatio => _aspectRatio;

  double _playbackSpeed;
  double get playbackSpeed => _playbackSpeed;

  Function _onInit;

  VlcPlayerController({ Function onInit }){
    _onInit = onInit;
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

  Future<void> _initialize(String url) async {
    if(initialized) throw new Exception("Player already initialized!");

    await _methodChannel.invokeMethod("initialize", {
      'url': url
    });
    _currentTime = 0;

    _eventChannel.receiveBroadcastStream().listen((event){
      switch(event['name']){
        case 'playing':
          if(event['width'] != null) _width = event['width'];
          if(event['height'] != null) _height = event['height'];
          if(event['length'] != null) _totalTime = event['length'];
          if(event['ratio'] != null) _aspectRatio = event['ratio'];
          _playing = event['value'];

          _fireEventHandlers();
          break;
        case 'buffering':
          _buffering = event['value'];
          _fireEventHandlers();
          break;
        case 'timeChanged':
          _currentTime = event['value'];
          _playbackSpeed = event['speed'];
          _fireEventHandlers();
          break;
      }
    });

    _initialized = true;
    _onInit();
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

  Future<void> seek(num time) async {
    await _methodChannel.invokeMethod("seek", {
      'time': time.toString()
    });
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _methodChannel.invokeMethod("setPlaybackSpeed", {
      'speed': speed.toString()
    });
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
