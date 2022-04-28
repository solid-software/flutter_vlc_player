import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../flutter_vlc_player_platform_interface.dart';
import '../messages/messages.dart';

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
    return await _api.initialize();
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
    var message = CreateMessage();
    message.viewId = viewId;
    message.uri = uri;
    message.type = type.index;
    message.packageName = package;
    message.hwAcc = hwAcc!.index;
    message.autoPlay = autoPlay ?? true;
    message.options = options?.get() ?? [];
    return await _api.create(message);
  }

  @override
  Future<void> dispose(int viewId) async {
    return await _api.dispose(ViewMessage()..viewId = viewId);
  }

  /// This method builds the appropriate platform view where the player
  /// can be rendered.
  /// The `viewId` is passed as a parameter from the framework on the
  /// `onPlatformViewCreated` callback.
  ///
  /// The `virtualDisplay` specifies whether Virtual displays or Hybrid composition is used on Android.
  /// iOS only uses Hybrid composition.
  @override
  Widget buildView(PlatformViewCreatedCallback onPlatformViewCreated,
      {bool virtualDisplay = true}) {
    const viewType = 'flutter_video_plugin/getVideoView';
    if (Platform.isAndroid) {
      if (virtualDisplay) {
        return AndroidView(
          viewType: viewType,
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          onPlatformViewCreated: onPlatformViewCreated,
          creationParamsCodec: const StandardMessageCodec(),
        );
      } else {
        return PlatformViewLink(
          viewType: viewType,
          surfaceFactory: (
            BuildContext context,
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
      }
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
  Stream<VlcMediaEvent> mediaEventsFor(int viewId) {
    return _mediaEventChannelFor(viewId).receiveBroadcastStream().map(
      (dynamic event) {
        final Map<dynamic, dynamic> map = event;
        //
        switch (map['event']) {
          case 'opening':
            return VlcMediaEvent(
              mediaEventType: VlcMediaEventType.opening,
            );

          case 'paused':
            return VlcMediaEvent(
              mediaEventType: VlcMediaEventType.paused,
            );

          case 'stopped':
            return VlcMediaEvent(
              mediaEventType: VlcMediaEventType.stopped,
            );

          case 'playing':
            return VlcMediaEvent(
              mediaEventType: VlcMediaEventType.playing,
              size: Size(
                map['width']?.toDouble() ?? 0.0,
                map['height']?.toDouble() ?? 0.0,
              ),
              playbackSpeed: map['speed'] ?? 1.0,
              duration: Duration(milliseconds: map['duration'] ?? 0),
              audioTracksCount: map['audioTracksCount'] ?? 1,
              activeAudioTrack: map['activeAudioTrack'] ?? 0,
              spuTracksCount: map['spuTracksCount'] ?? 0,
              activeSpuTrack: map['activeSpuTrack'] ?? -1,
            );

          case 'ended':
            return VlcMediaEvent(
              mediaEventType: VlcMediaEventType.ended,
              position: Duration(milliseconds: map['position'] ?? 0),
            );

          case 'buffering':
          case 'timeChanged':
            return VlcMediaEvent(
              mediaEventType: VlcMediaEventType.timeChanged,
              size: Size(
                map['width']?.toDouble() ?? 0.0,
                map['height']?.toDouble() ?? 0.0,
              ),
              playbackSpeed: map['speed'] ?? 1.0,
              position: Duration(milliseconds: map['position'] ?? 0),
              duration: Duration(milliseconds: map['duration'] ?? 0),
              audioTracksCount: map['audioTracksCount'] ?? 1,
              activeAudioTrack: map['activeAudioTrack'] ?? 0,
              spuTracksCount: map['spuTracksCount'] ?? 0,
              activeSpuTrack: map['activeSpuTrack'] ?? -1,
              bufferPercent: map['buffer'] ?? 100.0,
              isPlaying: map['isPlaying'] ?? false,
            );

          case 'mediaChanged':
            return VlcMediaEvent(
              mediaEventType: VlcMediaEventType.mediaChanged,
            );

          case 'recording':
            return VlcMediaEvent(
              mediaEventType: VlcMediaEventType.recording,
              isRecording: map['isRecording'] ?? false,
              recordPath: map['recordPath'] ?? '',
            );

          case 'error':
            return VlcMediaEvent(
              mediaEventType: VlcMediaEventType.error,
            );

          default:
            return VlcMediaEvent(
              mediaEventType: VlcMediaEventType.unknown,
            );
        }
      },
    );
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
    var message = SetMediaMessage();
    message.viewId = viewId;
    message.uri = uri;
    message.type = type.index;
    message.packageName = package;
    message.hwAcc = hwAcc!.index;
    message.autoPlay = autoPlay ?? true;
    return await _api.setStreamUrl(message);
  }

  @override
  Future<void> setLooping(int viewId, bool looping) async {
    return await _api.setLooping(LoopingMessage()
      ..viewId = viewId
      ..isLooping = looping);
  }

  @override
  Future<void> play(int viewId) async {
    return await _api.play(ViewMessage()..viewId = viewId);
  }

  @override
  Future<void> pause(int viewId) async {
    return await _api.pause(ViewMessage()..viewId = viewId);
  }

  @override
  Future<void> stop(int viewId) async {
    return await _api.stop(ViewMessage()..viewId = viewId);
  }

  @override
  Future<bool?> isPlaying(int viewId) async {
    var response = await _api.isPlaying(ViewMessage()..viewId = viewId);
    return response.result;
  }

  @override
  Future<bool?> isSeekable(int viewId) async {
    var response = await _api.isSeekable(ViewMessage()..viewId = viewId);
    return response.result;
  }

  @override
  Future<void> seekTo(int viewId, Duration position) async {
    return await _api.seekTo(PositionMessage()
      ..viewId = viewId
      ..position = position.inMilliseconds);
  }

  @override
  Future<Duration> getPosition(int viewId) async {
    var response = await _api.position(ViewMessage()..viewId = viewId);
    return Duration(milliseconds: response.position!);
  }

  @override
  Future<Duration> getDuration(int viewId) async {
    var response = await _api.duration(ViewMessage()..viewId = viewId);
    return Duration(milliseconds: response.duration!);
  }

  @override
  Future<void> setVolume(int viewId, int volume) async {
    return await _api.setVolume(VolumeMessage()
      ..viewId = viewId
      ..volume = volume);
  }

  @override
  Future<int?> getVolume(int viewId) async {
    var response = await _api.getVolume(ViewMessage()..viewId = viewId);
    return response.volume;
  }

  @override
  Future<void> setPlaybackSpeed(int viewId, double speed) async {
    assert(speed > 0);
    return await _api.setPlaybackSpeed(PlaybackSpeedMessage()
      ..viewId = viewId
      ..speed = speed);
  }

  @override
  Future<double?> getPlaybackSpeed(int viewId) async {
    var response = await _api.getPlaybackSpeed(ViewMessage()..viewId = viewId);
    return response.speed;
  }

  @override
  Future<int?> getSpuTracksCount(int viewId) async {
    var response = await _api.getSpuTracksCount(ViewMessage()..viewId = viewId);
    return response.count;
  }

  @override
  Future<Map<int, String>> getSpuTracks(int viewId) async {
    var response = await _api.getSpuTracks(ViewMessage()..viewId = viewId);
    return response.subtitles!.cast<int, String>();
  }

  @override
  Future<int?> getSpuTrack(int viewId) async {
    var response = await _api.getSpuTrack(ViewMessage()..viewId = viewId);
    return response.spuTrackNumber;
  }

  @override
  Future<void> setSpuTrack(int viewId, int spuTrackNumber) async {
    return await _api.setSpuTrack(SpuTrackMessage()
      ..viewId = viewId
      ..spuTrackNumber = spuTrackNumber);
  }

  @override
  Future<void> setSpuDelay(int viewId, int delay) async {
    return await _api.setSpuDelay(DelayMessage()
      ..viewId = viewId
      ..delay = delay);
  }

  @override
  Future<int?> getSpuDelay(int viewId) async {
    var response = await _api.getSpuDelay(ViewMessage()..viewId = viewId);
    return response.delay;
  }

  @override
  Future<void> addSubtitleTrack(
    int viewId, {
    required String uri,
    required DataSourceType type,
    bool? isSelected,
  }) async {
    var message = AddSubtitleMessage();
    message.viewId = viewId;
    message.uri = uri;
    message.type = type.index;
    message.isSelected = isSelected;
    return await _api.addSubtitleTrack(message);
  }

  @override
  Future<int?> getAudioTracksCount(int viewId) async {
    var response =
        await _api.getAudioTracksCount(ViewMessage()..viewId = viewId);
    return response.count;
  }

  @override
  Future<Map<int, String>> getAudioTracks(int viewId) async {
    var response = await _api.getAudioTracks(ViewMessage()..viewId = viewId);
    return response.audios!.cast<int, String>();
  }

  @override
  Future<int?> getAudioTrack(int viewId) async {
    var response = await _api.getAudioTrack(ViewMessage()..viewId = viewId);
    return response.audioTrackNumber;
  }

  @override
  Future<void> setAudioTrack(int viewId, int audioTrackNumber) async {
    return await _api.setAudioTrack(AudioTrackMessage()
      ..viewId = viewId
      ..audioTrackNumber = audioTrackNumber);
  }

  @override
  Future<void> setAudioDelay(int viewId, int delay) async {
    return await _api.setAudioDelay(DelayMessage()
      ..viewId = viewId
      ..delay = delay);
  }

  @override
  Future<int?> getAudioDelay(int viewId) async {
    var response = await _api.getAudioDelay(ViewMessage()..viewId = viewId);
    return response.delay;
  }

  @override
  Future<void> addAudioTrack(
    int viewId, {
    required String uri,
    required DataSourceType type,
    bool? isSelected,
  }) async {
    var message = AddAudioMessage();
    message.viewId = viewId;
    message.uri = uri;
    message.type = type.index;
    message.isSelected = isSelected;
    return await _api.addAudioTrack(message);
  }

  @override
  Future<int?> getVideoTracksCount(int viewId) async {
    var response =
        await _api.getVideoTracksCount(ViewMessage()..viewId = viewId);
    return response.count;
  }

  @override
  Future<Map<int, String>> getVideoTracks(int viewId) async {
    var response = await _api.getVideoTracks(ViewMessage()..viewId = viewId);
    return response.videos!.cast<int, String>();
  }

  @override
  Future<void> setVideoTrack(int viewId, int videoTrackNumber) async {
    return await _api.setVideoTrack(VideoTrackMessage()
      ..viewId = viewId
      ..videoTrackNumber = videoTrackNumber);
  }

  @override
  Future<int?> getVideoTrack(int viewId) async {
    var response = await _api.getVideoTrack(ViewMessage()..viewId = viewId);
    return response.videoTrackNumber;
  }

  @override
  Future<void> setVideoScale(int viewId, double scale) async {
    return await _api.setVideoScale(VideoScaleMessage()
      ..viewId = viewId
      ..scale = scale);
  }

  @override
  Future<double?> getVideoScale(int viewId) async {
    var response = await _api.getVideoScale(ViewMessage()..viewId = viewId);
    return response.scale;
  }

  @override
  Future<void> setVideoAspectRatio(int viewId, String aspect) async {
    return await _api.setVideoAspectRatio(VideoAspectRatioMessage()
      ..viewId = viewId
      ..aspectRatio = aspect);
  }

  @override
  Future<String?> getVideoAspectRatio(int viewId) async {
    var response =
        await _api.getVideoAspectRatio(ViewMessage()..viewId = viewId);
    return response.aspectRatio;
  }

  String base64Encode(List<int> value) => base64.encode(value);
  Uint8List base64Decode(String source) => base64.decode(source);

  @override
  Future<Uint8List> takeSnapshot(int viewId) async {
    var response = await _api.takeSnapshot(ViewMessage()..viewId = viewId);
    var base64String = response.snapshot!;
    var imageBytes = base64Decode(base64.normalize(base64String));
    return imageBytes;
  }

  @override
  Future<List<String>> getAvailableRendererServices(int viewId) async {
    var response =
        await _api.getAvailableRendererServices(ViewMessage()..viewId = viewId);
    return response.services!.cast<String>();
  }

  @override
  Future<void> startRendererScanning(int viewId,
      {String? rendererService}) async {
    return await _api.startRendererScanning(RendererScanningMessage()
      ..viewId = viewId
      ..rendererService = rendererService ?? '');
  }

  @override
  Future<void> stopRendererScanning(int viewId) async {
    return await _api.stopRendererScanning(ViewMessage()..viewId = viewId);
  }

  @override
  Future<Map<String, String>> getRendererDevices(int viewId) async {
    var response =
        await _api.getRendererDevices(ViewMessage()..viewId = viewId);
    return response.rendererDevices!.cast<String, String>();
  }

  @override
  Future<void> castToRenderer(int viewId, String rendererDevice) async {
    return await _api.castToRenderer(RenderDeviceMessage()
      ..viewId = viewId
      ..rendererDevice = rendererDevice);
  }

  @override
  Stream<VlcRendererEvent> rendererEventsFor(int viewId) {
    return _rendererEventChannelFor(viewId).receiveBroadcastStream().map(
      (dynamic event) {
        final Map<dynamic, dynamic> map = event;
        //
        switch (map['event']) {
          case 'attached':
            return VlcRendererEvent(
              eventType: VlcRendererEventType.attached,
              rendererId: map['id'],
              rendererName: map['name'],
            );
          //
          case 'detached':
            return VlcRendererEvent(
              eventType: VlcRendererEventType.detached,
              rendererId: map['id'],
              rendererName: map['name'],
            );
          //
          default:
            return VlcRendererEvent(eventType: VlcRendererEventType.unknown);
        }
      },
    );
  }

  @override
  Future<bool?> startRecording(int viewId, String saveDirectory) async {
    var response = await _api.startRecording(RecordMessage()
      ..viewId = viewId
      ..saveDirectory = saveDirectory);
    return response.result;
  }

  @override
  Future<bool?> stopRecording(int viewId) async {
    var response = await _api.stopRecording(ViewMessage()..viewId = viewId);
    return response.result;
  }
}
