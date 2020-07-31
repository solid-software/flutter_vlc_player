import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => new _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(home: MyAppScaffold());
  }
}

class MyAppScaffold extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => MyAppScaffoldState();
}

class MyAppScaffoldState extends State<MyAppScaffold> {
  Uint8List image;

  VlcPlayerController _videoViewController;
  VlcPlayerController _videoViewController2;
  bool isPlaying = true;
  double sliderValue = 0.0;
  double currentPlayerTime = 0;
  double volumeValue = 100;

  @override
  void initState() {
    _videoViewController = new VlcPlayerController(onInit: () {
      _videoViewController.play();
    });
    _videoViewController.addListener(() {
      setState(() {});
    });

    _videoViewController2 = new VlcPlayerController(onInit: () {
      _videoViewController2.play();
    });
    _videoViewController2.addListener(() {
      setState(() {});
    });

    Timer.periodic(Duration(seconds: 1), (Timer timer) {
      String state = _videoViewController2.playingState.toString();
      if (this.mounted) {
        setState(() {
          if (state == "PlayingState.PLAYING" &&
              sliderValue < _videoViewController2.duration.inSeconds) {
            sliderValue = _videoViewController2.position.inSeconds.toDouble();
          }
        });
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Plugin example app'),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera),
        onPressed: _createCameraImage,
      ),
      body: Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            SizedBox(
              height: 360,
              child: new VlcPlayer(
                aspectRatio: 16 / 9,
                url:
                    "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4",
                controller: _videoViewController,
                // Play with vlc options
                options: [
                  '--quiet',
                  '--no-drop-late-frames',
                  '--no-skip-frames',
                  '--rtsp-tcp'
                ],
                hwAcc: HwAcc
                    .DISABLED, // or {HwAcc.AUTO, HwAcc.DECODING, HwAcc.FULL}
                placeholder: Container(
                  height: 250.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[CircularProgressIndicator()],
                  ),
                ),
              ),
            ),
            SizedBox(
              height: 360,
              child: new VlcPlayer(
                aspectRatio: 16 / 9,
                url:
                    "http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_60fps_normal.mp4",
                controller: _videoViewController2,
                placeholder: Container(
                  height: 250.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[CircularProgressIndicator()],
                  ),
                ),
              ),
            ),
            Text("Seek"),
            Slider(
              activeColor: Colors.white,
              value: sliderValue,
              min: 0.0,
              max: _videoViewController2.duration == null
                  ? 1.0
                  : _videoViewController2.duration.inSeconds.toDouble(),
              onChanged: (progress) {
                setState(() {
                  sliderValue = progress.floor().toDouble();
                });
                //convert to Milliseconds since VLC requires MS to set time
                _videoViewController2.setTime(sliderValue.toInt() * 1000);
              },
            ),
            FlatButton(
                child: isPlaying ? Icon(Icons.pause) : Icon(Icons.play_arrow),
                onPressed: () => {playOrPauseVideo()}),
            Text("Volume Level"),
            Slider(
              min: 0,
              max: 100,
              value: volumeValue,
              onChanged: (value) {
                setState(() {
                  volumeValue = value;
                });
                _videoViewController2.setVolume(volumeValue.toInt());
              },
            ),
            FlatButton(
              child: Text("Change URL"),
              onPressed: () => _videoViewController.setStreamUrl(
                  "http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_2160p_60fps_normal.mp4"),
            ),
            FlatButton(
                child: Text("+speed"),
                onPressed: () => _videoViewController.setPlaybackSpeed(2.0)),
            FlatButton(
                child: Text("Normal"),
                onPressed: () => _videoViewController.setPlaybackSpeed(1)),
            FlatButton(
                child: Text("-speed"),
                onPressed: () => _videoViewController.setPlaybackSpeed(0.5)),
            Text("position=" +
                _videoViewController.position.inSeconds.toString() +
                ", duration=" +
                _videoViewController.duration.inSeconds.toString() +
                ", speed=" +
                _videoViewController.playbackSpeed.toString()),
            Text("ratio=" + _videoViewController.aspectRatio.toString()),
            Text("size=" +
                _videoViewController.size.width.toString() +
                "x" +
                _videoViewController.size.height.toString()),
            Text("state=" + _videoViewController.playingState.toString()),
            image == null ? Container() : Container(child: Image.memory(image)),
          ],
        ),
      ),
    );
  }

  void playOrPauseVideo() {
    String state = _videoViewController2.playingState.toString();

    if (state == "PlayingState.PLAYING") {
      _videoViewController2.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      _videoViewController2.play();
      setState(() {
        isPlaying = true;
      });
    }
  }

  void _createCameraImage() async {
    Uint8List file = await _videoViewController.takeSnapshot();
    setState(() {
      image = file;
    });
  }
}
