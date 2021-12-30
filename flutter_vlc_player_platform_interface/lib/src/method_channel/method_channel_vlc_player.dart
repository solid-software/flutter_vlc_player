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

  EventChannel _mediaEventChannelFor(int playerId) {
    return EventChannel('flutter_video_plugin/getVideoEvents_$playerId');
  }

  EventChannel _rendererEventChannelFor(int playerId) {
    return EventChannel('flutter_video_plugin/getRendererEvents_$playerId');
  }

  @override
  Future<void> init() async {
    return await _api.initialize();
  }

  @override
  Future<void> create({
    required int playerId,
    required String uri,
    required DataSourceType type,
    String? package,
    bool? autoPlay,
    HwAcc? hwAcc,
    VlcPlayerOptions? options,
  }) async {
    var message = CreateMessage();
    message.playerId = playerId;
    message.uri = uri;
    message.type = type.index;
    message.packageName = package;
    message.hwAcc = hwAcc!.index;
    message.autoPlay = autoPlay ?? true;
    message.options = options?.get() ?? [];
    return await _api.create(message);
  }

  @override
  Future<void> dispose(int playerId) async {
    return await _api.dispose(PlayerMessage()..playerId = playerId);
  }

  /// This method builds the appropriate platform view where the player
  /// can be rendered.
  /// The `playerId` is passed as a parameter from the framework on the
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
    return const Text('Requested platform is not yet supported by this plugin');
  }

  @override
  Stream<VlcMediaEvent> mediaEventsFor(int playerId) {
    return _mediaEventChannelFor(playerId).receiveBroadcastStream().map(
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
    int playerId, {
    required String uri,
    required DataSourceType type,
    String? package,
    bool? autoPlay,
    HwAcc? hwAcc,
  }) async {
    var message = SetMediaMessage();
    message.playerId = playerId;
    message.uri = uri;
    message.type = type.index;
    message.packageName = package;
    message.hwAcc = hwAcc!.index;
    message.autoPlay = autoPlay ?? true;
    return await _api.setStreamUrl(message);
  }

  @override
  Future<void> setLooping(int playerId, bool looping) async {
    return await _api.setLooping(LoopingMessage()
      ..playerId = playerId
      ..isLooping = looping);
  }

  @override
  Future<void> play(int playerId) async {
    return await _api.play(PlayerMessage()..playerId = playerId);
  }

  @override
  Future<void> pause(int playerId) async {
    return await _api.pause(PlayerMessage()..playerId = playerId);
  }

  @override
  Future<void> stop(int playerId) async {
    return await _api.stop(PlayerMessage()..playerId = playerId);
  }

  @override
  Future<bool?> isPlaying(int playerId) async {
    var response = await _api.isPlaying(PlayerMessage()..playerId = playerId);
    return response.result;
  }

  @override
  Future<bool?> isSeekable(int playerId) async {
    var response = await _api.isSeekable(PlayerMessage()..playerId = playerId);
    return response.result;
  }

  @override
  Future<void> seekTo(int playerId, Duration position) async {
    return await _api.seekTo(PositionMessage()
      ..playerId = playerId
      ..position = position.inMilliseconds);
  }

  @override
  Future<Duration> getPosition(int playerId) async {
    var response = await _api.position(PlayerMessage()..playerId = playerId);
    return Duration(milliseconds: response.position!);
  }

  @override
  Future<Duration> getDuration(int playerId) async {
    var response = await _api.duration(PlayerMessage()..playerId = playerId);
    return Duration(milliseconds: response.duration!);
  }

  @override
  Future<void> setVolume(int playerId, int volume) async {
    return await _api.setVolume(VolumeMessage()
      ..playerId = playerId
      ..volume = volume);
  }

  @override
  Future<int?> getVolume(int playerId) async {
    var response = await _api.getVolume(PlayerMessage()..playerId = playerId);
    return response.volume;
  }

  @override
  Future<void> setPlaybackSpeed(int playerId, double speed) async {
    assert(speed > 0);
    return await _api.setPlaybackSpeed(PlaybackSpeedMessage()
      ..playerId = playerId
      ..speed = speed);
  }

  @override
  Future<double?> getPlaybackSpeed(int playerId) async {
    var response =
        await _api.getPlaybackSpeed(PlayerMessage()..playerId = playerId);
    return response.speed;
  }

  @override
  Future<int?> getSpuTracksCount(int playerId) async {
    var response =
        await _api.getSpuTracksCount(PlayerMessage()..playerId = playerId);
    return response.count;
  }

  @override
  Future<Map<int, String>> getSpuTracks(int playerId) async {
    var response =
        await _api.getSpuTracks(PlayerMessage()..playerId = playerId);
    return response.subtitles!.cast<int, String>();
  }

  @override
  Future<int?> getSpuTrack(int playerId) async {
    var response = await _api.getSpuTrack(PlayerMessage()..playerId = playerId);
    return response.spuTrackNumber;
  }

  @override
  Future<void> setSpuTrack(int playerId, int spuTrackNumber) async {
    return await _api.setSpuTrack(SpuTrackMessage()
      ..playerId = playerId
      ..spuTrackNumber = spuTrackNumber);
  }

  @override
  Future<void> setSpuDelay(int playerId, int delay) async {
    return await _api.setSpuDelay(DelayMessage()
      ..playerId = playerId
      ..delay = delay);
  }

  @override
  Future<int?> getSpuDelay(int playerId) async {
    var response = await _api.getSpuDelay(PlayerMessage()..playerId = playerId);
    return response.delay;
  }

  @override
  Future<void> addSubtitleTrack(
    int playerId, {
    required String uri,
    required DataSourceType type,
    bool? isSelected,
  }) async {
    var message = AddSubtitleMessage();
    message.playerId = playerId;
    message.uri = uri;
    message.type = type.index;
    message.isSelected = isSelected;
    return await _api.addSubtitleTrack(message);
  }

  @override
  Future<int?> getAudioTracksCount(int playerId) async {
    var response =
        await _api.getAudioTracksCount(PlayerMessage()..playerId = playerId);
    return response.count;
  }

  @override
  Future<Map<int, String>> getAudioTracks(int playerId) async {
    var response =
        await _api.getAudioTracks(PlayerMessage()..playerId = playerId);
    return response.audios!.cast<int, String>();
  }

  @override
  Future<int?> getAudioTrack(int playerId) async {
    var response =
        await _api.getAudioTrack(PlayerMessage()..playerId = playerId);
    return response.audioTrackNumber;
  }

  @override
  Future<void> setAudioTrack(int playerId, int audioTrackNumber) async {
    return await _api.setAudioTrack(AudioTrackMessage()
      ..playerId = playerId
      ..audioTrackNumber = audioTrackNumber);
  }

  @override
  Future<void> setAudioDelay(int playerId, int delay) async {
    return await _api.setAudioDelay(DelayMessage()
      ..playerId = playerId
      ..delay = delay);
  }

  @override
  Future<int?> getAudioDelay(int playerId) async {
    var response =
        await _api.getAudioDelay(PlayerMessage()..playerId = playerId);
    return response.delay;
  }

  @override
  Future<void> addAudioTrack(
    int playerId, {
    required String uri,
    required DataSourceType type,
    bool? isSelected,
  }) async {
    var message = AddAudioMessage();
    message.playerId = playerId;
    message.uri = uri;
    message.type = type.index;
    message.isSelected = isSelected;
    return await _api.addAudioTrack(message);
  }

  @override
  Future<int?> getVideoTracksCount(int playerId) async {
    var response =
        await _api.getVideoTracksCount(PlayerMessage()..playerId = playerId);
    return response.count;
  }

  @override
  Future<Map<int, String>> getVideoTracks(int playerId) async {
    var response =
        await _api.getVideoTracks(PlayerMessage()..playerId = playerId);
    return response.videos!.cast<int, String>();
  }

  @override
  Future<void> setVideoTrack(int playerId, int videoTrackNumber) async {
    return await _api.setVideoTrack(VideoTrackMessage()
      ..playerId = playerId
      ..videoTrackNumber = videoTrackNumber);
  }

  @override
  Future<int?> getVideoTrack(int playerId) async {
    var response =
        await _api.getVideoTrack(PlayerMessage()..playerId = playerId);
    return response.videoTrackNumber;
  }

  @override
  Future<void> setVideoScale(int playerId, double scale) async {
    return await _api.setVideoScale(VideoScaleMessage()
      ..playerId = playerId
      ..scale = scale);
  }

  @override
  Future<double?> getVideoScale(int playerId) async {
    var response =
        await _api.getVideoScale(PlayerMessage()..playerId = playerId);
    return response.scale;
  }

  @override
  Future<void> setVideoAspectRatio(int playerId, String aspect) async {
    return await _api.setVideoAspectRatio(VideoAspectRatioMessage()
      ..playerId = playerId
      ..aspectRatio = aspect);
  }

  @override
  Future<String?> getVideoAspectRatio(int playerId) async {
    var response =
        await _api.getVideoAspectRatio(PlayerMessage()..playerId = playerId);
    return response.aspectRatio;
  }

  String base64Encode(List<int> value) => base64.encode(value);
  Uint8List base64Decode(String source) => base64.decode(source);

  @override
  Future<Uint8List> takeSnapshot(int playerId) async {
    var response =
        await _api.takeSnapshot(PlayerMessage()..playerId = playerId);
    var base64String = response.snapshot!;
    var imageBytes = base64Decode(base64.normalize(base64String));
    return imageBytes;
  }

  @override
  Future<List<String>> getAvailableRendererServices(int playerId) async {
    var response = await _api
        .getAvailableRendererServices(PlayerMessage()..playerId = playerId);
    return response.services!.cast<String>();
  }

  @override
  Future<void> startRendererScanning(int playerId,
      {String? rendererService}) async {
    return await _api.startRendererScanning(RendererScanningMessage()
      ..playerId = playerId
      ..rendererService = rendererService ?? '');
  }

  @override
  Future<void> stopRendererScanning(int playerId) async {
    return await _api
        .stopRendererScanning(PlayerMessage()..playerId = playerId);
  }

  @override
  Future<Map<String, String>> getRendererDevices(int playerId) async {
    var response =
        await _api.getRendererDevices(PlayerMessage()..playerId = playerId);
    return response.rendererDevices!.cast<String, String>();
  }

  @override
  Future<void> castToRenderer(int playerId, String rendererDevice) async {
    return await _api.castToRenderer(RenderDeviceMessage()
      ..playerId = playerId
      ..rendererDevice = rendererDevice);
  }

  @override
  Stream<VlcRendererEvent> rendererEventsFor(int playerId) {
    return _rendererEventChannelFor(playerId).receiveBroadcastStream().map(
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
  Future<bool?> startRecording(int playerId, String saveDirectory) async {
    var response = await _api.startRecording(RecordMessage()
      ..playerId = playerId
      ..saveDirectory = saveDirectory);
    return response.result;
  }

  @override
  Future<bool?> stopRecording(int playerId) async {
    var response =
        await _api.stopRecording(PlayerMessage()..playerId = playerId);
    return response.result;
  }
}
