#  VLC Player Plugin
Flutter plugin to view local videos and videos from the network. Work example:   
<img src="https://github.com/solid-software/flutter_vlc_player/blob/master/imgpsh_mobile_save.jfif?raw=true" width="200">
## Getting Started
**iOS integration:**
For iOS you needed to add this two rows into Info.plist file (see example for details): 
```
<key>io.flutter.embedded_views_preview</key>
<true/>
```
To start using the plugin, copy this code or follow the [example](https://github.com/solid-software/flutter_vlc_player/tree/master/example):
```dart
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/vlc_player.dart';
import 'package:flutter_vlc_player/vlc_player_controller.dart';

class ExampleVideo extends StatefulWidget {
  @override
  _ExampleVideoState createState() => _ExampleVideoState();
}

class _ExampleVideoState extends State<ExampleVideo> {
  final String urlToStreamVideo = 'http://213.226.254.135:91/mjpg/video.mjpg';
  final VlcPlayerController controller = VlcPlayerController();
  final int playerWidth = 640;
  final int playerHeight = 360;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VlcPlayer(
        defaultWidth: playerWidth,
        defaultHeight: playerHeight,
        url: urlToStreamVideo,
        controller: controller,
        placeholder: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

```

To take screenshot from video just follow next code:
```dart
Uint8List image = await controller.makeSnapshot();
```
## Current issues
Current issues list [is here](https://github.com/solid-software/flutter_vlc_player/issues).   
Found a bug? [Open the issue](https://github.com/solid-software/flutter_vlc_player/issues/new).
