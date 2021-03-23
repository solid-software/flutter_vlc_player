import '../enums/renderer_event_type.dart';

class VlcRendererEvent {
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

  /// The type of the event.
  final VlcRendererEventType eventType;

  /// The identifier of renderer device
  final String? rendererId;

  /// The name of cast device
  final String? rendererName;
}
