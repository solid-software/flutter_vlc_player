import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:flutter_vlc_player/vlc_player_flutter.dart';
import 'vlc_player_with_controls.dart';

class MultipleTab extends StatefulWidget {
  @override
  _MultipleTabState createState() => _MultipleTabState();
}

class _MultipleTabState extends State<MultipleTab> {
  VlcPlayerController _controller_1;
  VlcPlayerController _controller_2;
  VlcPlayerController _controller_3;

  String url_1 = 'https://media.w3.org/2010/05/sintel/trailer.mp4';
  String url_2 = 'http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyrides.mp4';
  String url_3 = 'http://samples.mplayerhq.hu/MPEG-4/embedded_subs/1Video_2Audio_2SUBs_timed_text_streams_.mp4';

  GlobalKey _key_1 = GlobalKey<VlcPlayerWithControlsState>();
  GlobalKey _key_2 = GlobalKey<VlcPlayerWithControlsState>();
  GlobalKey _key_3 = GlobalKey<VlcPlayerWithControlsState>();

  @override
  void initState() {
    super.initState();

    _controller_1 = VlcPlayerController.network(
      url_1,
      hwAcc: HwAcc.FULL,
      autoPlay: true,
      onInit: () async {},
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(2000),
        ]),
        rtp: VlcRtpOptions([
          VlcRtpOptions.rtpOverRtsp(true),
        ]),
      ),
    );
    //
    _controller_2 = VlcPlayerController.network(
      url_2,
      hwAcc: HwAcc.FULL,
      autoPlay: true,
      onInit: () async {},
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(2000),
        ]),
        rtp: VlcRtpOptions([
          VlcRtpOptions.rtpOverRtsp(true),
        ]),
      ),
    );
    //
    _controller_3 = VlcPlayerController.network(
      url_3,
      hwAcc: HwAcc.FULL,
      autoPlay: true,
      onInit: () async {},
      options: VlcPlayerOptions(
        advanced: VlcAdvancedOptions([
          VlcAdvancedOptions.networkCaching(2000),
        ]),
        rtp: VlcRtpOptions([
          VlcRtpOptions.rtpOverRtsp(true),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView(
        children: [
          Container(
            height: 400,
            child:
                VlcPlayerWithControls(key: _key_1, controller: _controller_1),
          ),
          SizedBox(height: 20),
          Container(
            height: 400,
            child:
                VlcPlayerWithControls(key: _key_2, controller: _controller_2),
          ),
          SizedBox(height: 20),
          Container(
            height: 400,
            child:
                VlcPlayerWithControls(key: _key_3, controller: _controller_3),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller_1.stopRendererScanning();
    _controller_1.removeListener(() {});
    _controller_2.stopRendererScanning();
    _controller_2.removeListener(() {});
    _controller_3.stopRendererScanning();
    _controller_3.removeListener(() {});
    super.dispose();
  }
}
