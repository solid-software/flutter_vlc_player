class VlcAdvancedOptions {
  final List<String> options;

  VlcAdvancedOptions(this.options);

  /// Caching value for local files, in milliseconds.
  static String fileCaching(int millis) {
    return '--file-caching=$millis';
  }

  /// Caching value for network resources, in milliseconds.
  static String networkCaching(int millis) {
    return '--network-caching=$millis';
  }

  /// Caching value for cameras and microphones, in milliseconds.
  static String liveCaching(int millis) {
    return '--live-caching=$millis';
  }

  /// It is possible to disable the input clock synchronisation for
  /// real-time sources. Use this if you experience jerky playback of
  /// network streams. {-1 (Default), 0 (Disable), 1 (Enable)}
  static String clockSynchronization(int mode) {
    return '--clock-synchro=$mode';
  }

  /// This defines the maximum input delay jitter that the synchronization
  /// algorithms should try to compensate (in milliseconds).
  static String clockJitter(int millis) {
    return '--clock-jitter=$millis';
  }
}
