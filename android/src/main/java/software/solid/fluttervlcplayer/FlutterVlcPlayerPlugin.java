package software.solid.fluttervlcplayer;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FlutterVlcPlayerPlugin */
public class FlutterVlcPlayerPlugin implements FlutterPlugin {

  public FlutterVlcPlayerPlugin() {}

  /**
   * Plugin registration.
   */
  public static void registerWith(Registrar registrar) {
    registrar
            .platformViewRegistry()
            .registerViewFactory(
                    "plugins.flutter.io/webview",
                    new FlutterVideoViewFactory(registrar.messenger(), registrar.view()));

  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    BinaryMessenger messenger = binding.getBinaryMessenger();
    binding
            .getFlutterEngine()
            .getPlatformViewsController()
            .getRegistry()
            .registerViewFactory(
                    "flutter_video_plugin/getVideoView", new FlutterVideoViewFactory(messenger, /*containerView=*/ null));
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {

  }


}
