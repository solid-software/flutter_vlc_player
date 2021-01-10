import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:flutter_vlc_player/vlc_player_flutter.dart';

import 'package:flutter/material.dart';

import 'controls_overlay.dart';

class VlcPlayerWithControls extends StatefulWidget {
  final VlcPlayerController controller;

  VlcPlayerWithControls({
    Key key,
    this.controller,
  })  : assert(controller != null, 'You must provide a vlc controller'),
        super(key: key);

  @override
  VlcPlayerWithControlsState createState() => VlcPlayerWithControlsState();
}

class VlcPlayerWithControlsState extends State<VlcPlayerWithControls>
    with AutomaticKeepAliveClientMixin {
  VlcPlayerController _controller;

  //
  final double initSnapshotRightPosition = 10;
  final double initSnapshotBottomPosition = 10;
  OverlayEntry _overlayEntry;

  //
  double sliderValue = 0.0;
  double volumeValue = 50;
  String position = "";
  String duration = "";
  int numberOfCaptions = 0;
  int numberOfAudioTracks = 0;

  //
  List<double> playbackSpeeds = [0.5, 1.0, 2.0];
  int playbackSpeedIndex = 1;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    //
    _controller = widget.controller;
    _controller.addListener(listener);
  }

  @override
  void dispose() {
    _controller.removeListener(listener);
    super.dispose();
  }

  void listener () async{
    if (!this.mounted) return;
    //
    if (_controller.value.initialized) {
      var oPosition = _controller.value.position;
      var oDuration = _controller.value.duration;
      if (oPosition != null && oDuration != null) {
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
        sliderValue = _controller.value.position.inSeconds.toDouble();
      }
      numberOfCaptions = _controller.value.spuTracksCount;
      numberOfAudioTracks = _controller.value.audioTracksCount;
      //
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Container(
          height: 50,
          color: Colors.black87,
          child: Row(
            children: [
              ListView(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                children: [
                  Stack(
                    children: [
                      IconButton(
                        tooltip: 'Get Subtitle Tracks',
                        icon: Icon(Icons.closed_caption),
                        color: Colors.white,
                        onPressed: () {
                          _getSubtitleTracks();
                        },
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(1),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 1, horizontal: 2),
                            child: Text(
                              '$numberOfCaptions',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      IconButton(
                        tooltip: 'Get Audio Tracks',
                        icon: Icon(Icons.audiotrack),
                        color: Colors.white,
                        onPressed: () {
                          _getAudioTracks();
                        },
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(1),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 1, horizontal: 2),
                            child: Text(
                              '$numberOfAudioTracks',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.timer),
                        color: Colors.white,
                        onPressed: () async {
                          playbackSpeedIndex++;
                          if (playbackSpeedIndex >= playbackSpeeds.length)
                            playbackSpeedIndex = 0;
                          return await _controller.setPlaybackSpeed(
                              playbackSpeeds.elementAt(playbackSpeedIndex));
                        },
                      ),
                      Positioned(
                        bottom: 7,
                        right: 3,
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(1),
                            ),
                            padding: EdgeInsets.symmetric(
                                vertical: 1, horizontal: 2),
                            child: Text(
                              '${playbackSpeeds.elementAt(playbackSpeedIndex)}x',
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    tooltip: 'Get Snapshot',
                    icon: Icon(Icons.camera),
                    color: Colors.white,
                    onPressed: () {
                      _createCameraImage();
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.cast),
                    color: Colors.white,
                    onPressed: () async {
                      _getRendererDevices();
                    },
                  ),
                ],
              ),
              Expanded(
                child: Container(),
              ),
              Container(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Size: ' +
                          (_controller.value.size?.width?.toInt() ?? 0)
                              .toString() +
                          'x' +
                          (_controller.value.size?.height?.toInt() ?? 0)
                              .toString(),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Status: ' +
                          _controller.value.playingState
                              .toString()
                              .split('.')[1],
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: Colors.black,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: <Widget>[
                Center(
                  child: VlcPlayer(
                    controller: _controller,
                  
                    aspectRatio: 16 / 9,
                    placeholder: Center(child: CircularProgressIndicator()),
                  ),
                ),
                ControlsOverlay(controller: _controller),
              ],
            ),
          ),
        ),
        Container(
          height: 50,
          color: Colors.black87,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                color: Colors.white,
                icon: _controller.value.isPlaying
                    ? Icon(Icons.pause_circle_outline)
                    : Icon(Icons.play_circle_outline),
                onPressed: () async {
                  return _controller.value.isPlaying
                      ? await _controller.pause()
                      : await _controller.play();
                },
              ),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Text(
                      position,
                      style: TextStyle(color: Colors.white),
                    ),
                    Expanded(
                      child: Slider(
                        activeColor: Colors.redAccent,
                        inactiveColor: Colors.white70,
                        value: sliderValue,
                        min: 0.0,
                        max: _controller.value.duration == null
                            ? 1.0
                            : _controller.value.duration.inSeconds.toDouble(),
                        onChanged: (progress) {
                          setState(() {
                            sliderValue = progress.floor().toDouble();
                          });
                          //convert to Milliseconds since VLC requires MS to set time
                          _controller.setTime(sliderValue.toInt() * 1000);
                        },
                      ),
                    ),
                    Text(
                      duration,
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.fullscreen),
                color: Colors.white,
                onPressed: () {},
              ),
            ],
          ),
        ),
        Container(
          color: Colors.black87,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: [
              Icon(
                Icons.volume_down,
                color: Colors.white,
              ),
              Expanded(
                child: Slider(
                  min: 0,
                  max: 100,
                  value: volumeValue,
                  onChanged: (value) {
                    setState(() {
                      volumeValue = value;
                    });
                    _controller.setVolume(volumeValue.toInt());
                  },
                ),
              ),
              Icon(
                Icons.volume_up,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _getSubtitleTracks() async {
    if (!_controller.value.isPlaying) return;

    Map<int, String> subtitleTracks = await _controller.getSpuTracks();
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
      if (selectedSubId != null) await _controller.setSpuTrack(selectedSubId);
    }
  }

  void _getAudioTracks() async {
    if (!_controller.value.isPlaying) return;

    Map<int, String> audioTracks = await _controller.getAudioTracks();
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
        await _controller.setAudioTrack(selectedAudioTrackId);
    }
  }

  void _getRendererDevices() async {
    Map<String, String> castDevices = await _controller.getRendererDevices();
    //
    if (castDevices != null && castDevices.length > 0) {
      String selectedCastDeviceName = await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Display Devices"),
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
      await _controller.castToRenderer(selectedCastDeviceName);
    } else {
      Scaffold.of(context)
          .showSnackBar(SnackBar(content: Text("No Display Device Found!")));
    }
  }

  void _createCameraImage() async {
    Uint8List snapshot = await _controller.takeSnapshot();
    _overlayEntry?.remove();
    _overlayEntry = _createSnapshotThumbnail(snapshot);
    Overlay.of(context).insert(_overlayEntry);
  }

  OverlayEntry _createSnapshotThumbnail(Uint8List snapshot) {
    double right = initSnapshotRightPosition;
    double bottom = initSnapshotBottomPosition;
    return OverlayEntry(
      builder: (context) => Positioned(
        right: right,
        bottom: bottom,
        width: 100,
        child: Material(
          elevation: 4.0,
          child: GestureDetector(
            onTap: () async {
              _overlayEntry?.remove();
              _overlayEntry = null;
              await showDialog(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    contentPadding: EdgeInsets.all(0),
                    content: Container(
                      child: Image.memory(snapshot),
                    ),
                  );
                },
              );
            },
            onVerticalDragUpdate: (dragUpdateDetails) {
              bottom -= dragUpdateDetails.delta.dy;
              _overlayEntry.markNeedsBuild();
            },
            onHorizontalDragUpdate: (dragUpdateDetails) {
              right -= dragUpdateDetails.delta.dx;
              _overlayEntry.markNeedsBuild();
            },
            onHorizontalDragEnd: (dragEndDetails) {
              if ((initSnapshotRightPosition - right).abs() >= 100) {
                _overlayEntry?.remove();
                _overlayEntry = null;
              } else {
                right = initSnapshotRightPosition;
                _overlayEntry.markNeedsBuild();
              }
            },
            onVerticalDragEnd: (dragEndDetails) {
              if ((initSnapshotBottomPosition - bottom).abs() >= 100) {
                _overlayEntry?.remove();
                _overlayEntry = null;
              } else {
                bottom = initSnapshotBottomPosition;
                _overlayEntry.markNeedsBuild();
              }
            },
            child: Container(
              child: Image.memory(snapshot),
            ),
          ),
        ),
      ),
    );
  }
}
