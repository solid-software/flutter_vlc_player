/// Indicates the current player state.
enum VlcPlayerState {
  /// The player is currently stopped.
  stopped,

  /// The player is currently paused.
  paused,

  /// The player is currently buffering.
  buffering,

  /// The player is currently playing.
  playing,

  /// The player is encountered an error.
  error,
}
