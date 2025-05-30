import 'package:pigeon/pigeon.dart';

// to make changes effect, must run "dart run pigeon --input pigeons/messages.dart"
@ConfigurePigeon(
  PigeonOptions(
    dartOut:
        '../flutter_vlc_player_platform_interface/lib/src/messages/messages.dart',
    swiftOut: 'ios/Classes/Messages.swift',
    javaOut:
        'android/src/main/java/software/solid/fluttervlcplayer/Messages.java',
    javaOptions: JavaOptions(package: 'software.solid.fluttervlcplayer'),
  ),
)
//ignore: prefer_match_file_name
class CreateMessage {
  final int playerId;
  final String uri;
  final int type;
  final String? packageName;
  final bool autoPlay;
  final int? hwAcc;
  final List<String> options;

  const CreateMessage({
    required this.playerId,
    required this.uri,
    required this.type,
    required this.packageName,
    required this.autoPlay,
    required this.hwAcc,
    required this.options,
  });
}

class SetMediaMessage {
  final int playerId;
  final String uri;
  final int type;
  final String? packageName;
  final bool autoPlay;
  final int? hwAcc;

  const SetMediaMessage({
    required this.playerId,
    required this.uri,
    required this.type,
    required this.packageName,
    required this.autoPlay,
    required this.hwAcc,
  });
}

class SpuTracksMessage {
  final int playerId;
  final Map<Object, Object> subtitles;

  const SpuTracksMessage({required this.playerId, required this.subtitles});
}

class AddSubtitleMessage {
  final int playerId;
  final String uri;
  final int type;
  final bool isSelected;

  const AddSubtitleMessage({
    required this.playerId,
    required this.uri,
    required this.type,
    required this.isSelected,
  });
}

class AddAudioMessage {
  final int playerId;
  final String uri;
  final int type;
  final bool isSelected;

  const AddAudioMessage({
    required this.playerId,
    required this.uri,
    required this.type,
    required this.isSelected,
  });
}

@HostApi(dartHostTestHandler: 'TestHostVlcPlayerApi')
abstract class VlcPlayerApi {
  void initialize();

  void create(CreateMessage msg);

  void dispose(int playerId);

  // general methods
  void setStreamUrl(SetMediaMessage msg);

  void play(int playerId);

  void pause(int playerId);

  void stop(int playerId);

  bool isPlaying(int playerId);

  bool isSeekable(int playerId);

  void setLooping(int playerId, bool isLooping);

  void seekTo(int playerId, int position);

  int position(int playerId);

  int duration(int playerId);

  void setVolume(int playerId, int volume);

  int getVolume(int playerId);

  void setPlaybackSpeed(int playerId, double speed);

  double getPlaybackSpeed(int playerId);

  String? takeSnapshot(int playerId);

  // captions & subtitles methods

  int getSpuTracksCount(int playerId);

  Map<int, String> getSpuTracks(int playerId);

  void setSpuTrack(int playerId, int spuTrackNumber);

  int getSpuTrack(int playerId);

  void setSpuDelay(int playerId, int delay);

  int getSpuDelay(int playerId);

  void addSubtitleTrack(AddSubtitleMessage msg);

  // audios methods
  int getAudioTracksCount(int playerId);

  Map<int, String> getAudioTracks(int playerId);

  void setAudioTrack(int playerId, int audioTrackNumber);

  int getAudioTrack(int playerId);

  void setAudioDelay(int playerId, int delay);

  int getAudioDelay(int playerId);

  void addAudioTrack(AddAudioMessage msg);

  // videos methods
  int getVideoTracksCount(int playerId);

  Map<int, String> getVideoTracks(int playerId);

  void setVideoTrack(int playerId, int videoTrackNumber);

  int getVideoTrack(int playerId);

  void setVideoScale(int playerId, double scale);

  double getVideoScale(int playerId);

  void setVideoAspectRatio(int playerId, String aspectRatio);

  String getVideoAspectRatio(int playerId);

  // casts & renderers methods
  List<String> getAvailableRendererServices(int playerId);

  void startRendererScanning(int playerId, String rendererService);

  void stopRendererScanning(int playerId);

  Map<String, String> getRendererDevices(int playerId);

  void castToRenderer(int playerId, String rendererId);

  // recording methods
  bool startRecording(int playerId, String saveDirectory);

  bool stopRecording(int playerId);
}
