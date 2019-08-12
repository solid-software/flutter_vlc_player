import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

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

  @override
  void initState() {
    imageKey = new GlobalKey();

    _videoViewController = new VlcPlayerController(
      onInit: (){
        _videoViewController.play();
      }
    );
    _videoViewController.addListener((){
      setState(() {});
    });

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
            new VlcPlayer(
              aspectRatio: 16 / 9,
              url: "http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_60fps_normal.mp4",
              controller: _videoViewController,
              placeholder: Container(
                height: 250.0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[CircularProgressIndicator()],
                ),
              ),
            ),

            FlatButton(
              child: Text("Change URL"),
              onPressed: () => _videoViewController.setStreamUrl("http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_2160p_60fps_normal.mp4"),
            ),

            FlatButton(
              child: Text("+speed"),
              onPressed: () => _videoViewController.setPlaybackSpeed(2.0)
            ),

            FlatButton(
                child: Text("Normal"),
                onPressed: () => _videoViewController.setPlaybackSpeed(1)
            ),

            FlatButton(
              child: Text("-speed"),
              onPressed: () => _videoViewController.setPlaybackSpeed(0.5)
            ),

            Text("position=" + _videoViewController.position.inSeconds.toString() + ", duration=" + _videoViewController.duration.inSeconds.toString() + ", speed=" + _videoViewController.playbackSpeed.toString()),
            Text("ratio=" + _videoViewController.aspectRatio.toString()),
            Text("size=" + _videoViewController.size.width.toString() + "x" + _videoViewController.size.height.toString()),
            Text("state=" + _videoViewController.playingState.toString()),

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

  void _createCameraImage() async {
    Uint8List file = await _videoViewController.makeSnapshot();
    setState(() {
      image = file;
    });
  }
}
