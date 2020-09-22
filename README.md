#  VLC Player Plugin
A VLC-powered alternative to Flutter's video_player that supports iOS and Android.

<p float="left">
  <img src="https://github.com/solid-software/flutter_vlc_player/blob/master/img_example_v4.jpg?raw=true" height="400">
  <img src="https://github.com/solid-software/flutter_vlc_player/blob/master/imgpsh_mobile_save.jfif?raw=true" height="400">
</p>



## Installation

### iOS
For iOS, you need to opt into the Flutter embedded views preview.  
This is done by adding the following to your project's `<project root>/ios/Runner/Info.plist` file (see example for details): 
```xml
<key>io.flutter.embedded_views_preview</key>
<true/>
```

If you're unable to view media loaded from an external source, you should also add the following:
```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```
For more information, or for more granular control over your App Transport Security (ATS) restrictions, you should
[read Apple's documentation](https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity/nsallowsarbitraryloads).

Make sure that following line in `<project root>/ios/Podfile` uncommented:

`platform :ios, '9.0'`

> NOTE: While the Flutter `video_player` is not functional on iOS Simulators, this package (`flutter_vlc_player`) **is**
> fully functional on iOS simulators.

To enable vlc cast functionality for external displays (chromecast), you should also add the following:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Used to search for chromecast devices</string>
<key>NSBonjourServices</key>
<array>
  <string>_googlecast._tcp</string>
</array>
```

<hr>

### Android
To load media/subitle from an internet source, your app will need the `INTERNET` permission.  
This is done by ensuring your `<project root>/android/app/src/main/AndroidManifest.xml` file contains a `uses-permission`
declaration for `android.permission.INTERNET`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

As Flutter includes this permission by default, the permission is likely already declared in the file.

Note that if you got "Cleartext HTTP traffic to * is not permitted"
you need to add the `android:usesClearTextTraffic="true"` flag in the AndroidManifest.xml file, or define a new "Network Security Configuration" file. For more information, check https://developer.android.com/training/articles/security-config

<br>

In order to load media/subtitle from internal device storage, you should put the storage permissions as follows:
```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```
In some cases you also need to add the `android:requestLegacyExternalStorage="true"` flag to the Application tag in AndroidManifest.xml file.

After that you can access the media/subtitle file by 

    "/storage/emulated/0/{FilePath}"
    "/sdcard/{FilePath}"

<hr>

## Quick Start
To start using the plugin, copy this code or follow the [example](https://github.com/solid-software/flutter_vlc_player/tree/master/example):

```dart
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class ExampleVideo extends StatefulWidget {
  @override
  _ExampleVideoState createState() => _ExampleVideoState();
}

class _ExampleVideoState extends State<ExampleVideo> {
  final String urlToStreamVideo = 'http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_60fps_normal.mp4';
  final VlcPlayerController controller = new VlcPlayerController(
      // Start playing as soon as the video is loaded.
      onInit: (){
          controller.play();
      }  
  );
  final int playerWidth = 640;
  final int playerHeight = 360;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: SizedBox(
            height: playerHeight,
            width: playerWidth,
            child: new VlcPlayer(
                aspectRatio: 16 / 9,
                url: urlToStreamVideo,
                controller: controller,
                placeholder: Center(child: CircularProgressIndicator()),
            )
        )
    );
  }
}
```

To take a screenshot from the video you can use `takeScreenshot`:
```dart
// Import typed_data for Uint8List.
import 'dart:typed_data';

Uint8List image = await controller.takeSnapshot();
```

This will return a Uint8List (binary data) for the image.
You could then base-64 encode and upload this to a server, save it to storage or even display it in Flutter with an image widget as follows:
```dart
Container(
  child: Image.memory(image)
)
```

## API
```dart
/// VlcPlayer widget.
const VlcPlayer({
    Key key,

    /// The [VlcPlayerController] that handles interaction with the platform code.
    @required this.controller,

    /// The aspect ratio used to display the video.
    /// This MUST be provided, however it could simply be (parentWidth / parentHeight) - where parentWidth and
    /// parentHeight are the width and height of the parent perhaps as defined by a LayoutBuilder.
    @required this.aspectRatio,

    /// This is the initial URL for the content. This also must be provided but [VlcPlayerController] implements
    /// [VlcPlayerController.setStreamUrl] method so this can be changed at any time.
    @required this.url,

    /// Set hardware acceleration for player. Default is Automatic.
    this.hwAcc,

    /// Adds options to vlc. For more [https://wiki.videolan.org/VLC_command-line_help] If nothing is provided,
    /// vlc will run without any options set.
    this.options,

    /// Set true if the provided url is local file
    this.isLocalMedia,

    /// The video should be played automatically.
    this.autoplay,

    /// Set the external subtitle to load with video
    this.subtitle,

    /// Set true if the provided subtitle is local file
    this.isLocalSubtitle,

    /// Set true if the provided subtitle is selected by default
    this.isSubtitleSelected,

    /// Loop the playback forever
    this.loop,

    /// Before the platform view has initialized, this placeholder will be rendered instead of the video player.
    /// This can simply be a [CircularProgressIndicator] (see the example.)
    this.placeholder,
  });
```

```dart
/// VlcPlayerController (passed to VlcPlayer widget as the controller parameter.)
VlcPlayerController({
    /// This is a callback that will be executed once the platform view has been initialized.
    /// If you want the media to play as soon as the platform view has initialized, you could just call
    /// [VlcPlayerController.play] in this callback. (see the example)
    VoidCallback onInit,

    /// This is a callback that will be executed every time a new cast device detected/removed
    /// It should be defined as "void Function(CastStatus, String, String)", where the CastStatus is an enum { DEVICE_ADDED, DEVICE_DELETED } and the next two String arguments are name and displayName of cast device, respectively.
    CastCallback onCastHandler
}){

  /*** PROPERTIES (Getters) ***/

  /// Once the [_methodChannel] and [_eventChannel] have been registered with
  /// the Flutter platform SDK counterparts, [hasClients] is set to true.
  /// At this point, the player is ready to begin playing content.
  bool hasClients = false;

  /// This is set to true when the player has loaded a URL.
  bool initialized = false;

  /// Returns the current state of the player.
  /// Valid states:
  /// - PlayingState.PLAYING
  /// - PlayingState.BUFFERING
  /// - PlayingState.STOPPED
  /// - PlayingState.PAUSED
  /// - PlayingState.ERROR
  /// - null (When the player is uninitialized)
  PlayingState playingState;

  /// The current position of the player, counted in milliseconds since start of
  /// the content.
  /// (SAFE) This value is always safe to use - it is set to Duration.zero when the player is uninitialized.
  int position = Duration.zero;

  /// The total duration of the content, counted in milliseconds.
  /// (SAFE) This value is always safe to use - it is set to Duration.zero when the player is uninitialized.
  int duration = Duration.zero;

  /// This is the dimensions of the content (height and width).
  /// (SAFE) This value is always safe to use - it is set to VlcMediaSize.zero when the player is uninitialized.
  VlcMediaSize size = VlcMediaSize.zero;

  /// This is the aspect ratio of the content as returned by VLC once the content has been loaded.
  /// (Not to be confused with the aspect ratio provided to the [VlcPlayer] widget, which is simply used for an
  /// [AspectRatio] wrapper around the content.)
  double aspectRatio;

  /// This is the playback speed as it is returned by VLC (meaning that this will not update until the actual rate
  /// at which VLC is playing the content has changed.)
  double playbackSpeed;

  /// Returns the number of available audio tracks embedded in media except the original audio.
  int audioTracksCount;

  /// Returns the active audio track index. "-1" means audio is disabled.
  int activeAudioTrack;

  /// Returns the number of available subtitle tracks embedded in media.
  int spuTracksCount;

  /// Returns the active subitlte track index. "-1" means subitle is disabled.
  int activeSpuTrack;

  /*** METHODS ***/
  /// This stops playback and changes the URL. Once the new URL has been loaded, the playback state will revert to
  /// its state before the method was called. (i.e. if setStreamUrl is called whilst media is playing, once the new
  /// URL has been loaded, the new stream will begin playing.)
  /// [url] - the URL of the stream to start playing.
  /// [isLocalMedia] - Set true if the media url is on local storage.
  /// [subtitle] - Set subtitle url if you wanna add subtitle on media loading.
  /// [isLocalSubtitle] - Set true if subtitle is on local storage
  /// [isSubtitleSelected] - Set true if you wanna force the added subtitle to start display on media.
  Future<void> setStreamUrl(String url, {bool isLocalMedia, String subtitle, bool isLocalSubtitle, bool isSubtitleSelected});

  /// Start playing media.
  Future<void> play();

  /// Pause media player.
  Future<void> pause();
  
  /// Stop media player.
  Future<void> stop();

  /// Returns true if media is playing.
  Future<bool> isPlaying();

  /// [time] - time in milliseconds to jump to.
  Future<void> setTime(int time);
  
  /// Returns current media seek time in milliseconds.
  Future<int> getTime();

  /// Returns duration/length of loaded video in milliseconds.
  Future<int> getDuration();

  /// [volume] - Set vlc volume level which should be in range [0-100].
  Future<void> setVolume(int volume);

  /// Returns current vlc volume level.
  Future<int> getVolume();

  /// [speed] - the rate at which VLC should play media.
  /// For reference:
  /// 2.0 is double speed.
  /// 1.0 is normal speed.
  /// 0.5 is half speed.
  Future<void> setPlaybackSpeed(double speed);

  /// Returns the vlc playback speed.
  Future<double> getPlaybackSpeed();

  /// Return the number of subtitle tracks (both embedded and inserted)
  Future<int> getSpuTracksCount();

  /// Return all subtitle tracks as array of <Int, String>
  /// The key parameter is the index of subtitle which is used for changing subtitle and the value is the display name of subtitle
  Future<Map<dynamic, dynamic>> getSpuTracks();

  /// [spuTrackNumber] - the subtitle index obtained from getSpuTracks()
  /// Change active subtitle index (set -1 to disable subtitle).
  Future<void> setSpuTrack(int spuTrackNumber);

  /// Returns selected spu track index
  Future<int> getSpuTrack();

  /// [delay] - the amount of time in milliseconds which vlc subtitle should be delayed. (both positive & negative value appliable)
  Future<void> setSpuDelay(int delay);

  /// Returns the amount of subtitle time delay.
  Future<int> getSpuDelay();

  
  /// [subtitlePath] - URL of subtitle
  /// [isLocalSubtitle] - Set true if subtitle is on local storage
  /// [isSubtitleSelected] - Set true if you wanna force the added subtitle to start display on media.
  /// Add extra subtitle to media.
  Future<void> addSubtitleTrack(String subtitlePath,
      {bool isLocalSubtitle, bool isSubtitleSelected});

  /// Returns the number of audio tracks
  Future<int> getAudioTracksCount();

  /// Returns all audio tracks as array of <Int, String>
  /// The key parameter is the index of audio track which is used for changing audio and the value is the display name of audio
  Future<Map<dynamic, dynamic>> getAudioTracks();

  /// Returns selected audio track index
  Future<int> getAudioTrack();

  /// [audioTrackNumber] - the audio track index obtained from getAudioTracks()
  /// Change active audio track index (set -1 to mute).
  Future<void> setAudioTrack(int audioTrackNumber);

  /// [delay] - the amount of time in milliseconds which vlc audio should be delayed. (both positive & negative value appliable)
  Future<void> setAudioDelay(int delay);

  /// Returns the amount of audio track time delay.
  Future<int> getAudioDelay();

  /// Returns the number of video tracks
  Future<int> getVideoTracksCount();
  
  /// Returns all video tracks as array of <Int, String>
  /// The key parameter is the index of video track and the value is the display name of video track
  Future<Map<dynamic, dynamic>> getVideoTracks();

  /// Returns an object which contains information about current video track
  Future<dynamic> getCurrentVideoTrack();

  /// Returns selected video track index
  Future<int> getVideoTrack();

  /// [scale] - the video scale value
  /// Set video scale
  Future<void> setVideoScale(double scale);

  /// Returns video scale
  Future<double> getVideoScale();

  /// [aspect] - the video apect ratio like "16:9"
  /// Set video aspect ratio
  Future<void> setVideoAspectRatio(String aspect);

  /// Returns video aspect ratio
  Future<String> getVideoAspectRatio();

  /// Returns binary data for a snapshot of the media at the current frame.
  Future<Uint8List> takeSnapshot();

  /// Start vlc cast discovery to find external display devices (chromecast)
  Future<void> startCastDiscovery();

  /// Stop vlc cast and cast discovery
  Future<void> stopCastDiscovery();

  /// Returns all detected cast devices as array of <String, String>
  /// The key parameter is the name of cast device and the value is the display name of cast device
  Future<Map<dynamic, dynamic>> getCastDevices();

  /// [castDevice] - name of cast device 
  /// Start vlc video casting to the selected device. Set null if you wanna to stop video casting.
  Future<void> startCasting(String castDevice);

  /// Disposes the platform view and unloads the VLC player.
  Future<void> dispose();

}
```

## Upgrade instructions

### Version 4.0 Upgrade For Existing Apps
To upgrade to version 4.0 (or v3.0), first you need to migrate the existing project to swift.

    Delete existing ios folder from root of flutter project.
    Run this command flutter create -i swift .

This command will create only ios directory with swift support. See https://stackoverflow.com/questions/52244346/how-to-enable-swift-support-for-existing-project-in-flutter

<hr>

### Breaking Changes (from V3 to V4)
1) Player Stop/Pause status is seperated 

    previously (v3 and lower): Stop/Pause -> STOPPED,
    <br>
    now (v4): Stop -> STOPPED and Pause -> PAUSED. 

2) Refactored belowing attributes & methods

    // attributes
    <br>
    audioCount -> audioTracksCount
    <br>
    activeAudioNum -> activeAudioTrack
    <br>
    subtitleCount -> spuTracksCount
    <br>
    activeSubtitleNum -> activeSpuTrack
    <br>
    <br>
    // methods
    <br>
    changeSound(int audioNumber) -> setAudioTrack(int audioTrackNumber)
    <br>
    changeSubtitle(int subtitleNumber) -> setSpuTrack(int spuTrackNumber)
    <br>
    addSubtitle(String filePath) -> addSubtitleTrack(String subtitlePath, ...)


<hr>

## Current issues
Current issues list [is here](https://github.com/solid-software/flutter_vlc_player/issues).   
Found a bug? [Open the issue](https://github.com/solid-software/flutter_vlc_player/issues/new).
