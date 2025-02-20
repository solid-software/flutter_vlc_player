import 'package:pigeon/pigeon_lib.dart';

//ignore: prefer_match_file_name
class ViewMessage {
  int? viewId;
}

class CreateMessage {
  int? viewId;
  String? uri;
  int? type;
  String? packageName;
  bool? autoPlay;
  int? hwAcc;
  List<String>? options;
}

class SetMediaMessage {
  int? viewId;
  String? uri;
  int? type;
  String? packageName;
  bool? autoPlay;
  int? hwAcc;
}

class BooleanMessage {
  int? viewId;
  bool? result;
}

class LoopingMessage {
  int? viewId;
  bool? isLooping;
}

class VolumeMessage {
  int? viewId;
  int? volume;
}

class PlaybackSpeedMessage {
  int? viewId;
  double? speed;
}

class PositionMessage {
  int? viewId;
  int? position;
}

class DurationMessage {
  int? viewId;
  int? duration;
}

class DelayMessage {
  int? viewId;
  int? delay;
}

class TrackCountMessage {
  int? viewId;
  int? count;
}

class SnapshotMessage {
  int? viewId;
  String? snapshot;
}

class SpuTracksMessage {
  int? viewId;
  Map<Object?, Object?>? subtitles;
}

class SpuTrackMessage {
  int? viewId;
  int? spuTrackNumber;
}

class AddSubtitleMessage {
  int? viewId;
  String? uri;
  int? type;
  bool? isSelected;
}

class AudioTracksMessage {
  int? viewId;
  Map<Object?, Object?>? audios;
}

class AudioTrackMessage {
  int? viewId;
  int? audioTrackNumber;
}

class AddAudioMessage {
  int? viewId;
  String? uri;
  int? type;
  bool? isSelected;
}

class VideoTracksMessage {
  int? viewId;
  Map<Object?, Object?>? videos;
}

class VideoTrackMessage {
  int? viewId;
  int? videoTrackNumber;
}

class VideoScaleMessage {
  int? viewId;
  double? scale;
}

class VideoAspectRatioMessage {
  int? viewId;
  String? aspectRatio;
}

class RendererServicesMessage {
  int? viewId;
  List<String>? services;
}

class RendererScanningMessage {
  int? viewId;
  String? rendererService;
}

class RendererDevicesMessage {
  int? viewId;
  Map<Object?, Object?>? rendererDevices;
}

class RenderDeviceMessage {
  int? viewId;
  String? rendererDevice;
}

class RecordMessage {
  int? viewId;
  String? saveDirectory;
}

@HostApi(dartHostTestHandler: 'TestHostVlcPlayerApi')
abstract class VlcPlayerApi {
  void initialize();
  void create(CreateMessage msg);
  void dispose(ViewMessage msg);
  // general methods
  void setStreamUrl(SetMediaMessage msg);
  void play(ViewMessage msg);
  void pause(ViewMessage msg);
  void stop(ViewMessage msg);
  BooleanMessage isPlaying(ViewMessage msg);
  BooleanMessage isSeekable(ViewMessage msg);
  void setLooping(LoopingMessage msg);
  void seekTo(PositionMessage msg);
  PositionMessage position(ViewMessage msg);
  DurationMessage duration(ViewMessage msg);
  void setVolume(VolumeMessage msg);
  VolumeMessage getVolume(ViewMessage msg);
  void setPlaybackSpeed(PlaybackSpeedMessage msg);
  PlaybackSpeedMessage getPlaybackSpeed(ViewMessage msg);
  SnapshotMessage takeSnapshot(ViewMessage msg);
  // captions & subtitles methods
  TrackCountMessage getSpuTracksCount(ViewMessage msg);
  SpuTracksMessage getSpuTracks(ViewMessage msg);
  void setSpuTrack(SpuTrackMessage msg);
  SpuTrackMessage getSpuTrack(ViewMessage msg);
  void setSpuDelay(DelayMessage msg);
  DelayMessage getSpuDelay(ViewMessage msg);
  void addSubtitleTrack(AddSubtitleMessage msg);
  // audios methods
  TrackCountMessage getAudioTracksCount(ViewMessage msg);
  AudioTracksMessage getAudioTracks(ViewMessage msg);
  void setAudioTrack(AudioTrackMessage msg);
  AudioTrackMessage getAudioTrack(ViewMessage msg);
  void setAudioDelay(DelayMessage msg);
  DelayMessage getAudioDelay(ViewMessage msg);
  void addAudioTrack(AddAudioMessage msg);
  // videos methods
  TrackCountMessage getVideoTracksCount(ViewMessage msg);
  VideoTracksMessage getVideoTracks(ViewMessage msg);
  void setVideoTrack(VideoTrackMessage msg);
  VideoTrackMessage getVideoTrack(ViewMessage msg);
  void setVideoScale(VideoScaleMessage msg);
  VideoScaleMessage getVideoScale(ViewMessage msg);
  void setVideoAspectRatio(VideoAspectRatioMessage msg);
  VideoAspectRatioMessage getVideoAspectRatio(ViewMessage msg);
  // casts & renderers methods
  RendererServicesMessage getAvailableRendererServices(ViewMessage msg);
  void startRendererScanning(RendererScanningMessage msg);
  void stopRendererScanning(ViewMessage msg);
  RendererDevicesMessage getRendererDevices(ViewMessage msg);
  void castToRenderer(RenderDeviceMessage msg);
  // recording methods
  BooleanMessage startRecording(RecordMessage msg);
  BooleanMessage stopRecording(ViewMessage msg);
}

// to make changes effect, must run "flutter pub run pigeon \--input pigeons/messages.dart --dart_null_safety"
void configurePigeon(PigeonOptions opts) {
  opts.dartOut =
      '../flutter_vlc_player_platform_interface/lib/src/messages/messages.dart';
  opts.objcHeaderOut = 'ios/Classes/messages.h';
  opts.objcSourceOut = 'ios/Classes/messages.m';
  opts.objcOptions?.prefix = '';
  opts.javaOut =
      'android/src/main/java/software/solid/fluttervlcplayer/Messages.java';
  opts.javaOptions?.package = 'software.solid.fluttervlcplayer';
}
