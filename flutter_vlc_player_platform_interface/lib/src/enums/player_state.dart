/// Indicates the current player state.
enum VlcPlayerState {
  /// The player is currently stopped.
  STOPPED,

  /// The player is currently paused.
  PAUSED,

  /// The player is currently buffering.
  BUFFERING,

  /// The player is currently playing.
  PLAYING,

  /// The player is encountered an error.
  ERROR,
}
