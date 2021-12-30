import 'package:pigeon/pigeon_lib.dart';

class PlayerMessage {
  int? playerId;
}

class CreateMessage {
  int? playerId;
  String? uri;
  int? type;
  String? packageName;
  bool? autoPlay;
  int? hwAcc;
  List<String>? options;
}

class SetMediaMessage {
  int? playerId;
  String? uri;
  int? type;
  String? packageName;
  bool? autoPlay;
  int? hwAcc;
}

class BooleanMessage {
  int? playerId;
  bool? result;
}

class LoopingMessage {
  int? playerId;
  bool? isLooping;
}

class VolumeMessage {
  int? playerId;
  int? volume;
}

class PlaybackSpeedMessage {
  int? playerId;
  double? speed;
}

class PositionMessage {
  int? playerId;
  int? position;
}

class DurationMessage {
  int? playerId;
  int? duration;
}

class DelayMessage {
  int? playerId;
  int? delay;
}

class TrackCountMessage {
  int? playerId;
  int? count;
}

class SnapshotMessage {
  int? playerId;
  String? snapshot;
}

class SpuTracksMessage {
  int? playerId;
  Map? subtitles;
}

class SpuTrackMessage {
  int? playerId;
  int? spuTrackNumber;
}

class AddSubtitleMessage {
  int? playerId;
  String? uri;
  int? type;
  bool? isSelected;
}

class AudioTracksMessage {
  int? playerId;
  Map? audios;
}

class AudioTrackMessage {
  int? playerId;
  int? audioTrackNumber;
}

class AddAudioMessage {
  int? playerId;
  String? uri;
  int? type;
  bool? isSelected;
}

class VideoTracksMessage {
  int? playerId;
  Map? videos;
}

class VideoTrackMessage {
  int? playerId;
  int? videoTrackNumber;
}

class VideoScaleMessage {
  int? playerId;
  double? scale;
}

class VideoAspectRatioMessage {
  int? playerId;
  String? aspectRatio;
}

class RendererServicesMessage {
  int? playerId;
  List<String>? services;
}

class RendererScanningMessage {
  int? playerId;
  String? rendererService;
}

class RendererDevicesMessage {
  int? playerId;
  Map? rendererDevices;
}

class RenderDeviceMessage {
  int? playerId;
  String? rendererDevice;
}

class RecordMessage {
  int? playerId;
  String? saveDirectory;
}

@HostApi(dartHostTestHandler: 'TestHostVlcPlayerApi')
abstract class VlcPlayerApi {
  void initialize();
  void create(CreateMessage msg);
  void dispose(PlayerMessage msg);
  // general methods
  void setStreamUrl(SetMediaMessage msg);
  void play(PlayerMessage msg);
  void pause(PlayerMessage msg);
  void stop(PlayerMessage msg);
  BooleanMessage isPlaying(PlayerMessage msg);
  BooleanMessage isSeekable(PlayerMessage msg);
  void setLooping(LoopingMessage msg);
  void seekTo(PositionMessage msg);
  PositionMessage position(PlayerMessage msg);
  DurationMessage duration(PlayerMessage msg);
  void setVolume(VolumeMessage msg);
  VolumeMessage getVolume(PlayerMessage msg);
  void setPlaybackSpeed(PlaybackSpeedMessage msg);
  PlaybackSpeedMessage getPlaybackSpeed(PlayerMessage msg);
  SnapshotMessage takeSnapshot(PlayerMessage msg);
  // captions & subtitles methods
  TrackCountMessage getSpuTracksCount(PlayerMessage msg);
  SpuTracksMessage getSpuTracks(PlayerMessage msg);
  void setSpuTrack(SpuTrackMessage msg);
  SpuTrackMessage getSpuTrack(PlayerMessage msg);
  void setSpuDelay(DelayMessage msg);
  DelayMessage getSpuDelay(PlayerMessage msg);
  void addSubtitleTrack(AddSubtitleMessage msg);
  // audios methods
  TrackCountMessage getAudioTracksCount(PlayerMessage msg);
  AudioTracksMessage getAudioTracks(PlayerMessage msg);
  void setAudioTrack(AudioTrackMessage msg);
  AudioTrackMessage getAudioTrack(PlayerMessage msg);
  void setAudioDelay(DelayMessage msg);
  DelayMessage getAudioDelay(PlayerMessage msg);
  void addAudioTrack(AddAudioMessage msg);
  // videos methods
  TrackCountMessage getVideoTracksCount(PlayerMessage msg);
  VideoTracksMessage getVideoTracks(PlayerMessage msg);
  void setVideoTrack(VideoTrackMessage msg);
  VideoTrackMessage getVideoTrack(PlayerMessage msg);
  void setVideoScale(VideoScaleMessage msg);
  VideoScaleMessage getVideoScale(PlayerMessage msg);
  void setVideoAspectRatio(VideoAspectRatioMessage msg);
  VideoAspectRatioMessage getVideoAspectRatio(PlayerMessage msg);
  // casts & renderers methods
  RendererServicesMessage getAvailableRendererServices(PlayerMessage msg);
  void startRendererScanning(RendererScanningMessage msg);
  void stopRendererScanning(PlayerMessage msg);
  RendererDevicesMessage getRendererDevices(PlayerMessage msg);
  void castToRenderer(RenderDeviceMessage msg);
  // recording methods
  BooleanMessage startRecording(RecordMessage msg);
  BooleanMessage stopRecording(PlayerMessage msg);
}

// to make changes effect, must run "flutter pub run pigeon \--input pigeons/messages.dart --dart_null_safety"
void configurePigeon(PigeonOptions opts) {
  opts.dartOut =
      '../flutter_vlc_player_platform_interface/lib/src/messages/messages.dart';
  opts.objcHeaderOut = 'ios/Classes/messages.h';
  opts.objcSourceOut = 'ios/Classes/messages.m';
  opts.objcOptions!.prefix = '';
  opts.javaOut =
      'android/src/main/java/software/solid/fluttervlcplayer/Messages.java';
  opts.javaOptions!.package = 'software.solid.fluttervlcplayer';
}
