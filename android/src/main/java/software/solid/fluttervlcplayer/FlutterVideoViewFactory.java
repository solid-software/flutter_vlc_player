package software.solid.fluttervlcplayer;

import android.content.Context;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;
import io.flutter.view.FlutterNativeView;

class FlutterVideoViewFactory extends PlatformViewFactory {
    PluginRegistry.Registrar registrar;
    BinaryMessenger messenger;

    public FlutterVideoViewFactory(BinaryMessenger messenger, PluginRegistry.Registrar registrar) {
        super(StandardMessageCodec.INSTANCE);
        this.messenger = messenger;
        this.registrar = registrar;
    }

    @Override
    public PlatformView create(Context context, int i, Object o) {
        final FlutterVideoView videoView = new FlutterVideoView(context, registrar, messenger, i);

        registrar.addViewDestroyListener(
                new PluginRegistry.ViewDestroyListener() {
                    @Override
                    public boolean onViewDestroy(FlutterNativeView view) {
                        videoView.dispose();
                        return false; // We are not interested in assuming ownership of the NativeView.
                    }
                }
        );

        return videoView;
    }
}
