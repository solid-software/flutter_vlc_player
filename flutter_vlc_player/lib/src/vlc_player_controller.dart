import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_vlc_player/src/enums/playing_state.dart';
import 'package:flutter_vlc_player/src/vlc_app_life_cycle_observer.dart';
import 'package:flutter_vlc_player/src/vlc_player_platform.dart';
import 'package:flutter_vlc_player/src/vlc_player_value.dart';
import 'package:flutter_vlc_player_platform_interface/flutter_vlc_player_platform_interface.dart';

/// Controls a platform vlc player, and provides updates when the state is
/// changing.
///
/// Instances must be initialized with initialize.
///
/// The video is displayed in a Flutter app by creating a [VlcPlayer] widget.
///
/// To reclaim the resources used by the player call [dispose].
///
/// After [dispose] all further calls are ignored.
class VlcPlayerController extends ValueNotifier<VlcPlayerValue> {
  int _maxVolume = 100;
  bool _startAtSet = false;

  /// The URI to the video file. This will be in different formats depending on
  /// the [DataSourceType] of the original video.
  final String dataSource;

  /// Set hardware acceleration for player. Default is Automatic.
  final HwAcc hwAcc;

  /// Adds options to vlc. For more [https://wiki.videolan.org/VLC_command-line_help] If nothing is provided,
  /// vlc will run without any options set.
  final VlcPlayerOptions? options;

  /// The video should be played automatically.
  final bool autoPlay;

  /// Initialize vlc player when the platform is ready automatically
  final bool autoInitialize;

  /// Video start from [startAt]. When initialization is complete
  final Duration? startAt;

  /// Set keep playing video in background, when app goes in background.
  /// The default value is false.
  final bool allowBackgroundPlayback;

  /// This is a callback that will be executed once the platform view has been initialized.
  /// If you want the media to play as soon as the platform view has initialized, you could just call
  /// [VlcPlayerController.play] in this callback. (see the example).
  ///
  /// This member is deprecated, please, use the [addOnInitListener] method instead.
  final VoidCallback? _onInit;

  /// This is a callback that will be executed every time a new renderer cast device attached/detached
  /// It should be defined as "void Function(VlcRendererEventType, String, String)", where the VlcRendererEventType is an enum { attached, detached } and the next two String arguments are unique-id and name of renderer device, respectively.
  ///
  /// This member is deprecated, please, use the [addOnRendererEventListener] method instead.
  final RendererCallback? _onRendererHandler;

  /// Only set for [asset] videos. The package that the asset was loaded from.
  String? package;

  DataSourceType _dataSourceType;
  bool? _isReadyToInitialize;

  /// The viewId for this controller
  // ignore: avoid_late_keyword
  late int _viewId;

  /// List of onInit listeners
  final List<VoidCallback> _onInitListeners = [];

  /// List of onRenderer listeners
  final List<RendererCallback> _onRendererEventListeners = [];
  bool _isDisposed = false;

  VlcAppLifeCycleObserver? _lifeCycleObserver;

  /// Describes the type of data source this [VlcPlayerController]
  /// is constructed with.
  DataSourceType get dataSourceType => _dataSourceType;

  /// Determine if platform is ready to call initialize method
  bool? get isReadyToInitialize => _isReadyToInitialize;

  /// This is just exposed for testing. It shouldn't be used by anyone depending
  /// on the plugin.
  @visibleForTesting
  int? get viewId => _viewId;

  ///
  /// The name of the asset is given by the [dataSource] argument and must not be
  /// null. The [package] argument must be non-null when the asset comes from a
  /// package and null otherwise.
  VlcPlayerController.asset(
    this.dataSource, {
    this.autoInitialize = true,
    this.allowBackgroundPlayback = false,
    this.startAt,
    this.package,
    this.hwAcc = HwAcc.auto,
    this.autoPlay = true,
    this.options,
    @Deprecated('Please, use the addOnInitListener method instead.')
    VoidCallback? onInit,
    @Deprecated('Please, use the addOnRendererEventListener method instead.')
    RendererCallback? onRendererHandler,
  }) : _dataSourceType = DataSourceType.asset,
       _onInit = onInit,
       _onRendererHandler = onRendererHandler,
       super(VlcPlayerValue(duration: Duration.zero));

  /// Constructs a [VlcPlayerController] playing a video from obtained from
  /// the network.
  ///
  /// The URI for the video is given by the [dataSource] argument and must not be
  /// null.
  VlcPlayerController.network(
    this.dataSource, {
    this.autoInitialize = true,
    this.allowBackgroundPlayback = false,
    this.startAt,
    this.hwAcc = HwAcc.auto,
    this.autoPlay = true,
    this.options,
    @Deprecated('Please, use the addOnInitListener method instead.')
    VoidCallback? onInit,
    @Deprecated('Please, use the addOnRendererEventListener method instead.')
    RendererCallback? onRendererHandler,
  }) : package = null,
       _dataSourceType = DataSourceType.network,
       _onInit = onInit,
       _onRendererHandler = onRendererHandler,
       super(VlcPlayerValue(duration: Duration.zero));

  /// Constructs a [VlcPlayerController] playing a video from a file.
  ///
  /// This will load the file from the file-URI given by:
  /// `'file://${file.path}'`.
  VlcPlayerController.file(
    File file, {
    this.autoInitialize = true,
    this.allowBackgroundPlayback = true,
    this.startAt,
    this.hwAcc = HwAcc.auto,
    this.autoPlay = true,
    this.options,
    @Deprecated('Please, use the addOnInitListener method instead.')
    VoidCallback? onInit,
    @Deprecated('Please, use the addOnRendererEventListener method instead.')
    RendererCallback? onRendererHandler,
  }) : dataSource = 'file://${file.path}',
       package = null,
       _dataSourceType = DataSourceType.file,
       _onInit = onInit,
       _onRendererHandler = onRendererHandler,
       super(VlcPlayerValue(duration: Duration.zero));

  /// Register a [VoidCallback] closure to be called when the controller gets initialized
  void addOnInitListener(VoidCallback listener) {
    _onInitListeners.add(listener);
  }

  /// Remove a previously registered closure from the list of onInit closures
  void removeOnInitListener(VoidCallback listener) {
    _onInitListeners.remove(listener);
  }

  /// Register a [RendererCallback] closure to be called when a cast renderer device gets attached/detached
  void addOnRendererEventListener(RendererCallback listener) {
    _onRendererEventListeners.add(listener);
  }

  /// Remove a previously registered closure from the list of OnRendererEvent closures
  void removeOnRendererEventListener(RendererCallback listener) {
    _onRendererEventListeners.remove(listener);
  }

  /// Attempts to open the given [url] and load metadata about the video.
  Future<void> initialize() async {
    if (_isDisposed) {
      throw Exception(
        'initialize was called on a disposed VlcPlayerController',
      );
    }
    if (value.isInitialized) {
      throw Exception('Already Initialized');
    }

    if (!allowBackgroundPlayback) {
      _lifeCycleObserver = VlcAppLifeCycleObserver(this)..initialize();
    }

    await vlcPlayerPlatform.create(
      viewId: _viewId,
      uri: dataSource,
      type: dataSourceType,
      package: package,
      hwAcc: hwAcc,
      autoPlay: autoPlay,
      options: options,
    );

    final initializingCompleter = Completer<void>();

    // listen for media events
    void mediaEventListener(VlcMediaEvent event) {
      if (_isDisposed) {
        return;
      }

      switch (event.mediaEventType) {
        case VlcMediaEventType.opening:
          value = value.copyWith(
            isPlaying: false,
            isBuffering: true,
            isEnded: false,
            playingState: PlayingState.buffering,
            errorDescription: VlcPlayerValue.noError,
          );
        case VlcMediaEventType.paused:
          value = value.copyWith(
            isPlaying: false,
            isBuffering: false,
            playingState: PlayingState.paused,
          );
        case VlcMediaEventType.stopped:
          value = value.copyWith(
            isPlaying: false,
            isBuffering: false,
            isRecording: false,
            playingState: PlayingState.stopped,
            position: Duration.zero,
          );
        case VlcMediaEventType.playing:
          value = value.copyWith(
            isEnded: false,
            isPlaying: true,
            isBuffering: false,
            playingState: PlayingState.playing,
            duration: event.duration,
            size: event.size,
            playbackSpeed: event.playbackSpeed,
            audioTracksCount: event.audioTracksCount,
            activeAudioTrack: event.activeAudioTrack,
            spuTracksCount: event.spuTracksCount,
            activeSpuTrack: event.activeSpuTrack,
            errorDescription: VlcPlayerValue.noError,
          );

          /// Calling start at
          _setStartAt();
        case VlcMediaEventType.ended:
          value = value.copyWith(
            isPlaying: false,
            isBuffering: false,
            isEnded: true,
            isRecording: false,
            playingState: PlayingState.ended,
            position: event.position,
          );
        case VlcMediaEventType.buffering:
        case VlcMediaEventType.timeChanged:
          value = value.copyWith(
            isEnded: false,
            isBuffering: event.mediaEventType == VlcMediaEventType.buffering,
            position: event.position,
            duration: event.duration,
            playbackSpeed: event.playbackSpeed,
            bufferPercent: event.bufferPercent,
            size: event.size,
            audioTracksCount: event.audioTracksCount,
            activeAudioTrack: event.activeAudioTrack,
            spuTracksCount: event.spuTracksCount,
            activeSpuTrack: event.activeSpuTrack,
            isPlaying: event.isPlaying,
            playingState:
                (event.isPlaying ?? false)
                    ? PlayingState.playing
                    : value.playingState,
            errorDescription: VlcPlayerValue.noError,
          );
        case VlcMediaEventType.mediaChanged:
          break;

        case VlcMediaEventType.recording:
          value = value.copyWith(
            playingState: PlayingState.recording,
            isRecording: event.isRecording,
            recordPath: event.recordPath,
          );
        case VlcMediaEventType.error:
          value = value.copyWith(
            isPlaying: false,
            isBuffering: false,
            isEnded: false,
            playingState: PlayingState.error,
            errorDescription: VlcPlayerValue.unknownError,
          );
        case VlcMediaEventType.unknown:
          break;
      }
    }

    void errorListener(Object obj) {
      value = VlcPlayerValue.erroneous(obj.toString());
      if (!initializingCompleter.isCompleted) {
        initializingCompleter.completeError(obj);
      }
    }

    vlcPlayerPlatform
        .mediaEventsFor(_viewId)
        .listen(mediaEventListener, onError: errorListener);

    // listen for renderer devices events
    void rendererEventListener(VlcRendererEvent event) {
      if (_isDisposed) {
        return;
      }
      switch (event.eventType) {
        case VlcRendererEventType.attached:
        case VlcRendererEventType.detached:
          _notifyOnRendererListeners(
            event.eventType,
            event.rendererId,
            event.rendererName,
          );
        case VlcRendererEventType.unknown:
          break;
      }
    }

    vlcPlayerPlatform.rendererEventsFor(_viewId).listen(rendererEventListener);

    if (!initializingCompleter.isCompleted) {
      initializingCompleter.complete(null);
    }
    //
    value = value.copyWith(
      isInitialized: true,
      playingState: PlayingState.initialized,
    );

    _notifyOnInitListeners();

    return initializingCompleter.future;
  }

  /// Seeking to start at
  Future<void> _setStartAt() async {
    // Check if already seted up or start at is null then return.
    if (startAt == null || _startAtSet) return;

    final Duration startAtDuration = startAt!;

    // Only perform the check if the video's duration is known (greater than zero)
    if (value.duration > Duration.zero &&
        startAtDuration.inMilliseconds > value.duration.inMilliseconds) {
      throw ArgumentError.value(
        startAtDuration,
        'Start At cannot be greater than video duration.',
      );
    }

    // Setting startAt
    _startAtSet = true;
    await seekTo(startAtDuration);
  }

  /// Dispose controller
  @override
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }
    _onInitListeners.clear();
    _onRendererEventListeners.clear();
    _lifeCycleObserver?.dispose();
    _isDisposed = true;
    //
    await vlcPlayerPlatform.dispose(_viewId);
    super.dispose();
  }

  /// Notify onInit callback & all registered listeners
  void _notifyOnInitListeners() {
    _onInit?.call();
    for (final listener in _onInitListeners) {
      listener();
    }
  }

  /// Notify onRendererHandler callback & all registered listeners
  void _notifyOnRendererListeners(
    VlcRendererEventType type,
    String? id,
    String? name,
  ) {
    if (id == null || name == null) return;
    _onRendererHandler?.call(type, id, name);
    for (final listener in _onRendererEventListeners) {
      listener(type, id, name);
    }
  }

  /// This stops playback and changes the data source. Once the new data source has been loaded, the playback state will revert to
  /// its state before the method was called. (i.e. if this method is called whilst media is playing, once the new
  /// data source has been loaded, the new stream will begin playing.)
  /// [dataSource] - the path of the asset file.
  Future<void> setMediaFromAsset(
    String dataSource, {
    String? package,
    bool? autoPlay,
    HwAcc? hwAcc,
    Duration? startAt,
  }) async {
    _dataSourceType = DataSourceType.asset;
    this.package = package;
    await _setStreamUrl(
      dataSource,
      dataSourceType: DataSourceType.asset,
      package: package,
      autoPlay: autoPlay,
      hwAcc: hwAcc,
      startAt: startAt,
    );
  }

  /// This stops playback and changes the data source. Once the new data source has been loaded, the playback state will revert to
  /// its state before the method was called. (i.e. if this method is called whilst media is playing, once the new
  /// data source has been loaded, the new stream will begin playing.)
  /// [dataSource] - the URL of the stream to start playing.
  Future<void> setMediaFromNetwork(
    String dataSource, {
    bool? autoPlay,
    HwAcc? hwAcc,
    Duration? startAt,
  }) async {
    _dataSourceType = DataSourceType.network;
    package = null;
    await _setStreamUrl(
      dataSource,
      dataSourceType: DataSourceType.network,
      autoPlay: autoPlay,
      hwAcc: hwAcc,
      startAt: startAt,
    );
  }

  /// This stops playback and changes the data source. Once the new data source has been loaded, the playback state will revert to
  /// its state before the method was called. (i.e. if this method is called whilst media is playing, once the new
  /// data source has been loaded, the new stream will begin playing.)
  /// [file] - the File stream to start playing.
  Future<void> setMediaFromFile(
    File file, {
    bool? autoPlay,
    HwAcc? hwAcc,
    Duration? startAt,
  }) async {
    _dataSourceType = DataSourceType.file;
    package = null;
    final dataSource = 'file://${file.path}';
    await _setStreamUrl(
      dataSource,
      dataSourceType: DataSourceType.file,
      autoPlay: autoPlay,
      hwAcc: hwAcc,
      startAt: startAt,
    );
  }

  /// This stops playback and changes the data source. Once the new data source has been loaded, the playback state will revert to
  /// its state before the method was called. (i.e. if this method is called whilst media is playing, once the new
  /// data source has been loaded, the new stream will begin playing.)
  /// [dataSource] - the URL of the stream to start playing.
  /// [dataSourceType] - the source type of media.
  Future<void> _setStreamUrl(
    String dataSource, {
    required DataSourceType dataSourceType,
    String? package,
    bool? autoPlay,
    HwAcc? hwAcc,
    Duration? startAt,
  }) async {
    _throwIfNotInitialized('setStreamUrl');
    await vlcPlayerPlatform.stop(_viewId);
    await vlcPlayerPlatform.setStreamUrl(
      _viewId,
      uri: dataSource,
      type: dataSourceType,
      package: package,
      hwAcc: hwAcc ?? HwAcc.auto,
      autoPlay: autoPlay ?? true,
    );

    if (startAt != null) {
      await vlcPlayerPlatform.seekTo(_viewId, startAt);
    }

    return;
  }

  /// Starts playing the video.
  ///
  /// This method returns a future that completes as soon as the "play" command
  /// has been sent to the platform, not when playback itself is totally
  /// finished.
  Future<void> play() async {
    _throwIfNotInitialized('play');
    await vlcPlayerPlatform.play(_viewId);
    // This ensures that the correct playback speed is always applied when
    // playing back. This is necessary because we do not set playback speed
    // when paused.
    await setPlaybackSpeed(value.playbackSpeed);
  }

  /// Pauses the video.
  Future<void> pause() async {
    _throwIfNotInitialized('pause');
    await vlcPlayerPlatform.pause(_viewId);
  }

  /// stops the video.
  Future<void> stop() async {
    _throwIfNotInitialized('stop');
    await vlcPlayerPlatform.stop(_viewId);
  }

  /// Sets whether or not the video should loop after playing once.
  Future<void> setLooping(bool looping) async {
    _throwIfNotInitialized('setLooping');
    value = value.copyWith(isLooping: looping);
    await vlcPlayerPlatform.setLooping(_viewId, looping);
  }

  /// Returns true if media is playing.
  Future<bool?> isPlaying() async {
    _throwIfNotInitialized('isPlaying');

    return vlcPlayerPlatform.isPlaying(_viewId);
  }

  /// Returns true if media is seekable.
  Future<bool?> isSeekable() async {
    _throwIfNotInitialized('isSeekable');

    return vlcPlayerPlatform.isSeekable(_viewId);
  }

  /// Set video timestamp in millisecond
  Future<void> setTime(int time) async {
    return seekTo(Duration(milliseconds: time));
  }

  /// Sets the video's current timestamp to be at [moment]. The next
  /// time the video is played it will resume from the given [moment].
  ///
  /// If [moment] is outside of the video's full range it will be automatically
  /// and silently clamped.
  Future<void> seekTo(Duration position) async {
    _throwIfNotInitialized('seekTo');
    final Duration newPosition;
    if (position > value.duration) {
      newPosition = value.duration;
    } else if (position < Duration.zero) {
      newPosition = Duration.zero;
    } else {
      newPosition = position;
    }
    await vlcPlayerPlatform.seekTo(_viewId, newPosition);
  }

  /// Get the video timestamp in millisecond
  Future<int> getTime() async {
    final position = await getPosition();

    return position.inMilliseconds;
  }

  /// Returns the position in the current video.
  Future<Duration> getPosition() async {
    _throwIfNotInitialized('getPosition');
    final position = await vlcPlayerPlatform.getPosition(_viewId);
    value = value.copyWith(position: position);

    return position;
  }

  /// Sets the max audio volume of
  ///
  /// [maxVolume] indicates a value between 1 (lowest) and 200 (highest) on a
  /// linear scale.
  Future<void> setMaxVolume(int maxVolume) async {
    _throwIfNotInitialized('setMaxVolume');
    _maxVolume = maxVolume.clamp(0, 200);
  }

  /// Returns current vlc max volume level.
  Future<int> getMaxVolume() async {
    _throwIfNotInitialized('getMaxVolume');

    return _maxVolume;
  }

  /// Sets the audio volume of
  ///
  /// [volume] indicates a value between 0 (silent), 100 (full volume) and 200 (maximum) on a
  /// linear scale.
  Future<void> setVolume(int volume) async {
    _throwIfNotInitialized('setVolume');
    value = value.copyWith(volume: volume.clamp(0, _maxVolume));
    await vlcPlayerPlatform.setVolume(_viewId, value.volume);
  }

  /// Returns current vlc volume level.
  Future<int?> getVolume() async {
    _throwIfNotInitialized('getVolume');
    final volume = await vlcPlayerPlatform.getVolume(_viewId);
    value = value.copyWith(volume: volume?.clamp(0, _maxVolume));

    return volume;
  }

  /// Returns duration/length of loaded video
  Future<Duration> getDuration() async {
    _throwIfNotInitialized('getDuration');
    final duration = await vlcPlayerPlatform.getDuration(_viewId);
    value = value.copyWith(duration: duration);

    return duration;
  }

  /// Sets the playback speed.
  ///
  /// [speed] - the rate at which VLC should play media.
  /// For reference:
  /// 2.0 is double speed.
  /// 1.0 is normal speed.
  /// 0.5 is half speed.
  Future<void> setPlaybackSpeed(double speed) async {
    if (speed < 0) {
      throw ArgumentError.value(
        speed,
        'Negative playback speeds are not supported.',
      );
    } else if (speed == 0) {
      throw ArgumentError.value(
        speed,
        'Zero playback speed is not supported. Consider using [pause].',
      );
    }
    _throwIfNotInitialized('setPlaybackSpeed');
    // Setting the playback speed on iOS will trigger the video to play. We
    // prevent this from happening by not applying the playback speed until
    // the video is manually played from Flutter.
    if (!value.isPlaying) return;
    value = value.copyWith(playbackSpeed: speed);
    await vlcPlayerPlatform.setPlaybackSpeed(_viewId, value.playbackSpeed);
  }

  /// Returns the vlc playback speed.
  Future<double?> getPlaybackSpeed() async {
    _throwIfNotInitialized('getPlaybackSpeed');
    final speed = await vlcPlayerPlatform.getPlaybackSpeed(_viewId);
    value = value.copyWith(playbackSpeed: speed);

    return speed;
  }

  /// Return the number of subtitle tracks (both embedded and inserted)
  Future<int?> getSpuTracksCount() async {
    _throwIfNotInitialized('getSpuTracksCount');
    final spuTracksCount = await vlcPlayerPlatform.getSpuTracksCount(_viewId);
    value = value.copyWith(spuTracksCount: spuTracksCount);

    return spuTracksCount;
  }

  /// Return all subtitle tracks as array of <Int, String>
  /// The key parameter is the index of subtitle which is used for changing subtitle
  /// and the value is the display name of subtitle
  Future<Map<int, String>> getSpuTracks() async {
    _throwIfNotInitialized('getSpuTracks');

    return vlcPlayerPlatform.getSpuTracks(_viewId);
  }

  /// Change active subtitle index (set -1 to disable subtitle).
  /// [spuTrackNumber] - the subtitle index obtained from getSpuTracks()
  Future<void> setSpuTrack(int spuTrackNumber) async {
    _throwIfNotInitialized('setSpuTrack');

    return vlcPlayerPlatform.setSpuTrack(_viewId, spuTrackNumber);
  }

  /// Returns active spu track index
  Future<int?> getSpuTrack() async {
    _throwIfNotInitialized('getSpuTrack');
    final activeSpuTrack = await vlcPlayerPlatform.getSpuTrack(_viewId);
    value = value.copyWith(activeSpuTrack: activeSpuTrack);

    return activeSpuTrack;
  }

  /// [spuDelay] - the amount of time in milliseconds which vlc subtitle should be delayed.
  /// (both positive & negative value applicable)
  Future<void> setSpuDelay(int spuDelay) async {
    _throwIfNotInitialized('setSpuDelay');
    value = value.copyWith(spuDelay: spuDelay);

    return vlcPlayerPlatform.setSpuDelay(_viewId, spuDelay);
  }

  /// Returns the amount of subtitle time delay.
  Future<int?> getSpuDelay() async {
    _throwIfNotInitialized('getSpuDelay');
    final spuDelay = await vlcPlayerPlatform.getSpuDelay(_viewId);
    value = value.copyWith(spuDelay: spuDelay);

    return spuDelay;
  }

  /// Add extra network subtitle to media.
  /// [dataSource] - Url of subtitle
  /// [isSelected] - Set true if you wanna force the added subtitle to start display on media.
  Future<void> addSubtitleFromNetwork(
    String dataSource, {
    bool? isSelected,
  }) async {
    return _addSubtitleTrack(
      dataSource,
      dataSourceType: DataSourceType.network,
      isSelected: isSelected ?? true,
    );
  }

  /// Add extra subtitle file to media.
  /// [file] - Subtitle file
  /// [isSelected] - Set true if you wanna force the added subtitle to start display on media.
  Future<void> addSubtitleFromFile(File file, {bool? isSelected}) async {
    return _addSubtitleTrack(
      'file://${file.path}',
      dataSourceType: DataSourceType.file,
      isSelected: isSelected ?? true,
    );
  }

  /// Add extra subtitle to media.
  /// [uri] - URI of subtitle
  /// [isSelected] - Set true if you wanna force the added subtitle to start display on media.
  Future<void> _addSubtitleTrack(
    String uri, {
    required DataSourceType dataSourceType,
    bool? isSelected,
  }) async {
    _throwIfNotInitialized('addSubtitleTrack');

    return vlcPlayerPlatform.addSubtitleTrack(
      _viewId,
      uri: uri,
      type: dataSourceType,
      isSelected: isSelected ?? true,
    );
  }

  /// Returns the number of audio tracks
  Future<int?> getAudioTracksCount() async {
    _throwIfNotInitialized('getAudioTracksCount');
    final audioTracksCount = await vlcPlayerPlatform.getAudioTracksCount(
      _viewId,
    );
    value = value.copyWith(audioTracksCount: audioTracksCount);

    return audioTracksCount;
  }

  /// Returns all audio tracks as array of <Int, String>
  /// The key parameter is the index of audio track which is used for changing audio
  /// and the value is the display name of audio
  Future<Map<int, String>> getAudioTracks() async {
    _throwIfNotInitialized('getAudioTracks');

    return vlcPlayerPlatform.getAudioTracks(_viewId);
  }

  /// Returns active audio track index
  Future<int?> getAudioTrack() async {
    _throwIfNotInitialized('getAudioTrack');
    final activeAudioTrack = await vlcPlayerPlatform.getAudioTrack(_viewId);
    value = value.copyWith(activeAudioTrack: activeAudioTrack);

    return activeAudioTrack;
  }

  /// Change active audio track index (set -1 to mute).
  /// [audioTrackNumber] - the audio track index obtained from getAudioTracks()
  Future<void> setAudioTrack(int audioTrackNumber) async {
    _throwIfNotInitialized('setAudioTrack');

    return vlcPlayerPlatform.setAudioTrack(_viewId, audioTrackNumber);
  }

  /// [audioDelay] - the amount of time in milliseconds which vlc audio should be delayed.
  /// (both positive & negative value appliable)
  Future<void> setAudioDelay(int audioDelay) async {
    _throwIfNotInitialized('setAudioDelay');
    value = value.copyWith(audioDelay: audioDelay);

    return vlcPlayerPlatform.setAudioDelay(_viewId, audioDelay);
  }

  /// Returns the amount of audio track time delay in millisecond.
  Future<int?> getAudioDelay() async {
    _throwIfNotInitialized('getAudioDelay');
    final audioDelay = await vlcPlayerPlatform.getAudioDelay(_viewId);
    value = value.copyWith(audioDelay: audioDelay);

    return audioDelay;
  }

  /// Add extra network audio to media.
  /// [dataSource] - Url of audio
  /// [isSelected] - Set true if you wanna force the added audio to start playing on media.
  Future<void> addAudioFromNetwork(
    String dataSource, {
    bool? isSelected,
  }) async {
    return _addAudioTrack(
      dataSource,
      dataSourceType: DataSourceType.network,
      isSelected: isSelected ?? true,
    );
  }

  /// Add extra audio file to media.
  /// [file] - Audio file
  /// [isSelected] - Set true if you wanna force the added audio to start playing on media.
  Future<void> addAudioFromFile(File file, {bool? isSelected}) async {
    return _addAudioTrack(
      'file://${file.path}',
      dataSourceType: DataSourceType.file,
      isSelected: isSelected ?? true,
    );
  }

  /// Add extra audio to media.
  /// [uri] - URI of audio
  /// [isSelected] - Set true if you wanna force the added audio to start playing on media.
  Future<void> _addAudioTrack(
    String uri, {
    required DataSourceType dataSourceType,
    bool? isSelected,
  }) async {
    _throwIfNotInitialized('addAudioTrack');

    return vlcPlayerPlatform.addAudioTrack(
      _viewId,
      uri: uri,
      type: dataSourceType,
      isSelected: isSelected ?? true,
    );
  }

  /// Returns the number of video tracks
  Future<int?> getVideoTracksCount() async {
    _throwIfNotInitialized('getVideoTracksCount');
    final videoTracksCount = await vlcPlayerPlatform.getVideoTracksCount(
      _viewId,
    );
    value = value.copyWith(videoTracksCount: videoTracksCount);

    return videoTracksCount;
  }

  /// Returns all video tracks as array of <Int, String>
  /// The key parameter is the index of video track and the value is the display name of video track
  Future<Map<int, String>> getVideoTracks() async {
    _throwIfNotInitialized('getVideoTracks');

    return vlcPlayerPlatform.getVideoTracks(_viewId);
  }

  /// Change active video track index.
  /// [videoTrackNumber] - the video track index obtained from getVideoTracks()
  Future<void> setVideoTrack(int videoTrackNumber) async {
    _throwIfNotInitialized('setVideoTrack');

    return vlcPlayerPlatform.setVideoTrack(_viewId, videoTrackNumber);
  }

  /// Returns active video track index
  Future<int?> getVideoTrack() async {
    _throwIfNotInitialized('getVideoTrack');
    final activeVideoTrack = await vlcPlayerPlatform.getVideoTrack(_viewId);
    value = value.copyWith(activeVideoTrack: activeVideoTrack);

    return activeVideoTrack;
  }

  /// [scale] - the video scale value
  /// Set video scale
  Future<void> setVideoScale(double videoScale) async {
    _throwIfNotInitialized('setVideoScale');
    value = value.copyWith(videoScale: videoScale);

    return vlcPlayerPlatform.setVideoScale(_viewId, videoScale);
  }

  /// Returns video scale
  Future<double?> getVideoScale() async {
    _throwIfNotInitialized('getVideoScale');
    final videoScale = await vlcPlayerPlatform.getVideoScale(_viewId);
    value = value.copyWith(videoScale: videoScale);

    return videoScale;
  }

  /// [aspectRatio] - the video aspect ratio like "16:9"
  ///
  /// Set video aspect ratio
  Future<void> setVideoAspectRatio(String aspectRatio) async {
    _throwIfNotInitialized('setVideoAspectRatio');

    return vlcPlayerPlatform.setVideoAspectRatio(_viewId, aspectRatio);
  }

  /// Returns video aspect ratio in string format
  ///
  /// This is different from the aspectRatio property in video value "16:9"
  Future<String?> getVideoAspectRatio() async {
    _throwIfNotInitialized('getVideoAspectRatio');

    return vlcPlayerPlatform.getVideoAspectRatio(_viewId);
  }

  /// Returns binary data for a snapshot of the media at the current frame.
  ///
  Future<Uint8List?> takeSnapshot() async {
    _throwIfNotInitialized('takeSnapshot');

    return vlcPlayerPlatform.takeSnapshot(_viewId);
  }

  /// Get list of available renderer services which is supported by vlc library
  Future<List<String>> getAvailableRendererServices() async {
    _throwIfNotInitialized('getAvailableRendererServices');

    return vlcPlayerPlatform.getAvailableRendererServices(_viewId);
  }

  /// Start vlc cast discovery to find external display devices (chromecast)
  /// By setting serviceName, the vlc discovers renderer with that service
  Future<void> startRendererScanning({String? rendererService}) async {
    _throwIfNotInitialized('startRendererScanning');

    return vlcPlayerPlatform.startRendererScanning(
      _viewId,
      rendererService: rendererService ?? '',
    );
  }

  /// Stop vlc cast and scan
  Future<void> stopRendererScanning() async {
    _throwIfNotInitialized('stopRendererScanning');

    return vlcPlayerPlatform.stopRendererScanning(_viewId);
  }

  /// Returns all detected renderer devices as array of <String, String>
  /// The key parameter is the name of cast device and the value is the display name of cast device
  Future<Map<String, String>> getRendererDevices() async {
    _throwIfNotInitialized('getRendererDevices');

    return vlcPlayerPlatform.getRendererDevices(_viewId);
  }

  /// [castDevice] - name of renderer device
  /// Start vlc video casting to the selected device.
  /// Set null if you wanna stop video casting.
  Future<void> castToRenderer(String castDevice) async {
    _throwIfNotInitialized('castToRenderer');

    return vlcPlayerPlatform.castToRenderer(_viewId, castDevice);
  }

  /// [saveDirectory] - directory path of the recorded file
  /// Returns true if media is start recording.
  Future<bool?> startRecording(String saveDirectory) async {
    _throwIfNotInitialized('startRecording');

    return vlcPlayerPlatform.startRecording(_viewId, saveDirectory);
  }

  /// Returns true if media is stop recording.
  Future<bool?> stopRecording() async {
    _throwIfNotInitialized('stopRecording');

    return vlcPlayerPlatform.stopRecording(_viewId);
  }

  /// [functionName] - name of function
  /// throw exception if vlc player controller is not initialized
  void _throwIfNotInitialized(String functionName) {
    if (!value.isInitialized) {
      throw Exception(
        '$functionName() was called on an uninitialized VlcPlayerController.',
      );
    }
    // ignore: prefer_early_return
    if (_isDisposed) {
      throw Exception(
        '$functionName() was called on a disposed VlcPlayerController.',
      );
    }
  }

  /// [viewId] - the id of view that is generated by the platform
  /// This method will be called after the platform view has been created
  Future<void> onPlatformViewCreated(int viewId) async {
    _viewId = viewId;
    if (autoInitialize) {
      await initialize();
    }
    _isReadyToInitialize = true;
  }
}

///
typedef RendererCallback = void Function(VlcRendererEventType, String, String);
