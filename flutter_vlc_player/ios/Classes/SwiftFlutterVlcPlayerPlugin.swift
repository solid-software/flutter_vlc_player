import Foundation
import Flutter

public class SwiftFlutterVlcPlayerPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let vlcViewFactory = VLCViewFactory(registrar: registrar)
        registrar.register(vlcViewFactory, withId: "flutter_video_plugin/getVideoView")
    }
}
