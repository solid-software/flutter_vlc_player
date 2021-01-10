import 'vlc_audio_options.dart';
import 'vlc_rtp_options.dart';
import 'vlc_stream_output_options.dart';
import 'vlc_video_options.dart';
import 'vlc_advanced_options.dart';

class VlcPlayerOptions {
  VlcPlayerOptions({
    this.advanced,
    this.audio,
    this.video,
    this.rtp,
    this.sout,
    this.extras,
  });

  final VlcAdvancedOptions advanced;
  final VlcAudioOptions audio;
  final VlcVideoOptions video;
  final VlcRtpOptions rtp;
  final VlcStreamOutputOptions sout;
  final List<String> extras;

  List<String> get() {
    List<String> options = List<String>();
    if (advanced != null) options.addAll(advanced.options);
    if (audio != null) options.addAll(audio.options);
    if (video != null) options.addAll(video.options);
    if (rtp != null) options.addAll(rtp.options);
    if (sout != null) options.addAll(sout.options);
    if (extras != null) options.addAll(extras);
    return options;
  }
}
