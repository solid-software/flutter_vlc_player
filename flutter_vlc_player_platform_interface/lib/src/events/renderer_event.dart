import 'package:flutter_vlc_player_platform_interface/src/enums/renderer_event_type.dart';

// ignore: prefer_match_file_name
class VlcRendererEvent {
  /// The type of the event.
  final VlcRendererEventType eventType;

  /// The identifier of renderer device
  final String? rendererId;

  /// The name of cast device
  final String? rendererName;

  /// Creates an instance of [VlcRendererEvent].
  ///
  /// The [eventType] argument is required.
  ///
  /// Depending on the [eventType], the [rendererId], [rendererName]
  VlcRendererEvent({
    required this.eventType,
    this.rendererId,
    this.rendererName,
  });
}
