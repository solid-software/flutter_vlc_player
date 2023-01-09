import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_vlc_player_platform_interface/src/messages/messages.dart';

class VlcTextureWidget extends StatelessWidget {
  const VlcTextureWidget(
      {Key? key, required this.onPlatformViewCreated, required this.api})
      : super(key: key);

  final PlatformViewCreatedCallback onPlatformViewCreated;
  final VlcPlayerApi api;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, size) {
      return VlcTextureSizeWidget(
          onPlatformViewCreated: onPlatformViewCreated,
          api: api,
          size: Size(size.maxWidth, size.maxHeight));
    });
  }
}

class VlcTextureSizeWidget extends StatefulWidget {
  const VlcTextureSizeWidget(
      {Key? key,
      required this.onPlatformViewCreated,
      required this.api,
      required this.size})
      : super(key: key);

  final PlatformViewCreatedCallback onPlatformViewCreated;
  final VlcPlayerApi api;
  final Size size;

  @override
  State<VlcTextureSizeWidget> createState() => _VlcTextureSizeWidgetState();
}

class _VlcTextureSizeWidgetState extends State<VlcTextureSizeWidget> {
  int? textureId;
  late Size size;

  @override
  void initState() {
    super.initState();
    size = widget.size;
    widget.api.createTextureEntry(
        CreateTextureMessage()..width=size.width..height=size.height).then((value) {
      if (mounted) {
        setState(() {
          textureId = value.result;
        });
        widget.onPlatformViewCreated(value.result!);
      } else {
        widget.api.disposeTextureEntry(value);
      }
    });
  }

  @override
  void didUpdateWidget(covariant VlcTextureSizeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (size != widget.size) {
      changeSize(widget.size);
    }
  }

  void changeSize(Size size) {
    this.size = size;
    // TODO: change size
  }

  @override
  void dispose() {
    super.dispose();
    if (textureId != null) {
      widget.api.disposeTextureEntry(IntMessage()..viewId = textureId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return textureId != null
        ? Texture(textureId: textureId!)
        : const SizedBox();
  }
}
