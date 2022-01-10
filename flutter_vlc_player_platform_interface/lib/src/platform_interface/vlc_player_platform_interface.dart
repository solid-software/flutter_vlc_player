import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import '../../flutter_vlc_player_platform_interface.dart';
import '../method_channel/method_channel_vlc_player.dart';

/// The interface that implementations of vlc must implement.
///
/// Platform implementations should extend this class rather than implement it as `vlc`
/// does not consider newly added methods to be breaking changes.
abstract class VlcPlayerPlatform extends PlatformInterface {
  /// Constructs a VlcPlayerPlatform.
  VlcPlayerPlatform() : super(token: _token);

  static final Object _token = Object();

  static VlcPlayerPlatform _instance = MethodChannelVlcPlayer();

  /// The default instance of [VlcPlayerPlatform] to use.
  ///
  /// Defaults to [MethodChannelVlcPlayer].
  static VlcPlayerPlatform get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [VlcPlayerPlatform] when they register themselves.
  static set instance(VlcPlayerPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns a widget displaying the video.
  Widget buildView(PlatformViewCreatedCallback onPlatformViewCreated) {
    throw _unimplemented('buildView');
  }

  /// Initializes the platform interface and disposes all existing players.
  ///
  /// This method is called when the plugin is first initialized
  /// and on every full restart.
  Future<void> init() {
    throw _unimplemented('init');
  }

  /// Clears one video.
  Future<void> dispose(int playerId) {
    throw _unimplemented('dispose');
  }

  /// Creates an instance of a vlc player
  Future<void> create({
    required int playerId,
    required String uri,
    required DataSourceType type,
    String? package,
    bool? autoPlay,
    HwAcc? hwAcc,
    VlcPlayerOptions? options,
  }) {
    throw _unimplemented('create');
  }

  /// Returns a Stream of [VlcMediaEvent]s.
  Stream<VlcMediaEvent> mediaEventsFor(int playerId) {
    throw _unimplemented('mediaEventsFor');
  }

  /// Set/Change video streaming url
  Future<void> setStreamUrl(
    int playerId, {
    required String uri,
    required DataSourceType type,
    String? package,
    bool? autoPlay,
    HwAcc? hwAcc,
  }) {
    throw _unimplemented('setStreamUrl');
  }

  /// Sets the looping attribute of the video.
  Future<void> setLooping(int playerId, bool looping) {
    throw _unimplemented('setLooping');
  }

  /// Starts the video playback.
  Future<void> play(int playerId) {
    throw _unimplemented('play');
  }

  /// Pauses the video playback.
  Future<void> pause(int playerId) {
    throw _unimplemented('pause');
  }

  /// Stops the video playback.
  Future<void> stop(int playerId) {
    throw _unimplemented('stop');
  }

  /// Returns true if media is playing.
  Future<bool?> isPlaying(int playerId) {
    throw _unimplemented('isPlaying');
  }

  /// Returns true if media is seekable.
  Future<bool?> isSeekable(int playerId) {
    throw _unimplemented('isSeekable');
  }

  /// Same as seekTo
  /// Sets the video position to a [Duration] from the start.
  Future<void> setTime(int playerId, Duration position) {
    throw _unimplemented('setTime');
  }

  /// Sets the video position to a [Duration] from the start.
  Future<void> seekTo(int playerId, Duration position) {
    throw _unimplemented('seekTo');
  }

  /// Same as getPosition
  /// Gets the video position as [Duration] from the start.
  Future<Duration> getTime(int playerId) {
    throw _unimplemented('getTime');
  }

  /// Gets the video position as [Duration] from the start.
  Future<Duration> getPosition(int playerId) {
    throw _unimplemented('getPosition');
  }

  /// Returns duration/length of loaded video in milliseconds.
  Future<Duration> getDuration(int playerId) {
    throw _unimplemented('getDuration');
  }

  /// Sets the volume to a range between 0 and 100.
  Future<void> setVolume(int playerId, int volume) {
    throw _unimplemented('setVolume');
  }

  /// Returns current vlc volume level within a range between 0 and 100.
  Future<int?> getVolume(int playerId) {
    throw _unimplemented('getVolume');
  }

  /// Sets the playback speed to a [speed] value indicating the playback rate.
  Future<void> setPlaybackSpeed(int playerId, double speed) {
    throw _unimplemented('setPlaybackSpeed');
  }

  /// Returns the vlc playback speed.
  Future<double?> getPlaybackSpeed(int playerId) {
    throw _unimplemented('getPlaybackSpeed');
  }

  /// Return the number of subtitle tracks (both embedded and inserted)
  Future<int?> getSpuTracksCount(int playerId) {
    throw _unimplemented('getSpuTracksCount');
  }

  /// Return all subtitle tracks as array of <Int, String>
  /// The key parameter is the index of subtitle which is used for changing subtitle and the value is the display name of subtitle
  Future<Map<int, String>> getSpuTracks(int playerId) {
    throw _unimplemented('getSpuTracks');
  }

  /// Change active subtitle index (set -1 to disable subtitle).
  /// [spuTrackNumber] - the subtitle index obtained from getSpuTracks()
  Future<void> setSpuTrack(int playerId, int spuTrackNumber) {
    throw _unimplemented('setSpuTrack');
  }

  /// Returns the selected spu track index
  Future<int?> getSpuTrack(int playerId) {
    throw _unimplemented('getSpuTrack');
  }

  /// [delay] - the amount of time in milliseconds which vlc subtitle should be delayed.
  /// (support both positive & negative delay value)
  Future<void> setSpuDelay(int playerId, int delay) {
    throw _unimplemented('setSpuDelay');
  }

  /// Returns the amount of subtitle time delay.
  Future<int?> getSpuDelay(int playerId) {
    throw _unimplemented('getSpuDelay');
  }

  /// Add extra subtitle to media.
  /// [uri] - URL of subtitle
  /// [type] - Set type of subtitle
  /// [isSelected] - Set true if you wanna force the added subtitle to start display on media.
  Future<void> addSubtitleTrack(
    int playerId, {
    required String uri,
    required DataSourceType type,
    bool? isSelected,
  }) {
    throw _unimplemented('addSubtitleTrack');
  }

  /// Returns the number of audio tracks
  Future<int?> getAudioTracksCount(int playerId) {
    throw _unimplemented('getAudioTracksCount');
  }

  /// Returns all audio tracks as array of <Int, String>
  /// The key parameter is the index of audio track which is used for changing audio and the value is the display name of audio
  Future<Map<int, String>> getAudioTracks(int playerId) {
    throw _unimplemented('getAudioTracks');
  }

  /// Returns selected audio track index
  Future<int?> getAudioTrack(int playerId) {
    throw _unimplemented('getAudioTrack');
  }

  /// Change active audio track index (set -1 to mute).
  /// [audioTrackNumber] - the audio track index obtained from getAudioTracks()
  Future<void> setAudioTrack(int playerId, int audioTrackNumber) {
    throw _unimplemented('setAudioTrack');
  }

  /// [delay] - the amount of time in milliseconds which vlc audio should be delayed.
  /// (support both positive & negative value)
  Future<void> setAudioDelay(int playerId, int delay) {
    throw _unimplemented('setAudioDelay');
  }

  /// Returns the amount of audio track time delay.
  Future<int?> getAudioDelay(int playerId) {
    throw _unimplemented('getAudioDelay');
  }

  /// Add extra audio to media.
  /// [uri] - uri of audio
  /// [type] - type of subtitle (network or file)
  /// [isSelected] - Set true if you wanna force the added subtitle to start display on media.
  Future<void> addAudioTrack(
    int playerId, {
    required String uri,
    required DataSourceType type,
    bool? isSelected,
  }) {
    throw _unimplemented('addAudioTrack');
  }

  /// Returns the number of video tracks
  Future<int?> getVideoTracksCount(int playerId) {
    throw _unimplemented('getVideoTracksCount');
  }

  /// Returns all video tracks as array of <Int, String>
  /// The key parameter is the index of video track and the value is the display name of video track
  Future<Map<int, String>> getVideoTracks(int playerId) {
    throw _unimplemented('getVideoTracks');
  }

  /// Change active video track index.
  /// [videoTrackNumber] - the video track index obtained from getVideoTracks()
  Future<void> setVideoTrack(int playerId, int videoTrackNumber) {
    throw _unimplemented('setVideoTrack');
  }

  /// Returns selected video track index
  Future<int?> getVideoTrack(int playerId) {
    throw _unimplemented('getVideoTrack');
  }

  /// [scale] - the video scale value
  /// Set video scale
  Future<void> setVideoScale(int playerId, double scale) {
    throw _unimplemented('setVideoScale');
  }

  /// Returns video scale
  Future<double?> getVideoScale(int playerId) {
    throw _unimplemented('getVideoScale');
  }

  /// [aspect] - the video apect ratio like '16:9'
  /// Set video aspect ratio
  Future<void> setVideoAspectRatio(int playerId, String aspect) {
    throw _unimplemented('setVideoAspectRatio');
  }

  /// Returns video aspect ratio
  Future<String?> getVideoAspectRatio(int playerId) {
    throw _unimplemented('getVideoAspectRatio');
  }

  /// Returns binary data for a snapshot of the media at the current frame.
  Future<Uint8List> takeSnapshot(int playerId) {
    throw _unimplemented('takeSnapshot');
  }

  /// Returns list of all avialble vlc renderer services
  Future<List<String>> getAvailableRendererServices(int playerId) {
    throw _unimplemented('getAvailableRendererServices');
  }

  /// Start vlc renderer discovery to find external display devices (chromecast)
  Future<void> startRendererScanning(int playerId, {String? rendererService}) {
    throw _unimplemented('startRendererScanning');
  }

  /// Stop vlc renderer and cast discovery
  Future<void> stopRendererScanning(int playerId) {
    throw _unimplemented('stopRendererScanning');
  }

  /// Returns all detected renderer devices as array of <String, String>
  /// The key parameter is the name of renderer device and the value is the display name of renderer device
  Future<Map<String, String>> getRendererDevices(int playerId) {
    throw _unimplemented('getRendererDevices');
  }

  /// [rendererDevice] - name of renderer device
  /// Start vlc video casting to the renderered device.
  ///  Set null if you wanna to stop video casting.
  Future<void> castToRenderer(int playerId, String rendererDevice) {
    throw _unimplemented('castToRenderer');
  }

  /// Returns a Stream of [VlcRendererEvent]s.
  Stream<VlcRendererEvent> rendererEventsFor(int playerId) {
    throw _unimplemented('rendererEventsFor');
  }

  /// Returns true if vlc starts recording.
  Future<bool?> startRecording(int playerId, String saveDirectory) {
    throw _unimplemented('startRecording');
  }

  /// Returns true if vlc stops recording.
  Future<bool?> stopRecording(int playerId) {
    throw _unimplemented('stopRecording');
  }

  Object _unimplemented(String methodName) {
    return UnimplementedError('$methodName has not been implemented.');
  }
}
