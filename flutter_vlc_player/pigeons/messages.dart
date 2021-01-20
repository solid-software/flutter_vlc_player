import 'package:pigeon/pigeon_lib.dart';

class TextureMessage {
  int textureId;
}

class CreateMessage {
  int textureId;
  String uri;
  int type;
  String packageName;
  bool autoPlay;
  int hwAcc;
  List<String> options;
}

class SetMediaMessage {
  int textureId;
  String uri;
  int type;
  String packageName;
  bool autoPlay;
  int hwAcc;
}

class BooleanMessage {
  int textureId;
  bool result;
}

class LoopingMessage {
  int textureId;
  bool isLooping;
}

class VolumeMessage {
  int textureId;
  int volume;
}

class PlaybackSpeedMessage {
  int textureId;
  double speed;
}

class PositionMessage {
  int textureId;
  int position;
}

class DurationMessage {
  int textureId;
  int duration;
}

class DelayMessage {
  int textureId;
  int delay;
}

class TrackCountMessage {
  int textureId;
  int count;
}

class SnapshotMessage {
  int textureId;
  String snapshot;
}

class SpuTracksMessage {
  int textureId;
  Map subtitles;
}

class SpuTrackMessage {
  int textureId;
  int spuTrackNumber;
}

class AddSubtitleMessage {
  int textureId;
  String uri;
  int type;
  bool isSelected;
}

class AudioTracksMessage {
  int textureId;
  Map audios;
}

class AudioTrackMessage {
  int textureId;
  int audioTrackNumber;
}

class AddAudioMessage {
  int textureId;
  String uri;
  int type;
  bool isSelected;
}

class VideoTracksMessage {
  int textureId;
  Map videos;
}

class VideoTrackMessage {
  int textureId;
  int videoTrackNumber;
}

class VideoScaleMessage {
  int textureId;
  double scale;
}

class VideoAspectRatioMessage {
  int textureId;
  String aspectRatio;
}

class RendererServicesMessage {
  int textureId;
  List<String> services;
}

class RendererScanningMessage {
  int textureId;
  String rendererService;
}

class RendererDevicesMessage {
  int textureId;
  Map rendererDevices;
}

class RenderDeviceMessage {
  int textureId;
  String rendererDevice;
}

@HostApi(dartHostTestHandler: 'TestHostVlcPlayerApi')
abstract class VlcPlayerApi {
  void initialize();
  void create(CreateMessage msg);
  void dispose(TextureMessage msg);
  // general
  void setStreamUrl(SetMediaMessage msg);
  void play(TextureMessage msg);
  void pause(TextureMessage msg);
  void stop(TextureMessage msg);
  BooleanMessage isPlaying(TextureMessage msg);
  void setLooping(LoopingMessage msg);
  void seekTo(PositionMessage msg);
  PositionMessage position(TextureMessage msg);
  DurationMessage duration(TextureMessage msg);
  void setVolume(VolumeMessage msg);
  VolumeMessage getVolume(TextureMessage msg);
  void setPlaybackSpeed(PlaybackSpeedMessage msg);
  PlaybackSpeedMessage getPlaybackSpeed(TextureMessage msg);
  SnapshotMessage takeSnapshot(TextureMessage msg);
  // captions & subtitles
  TrackCountMessage getSpuTracksCount(TextureMessage msg);
  SpuTracksMessage getSpuTracks(TextureMessage msg);
  void setSpuTrack(SpuTrackMessage msg);
  SpuTrackMessage getSpuTrack(TextureMessage msg);
  void setSpuDelay(DelayMessage msg);
  DelayMessage getSpuDelay(TextureMessage msg);
  void addSubtitleTrack(AddSubtitleMessage msg);
  // audios
  TrackCountMessage getAudioTracksCount(TextureMessage msg);
  AudioTracksMessage getAudioTracks(TextureMessage msg);
  void setAudioTrack(AudioTrackMessage msg);
  AudioTrackMessage getAudioTrack(TextureMessage msg);
  void setAudioDelay(DelayMessage msg);
  DelayMessage getAudioDelay(TextureMessage msg);
  void addAudioTrack(AddAudioMessage msg);
  // videos
  TrackCountMessage getVideoTracksCount(TextureMessage msg);
  VideoTracksMessage getVideoTracks(TextureMessage msg);
  void setVideoTrack(VideoTrackMessage msg);
  VideoTrackMessage getVideoTrack(TextureMessage msg);
  void setVideoScale(VideoScaleMessage msg);
  VideoScaleMessage getVideoScale(TextureMessage msg);
  void setVideoAspectRatio(VideoAspectRatioMessage msg);
  VideoAspectRatioMessage getVideoAspectRatio(TextureMessage msg);
  // casts & renderers
  RendererServicesMessage getAvailableRendererServices(TextureMessage msg);
  void startRendererScanning(RendererScanningMessage msg);
  void stopRendererScanning(TextureMessage msg);
  RendererDevicesMessage getRendererDevices(TextureMessage msg);
  void castToRenderer(RenderDeviceMessage msg);
}

// to make changes effect, must run "flutter pub run pigeon \--input pigeons/messages.dart --dart_null_safety"
void configurePigeon(PigeonOptions opts) {
  opts.dartOut =
      '../flutter_vlc_player_platform_interface/lib/src/messages/messages.dart';
  opts.objcHeaderOut = 'ios/Classes/messages.h';
  opts.objcSourceOut = 'ios/Classes/messages.m';
  opts.objcOptions.prefix = '';
  opts.javaOut =
      'android/src/main/java/software/solid/fluttervlcplayer/Messages.java';
  opts.javaOptions.package = 'software.solid.fluttervlcplayer';
}
