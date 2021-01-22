class VlcRtpOptions {
  final List<String> options;

  VlcRtpOptions(this.options);

  /// Use RTP over RTSP (TCP)
  static String rtpOverRtsp(bool enable) {
    return enable ? '--rtsp-tcp' : '--no-rtsp-tcp';
  }
}
