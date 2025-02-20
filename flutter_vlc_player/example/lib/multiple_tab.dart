import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:flutter_vlc_player_example/vlc_player_with_controls.dart';

class MultipleTab extends StatefulWidget {
  @override
  _MultipleTabState createState() => _MultipleTabState();
}

class _MultipleTabState extends State<MultipleTab> {
  static const _heightWithControls = 400.0;
  static const _heightWithoutControls = 300.0;
  static const _networkCachingTime = 2000;

  List<VlcPlayerController> controllers = <VlcPlayerController>[];

  List<String> urls = [
    'https://www.tomandjerryonline.com/Videos/Ford%20Mondeo%20-%20Tom%20and%20Jerry.mov',
    'https://www.tomandjerryonline.com/Videos/TomAndJerryTales_HQ.wmv',
    'https://www.tomandjerryonline.com/Videos/tjpb1.mov',
  ];

  bool showPlayerControls = true;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < urls.length; i++) {
      final controller = VlcPlayerController.network(
        urls[i],
        hwAcc: HwAcc.full,
        autoPlay: false,
        options: VlcPlayerOptions(
          advanced: VlcAdvancedOptions([
            VlcAdvancedOptions.networkCaching(_networkCachingTime),
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
    return ListView.separated(
      itemCount: controllers.length,
      separatorBuilder: (_, __) {
        return const Divider(height: 5, thickness: 5, color: Colors.grey);
      },
      itemBuilder: (_, index) {
        return SizedBox(
          height:
              showPlayerControls ? _heightWithControls : _heightWithoutControls,
          child: VlcPlayerWithControls(
            controller: controllers[index],
            showControls: showPlayerControls,
          ),
        );
      },
    );
  }

  @override
  Future<void> dispose() async {
    for (final controller in controllers) {
      await controller.stopRendererScanning();
      await controller.dispose();
    }
    super.dispose();
  }
}
