import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:path_provider/path_provider.dart';

import 'video_data.dart';
import 'vlc_player_with_controls.dart';

class SingleTab extends StatefulWidget {
  @override
  _SingleTabState createState() => _SingleTabState();
}

class _SingleTabState extends State<SingleTab> {
  VlcPlayerController _controller;
  final _key = GlobalKey<VlcPlayerWithControlsState>();

  //
  List<VideoData> listVideos;
  int selectedVideoIndex;

  Future<File> _loadVideoToFs() async {
    final videoData = await rootBundle.load('assets/sample.mp4');
    final videoBytes = Uint8List.view(videoData.buffer);
    var dir = (await getTemporaryDirectory()).path;
    var temp = File('$dir/temp.file');
    temp.writeAsBytesSync(videoBytes);
    return temp;
  }

  void fillVideos() {
    listVideos = <VideoData>[];
    //
    listVideos.add(VideoData(
      name: 'Network Video 1',
      path:
          'http://samples.mplayerhq.hu/MPEG-4/embedded_subs/1Video_2Audio_2SUBs_timed_text_streams_.mp4',
      type: VideoType.network,
    ));
    //
    listVideos.add(VideoData(
      name: 'Network Video 2',
      path: 'https://media.w3.org/2010/05/sintel/trailer.mp4',
      type: VideoType.network,
    ));
    //
    listVideos.add(VideoData(
      name: 'HLS Streaming Video 1',
      path:
          'http://demo.unified-streaming.com/video/tears-of-steel/tears-of-steel.ism/.m3u8',
      type: VideoType.network,
    ));
    //
    listVideos.add(VideoData(
      name: 'File Video 1',
      path: 'System File Example',
      type: VideoType.file,
    ));
    //
    listVideos.add(VideoData(
      name: 'Asset Video 1',
      path: 'assets/sample.mp4',
      type: VideoType.asset,
    ));
  }

  @override
  void initState() {
    super.initState();

    //
    fillVideos();
    selectedVideoIndex = 0;
    //
    var initVideo = listVideos[selectedVideoIndex];
    switch (initVideo.type) {
      case VideoType.network:
        _controller = VlcPlayerController.network(
          initVideo.path,
          hwAcc: HwAcc.full,
          options: VlcPlayerOptions(
            advanced: VlcAdvancedOptions([
              VlcAdvancedOptions.networkCaching(2000),
            ]),
            subtitle: VlcSubtitleOptions([
              VlcSubtitleOptions.boldStyle(true),
              VlcSubtitleOptions.fontSize(30),
              VlcSubtitleOptions.outlineColor(VlcSubtitleColor.yellow),
              VlcSubtitleOptions.outlineThickness(VlcSubtitleThickness.normal),
              // works only on externally added subtitles
              VlcSubtitleOptions.color(VlcSubtitleColor.navy),
            ]),
            http: VlcHttpOptions([
              VlcHttpOptions.httpReconnect(true),
            ]),
            rtp: VlcRtpOptions([
              VlcRtpOptions.rtpOverRtsp(true),
            ]),
          ),
        );
        break;
      case VideoType.file:
        var file = File(initVideo.path);
        _controller = VlcPlayerController.file(
          file,
        );
        break;
      case VideoType.asset:
        _controller = VlcPlayerController.asset(
          initVideo.path,
          options: VlcPlayerOptions(),
        );
        break;
      case VideoType.recorded:
        break;
    }
    _controller.addOnInitListener(() async {
      await _controller.startRendererScanning();
    });
    _controller.addOnRendererEventListener((type, id, name) {
      print('OnRendererEventListener $type $id $name');
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          height: 400,
          child: VlcPlayerWithControls(
            key: _key,
            controller: _controller,
            onStopRecording: (recordPath) {
              setState(() {
                listVideos.add(VideoData(
                  name: 'Recorded Video',
                  path: recordPath,
                  type: VideoType.recorded,
                ));
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'The recorded video file has been added to the end of list.'),
                ),
              );
            },
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          itemCount: listVideos.length,
          physics: NeverScrollableScrollPhysics(),
          itemBuilder: (BuildContext context, int index) {
            var video = listVideos[index];
            IconData iconData;
            switch (video.type) {
              case VideoType.network:
                iconData = Icons.cloud;
                break;
              case VideoType.file:
                iconData = Icons.insert_drive_file;
                break;
              case VideoType.asset:
                iconData = Icons.all_inbox;
                break;
              case VideoType.recorded:
                iconData = Icons.videocam;
                break;
            }
            return ListTile(
              dense: true,
              selected: selectedVideoIndex == index,
              selectedTileColor: Colors.black54,
              leading: Icon(
                iconData,
                color:
                    selectedVideoIndex == index ? Colors.white : Colors.black,
              ),
              title: Text(
                video.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      selectedVideoIndex == index ? Colors.white : Colors.black,
                ),
              ),
              subtitle: Text(
                video.path,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color:
                      selectedVideoIndex == index ? Colors.white : Colors.black,
                ),
              ),
              onTap: () async {
                await _controller.stopRecording();
                switch (video.type) {
                  case VideoType.network:
                    await _controller.setMediaFromNetwork(
                      video.path,
                      hwAcc: HwAcc.full,
                    );
                    break;
                  case VideoType.file:
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copying file to temporary storage...'),
                      ),
                    );
                    await Future.delayed(Duration(seconds: 1));
                    var tempVideo = await _loadVideoToFs();
                    await Future.delayed(Duration(seconds: 1));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Now trying to play...'),
                      ),
                    );
                    await Future.delayed(Duration(seconds: 1));
                    if (await tempVideo.exists()) {
                      await _controller.setMediaFromFile(tempVideo);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('File load error.'),
                        ),
                      );
                    }
                    break;
                  case VideoType.asset:
                    await _controller.setMediaFromAsset(video.path);
                    break;
                  case VideoType.recorded:
                    var recordedFile = File(video.path);
                    await _controller.setMediaFromFile(recordedFile);
                    break;
                }
                setState(() {
                  selectedVideoIndex = index;
                });
              },
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() async {
    super.dispose();
    await _controller.stopRecording();
    await _controller.stopRendererScanning();
    await _controller.dispose();
  }
}
