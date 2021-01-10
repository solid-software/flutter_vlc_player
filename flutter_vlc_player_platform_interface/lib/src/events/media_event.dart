import 'dart:ui';

import 'package:meta/meta.dart';

import '../enums/media_event_type.dart';

class VlcMediaEvent {
  /// Creates an instance of [VlcMediaEvent].
  ///
  /// The [mediaEventType] argument is required.
  ///
  /// Depending on the [mediaEventType], the [duration], [size]
  /// arguments can be null.
  VlcMediaEvent({
    @required this.mediaEventType,
    this.duration,
    this.size,
    this.position,
    this.playbackSpeed,
    this.audioTracksCount,
    this.activeAudioTrack,
    this.spuTracksCount,
    this.activeSpuTrack,
    this.bufferPercent,
  });

  /// The type of the event.
  final VlcMediaEventType mediaEventType;

  /// Size of the video.
  ///
  /// Only used if [eventType] is [VlcMediaEventType.INITIALIZED].
  final Size size;

  /// Duration of the video.
  ///
  /// Only used if [eventType] is [VlcMediaEventType.INITIALIZED].
  final Duration duration;

  /// Position of the video.
  ///
  /// Only used if [eventType] is [VlcMediaEventType.INITIALIZED, VlcMediaEventType.PLAYING].
  final Duration position;

  /// Playback speed of the video.
  ///
  /// Only used if [eventType] is [VlcMediaEventType.PLAYING].
  final double playbackSpeed;

  /// The number of available audio tracks embedded in media except the original audio.
  ///
  /// Only used if [eventType] is [VlcMediaEventType.PLAYING].
  final int audioTracksCount;

  /// The active audio track index. "-1" means audio is disabled.
  ///
  /// Only used if [eventType] is [VlcMediaEventType.PLAYING].
  final int activeAudioTrack;

  /// Returns the number of available subtitle tracks embedded in media.
  ///
  /// Only used if [eventType] is [VlcMediaEventType.PLAYING].
  final int spuTracksCount;

  /// Returns the active subtitle track index. "-1" means subtitle is disabled.
  ///
  /// Only used if [eventType] is [VlcMediaEventType.PLAYING].
  final int activeSpuTrack;

  /// Returns the buffer percent of media.
  ///
  /// Only used if [eventType] is [VlcMediaEventType.BUFFERING].
  final double bufferPercent;
}
