import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_vlc_player_platform_interface/flutter_vlc_player_platform_interface.dart';
import 'package:flutter_vlc_player_platform_interface/src/messages/messages.dart';

/// An implementation of [VlcPlayerPlatform] that uses method channels.
class MethodChannelVlcPlayer extends VlcPlayerPlatform {
  final _api = VlcPlayerApi();

  EventChannel _mediaEventChannelFor(int viewId) {
    return EventChannel('flutter_video_plugin/getVideoEvents_$viewId');
  }

  EventChannel _rendererEventChannelFor(int viewId) {
    return EventChannel('flutter_video_plugin/getRendererEvents_$viewId');
  }

  @override
  Future<void> init() async {
    return _api.initialize();
  }

  @override
  Future<void> create({
    required int viewId,
    required String uri,
    required DataSourceType type,
    String? package,
    bool? autoPlay,
    HwAcc? hwAcc,
    VlcPlayerOptions? options,
  }) async {
    final message = CreateMessage();
    message.viewId = viewId;
    message.uri = uri;
    message.type = type.index;
    message.packageName = package;
    message.hwAcc = hwAcc?.index;
    message.autoPlay = autoPlay ?? true;
    message.options = options?.get() ?? [];

    return _api.create(message);
  }

  // ignore: proper_super_calls
  @override
  Future<void> dispose(int viewId) async {
    return _api.dispose(ViewMessage()..viewId = viewId);
  }

  /// This method builds the appropriate platform view where the player
  /// can be rendered.
  /// The `viewId` is passed as a parameter from the framework on the
  /// `onPlatformViewCreated` callback.
  ///
  /// The `virtualDisplay` specifies whether Virtual displays or Hybrid composition is used on Android.
  /// iOS only uses Hybrid composition.
  @override
  Widget buildView(
    PlatformViewCreatedCallback onPlatformViewCreated, {
    bool virtualDisplay = true,
  }) {
    const viewType = 'flutter_video_plugin/getVideoView';
    if (Platform.isAndroid) {
      return virtualDisplay
          ? AndroidView(
            viewType: viewType,
            hitTestBehavior: PlatformViewHitTestBehavior.transparent,
            onPlatformViewCreated: onPlatformViewCreated,
            creationParamsCodec: const StandardMessageCodec(),
          )
          : PlatformViewLink(
            viewType: viewType,
            surfaceFactory: (
              BuildContext _,
              PlatformViewController controller,
            ) {
              return AndroidViewSurface(
                controller: controller as AndroidViewController,
                gestureRecognizers: const {},
                hitTestBehavior: PlatformViewHitTestBehavior.transparent,
              );
            },
            onCreatePlatformView: (PlatformViewCreationParams params) {
              return PlatformViewsService.initSurfaceAndroidView(
                  id: params.id,
                  viewType: viewType,
                  layoutDirection: TextDirection.ltr,
                  creationParamsCodec: const StandardMessageCodec(),
                )
                ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
                ..addOnPlatformViewCreatedListener(onPlatformViewCreated)
                ..create();
            },
          );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: viewType,
        onPlatformViewCreated: onPlatformViewCreated,
        hitTestBehavior: PlatformViewHitTestBehavior.transparent,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return const Text('Requested platform is not yet supported by this plugin');
  }

  @override
  // ignore: cyclomatic_complexity
  Stream<VlcMediaEvent> mediaEventsFor(int viewId) {
    return _mediaEventChannelFor(viewId).receiveBroadcastStream().map((
      dynamic event,
    ) {
      final Map<Object?, Object?> map = event as Map<Object?, Object?>;
      //
      switch (map['event']) {
        case 'opening':
          return VlcMediaEvent(mediaEventType: VlcMediaEventType.opening);

        case 'paused':
          return VlcMediaEvent(mediaEventType: VlcMediaEventType.paused);

        case 'stopped':
          return VlcMediaEvent(mediaEventType: VlcMediaEventType.stopped);

        case 'playing':
          return VlcMediaEvent(
            mediaEventType: VlcMediaEventType.playing,
            size: Size(
              (map['width'] as num?)?.toDouble() ?? 0.0,
              (map['height'] as num?)?.toDouble() ?? 0.0,
            ),
            playbackSpeed: map['speed'] as double? ?? 1.0,
            duration: Duration(milliseconds: map['duration'] as int? ?? 0),
            audioTracksCount: map['audioTracksCount'] as int? ?? 1,
            activeAudioTrack: map['activeAudioTrack'] as int? ?? 0,
            spuTracksCount: map['spuTracksCount'] as int? ?? 0,
            activeSpuTrack: map['activeSpuTrack'] as int? ?? -1,
          );

        case 'ended':
          return VlcMediaEvent(
            mediaEventType: VlcMediaEventType.ended,
            position: Duration(milliseconds: map['position'] as int? ?? 0),
          );

        case 'buffering':
        case 'timeChanged':
          const defaultBufferPercent = 100.0;

          return VlcMediaEvent(
            mediaEventType: VlcMediaEventType.timeChanged,
            size: Size(
              (map['width'] as num?)?.toDouble() ?? 0.0,
              (map['height'] as num?)?.toDouble() ?? 0.0,
            ),
            playbackSpeed: map['speed'] as double? ?? 1.0,
            position: Duration(milliseconds: map['position'] as int? ?? 0),
            duration: Duration(milliseconds: map['duration'] as int? ?? 0),
            audioTracksCount: map['audioTracksCount'] as int? ?? 1,
            activeAudioTrack: map['activeAudioTrack'] as int? ?? 0,
            spuTracksCount: map['spuTracksCount'] as int? ?? 0,
            activeSpuTrack: map['activeSpuTrack'] as int? ?? -1,
            bufferPercent: map['buffer'] as double? ?? defaultBufferPercent,
            isPlaying: map['isPlaying'] as bool? ?? false,
          );

        case 'mediaChanged':
          return VlcMediaEvent(mediaEventType: VlcMediaEventType.mediaChanged);

        case 'recording':
          return VlcMediaEvent(
            mediaEventType: VlcMediaEventType.recording,
            isRecording: map['isRecording'] as bool? ?? false,
            recordPath: map['recordPath'] as String? ?? '',
          );

        case 'error':
          return VlcMediaEvent(mediaEventType: VlcMediaEventType.error);

        default:
          return VlcMediaEvent(mediaEventType: VlcMediaEventType.unknown);
      }
    });
  }

  @override
  Future<void> setStreamUrl(
    int viewId, {
    required String uri,
    required DataSourceType type,
    String? package,
    bool? autoPlay,
    HwAcc? hwAcc,
  }) async {
    final message = SetMediaMessage();
    message.viewId = viewId;
    message.uri = uri;
    message.type = type.index;
    message.packageName = package;
    message.hwAcc = hwAcc?.index;
    message.autoPlay = autoPlay ?? true;

    return _api.setStreamUrl(message);
  }

  @override
  Future<void> setLooping(int viewId, bool looping) async {
    return _api.setLooping(
      LoopingMessage()
        ..viewId = viewId
        ..isLooping = looping,
    );
  }

  @override
  Future<void> play(int viewId) async {
    return _api.play(ViewMessage()..viewId = viewId);
  }

  @override
  Future<void> pause(int viewId) async {
    return _api.pause(ViewMessage()..viewId = viewId);
  }

  @override
  Future<void> stop(int viewId) async {
    return _api.stop(ViewMessage()..viewId = viewId);
  }

  @override
  Future<bool?> isPlaying(int viewId) async {
    final response = await _api.isPlaying(ViewMessage()..viewId = viewId);

    return response.result;
  }

  @override
  Future<bool?> isSeekable(int viewId) async {
    final response = await _api.isSeekable(ViewMessage()..viewId = viewId);

    return response.result;
  }

  @override
  Future<void> seekTo(int viewId, Duration position) async {
    return _api.seekTo(
      PositionMessage()
        ..viewId = viewId
        ..position = position.inMilliseconds,
    );
  }

  @override
  Future<Duration> getPosition(int viewId) async {
    final response = await _api.position(ViewMessage()..viewId = viewId);

    return Duration(milliseconds: response.position ?? 0);
  }

  @override
  Future<Duration> getDuration(int viewId) async {
    final response = await _api.duration(ViewMessage()..viewId = viewId);

    return Duration(milliseconds: response.duration ?? 0);
  }

  @override
  Future<void> setVolume(int viewId, int volume) async {
    return _api.setVolume(
      VolumeMessage()
        ..viewId = viewId
        ..volume = volume,
    );
  }

  @override
  Future<int?> getVolume(int viewId) async {
    final response = await _api.getVolume(ViewMessage()..viewId = viewId);

    return response.volume;
  }

  @override
  Future<void> setPlaybackSpeed(int viewId, double speed) async {
    assert(speed > 0);

    return _api.setPlaybackSpeed(
      PlaybackSpeedMessage()
        ..viewId = viewId
        ..speed = speed,
    );
  }

  @override
  Future<double?> getPlaybackSpeed(int viewId) async {
    final response = await _api.getPlaybackSpeed(
      ViewMessage()..viewId = viewId,
    );

    return response.speed;
  }

  @override
  Future<int?> getSpuTracksCount(int viewId) async {
    final response = await _api.getSpuTracksCount(
      ViewMessage()..viewId = viewId,
    );

    return response.count;
  }

  @override
  Future<Map<int, String>> getSpuTracks(int viewId) async {
    final response = await _api.getSpuTracks(ViewMessage()..viewId = viewId);

    return response.subtitles?.cast<int, String>() ?? {};
  }

  @override
  Future<int?> getSpuTrack(int viewId) async {
    final response = await _api.getSpuTrack(ViewMessage()..viewId = viewId);

    return response.spuTrackNumber;
  }

  @override
  Future<void> setSpuTrack(int viewId, int spuTrackNumber) async {
    return _api.setSpuTrack(
      SpuTrackMessage()
        ..viewId = viewId
        ..spuTrackNumber = spuTrackNumber,
    );
  }

  @override
  Future<void> setSpuDelay(int viewId, int delay) async {
    return _api.setSpuDelay(
      DelayMessage()
        ..viewId = viewId
        ..delay = delay,
    );
  }

  @override
  Future<int?> getSpuDelay(int viewId) async {
    final response = await _api.getSpuDelay(ViewMessage()..viewId = viewId);

    return response.delay;
  }

  @override
  Future<void> addSubtitleTrack(
    int viewId, {
    required String uri,
    required DataSourceType type,
    bool? isSelected,
  }) async {
    final message = AddSubtitleMessage();
    message.viewId = viewId;
    message.uri = uri;
    message.type = type.index;
    message.isSelected = isSelected;

    return _api.addSubtitleTrack(message);
  }

  @override
  Future<int?> getAudioTracksCount(int viewId) async {
    final response = await _api.getAudioTracksCount(
      ViewMessage()..viewId = viewId,
    );

    return response.count;
  }

  @override
  Future<Map<int, String>> getAudioTracks(int viewId) async {
    final response = await _api.getAudioTracks(ViewMessage()..viewId = viewId);

    return response.audios?.cast<int, String>() ?? {};
  }

  @override
  Future<int?> getAudioTrack(int viewId) async {
    final response = await _api.getAudioTrack(ViewMessage()..viewId = viewId);

    return response.audioTrackNumber;
  }

  @override
  Future<void> setAudioTrack(int viewId, int audioTrackNumber) async {
    return _api.setAudioTrack(
      AudioTrackMessage()
        ..viewId = viewId
        ..audioTrackNumber = audioTrackNumber,
    );
  }

  @override
  Future<void> setAudioDelay(int viewId, int delay) async {
    return _api.setAudioDelay(
      DelayMessage()
        ..viewId = viewId
        ..delay = delay,
    );
  }

  @override
  Future<int?> getAudioDelay(int viewId) async {
    final response = await _api.getAudioDelay(ViewMessage()..viewId = viewId);

    return response.delay;
  }

  @override
  Future<void> addAudioTrack(
    int viewId, {
    required String uri,
    required DataSourceType type,
    bool? isSelected,
  }) async {
    final message = AddAudioMessage();
    message.viewId = viewId;
    message.uri = uri;
    message.type = type.index;
    message.isSelected = isSelected;

    return _api.addAudioTrack(message);
  }

  @override
  Future<int?> getVideoTracksCount(int viewId) async {
    final response = await _api.getVideoTracksCount(
      ViewMessage()..viewId = viewId,
    );

    return response.count;
  }

  @override
  Future<Map<int, String>> getVideoTracks(int viewId) async {
    final response = await _api.getVideoTracks(ViewMessage()..viewId = viewId);

    return response.videos?.cast<int, String>() ?? {};
  }

  @override
  Future<void> setVideoTrack(int viewId, int videoTrackNumber) async {
    return _api.setVideoTrack(
      VideoTrackMessage()
        ..viewId = viewId
        ..videoTrackNumber = videoTrackNumber,
    );
  }

  @override
  Future<int?> getVideoTrack(int viewId) async {
    final response = await _api.getVideoTrack(ViewMessage()..viewId = viewId);

    return response.videoTrackNumber;
  }

  @override
  Future<void> setVideoScale(int viewId, double scale) async {
    return _api.setVideoScale(
      VideoScaleMessage()
        ..viewId = viewId
        ..scale = scale,
    );
  }

  @override
  Future<double?> getVideoScale(int viewId) async {
    final response = await _api.getVideoScale(ViewMessage()..viewId = viewId);

    return response.scale;
  }

  @override
  Future<void> setVideoAspectRatio(int viewId, String aspect) async {
    return _api.setVideoAspectRatio(
      VideoAspectRatioMessage()
        ..viewId = viewId
        ..aspectRatio = aspect,
    );
  }

  @override
  Future<String?> getVideoAspectRatio(int viewId) async {
    final response = await _api.getVideoAspectRatio(
      ViewMessage()..viewId = viewId,
    );

    return response.aspectRatio;
  }

  String base64Encode(List<int> value) => base64.encode(value);
  Uint8List base64Decode(String source) => base64.decode(source);

  @override
  Future<Uint8List> takeSnapshot(int viewId) async {
    final response = await _api.takeSnapshot(ViewMessage()..viewId = viewId);
    final base64String = response.snapshot ?? "";
    final imageBytes = base64Decode(base64.normalize(base64String));

    return imageBytes;
  }

  @override
  Future<List<String>> getAvailableRendererServices(int viewId) async {
    final response = await _api.getAvailableRendererServices(
      ViewMessage()..viewId = viewId,
    );

    return response.services?.cast<String>() ?? [];
  }

  @override
  Future<void> startRendererScanning(
    int viewId, {
    String? rendererService,
  }) async {
    return _api.startRendererScanning(
      RendererScanningMessage()
        ..viewId = viewId
        ..rendererService = rendererService ?? '',
    );
  }

  @override
  Future<void> stopRendererScanning(int viewId) async {
    return _api.stopRendererScanning(ViewMessage()..viewId = viewId);
  }

  @override
  Future<Map<String, String>> getRendererDevices(int viewId) async {
    final response = await _api.getRendererDevices(
      ViewMessage()..viewId = viewId,
    );

    return response.rendererDevices?.cast<String, String>() ?? {};
  }

  @override
  Future<void> castToRenderer(int viewId, String rendererDevice) async {
    return _api.castToRenderer(
      RenderDeviceMessage()
        ..viewId = viewId
        ..rendererDevice = rendererDevice,
    );
  }

  @override
  Stream<VlcRendererEvent> rendererEventsFor(int viewId) {
    return _rendererEventChannelFor(viewId).receiveBroadcastStream().map((
      dynamic event,
    ) {
      final Map<Object?, Object?> map = event as Map<Object?, Object?>;
      //
      switch (map['event']) {
        case 'attached':
          return VlcRendererEvent(
            eventType: VlcRendererEventType.attached,
            rendererId: map['id'].toString(),
            rendererName: map['name'].toString(),
          );
        //
        case 'detached':
          return VlcRendererEvent(
            eventType: VlcRendererEventType.detached,
            rendererId: map['id'].toString(),
            rendererName: map['name'].toString(),
          );
        //
        default:
          return VlcRendererEvent(eventType: VlcRendererEventType.unknown);
      }
    });
  }

  @override
  Future<bool?> startRecording(int viewId, String saveDirectory) async {
    final response = await _api.startRecording(
      RecordMessage()
        ..viewId = viewId
        ..saveDirectory = saveDirectory,
    );

    return response.result;
  }

  @override
  Future<bool?> stopRecording(int viewId) async {
    final response = await _api.stopRecording(ViewMessage()..viewId = viewId);

    return response.result;
  }
}
