package software.solid.fluttervlcplayer;

import androidx.annotation.NonNull;

import io.flutter.Log;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.PluginRegistry.Registrar;

/** FlutterVlcPlayerPlugin */
public class FlutterVlcPlayerPlugin implements FlutterPlugin, ActivityAware {
  private FlutterPluginBinding pluginBinding;

  public FlutterVlcPlayerPlugin() {}

  /**
   * Plugin registration.
   */
  public static void registerWith(Registrar registrar) {
    registrar
            .platformViewRegistry()
            .registerViewFactory(
                    "flutter_video_plugin/getVideoView",
                    new FlutterVideoViewFactory(registrar.messenger(), registrar.view(), registrar.textures()));

  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    this.pluginBinding = binding;

  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
pluginBinding= null;


  }


  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    BinaryMessenger messenger = pluginBinding.getBinaryMessenger();
    pluginBinding
            .getPlatformViewRegistry()
            .registerViewFactory(
                    "flutter_video_plugin/getVideoView", new FlutterVideoViewFactory(messenger, /*containerView=*/ null, pluginBinding.getTextureRegistry()));
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {

  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    Log.d("VIDEO", "Reattached ");
  }

  @Override
  public void onDetachedFromActivity() {

  }
}
