import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/vlc_player.dart';
import 'package:flutter_vlc_player/vlc_player_controller.dart';

const String mp4Link = "http://streams.videolan.org/streams/mp4/Mr_MrsSmith-h264_aac.mp4";
const String mjpLink = "http://213.226.254.135:91/mjpg/video.mjpg";
const String hlsLink = ""; //in future

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Uint8List image;
  GlobalKey imageKey;
  VlcPlayer videoView;
  VlcPlayerController _videoViewController;
  VlcPlayerController _videoViewController2;

  @override
  void initState() {
    imageKey = new GlobalKey();
    _videoViewController = new VlcPlayerController();
    _videoViewController2 = new VlcPlayerController();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
        appBar: new AppBar(
          title: const Text('Plugin example app'),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.camera),
          onPressed: _createCameraImage,
        ),
        body: Column(
          children: <Widget>[
            Stack(
              children: <Widget>[
                VlcPlayer(
                  defaultWidth: 640,
                  defaultHeight: 360,
                  url: mp4Link,
                  controller: _videoViewController,
                  placeholder: Container(
                    height: 250.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[CircularProgressIndicator()],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                      onTap: () {
                        _playPause(_videoViewController);
                      },
                      child: Container(
                        color: Colors.transparent,
                      )),
                )
              ],
            ),
            Stack(
              children: <Widget>[
                VlcPlayer(
                  defaultWidth: 640,
                  defaultHeight: 360,
                  url: mjpLink,
                  controller: _videoViewController2,
                  placeholder: Container(
                    height: 250.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[CircularProgressIndicator()],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: GestureDetector(
                      onTap: () {
                        _playPauseStream(_videoViewController2, urlLink: mjpLink);
                      },
                      child: Container(
                        color: Colors.transparent,
                      )),
                )
              ],
            ),
            Expanded(
              child: image == null
                  ? Container()
                  : Container(
                      decoration: BoxDecoration(image: DecorationImage(image: MemoryImage(image))),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _playPause(VlcPlayerController playerController) {
    playerController.isPlaying().then(
      (isPlaying) {
        if (isPlaying) {
          playerController.pause();
        } else {
          playerController.play();
        }
      },
    );
  }

  void _playPauseStream(VlcPlayerController playerController, {String urlLink}) {
    playerController.isPlaying().then(
      (isPlaying) {
        if (isPlaying) {
          playerController.pause();
        } else {
          playerController.playUrl(urlLink);
        }
      },
    );
  }

  void _createCameraImage() async {
    Uint8List file = await _videoViewController.makeSnapshot();
    setState(() {
      image = file;
    });
  }
}
