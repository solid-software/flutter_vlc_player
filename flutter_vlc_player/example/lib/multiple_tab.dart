import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

import 'vlc_player_with_controls.dart';

class MultipleTab extends StatefulWidget {
  @override
  _MultipleTabState createState() => _MultipleTabState();
}

class _MultipleTabState extends State<MultipleTab> {
  List<VlcPlayerController> controllers;
  List<String> urls = [
    'https://www.tomandjerryonline.com/Videos/Ford%20Mondeo%20-%20Tom%20and%20Jerry.mov',
    'https://www.tomandjerryonline.com/Videos/TomAndJerryTales_HQ.wmv',
    'https://www.tomandjerryonline.com/Videos/tjpb1.mov'
  ];

  bool showPlayerControls = true;

  @override
  void initState() {
    super.initState();
    controllers = <VlcPlayerController>[];
    for (var i = 0; i < urls.length; i++) {
      var controller = VlcPlayerController.network(
        urls[i],
        hwAcc: HwAcc.full,
        autoPlay: false,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(2000),
          ]),
          rtp: VlcRtpOptions([
            VlcRtpOptions.rtpOverRtsp(true),
          ]),
        ),
      );
      controllers.add(controller);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ListView.separated(
        itemCount: controllers.length,
        separatorBuilder: (_, index) {
          return Divider(height: 5, thickness: 5, color: Colors.grey);
        },
        itemBuilder: (_, index) {
          return Container(
            height: showPlayerControls ? 400 : 300,
            child: VlcPlayerWithControls(
              controller: controllers[index],
              showControls: showPlayerControls,
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() async {
    super.dispose();
    for (final controller in controllers) {
      await controller.stopRendererScanning();
      await controller.dispose();
    }
  }
}
