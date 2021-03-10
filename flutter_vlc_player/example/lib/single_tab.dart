import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/cupertino.dart';
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
          hwAcc: HwAcc.FULL,
          onInit: () async {
            await _controller.startRendererScanning();
          },
          onRendererHandler: (type, id, name) {
            print('onRendererHandler $type $id $name');
          },
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
          onInit: () async {
            await _controller.startRendererScanning();
          },
          onRendererHandler: (type, id, name) {
            print('onRendererHandler $type $id $name');
          },
        );
        break;
      case VideoType.asset:
        _controller = VlcPlayerController.asset(
          initVideo.path,
          onInit: () async {
            await _controller.startRendererScanning();
          },
          onRendererHandler: (type, id, name) {
            print('onRendererHandler $type $id $name');
          },
          options: VlcPlayerOptions(),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Container(
          height: 400,
          child: VlcPlayerWithControls(key: _key, controller: _controller),
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
            }
            return ListTile(
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
                switch (video.type) {
                  case VideoType.network:
                    await _controller.setMediaFromNetwork(video.path,
                        hwAcc: HwAcc.FULL);
                    break;
                  case VideoType.file:
                    Scaffold.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copying file to temporary storage...'),
                      ),
                    );
                    await Future.delayed(Duration(seconds: 1));
                    var tempVideo = await _loadVideoToFs();
                    await Future.delayed(Duration(seconds: 1));
                    Scaffold.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Now trying to play...'),
                      ),
                    );
                    await Future.delayed(Duration(seconds: 1));
                    if (await tempVideo.exists()) {
                      await _controller.setMediaFromFile(tempVideo);
                    } else {
                      Scaffold.of(context).showSnackBar(
                        SnackBar(
                          content: Text('File load error.'),
                        ),
                      );
                    }
                    break;
                  case VideoType.asset:
                    await _controller.setMediaFromAsset(video.path);
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
    await _controller.stopRendererScanning();
    await _controller.dispose();
  }
}
