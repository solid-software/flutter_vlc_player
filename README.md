#  VLC Player Plugin
A VLC-powered alternative to Flutter's video_player that supports iOS and Android.

<img src="https://github.com/solid-software/flutter_vlc_player/blob/master/imgpsh_mobile_save.jfif?raw=true" width="200">

## Installation

### Version 3.0 Upgrade For Existing Apps
For migration to version 3, the project is based in swift. Your existing project will need to migratate

    Delete existing ios folder from root of flutter project.
    Run this command flutter create -i swift .

This command will create only ios directory with swift support. See https://stackoverflow.com/questions/52244346/how-to-enable-swift-support-for-existing-project-in-flutter

Change your project to use 9.0
# Uncomment this line to define a global platform for your project
 platform :ios, '9.0'


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

### Android
To load media from an internet source, your app will need the `INTERNET` permission.  
This is done by ensuring your `<project root>/android/app/src/main/AndroidManifest.xml` file contains a `uses-permission`
declaration for `android.permission.INTERNET`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

As Flutter includes this permission by default, the permission is likely already declared in the file.

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
    VoidCallback onInit
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
  /// (SAFE) This value is always safe to use - it is set to Size.zero when the player is uninitialized.
  Size size = Size.zero;

  /// This is the aspect ratio of the content as returned by VLC once the content has been loaded.
  /// (Not to be confused with the aspect ratio provided to the [VlcPlayer] widget, which is simply used for an
  /// [AspectRatio] wrapper around the content.)
  double aspectRatio;

  /// This is the playback speed as it is returned by VLC (meaning that this will not update until the actual rate
  /// at which VLC is playing the content has changed.)
  double playbackSpeed;

  /*** METHODS ***/
  /// [url] - the URL of the stream to start playing.
  /// This stops playback and changes the URL. Once the new URL has been loaded, the playback state will revert to
  /// its state before the method was called. (i.e. if setStreamUrl is called whilst media is playing, once the new
  /// URL has been loaded, the new stream will begin playing.)
  Future<void> setStreamUrl(String url);

  Future<void> play();
  Future<void> pause();
  Future<void> stop();

  /// [time] - time in milliseconds to jump to.
  Future<void> setTime(int time);

  /// [speed] - the rate at which VLC should play media.
  /// For reference:
  /// 2.0 is double speed.
  /// 1.0 is normal speed.
  /// 0.5 is half speed.
  Future<void> setPlaybackSpeed(double speed);

  /// Returns binary data for a snapshot of the media at the current frame.
  Future<Uint8List> takeSnapshot();

  /// Disposes the platform view and unloads the VLC player.
  void dispose();

}
```

## Current issues
Current issues list [is here](https://github.com/solid-software/flutter_vlc_player/issues).   
Found a bug? [Open the issue](https://github.com/solid-software/flutter_vlc_player/issues/new).
