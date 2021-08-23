class VlcHttpOptions {
  final List<String> options;

  VlcHttpOptions(this.options);

  /// Automatically try to reconnect to the stream in case of a sudden disconnect.
  /// (default disabled)
  static String httpReconnect(bool enable) {
    return enable ? '--http-reconnect' : '--no-http-reconnect';
  }

  /// Keep reading a resource that keeps being updated.
  /// (default disabled)
  static String httpContinuous(bool enable) {
    return enable ? '--http-continuous' : '--no-http-continuous';
  }

  /// Forward cookies across HTTP redirections.
  /// (default enabled)
  static String httpForwardCookies(bool enable) {
    return enable ? '--http-forward-cookies' : '--no-http-forward-cookies';
  }

  /// Provide the referral URL, i.e. HTTP "Referer" (sic).
  static String httpReferrer(String referrer) {
    return '--http-referrer=' + referrer;
  }

  /// Override the name and version of the application as provided to the
  /// HTTP server, i.e. the HTTP "User-Agent". Name and version must be
  /// separated by a forward slash, e.g. "FooBar/1.2.3".
  static String httpUserAgent(String userAgent) {
    return '--http-user-agent=' + userAgent;
  }
}
