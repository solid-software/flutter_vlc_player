class VlcAudioOptions {
  final List<String> options;

  VlcAudioOptions(this.options);

  /// Enable/Disable time stretching audio
  /// This allows playing audio at lower or higher speed without affecting
  /// the audio pitch
  static String audioTimeStretch(bool enable) {
    return enable ? '--audio-time-stretch' : '--no-audio-time-stretch';
  }
}
