import 'dart:ui';

import 'package:flutter_vlc_player_platform_interface/src/enums/media_event_type.dart';

// ignore: prefer_match_file_name
class VlcMediaEvent {
  /// The type of the event.
  final VlcMediaEventType mediaEventType;

  /// Size of the video.
  ///
  /// Only used if [eventType] is [VlcMediaEventType.buffering, VlcMediaEventType.playing].
  final Size? size;

  /// Duration of the video.
  ///
  /// Only used if [eventType] is [VlcMediaEventType.buffering, VlcMediaEventType.playing].
  final Duration? duration;

  /// Position of the video.
  ///
  /// Only used if [eventType] is [VlcMediaEventType.buffering].
  final Duration? position;

  /// Playback speed of the video.
  ///
  /// Only used if [eventType] is [VlcMediaEventType.buffering, VlcMediaEventType.playing].
  final double? playbackSpeed;

  /// The number of available audio tracks embedded in media except the original audio.
  ///
  /// Only used if [eventType] is [VlcMediaEventType.buffering, VlcMediaEventType.playing].
  final int? audioTracksCount;

  /// The active audio track index. "-1" means audio is disabled.
  ///
  /// Only used if [eventType] is [VlcMediaEventType.buffering, VlcMediaEventType.playing].
  final int? activeAudioTrack;

  /// Returns the number of available subtitle tracks embedded in media.
  ///
  /// Only used if [eventType] is [VlcMediaEventType.buffering, VlcMediaEventType.playing].
  final int? spuTracksCount;

  /// Returns the active subtitle track index. "-1" means subtitle is disabled.
  ///
  /// Only used if [eventType] is [VlcMediaEventType.buffering, VlcMediaEventType.playing].
  final int? activeSpuTrack;

  /// Returns the buffer percent of media.
  ///
  /// Only used if [eventType] is [VlcMediaEventType.buffering].
  final double? bufferPercent;

  /// Returns the playing state of media.
  ///
  /// Only used if [eventType] is [VlcMediaEventType.buffering].
  final bool? isPlaying;

  /// Returns the recording state of media.
  ///
  /// Only used if [eventType] is [VlcMediaEventType.playing, VlcMediaEventType.recording].
  final bool? isRecording;

  /// Returns the recording path of media.
  ///
  /// Only used if [eventType] is [VlcMediaEventType.recording].
  final String? recordPath;

  /// Creates an instance of [VlcMediaEvent].
  ///
  /// The [mediaEventType] argument is required.
  ///
  /// Depending on the [mediaEventType], the [duration], [size]
  /// arguments can be null.
  VlcMediaEvent({
    required this.mediaEventType,
    this.duration,
    this.size,
    this.position,
    this.playbackSpeed,
    this.audioTracksCount,
    this.activeAudioTrack,
    this.spuTracksCount,
    this.activeSpuTrack,
    this.bufferPercent,
    this.isPlaying,
    this.isRecording,
    this.recordPath,
  });
}
