#  VLC Player Plugin
Flutter plugin to view local videos and videos from the network.

## Getting Started
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
