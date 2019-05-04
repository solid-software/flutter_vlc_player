package software.solid.fluttervlcplayer;

import android.content.Context;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

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
        return new FlutterVideoView(context, registrar, messenger, i);
    }
}
