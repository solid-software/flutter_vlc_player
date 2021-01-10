// import 'dart:async';
// import 'dart:io';
// import 'dart:typed_data';
//
// import 'package:cryptoutils/cryptoutils.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
// import 'package:flutter/services.dart';
//
// enum PlayingState { STOPPED, PAUSED, BUFFERING, PLAYING, ERROR }
// enum HwAcc { AUTO, DISABLED, DECODING, FULL }
// enum CastStatus { DEVICE_ADDED, DEVICE_DELETED }
//
// typedef CastCallback = void Function(CastStatus, String, String);
//
// int getHwAcc({@required HwAcc hwAcc}) {
//   switch (hwAcc) {
//     case HwAcc.DISABLED:
//       return 0;
//     case HwAcc.DECODING:
//       return 1;
//     case HwAcc.FULL:
//       return 2;
//     case HwAcc.AUTO:
//     default:
//       return -1;
//   }
// }
//
// class VlcMediaSize {
//   final int width;
//   final int height;
//
//   static const zero = const VlcMediaSize(0, 0);
//
//   const VlcMediaSize(int width, int height)
//       : this.width = width,
//         this.height = height;
// }
//
// class VlcPlayer extends StatefulWidget {
//   final double aspectRatio;
//   final HwAcc hwAcc;
//   final List<String> options;
//   final bool autoplay;
//   final String url;
//   final bool isLocalMedia;
//   final String subtitle;
//   final bool isLocalSubtitle;
//   final bool isSubtitleSelected;
//   final bool loop;
//   final Widget placeholder;
//   final VlcPlayerController controller;
//
//   const VlcPlayer({
//     Key key,
//
//     /// The [VlcPlayerController] that handles interaction with the platform code.
//     @required this.controller,
//
//     /// The aspect ratio used to display the video.
//     /// This MUST be provided, however it could simply be (parentWidth / parentHeight) - where parentWidth and
//     /// parentHeight are the width and height of the parent perhaps as defined by a LayoutBuilder.
//     @required this.aspectRatio,
//
//     /// This is the initial URL for the content. This also must be provided but [VlcPlayerController] implements
//     /// [VlcPlayerController.setStreamUrl] method so this can be changed at any time.
//     @required this.url,
//
//     /// Set hardware acceleration for player. Default is Automatic.
//     this.hwAcc,
//
//     /// Adds options to vlc. For more [https://wiki.videolan.org/VLC_command-line_help] If nothing is provided,
//     /// vlc will run without any options set.
//     this.options,
//
//     /// Set true if the provided url is local file
//     this.isLocalMedia,
//
//     /// The video should be played automatically.
//     this.autoplay,
//
//     /// Set the external subtitle to load with video
//     this.subtitle,
//
//     /// Set true if the provided subtitle is local file
//     this.isLocalSubtitle,
//
//     /// Set true if the provided subtitle is selected by default
//     this.isSubtitleSelected,
//
//     /// Loop the playback forever
//     this.loop,
//
//     /// Before the platform view has initialized, this placeholder will be rendered instead of the video player.
//     /// This can simply be a [CircularProgressIndicator] (see the example.)
//     this.placeholder,
//   });
//
//   @override
//   _VlcPlayerState createState() => _VlcPlayerState();
// }
//
// class _VlcPlayerState extends State<VlcPlayer>
//     with AutomaticKeepAliveClientMixin {
//   VlcPlayerController _controller;
//   int videoRenderId;
//   bool playerInitialized = false;
//
//   @override
//   bool get wantKeepAlive => true;
//
//   @override
//   void initState() {
//     super.initState();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     return AspectRatio(
//       aspectRatio: widget.aspectRatio,
//       child: Stack(
//         children: <Widget>[
//           Offstage(
//               offstage: playerInitialized,
//               child: widget.placeholder ?? Container()),
//           Offstage(
//             offstage: !playerInitialized,
//             child: _createPlatformView(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _createPlatformView() {
//     if (Platform.isIOS) {
//       return UiKitView(
//           viewType: "flutter_video_plugin/getVideoView",
//           hitTestBehavior: PlatformViewHitTestBehavior.transparent,
//           onPlatformViewCreated: _onPlatformViewCreated);
//     } else if (Platform.isAndroid) {
//       return AndroidView(
//           viewType: "flutter_video_plugin/getVideoView",
//           hitTestBehavior: PlatformViewHitTestBehavior.transparent,
//           onPlatformViewCreated: _onPlatformViewCreated);
//     }
//
//     throw new Exception(
//         "flutter_vlc_plugin has not been implemented on your platform.");
//   }
//
//   void _onPlatformViewCreated(int id) async {
//     _controller = widget.controller;
//     _controller.registerChannels(id);
//
//     _controller.addListener(() {
//       if (!mounted) return;
//
//       // Whenever the initialization state of the player changes,
//       // it needs to be updated. As soon as the Flutter part of this library
//       // is aware of it, the controller will fire an event, so we're okay
//       // to update this here.
//       if (playerInitialized != _controller.initialized)
//         setState(() {
//           playerInitialized = _controller.initialized;
//         });
//     });
//
//     // Once the controller has clients registered, we're good to register
//     // with LibVLC on the platform side.
//     if (_controller.hasClients) {
//       await _controller._initialize(
//         url: widget.url,
//         hwAcc: widget.hwAcc,
//         options: widget.options,
//         autoplay: widget.autoplay,
//         isLocalMedia: widget.isLocalMedia,
//         subtitle: widget.subtitle,
//         isLocalSubtitle: widget.isLocalSubtitle,
//         loop: widget.loop,
//       );
//     }
//   }
//
//   @override
//   void deactivate() {
//     _controller.dispose();
//     playerInitialized = false;
//     super.deactivate();
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
// }
//
// class VlcPlayerController {
//   MethodChannel _methodChannel;
//   EventChannel _eventChannel;
//
//   VoidCallback _onInit;
//   CastCallback _onCastHandler;
//   List<VoidCallback> _eventHandlers;
//
//   /// Once the [_methodChannel] and [_eventChannel] have been registered with
//   /// the Flutter platform SDK counterparts, [hasClients] is set to true.
//   /// At this point, the player is ready to begin playing content.
//   bool hasClients = false;
//
//   /// Whether or not the player is initialized.
//   /// This is set to true when the player has loaded a URL.
//   bool get initialized => _initialized;
//   bool _initialized = false;
//
//   /// Returns the current state of the player.
//   /// Valid states can be seen on the [PlayingState] enum.
//   ///
//   /// When the state is [PlayingState.BUFFERING], it means the player is
//   /// *not* playing because content needs to be buffered first.
//   ///
//   /// Essentially, when [playingState] is [PlayingState.BUFFERING] you
//   /// should show a loading indicator.
//   PlayingState get playingState => _playingState;
//   PlayingState _playingState;
//
//   /// The current position of the player, counted in milliseconds since start of
//   /// the content. This is as it is returned by LibVLC.
//   int _position;
//
//   /// This is a Flutter duration that is returned as an abstraction of
//   /// [_position].
//   ///
//   /// Returns [Duration.zero] when the position is null (i.e. the player
//   /// is uninitialized.)
//   Duration get position =>
//       _position != null ? new Duration(milliseconds: _position) : Duration.zero;
//
//   /// The total duration of the content, counted in milliseconds. This is as it
//   /// is returned by LibVLC.
//   int _duration;
//
//   /// This is a Flutter [Duration] that is returned as an abstraction of
//   /// [_duration].
//   ///
//   /// Returns [Duration.zero] when the duration is null (i.e. the player
//   /// is uninitialized.)
//   Duration get duration =>
//       _duration != null ? new Duration(milliseconds: _duration) : Duration.zero;
//
//   /// This is the dimensions of the content (height and width) as returned by LibVLC.
//   ///
//   /// Returns [VlcMediaSize.zero] when the size is null
//   /// (i.e. the player is uninitialized.)
//   VlcMediaSize get size => _size != null ? _size : VlcMediaSize.zero;
//   VlcMediaSize _size;
//
//   /// This is the aspect ratio of the content as returned by LibVLC.
//   /// Not to be confused with the aspect ratio provided to the [VlcPlayer]
//   /// widget, which is simply used for an [AspectRatio] wrapper around the
//   /// content.
//   double _aspectRatio;
//
//   double get aspectRatio => _aspectRatio;
//
//   /// This is the playback speed as returned by LibVLC. Whilst playback speed
//   /// can be manipulated through the library, as this is the value actually
//   /// returned by the library, it will be the speed that LibVLC is actually
//   /// trying to process the content at.
//   double _playbackSpeed;
//
//   double get playbackSpeed => _playbackSpeed;
//
//   /// Returns the number of available audio tracks embedded in media except the original audio.
//   int _audioTracksCount = 1;
//
//   int get audioTracksCount => _audioTracksCount - 1;
//
//   /// Returns the active audio track index. "-1" means audio is disabled.
//   int _activeAudioTrack = 1;
//
//   int get activeAudioTrack => _activeAudioTrack;
//
//   /// Returns the number of available subtitle tracks embedded in media.
//   int _spuTracksCount = 0;
//
//   int get spuTracksCount => _spuTracksCount;
//
//   /// Returns the active subtitle track index. "-1" means subtitle is disabled.
//   int _activeSpuTrack = 0;
//
//   int get activeSpuTrack => _activeSpuTrack;
//
//   VlcPlayerController({
//     /// This is a callback that will be executed once the platform view has been initialized.
//     /// If you want the media to play as soon as the platform view has initialized, you could just call
//     /// [VlcPlayerController.play] in this callback. (see the example)
//     VoidCallback onInit,
//
//     /// This is a callback that will be executed every time a new cast device detected/removed
//     /// It should be defined as "void Function(CastStatus, String, String)", where the CastStatus is an enum { DEVICE_ADDED, DEVICE_DELETED } and the next two String arguments are name and displayName of cast device, respectively.
//     CastCallback onCastHandler,
//   }) {
//     _onInit = onInit;
//     _onCastHandler = onCastHandler;
//     _eventHandlers = new List();
//   }
//
//   void registerChannels(int id) {
//     _methodChannel = MethodChannel("flutter_video_plugin/getVideoView_$id");
//     _eventChannel = EventChannel("flutter_video_plugin/getVideoEvents_$id");
//     hasClients = true;
//   }
//
//   void addListener(VoidCallback listener) {
//     _eventHandlers.add(listener);
//   }
//
//   void removeListener(VoidCallback listener) {
//     _eventHandlers.remove(listener);
//   }
//
//   void clearListeners() {
//     _eventHandlers.clear();
//   }
//
//   void _fireEventHandlers() {
//     _eventHandlers.forEach((handler) => handler());
//   }
//
//   Future<void> _initialize({
//     @required String url,
//     HwAcc hwAcc,
//     List<String> options,
//     bool autoplay,
//     bool isLocalMedia,
//     String subtitle,
//     bool isLocalSubtitle,
//     bool isSubtitleSelected,
//     bool loop,
//   }) async {
//     //if(initialized) throw new Exception("Player already initialized!");
//
//     await _methodChannel.invokeMethod("initialize", {
//       'url': url,
//       'hwAcc': getHwAcc(hwAcc: hwAcc),
//       'options': options ?? [],
//       'autoplay': autoplay ?? true,
//       'isLocalMedia': isLocalMedia ?? false,
//       'subtitle': subtitle ?? '',
//       'isLocalSubtitle': isLocalSubtitle ?? false,
//       'isSubtitleSelected': isSubtitleSelected ?? true,
//       'loop': loop ?? false,
//     });
//     _position = 0;
//
//     _eventChannel.receiveBroadcastStream().listen((event) {
//       switch (event['name']) {
//         case 'playing':
//           if (event['width'] != null && event['height'] != null)
//             _size = new VlcMediaSize(event['width'], event['height']);
//           if (event['length'] != null) _duration = event['length'];
//           if (event['ratio'] != null) _aspectRatio = event['ratio'];
//           if (event['audioTracksCount'] != null)
//             _audioTracksCount = event['audioTracksCount'];
//           if (event['activeAudioTrack'] != null)
//             _activeAudioTrack = event['activeAudioTrack'];
//           if (event['spuTracksCount'] != null)
//             _spuTracksCount = event['spuTracksCount'];
//           if (event['activeSpuTrack'] != null)
//             _activeSpuTrack = event['activeSpuTrack'];
//
//           _playingState =
//               event['value'] ? PlayingState.PLAYING : PlayingState.STOPPED;
//
//           _fireEventHandlers();
//           break;
//
//         case 'buffering':
//           if (event['value']) _playingState = PlayingState.BUFFERING;
//           _fireEventHandlers();
//           break;
//
//         case 'paused':
//           _playingState = PlayingState.PAUSED;
//           _fireEventHandlers();
//           break;
//
//         case 'stopped':
//           _playingState = PlayingState.STOPPED;
//           _fireEventHandlers();
//           break;
//
//         case 'timeChanged':
//           _position = event['value'];
//           _playbackSpeed = event['speed'];
//           _fireEventHandlers();
//           break;
//
//         case 'castItemAdded':
//           if (_onCastHandler != null)
//             _onCastHandler(
//                 CastStatus.DEVICE_ADDED, event['value'], event['displayName']);
//           break;
//
//         case 'castItemDeleted':
//           if (_onCastHandler != null)
//             _onCastHandler(CastStatus.DEVICE_DELETED, event['value'],
//                 event['displayName']);
//           break;
//       }
//     }).onError((e) {
//       _playingState = PlayingState.ERROR;
//       _fireEventHandlers();
//     });
//
//     _initialized = true;
//     _fireEventHandlers();
//     _onInit();
//   }
//
//   /// This stops playback and changes the URL. Once the new URL has been loaded, the playback state will revert to
//   /// its state before the method was called. (i.e. if setStreamUrl is called whilst media is playing, once the new
//   /// URL has been loaded, the new stream will begin playing.)
//   /// [url] - the URL of the stream to start playing.
//   /// [isLocalMedia] - Set true if the media url is on local storage.
//   /// [subtitle] - Set subtitle url if you wanna add subtitle on media loading.
//   /// [isLocalSubtitle] - Set true if subtitle is on local storage
//   /// [isSubtitleSelected] - Set true if you wanna force the added subtitle to start display on media.
//   Future<void> setStreamUrl(String url,
//       {bool isLocalMedia,
//       String subtitle,
//       bool isLocalSubtitle,
//       bool isSubtitleSelected}) async {
//     _initialized = false;
//     _fireEventHandlers();
//
//     bool wasPlaying = (_playingState == PlayingState.PLAYING);
//     await _methodChannel.invokeMethod("changeURL", {
//       'url': url,
//       'isLocalMedia': isLocalMedia ?? false,
//       'subtitle': subtitle ?? '',
//       'isLocalSubtitle': isLocalSubtitle ?? false,
//       'isSubtitleSelected': isSubtitleSelected ?? true,
//     });
//     if (wasPlaying) play();
//
//     _initialized = true;
//     _fireEventHandlers();
//   }
//
//   /// Start playing media.
//   Future<void> play() async {
//     await _methodChannel.invokeMethod("setPlaybackState", {
//       'playbackState': 'play',
//     });
//   }
//
//   /// Pause media player.
//   Future<void> pause() async {
//     await _methodChannel.invokeMethod("setPlaybackState", {
//       'playbackState': 'pause',
//     });
//   }
//
//   /// Stop media player.
//   Future<void> stop() async {
//     await _methodChannel.invokeMethod("setPlaybackState", {
//       'playbackState': 'stop',
//     });
//   }
//
//   /// Returns true if media is playing.
//   Future<bool> isPlaying() async {
//     var result = await _methodChannel.invokeMethod("isPlaying");
//     return result;
//   }
//
//   /// [time] - time in milliseconds to jump to.
//   Future<void> setTime(int time) async {
//     await _methodChannel.invokeMethod("setTime", {
//       'time': time.toString(),
//     });
//   }
//
//   /// Returns current media seek time in milliseconds.
//   Future<int> getTime() async {
//     var result = await _methodChannel.invokeMethod("getTime");
//     return result;
//   }
//
//   /// Returns duration/length of loaded video in milliseconds.
//   Future<int> getDuration() async {
//     var result = await _methodChannel.invokeMethod("getDuration");
//     return result;
//   }
//
//   /// [volume] - Set vlc volume level which should be in range [0-100].
//   Future<void> setVolume(int volume) async {
//     await _methodChannel.invokeMethod("setVolume", {
//       'volume': volume,
//     });
//   }
//
//   /// Returns current vlc volume level.
//   Future<int> getVolume() async {
//     var result = await _methodChannel.invokeMethod("getVolume");
//     return result;
//   }
//
//   /// [speed] - the rate at which VLC should play media.
//   /// For reference:
//   /// 2.0 is double speed.
//   /// 1.0 is normal speed.
//   /// 0.5 is half speed.
//   Future<void> setPlaybackSpeed(double speed) async {
//     await _methodChannel.invokeMethod("setPlaybackSpeed", {
//       'speed': speed.toString(),
//     });
//   }
//
//   /// Returns the vlc playback speed.
//   Future<double> getPlaybackSpeed() async {
//     var result = await _methodChannel.invokeMethod("getPlaybackSpeed");
//     return result;
//   }
//
//   /// Return the number of subtitle tracks (both embedded and inserted)
//   Future<int> getSpuTracksCount() async {
//     var result = await _methodChannel.invokeMethod("getSpuTracksCount");
//     return result;
//   }
//
//   /// Return all subtitle tracks as array of <Int, String>
//   /// The key parameter is the index of subtitle which is used for changing subtitle and the value is the display name of subtitle
//   Future<Map<dynamic, dynamic>> getSpuTracks() async {
//     Map<dynamic, dynamic> list =
//         await _methodChannel.invokeMethod("getSpuTracks", {
//       'getSpuTracks': 'getSpuTracks',
//     });
//     return list;
//   }
//
//   /// Change active subtitle index (set -1 to disable subtitle).
//   /// [spuTrackNumber] - the subtitle index obtained from getSpuTracks()
//   Future<void> setSpuTrack(int spuTrackNumber) async {
//     await _methodChannel.invokeMethod("setSpuTrack", {
//       'spuTrackNumber': spuTrackNumber,
//     });
//   }
//
//   /// Returns selected spu track index
//   Future<int> getSpuTrack() async {
//     var result = await _methodChannel.invokeMethod("getSpuTrack");
//     return result;
//   }
//
//   /// [delay] - the amount of time in milliseconds which vlc subtitle should be delayed. (both positive & negative value appliable)
//   Future<void> setSpuDelay(int delay) async {
//     await _methodChannel.invokeMethod("setSpuDelay", {
//       'delay': delay.toString(),
//     });
//   }
//
//   /// Returns the amount of subtitle time delay.
//   Future<int> getSpuDelay() async {
//     var result = await _methodChannel.invokeMethod("getSpuDelay");
//     return result;
//   }
//
//   /// Add extra subtitle to media.
//   /// [subtitlePath] - URL of subtitle
//   /// [isLocalSubtitle] - Set true if subtitle is on local storage
//   /// [isSubtitleSelected] - Set true if you wanna force the added subtitle to start display on media.
//   Future<void> addSubtitleTrack(String subtitlePath,
//       {bool isLocalSubtitle, bool isSubtitleSelected}) async {
//     await _methodChannel.invokeMethod("addSubtitleTrack", {
//       'subtitlePath': subtitlePath,
//       'isLocalSubtitle': isLocalSubtitle ?? false,
//       'isSubtitleSelected': isSubtitleSelected ?? true,
//     });
//   }
//
//   /// Returns the number of audio tracks
//   Future<int> getAudioTracksCount() async {
//     var result = await _methodChannel.invokeMethod(
//         "getAudioTracksCount", {'getAudioTracksCount': 'getAudioTracksCount'});
//     return result;
//   }
//
//   /// Returns all audio tracks as array of <Int, String>
//   /// The key parameter is the index of audio track which is used for changing audio and the value is the display name of audio
//   Future<Map<dynamic, dynamic>> getAudioTracks() async {
//     Map<dynamic, dynamic> list = await _methodChannel
//         .invokeMethod("getAudioTracks", {'getAudioTracks': 'getAudiotracks'});
//     return list;
//   }
//
//   /// Returns selected audio track index
//   Future<int> getAudioTrack() async {
//     var result = await _methodChannel.invokeMethod("getAudioTrack");
//     return result;
//   }
//
//   /// Change active audio track index (set -1 to mute).
//   /// [audioTrackNumber] - the audio track index obtained from getAudioTracks()
//   Future<void> setAudioTrack(int audioTrackNumber) async {
//     await _methodChannel.invokeMethod("setAudioTrack", {
//       'audioTrackNumber': audioTrackNumber,
//     });
//   }
//
//   /// [delay] - the amount of time in milliseconds which vlc audio should be delayed. (both positive & negative value appliable)
//   Future<void> setAudioDelay(int delay) async {
//     await _methodChannel.invokeMethod("setAudioDelay", {
//       'delay': delay.toString(),
//     });
//   }
//
//   /// Returns the amount of audio track time delay.
//   Future<int> getAudioDelay() async {
//     var result = await _methodChannel.invokeMethod("getAudioDelay");
//     return result;
//   }
//
//   /// Returns the number of video tracks
//   Future<int> getVideoTracksCount() async {
//     var result = await _methodChannel.invokeMethod("getVideoTracksCount");
//     return result;
//   }
//
//   /// Returns all video tracks as array of <Int, String>
//   /// The key parameter is the index of video track and the value is the display name of video track
//   Future<Map<dynamic, dynamic>> getVideoTracks() async {
//     Map<dynamic, dynamic> list =
//         await _methodChannel.invokeMethod("getVideoTracks");
//     return list;
//   }
//
//   /// Returns an object which contains information about current video track
//   Future<dynamic> getCurrentVideoTrack() async {
//     return await _methodChannel.invokeMethod("getCurrentVideoTrack");
//   }
//
//   /// Returns selected video track index
//   Future<int> getVideoTrack() async {
//     return await _methodChannel.invokeMethod("getVideoTrack");
//   }
//
//   /// [scale] - the video scale value
//   /// Set video scale
//   Future<void> setVideoScale(double scale) async {
//     await _methodChannel.invokeMethod("setVideoScale", {
//       'scale': scale.toString(),
//     });
//   }
//
//   /// Returns video scale
//   Future<double> getVideoScale() async {
//     var result = await _methodChannel.invokeMethod("getVideoScale");
//     return result;
//   }
//
//   /// [aspect] - the video apect ratio like "16:9"
//   /// Set video aspect ratio
//   Future<void> setVideoAspectRatio(String aspect) async {
//     await _methodChannel.invokeMethod("setVideoAspectRatio", {
//       'aspect': aspect,
//     });
//   }
//
//   /// Returns video aspect ratio
//   Future<String> getVideoAspectRatio() async {
//     var result = await _methodChannel.invokeMethod("getVideoAspectRatio");
//     return result;
//   }
//
//   /// Returns binary data for a snapshot of the media at the current frame.
//   Future<Uint8List> takeSnapshot() async {
//     var result =
//         await _methodChannel.invokeMethod("getSnapshot", {'getSnapShot': ''});
//     var base64String = result['snapshot'];
//     Uint8List imageBytes = CryptoUtils.base64StringToBytes(base64String);
//     return imageBytes;
//   }
//
//   /// Start vlc cast discovery to find external display devices (chromecast)
//   Future<void> startCastDiscovery() async {
//     await _methodChannel.invokeMethod(
//         "startCastDiscovery", {"startCastDiscovery": "startCastDiscovery"});
//   }
//
//   /// Stop vlc cast and cast discovery
//   Future<void> stopCastDiscovery() async {
//     await _methodChannel.invokeMethod(
//         "stopCastDiscovery", {"stopCastDiscovery": "stopCastDiscovery"});
//   }
//
//   /// Returns all detected cast devices as array of <String, String>
//   /// The key parameter is the name of cast device and the value is the display name of cast device
//   Future<Map<dynamic, dynamic>> getCastDevices() async {
//     Map<dynamic, dynamic> list = await _methodChannel
//         .invokeMethod("getCastDevices", {"getCastDevices": "getCastDevices"});
//     return list;
//   }
//
//   /// [castDevice] - name of cast device
//   /// Start vlc video casting to the selected device. Set null if you wanna to stop video casting.
//   Future<void> startCasting(String castDevice) async {
//     await _methodChannel.invokeMethod("startCasting", {
//       'startCasting': castDevice,
//     });
//   }
//
//   /// Disposes the platform view and unloads the VLC player.
//   Future<void> dispose() async {
//     await _methodChannel.invokeMethod("dispose");
//   }
// }
