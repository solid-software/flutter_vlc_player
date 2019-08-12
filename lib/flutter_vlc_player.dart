import 'dart:async';
import 'dart:typed_data';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:cryptoutils/cryptoutils.dart';
import 'package:flutter/services.dart';

enum PlayingState { STOPPED, BUFFERING, PLAYING }

class Size {
  final int width;
  final int height;

  static const zero = const Size(0, 0);

  const Size(int width, int height) :
      this.width = width,
      this.height = height;
}

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
        onPlatformViewCreated: _onPlatformViewCreated
      );
    } else if (Platform.isAndroid) {
      return AndroidView(
        viewType: "flutter_video_plugin/getVideoView",
        hitTestBehavior: PlatformViewHitTestBehavior.transparent,
        onPlatformViewCreated: _onPlatformViewCreated
      );
    }

    throw new Exception("flutter_vlc_plugin has not been implemented on your platform.");
  }

  void _onPlatformViewCreated(int id) async {
    _controller = widget.controller;
    _controller.registerChannels(id);

    _controller.addListener((){
      // Whenever the initialization state of the player changes,
      // it needs to be updated. As soon as the Flutter part of this library
      // is aware of it, the controller will fire an event, so we're okay
      // to update this here.
      if(playerInitialized != _controller.initialized) setState(() {
        playerInitialized = _controller.initialized;
      });
    });

    // Once the controller has clients registered, we're good to register
    // with LibVLC on the platform side.
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

  VoidCallback _onInit;
  List<VoidCallback> _eventHandlers;

  /// Once the [_methodChannel] and [_eventChannel] have been registered with
  /// the Flutter platform SDK counterparts, [hasClients] is set to true.
  /// At this point, the player is ready to begin playing content.
  bool hasClients = false;

  /// Whether or not the player is initialized.
  /// This is set to true when the player has loaded a URL.
  bool get initialized => _initialized;
  bool _initialized = false;

  /// Returns the current state of the player.
  /// Valid states can be seen on the [PlayingState] enum.
  ///
  /// When the state is [PlayingState.BUFFERING], it means the player is
  /// *not* playing because content needs to be buffered first.
  ///
  /// Essentially, when [playingState] is [PlayingState.BUFFERING] you
  /// should show a loading indicator.
  PlayingState get playingState => _playingState;
  PlayingState _playingState;

  /// The current position of the player, counted in milliseconds since start of
  /// the content. This is as it is returned by LibVLC.
  int _position;
  /// This is a Flutter duration that is returned as an abstraction of
  /// [_position].
  ///
  /// Returns [Duration.zero] when the position is null (i.e. the player
  /// is uninitialized.)
  Duration get position => _position != null
      ? new Duration(milliseconds: _position)
      : Duration.zero;

  /// The total duration of the content, counted in milliseconds. This is as it
  /// is returned by LibVLC.
  int _duration;
  /// This is a Flutter [Duration] that is returned as an abstraction of
  /// [_duration].
  ///
  /// Returns [Duration.zero] when the duration is null (i.e. the player
  /// is uninitialized.)
  Duration get duration => _duration != null
      ? new Duration(milliseconds: _duration)
      : Duration.zero;

  /// This is the size of the content as returned by LibVLC.
  ///
  /// Returns [Size.zero] when the size is null
  /// (i.e. the player is uninitialized.)
  Size get size => _size != null
      ? _size
      : Size.zero;
  Size _size;

  /// This is the aspect ratio of the content as returned by LibVLC.
  /// Not to be confused with the aspect ratio provided to the [VlcPlayer]
  /// widget, which is simply used for an [AspectRatio] wrapper around the
  /// content.
  double _aspectRatio;
  double get aspectRatio => _aspectRatio;

  /// This is the playback speed as returned by LibVLC. Whilst playback speed
  /// can be manipulated through the library, as this is the value actually
  /// returned by the library, it will be the speed that LibVLC is actually
  /// trying to process the content at.
  double _playbackSpeed;
  double get playbackSpeed => _playbackSpeed;

  VlcPlayerController({ VoidCallback onInit }){
    _onInit = onInit;
    _eventHandlers = new List();
  }

  void registerChannels(int id) {
    _methodChannel = MethodChannel("flutter_video_plugin/getVideoView_$id");
    _eventChannel = EventChannel("flutter_video_plugin/getVideoEvents_$id");
    hasClients = true;
  }

  void addListener(VoidCallback listener){
    _eventHandlers.add(listener);
  }

  void removeListener(VoidCallback listener){
    _eventHandlers.remove(listener);
  }

  void clearListeners(){
    _eventHandlers.clear();
  }

  void _fireEventHandlers(){
    _eventHandlers.forEach((handler) => handler());
  }

  Future<void> _initialize(String url) async {
    if(initialized) throw new Exception("Player already initialized!");

    await _methodChannel.invokeMethod("initialize", {
      'url': url
    });
    _position = 0;

    _eventChannel.receiveBroadcastStream().listen((event){
      switch(event['name']){
        case 'playing':
          if(event['width'] != null && event['height'] != null)
            _size = new Size(event['width'], event['height']);
          if(event['length'] != null) _duration = event['length'];
          if(event['ratio'] != null) _aspectRatio = event['ratio'];

          print(event);
          _playingState = event['value']
              ? PlayingState.PLAYING
              : PlayingState.STOPPED;

          _fireEventHandlers();
          break;

        case 'buffering':
          if(event['value']) _playingState = PlayingState.BUFFERING;
          _fireEventHandlers();
          break;

        case 'timeChanged':
          _position = event['value'];
          _playbackSpeed = event['speed'];
          _fireEventHandlers();
          break;
      }
    });

    _initialized = true;
    _fireEventHandlers();
    _onInit();
  }

  Future<void> setStreamUrl(String url) async {
    _initialized = false;
    _fireEventHandlers();

    bool wasPlaying = _playingState != PlayingState.STOPPED;
    await _methodChannel.invokeMethod("changeURL", {
      'url': url
    });
    if(wasPlaying) play();

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

  Future<void> setTime(int time) async {
    await _methodChannel.invokeMethod("setTime", {
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
