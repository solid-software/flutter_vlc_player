import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../flutter_vlc_player_platform_interface.dart';
import '../enums/hardware_acceleration.dart';
import '../enums/media_event_type.dart';
import '../enums/renderer_event_type.dart';
import '../events/media_event.dart';
import '../events/renderer_event.dart';
import '../messages/messages.dart';
import '../platform_interface/vlc_player_platform_interface.dart';
import '../utils/options/vlc_player_options.dart';

/// An implementation of [VlcPlayerPlatform] that uses method channels.
class MethodChannelVlcPlayer extends VlcPlayerPlatform {
  final _api = VlcPlayerApi();

  EventChannel _mediaEventChannelFor(int textureId) {
    return EventChannel('flutter_video_plugin/getVideoEvents_$textureId');
  }

  EventChannel _rendererEventChannelFor(int textureId) {
    return EventChannel('flutter_video_plugin/getRendererEvents_$textureId');
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
    message.textureId = viewId;
    message.uri = uri;
    message.type = type.index;
    message.packageName = package;
    message.hwAcc = hwAcc!.index;
    message.autoPlay = autoPlay ?? true;
    message.options = options?.get() ?? [];
    return await _api.create(message);
  }

  @override
  Future<void> dispose(int textureId) async {
    return await _api.dispose(TextureMessage()..textureId = textureId);
  }

  /// This method builds the appropriate platform view where the player
  /// can be rendered.
  /// The `textureId` is passed as a parameter from the framework on the
  /// `onPlatformViewCreated` callback.
  @override
  Widget buildView(PlatformViewCreatedCallback onPlatformViewCreated) {
    if (Platform.isAndroid) {
      return AndroidView(
        viewType: 'flutter_video_plugin/getVideoView',
        hitTestBehavior: PlatformViewHitTestBehavior.transparent,
        onPlatformViewCreated: onPlatformViewCreated,
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: 'flutter_video_plugin/getVideoView',
        onPlatformViewCreated: onPlatformViewCreated,
        hitTestBehavior: PlatformViewHitTestBehavior.transparent,
        creationParamsCodec: const StandardMessageCodec(),
      );
    }
    return Text('Requested platform is not yet supported by this plugin');
  }

  @override
  Stream<VlcMediaEvent> mediaEventsFor(int textureId) {
    return _mediaEventChannelFor(textureId).receiveBroadcastStream().map(
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
    int textureId, {
    required String uri,
    required DataSourceType type,
    String? package,
    bool? autoPlay,
    HwAcc? hwAcc,
  }) async {
    var message = SetMediaMessage();
    message.textureId = textureId;
    message.uri = uri;
    message.type = type.index;
    message.packageName = package;
    message.hwAcc = hwAcc!.index;
    message.autoPlay = autoPlay ?? true;
    return await _api.setStreamUrl(message);
  }

  @override
  Future<void> setLooping(int textureId, bool looping) async {
    return await _api.setLooping(LoopingMessage()
      ..textureId = textureId
      ..isLooping = looping);
  }

  @override
  Future<void> play(int textureId) async {
    return await _api.play(TextureMessage()..textureId = textureId);
  }

  @override
  Future<void> pause(int textureId) async {
    return await _api.pause(TextureMessage()..textureId = textureId);
  }

  @override
  Future<void> stop(int textureId) async {
    return await _api.stop(TextureMessage()..textureId = textureId);
  }

  @override
  Future<bool?> isPlaying(int textureId) async {
    var response =
        await _api.isPlaying(TextureMessage()..textureId = textureId);
    return response.result;
  }

  @override
  Future<bool?> isSeekable(int textureId) async {
    var response =
        await _api.isSeekable(TextureMessage()..textureId = textureId);
    return response.result;
  }

  @override
  Future<void> seekTo(int textureId, Duration position) async {
    return await _api.seekTo(PositionMessage()
      ..textureId = textureId
      ..position = position.inMilliseconds);
  }

  @override
  Future<Duration> getPosition(int textureId) async {
    var response = await _api.position(TextureMessage()..textureId = textureId);
    return Duration(milliseconds: response.position!);
  }

  @override
  Future<Duration> getDuration(int textureId) async {
    var response = await _api.duration(TextureMessage()..textureId = textureId);
    return Duration(milliseconds: response.duration!);
  }

  @override
  Future<void> setVolume(int textureId, int volume) async {
    return await _api.setVolume(VolumeMessage()
      ..textureId = textureId
      ..volume = volume);
  }

  @override
  Future<int?> getVolume(int textureId) async {
    var response =
        await _api.getVolume(TextureMessage()..textureId = textureId);
    return response.volume;
  }

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) async {
    assert(speed > 0);
    return await _api.setPlaybackSpeed(PlaybackSpeedMessage()
      ..textureId = textureId
      ..speed = speed);
  }

  @override
  Future<double?> getPlaybackSpeed(int textureId) async {
    var response =
        await _api.getPlaybackSpeed(TextureMessage()..textureId = textureId);
    return response.speed;
  }

  @override
  Future<int?> getSpuTracksCount(int textureId) async {
    var response =
        await _api.getSpuTracksCount(TextureMessage()..textureId = textureId);
    return response.count;
  }

  @override
  Future<Map<int, String>> getSpuTracks(int textureId) async {
    var response =
        await _api.getSpuTracks(TextureMessage()..textureId = textureId);
    return response.subtitles!.cast<int, String>();
  }

  @override
  Future<int?> getSpuTrack(int textureId) async {
    var response =
        await _api.getSpuTrack(TextureMessage()..textureId = textureId);
    return response.spuTrackNumber;
  }

  @override
  Future<void> setSpuTrack(int textureId, int spuTrackNumber) async {
    return await _api.setSpuTrack(SpuTrackMessage()
      ..textureId = textureId
      ..spuTrackNumber = spuTrackNumber);
  }

  @override
  Future<void> setSpuDelay(int textureId, int delay) async {
    return await _api.setSpuDelay(DelayMessage()
      ..textureId = textureId
      ..delay = delay);
  }

  @override
  Future<int?> getSpuDelay(int textureId) async {
    var response =
        await _api.getSpuDelay(TextureMessage()..textureId = textureId);
    return response.delay;
  }

  @override
  Future<void> addSubtitleTrack(
    int textureId, {
    required String uri,
    required DataSourceType type,
    bool? isSelected,
  }) async {
    var message = AddSubtitleMessage();
    message.textureId = textureId;
    message.uri = uri;
    message.type = type.index;
    message.isSelected = isSelected;
    return await _api.addSubtitleTrack(message);
  }

  @override
  Future<int?> getAudioTracksCount(int textureId) async {
    var response =
        await _api.getAudioTracksCount(TextureMessage()..textureId = textureId);
    return response.count;
  }

  @override
  Future<Map<int, String>> getAudioTracks(int textureId) async {
    var response =
        await _api.getAudioTracks(TextureMessage()..textureId = textureId);
    return response.audios!.cast<int, String>();
  }

  @override
  Future<int?> getAudioTrack(int textureId) async {
    var response =
        await _api.getAudioTrack(TextureMessage()..textureId = textureId);
    return response.audioTrackNumber;
  }

  @override
  Future<void> setAudioTrack(int textureId, int audioTrackNumber) async {
    return await _api.setAudioTrack(AudioTrackMessage()
      ..textureId = textureId
      ..audioTrackNumber = audioTrackNumber);
  }

  @override
  Future<void> setAudioDelay(int textureId, int delay) async {
    return await _api.setAudioDelay(DelayMessage()
      ..textureId = textureId
      ..delay = delay);
  }

  @override
  Future<int?> getAudioDelay(int textureId) async {
    var response =
        await _api.getAudioDelay(TextureMessage()..textureId = textureId);
    return response.delay;
  }

  @override
  Future<void> addAudioTrack(
    int textureId, {
    required String uri,
    required DataSourceType type,
    bool? isSelected,
  }) async {
    var message = AddAudioMessage();
    message.textureId = textureId;
    message.uri = uri;
    message.type = type.index;
    message.isSelected = isSelected;
    return await _api.addAudioTrack(message);
  }

  @override
  Future<int?> getVideoTracksCount(int textureId) async {
    var response =
        await _api.getVideoTracksCount(TextureMessage()..textureId = textureId);
    return response.count;
  }

  @override
  Future<Map<int, String>> getVideoTracks(int textureId) async {
    var response =
        await _api.getVideoTracks(TextureMessage()..textureId = textureId);
    return response.videos!.cast<int, String>();
  }

  @override
  Future<void> setVideoTrack(int textureId, int videoTrackNumber) async {
    return await _api.setVideoTrack(VideoTrackMessage()
      ..textureId = textureId
      ..videoTrackNumber = videoTrackNumber);
  }

  @override
  Future<int?> getVideoTrack(int textureId) async {
    var response =
        await _api.getVideoTrack(TextureMessage()..textureId = textureId);
    return response.videoTrackNumber;
  }

  @override
  Future<void> setVideoScale(int textureId, double scale) async {
    return await _api.setVideoScale(VideoScaleMessage()
      ..textureId = textureId
      ..scale = scale);
  }

  @override
  Future<double?> getVideoScale(int textureId) async {
    var response =
        await _api.getVideoScale(TextureMessage()..textureId = textureId);
    return response.scale;
  }

  @override
  Future<void> setVideoAspectRatio(int textureId, String aspect) async {
    return await _api.setVideoAspectRatio(VideoAspectRatioMessage()
      ..textureId = textureId
      ..aspectRatio = aspect);
  }

  @override
  Future<String?> getVideoAspectRatio(int textureId) async {
    var response =
        await _api.getVideoAspectRatio(TextureMessage()..textureId = textureId);
    return response.aspectRatio;
  }

  String base64Encode(List<int> value) => base64.encode(value);
  Uint8List base64Decode(String source) => base64.decode(source);

  @override
  Future<Uint8List> takeSnapshot(int textureId) async {
    var response =
        await _api.takeSnapshot(TextureMessage()..textureId = textureId);
    var base64String = response.snapshot!;
    var imageBytes = base64Decode(base64.normalize(base64String));
    return imageBytes;
  }

  @override
  Future<List<String>> getAvailableRendererServices(int textureId) async {
    var response = await _api
        .getAvailableRendererServices(TextureMessage()..textureId = textureId);
    return response.services!.cast<String>();
  }

  @override
  Future<void> startRendererScanning(int textureId,
      {String? rendererService}) async {
    return await _api.startRendererScanning(RendererScanningMessage()
      ..textureId = textureId
      ..rendererService = rendererService ?? '');
  }

  @override
  Future<void> stopRendererScanning(int textureId) async {
    return await _api
        .stopRendererScanning(TextureMessage()..textureId = textureId);
  }

  @override
  Future<Map<String, String>> getRendererDevices(int textureId) async {
    var response =
        await _api.getRendererDevices(TextureMessage()..textureId = textureId);
    return response.rendererDevices!.cast<String, String>();
  }

  @override
  Future<void> castToRenderer(int textureId, String rendererDevice) async {
    return await _api.castToRenderer(RenderDeviceMessage()
      ..textureId = textureId
      ..rendererDevice = rendererDevice);
  }

  @override
  Stream<VlcRendererEvent> rendererEventsFor(int textureId) {
    return _rendererEventChannelFor(textureId).receiveBroadcastStream().map(
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
  Future<bool?> startRecording(int textureId, String saveDirectory) async {
    var response = await _api.startRecording(RecordMessage()
      ..textureId = textureId
      ..saveDirectory = saveDirectory);
    return response.result;
  }

  @override
  Future<bool?> stopRecording(int textureId) async {
    var response =
        await _api.stopRecording(TextureMessage()..textureId = textureId);
    return response.result;
  }
}
