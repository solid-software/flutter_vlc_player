class VlcVideoOptions {
  final List<String> options;

  VlcVideoOptions(this.options);

  /// Drop late frames
  /// This drops frames that are late (arrive to the video output after
  /// their intended display date).
  static String dropLateFrames(bool enable) {
    return enable ? '--drop-late-frames' : '--no-drop-late-frames';
  }

  /// Skip frames
  /// Enables framedropping on MPEG2 stream. Framedropping occurs when your
  /// computer is not powerful enough
  static String skipFrames(bool enable) {
    return enable ? '--skip-frames' : '--no-skip-frames';
  }
}
