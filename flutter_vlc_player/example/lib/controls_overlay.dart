import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/vlc_player_flutter.dart';

class ControlsOverlay extends StatelessWidget {
  const ControlsOverlay({Key key, this.controller}) : super(key: key);

  final VlcPlayerController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        AnimatedSwitcher(
          duration: Duration(milliseconds: 50),
          reverseDuration: Duration(milliseconds: 200),
          child: controller.value.isPlaying
              ? SizedBox.shrink()
              : SizedBox.expand(
                  child: Container(
                    color: Colors.black45,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        IconButton(
                          onPressed: () async {
                            if (controller.value.duration != null)
                              await controller.seekTo(
                                  controller.value.position -
                                      Duration(seconds: 10));
                          },
                          color: Colors.white,
                          iconSize: 60.0,
                          icon: Icon(Icons.replay_10),
                        ),
                        IconButton(
                          onPressed: () async {
                            await controller.play();
                          },
                          color: Colors.white,
                          iconSize: 100.0,
                          icon: Icon(Icons.play_arrow),
                        ),
                        IconButton(
                          onPressed: () async {
                            if (controller.value.duration != null)
                              await controller.seekTo(
                                  controller.value.position +
                                      Duration(seconds: 10));
                          },
                          color: Colors.white,
                          iconSize: 60.0,
                          icon: Icon(Icons.forward_10),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        GestureDetector(
          onTap: !controller.value.isPlaying
              ? null
              : () async {
                  if (controller.value.isPlaying) {
                    await controller.pause();
                  }
                },
        ),
      ],
    );
  }
}
