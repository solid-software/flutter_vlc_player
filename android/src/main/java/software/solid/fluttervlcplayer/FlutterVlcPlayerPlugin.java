package software.solid.fluttervlcplayer;

import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FlutterVlcPlayerPlugin */
public class FlutterVlcPlayerPlugin {

  /**
   * Plugin registration.
   */
  public static void registerWith(Registrar registrar) {
    registrar.platformViewRegistry().registerViewFactory(
            "flutter_video_plugin/getVideoView",
            new FlutterVideoViewFactory(registrar.messenger(), registrar)
    );
  }
}
