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
  String initUrl =
      "http://samples.mplayerhq.hu/MPEG-4/embedded_subs/1Video_2Audio_2SUBs_timed_text_streams_.mp4";

//  String initUrl = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4";
//  String initUrl = "/storage/emulated/0/Download/Test.mp4";
//  String initUrl = "/sdcard/Download/Test.mp4";

  String changeUrl =
      "http://distribution.bbb3d.renderfarming.net/video/mp4/bbb_sunflower_1080p_30fps_normal.mp4";

  Uint8List image;
  VlcPlayerController _videoViewController;
  bool isPlaying = true;
  double sliderValue = 0.0;
  double currentPlayerTime = 0;
  double volumeValue = 100;
  String position = "";
  String duration = "";
  int numberOfCaptions = 0;
  int numberOfAudioTracks = 0;
  bool isBuffering = true;
  bool getCastDeviceBtnEnabled = false;

  var _scaffoldKey = new GlobalKey<ScaffoldState>();
  @override
  void initState() {
    _videoViewController = new VlcPlayerController(onInit: () {
      _videoViewController.play();
    });
    _videoViewController.addListener(() {
      if (!this.mounted) return;
      if (_videoViewController.initialized) {
        var oPosition = _videoViewController.position;
        var oDuration = _videoViewController.duration;
        if (oDuration.inHours == 0) {
          var strPosition = oPosition.toString().split('.')[0];
          var strDuration = oDuration.toString().split('.')[0];
          position =
              "${strPosition.split(':')[1]}:${strPosition.split(':')[2]}";
          duration =
              "${strDuration.split(':')[1]}:${strDuration.split(':')[2]}";
        } else {
          position = oPosition.toString().split('.')[0];
          duration = oDuration.toString().split('.')[0];
        }
        sliderValue = _videoViewController.position.inSeconds.toDouble();
        numberOfCaptions = _videoViewController.spuTracksCount;
        numberOfAudioTracks = _videoViewController.audioTracksCount;

        switch (_videoViewController.playingState) {
          case PlayingState.PAUSED:
            setState(() {
              isBuffering = false;
            });
            break;

          case PlayingState.STOPPED:
            setState(() {
              isPlaying = false;
              isBuffering = false;
            });
            break;
          case PlayingState.BUFFERING:
            setState(() {
              isBuffering = true;
            });
            break;
          case PlayingState.PLAYING:
            setState(() {
              isBuffering = false;
            });
            break;
          case PlayingState.ERROR:
            setState(() {});
            print("VLC encountered error");
            break;
          default:
            setState(() {});
            break;
        }
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: const Text('Plugin example app'),
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera),
        onPressed: _createCameraImage,
      ),
      body: Builder(builder: (context) {
        return Container(
          padding: EdgeInsets.all(10),
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              SizedBox(
                height: 250,
                child: new VlcPlayer(
                  aspectRatio: 16 / 9,
                  url: initUrl,
                  isLocalMedia: false,
                  controller: _videoViewController,
                  // Play with vlc options
                  options: [
                    '--quiet',
//                '-vvv',
                    '--no-drop-late-frames',
                    '--no-skip-frames',
                    '--rtsp-tcp',
                  ],
                  hwAcc: HwAcc.DISABLED,
                  // or {HwAcc.AUTO, HwAcc.DECODING, HwAcc.FULL}
                  placeholder: Container(
                    height: 250.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[CircularProgressIndicator()],
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Flexible(
                    flex: 1,
                    child: FlatButton(
                        child: isPlaying
                            ? Icon(Icons.pause_circle_outline)
                            : Icon(Icons.play_circle_outline),
                        onPressed: () => {playOrPauseVideo()}),
                  ),
                  Flexible(
                    flex: 3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(position),
                        Expanded(
                          child: Slider(
                            activeColor: Colors.red,
                            value: sliderValue,
                            min: 0.0,
                            max: _videoViewController.duration == null
                                ? 1.0
                                : _videoViewController.duration.inSeconds
                                    .toDouble(),
                            onChanged: (progress) {
                              setState(() {
                                sliderValue = progress.floor().toDouble();
                              });
                              //convert to Milliseconds since VLC requires MS to set time
                              _videoViewController
                                  .setTime(sliderValue.toInt() * 1000);
                            },
                          ),
                        ),
                        Text(duration),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(height: 1),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Text("Volume Level"),
                  Slider(
                    min: 0,
                    max: 100,
                    value: volumeValue,
                    onChanged: (value) {
                      setState(() {
                        volumeValue = value;
                      });
                      _videoViewController.setVolume(volumeValue.toInt());
                    },
                  ),
                ],
              ),
              Divider(height: 1),
              Row(
                children: [
                  FlatButton(
                    child: Text("Change URL"),
                    onPressed: () =>
                        _videoViewController.setStreamUrl(changeUrl),
                  ),
                  FlatButton(
                      child: Text("+speed"),
                      onPressed: () =>
                          _videoViewController.setPlaybackSpeed(2.0)),
                  FlatButton(
                      child: Text("Normal"),
                      onPressed: () =>
                          _videoViewController.setPlaybackSpeed(1)),
                  FlatButton(
                      child: Text("-speed"),
                      onPressed: () =>
                          _videoViewController.setPlaybackSpeed(0.5)),
                ],
              ),
              Divider(height: 1),
              Container(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Text("position=" +
                        _videoViewController.position.inSeconds.toString() +
                        ", duration=" +
                        _videoViewController.duration.inSeconds.toString() +
                        ", speed=" +
                        _videoViewController.playbackSpeed.toString()),
                    Text(
                        "ratio=" + _videoViewController.aspectRatio.toString()),
                    Text("size=" +
                        _videoViewController.size.width.toString() +
                        "x" +
                        _videoViewController.size.height.toString()),
                    Text("state=" +
                        _videoViewController.playingState.toString()),
                  ],
                ),
              ),
              Divider(height: 1),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  RaisedButton(
                    child: Text('Get Subtitle Tracks'),
                    onPressed: () {
                      _getSubtitleTracks();
                    },
                  ),
                  RaisedButton(
                    child: Text('Get Audio Tracks'),
                    onPressed: () {
                      _getAudioTracks();
                    },
                  )
                ],
              ),
              Divider(height: 1),
              Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Flexible(
                    flex: 1,
                    child: RaisedButton(
                      padding: EdgeInsets.all(5),
                      child: Text(
                        'Discover Cast Devices',
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      onPressed: () async {
                        await _videoViewController.startCastDiscovery();
                        _scaffoldKey.currentState.showSnackBar(
                            SnackBar(content: Text("Cast Discovery Started")));
                        setState(() {
                          getCastDeviceBtnEnabled = true;
                        });
                      },
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: RaisedButton(
                      padding: EdgeInsets.all(5),
                      child: Text(
                        'Get Cast Devices',
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      onPressed: !getCastDeviceBtnEnabled
                          ? null
                          : () {
                              _getCastDevices();
                            },
                    ),
                  ),
                  Flexible(
                    flex: 1,
                    child: RaisedButton(
                      padding: EdgeInsets.all(5),
                      child: Text(
                        'Stop Discovery',
                        style: TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      onPressed: () async {
                        await _videoViewController.stopCastDiscovery();
                        _scaffoldKey.currentState.showSnackBar(
                            SnackBar(content: Text("Cast Discovery Stopped")));
                        setState(() {
                          getCastDeviceBtnEnabled = false;
                        });
                      },
                    ),
                  )
                ],
              ),
              Divider(height: 1),
              image == null
                  ? Container()
                  : Container(child: Image.memory(image)),
            ],
          ),
        );
      }),
    );
  }

  @override
  void dispose() {
    _videoViewController.dispose();
    super.dispose();
  }

  void playOrPauseVideo() {
    String state = _videoViewController.playingState.toString();

    if (state == "PlayingState.PLAYING") {
      _videoViewController.pause();
      setState(() {
        isPlaying = false;
      });
    } else {
      _videoViewController.play();
      setState(() {
        isPlaying = true;
      });
    }
  }

  void _getSubtitleTracks() async {
    if (_videoViewController.playingState.toString() != "PlayingState.PLAYING")
      return;

    Map<dynamic, dynamic> subtitleTracks =
        await _videoViewController.getSpuTracks();
    //
    if (subtitleTracks != null && subtitleTracks.length > 0) {
      int selectedSubId = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Select Subtitle"),
            content: Container(
              width: double.maxFinite,
              height: 250,
              child: ListView.builder(
                itemCount: subtitleTracks.keys.length + 1,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      index < subtitleTracks.keys.length
                          ? subtitleTracks.values.elementAt(index).toString()
                          : 'Disable',
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                        index < subtitleTracks.keys.length
                            ? subtitleTracks.keys.elementAt(index)
                            : -1,
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      );
      if (selectedSubId != null)
        await _videoViewController.setSpuTrack(selectedSubId);
    }
  }

  void _getAudioTracks() async {
    if (_videoViewController.playingState.toString() != "PlayingState.PLAYING")
      return;

    Map<dynamic, dynamic> audioTracks =
        await _videoViewController.getAudioTracks();
    //
    if (audioTracks != null && audioTracks.length > 0) {
      int selectedAudioTrackId = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Select Audio"),
            content: Container(
              width: double.maxFinite,
              height: 250,
              child: ListView.builder(
                itemCount: audioTracks.keys.length + 1,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      index < audioTracks.keys.length
                          ? audioTracks.values.elementAt(index).toString()
                          : 'Disable',
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                        index < audioTracks.keys.length
                            ? audioTracks.keys.elementAt(index)
                            : -1,
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      );
      if (selectedAudioTrackId != null)
        await _videoViewController.setAudioTrack(selectedAudioTrackId);
    }
  }

  void _getCastDevices() async {
    Map<dynamic, dynamic> castDevices =
        await _videoViewController.getCastDevices();
    //
    if (castDevices != null && castDevices.length > 0) {
      String selectedCastDeviceName = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Select Cast Device"),
            content: Container(
              width: double.maxFinite,
              height: 250,
              child: ListView.builder(
                itemCount: castDevices.keys.length + 1,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(
                      index < castDevices.keys.length
                          ? castDevices.values.elementAt(index).toString()
                          : 'Disconnect',
                    ),
                    onTap: () {
                      Navigator.pop(
                        context,
                        index < castDevices.keys.length
                            ? castDevices.keys.elementAt(index)
                            : null,
                      );
                    },
                  );
                },
              ),
            ),
          );
        },
      );
      await _videoViewController.startCasting(
        selectedCastDeviceName,
      );
    } else {
      _scaffoldKey.currentState
          .showSnackBar(SnackBar(content: Text("No Cast Device Found!")));
    }
  }

  void _createCameraImage() async {
    Uint8List file = await _videoViewController.takeSnapshot();
    setState(() {
      image = file;
    });
  }
}
