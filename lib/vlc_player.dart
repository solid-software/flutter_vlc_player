import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_vlc_player/vlc_player_controller.dart';

class VlcPlayer extends StatefulWidget {
  final int defaultHeight;
  final int defaultWidth;
  final String url;
  final bool isLocal;
  final String subtitle;
  final Widget placeholder;
  final VlcPlayerController controller;

  const VlcPlayer({
    Key key,
    @required this.defaultHeight,
    @required this.defaultWidth,
    @required this.url,
    this.isLocal=false,
    this.subtitle='',
    @required this.controller,
    this.placeholder,
  });

  @override
  _VlcPlayerState createState() => _VlcPlayerState();
}

class _VlcPlayerState extends State<VlcPlayer> {
  int videoRenderId;
  double aspectRatio = 0.7;
  VlcPlayerController _controller;
  bool readyToShow = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1 + aspectRatio,
      child: Stack(
        children: <Widget>[
          Offstage(offstage: readyToShow, child: widget.placeholder),
          Offstage(
            offstage: !readyToShow,
            child: _createPlatformView(),
          ),
        ],
      ),
    );
  }

  Widget _createPlatformView() {
    if (Platform.isIOS) {
      return UiKitView(
          viewType: "flutter_video_plugin/getVideoView",
          onPlatformViewCreated: _onPlatformViewCreated);
    } else if (Platform.isAndroid) {
      return AndroidView(
          viewType: "flutter_video_plugin/getVideoView",
          hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          onPlatformViewCreated: _onPlatformViewCreated);
    }
    return Container();
  }

  void _onPlatformViewCreated(int id) async {
    _controller = widget.controller;
    _controller.initView(id);
    if (_controller.hasClients) {
      String aspectRatioString = await _controller.setStreamUrl(
          widget.url, widget.isLocal, widget.subtitle, widget.defaultHeight, widget.defaultWidth);
      setState(() {
        readyToShow = true;
      });
      if (aspectRatioString != null && aspectRatioString.isNotEmpty)
        aspectRatio = double.parse(aspectRatioString);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
