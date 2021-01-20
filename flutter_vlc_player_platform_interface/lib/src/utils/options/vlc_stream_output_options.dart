class VlcStreamOutputOptions {
  final List<String> options;

  VlcStreamOutputOptions(this.options);

  /// Stream output muxer caching (ms)
  /// This allow you to configure the initial caching amount for stream
  /// output muxer. This value should be set in milliseconds.
  static String soutMuxCaching(int millis) {
    return '--sout-mux-caching=$millis';
  }
}
