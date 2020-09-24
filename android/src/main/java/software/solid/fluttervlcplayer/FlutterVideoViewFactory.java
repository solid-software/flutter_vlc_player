package software.solid.fluttervlcplayer;

import android.content.Context;
import android.view.View;

import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;
import io.flutter.view.FlutterNativeView;

public final class FlutterVideoViewFactory extends PlatformViewFactory {
    BinaryMessenger messenger;
    private final View containerView;

    public FlutterVideoViewFactory(BinaryMessenger messenger, View containerView) {
        super(StandardMessageCodec.INSTANCE);
        this.messenger = messenger;
        this.containerView = containerView;
    }

    @Override
    public PlatformView create(Context context, int viewId, Object args) {
        Map<String, Object> params = (Map<String, Object>) args;
        return new FlutterVideoView(context, messenger, viewId, params, containerView);
    }


//    @Override
//    public PlatformView create(Context context, int id, Object args) {
//        final FlutterVideoView videoView = new FlutterVideoView(context, registrar, messenger, i);
//
//        registrar.addViewDestroyListener(
//                new PluginRegistry.ViewDestroyListener() {
//                    @Override
//                    public boolean onViewDestroy(FlutterNativeView view) {
//                        videoView.dispose();
//                        return false; // We are not interested in assuming ownership of the NativeView.
//                    }
//                }
//        );
//
//        return videoView;
//    }
}
