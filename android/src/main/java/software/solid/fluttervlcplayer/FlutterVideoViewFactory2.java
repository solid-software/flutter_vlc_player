package software.solid.fluttervlcplayer;

import android.app.Application;
import android.content.Context;

import androidx.lifecycle.Lifecycle;

import java.util.Map;
import java.util.concurrent.atomic.AtomicInteger;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;
import io.flutter.view.TextureRegistry;

public class FlutterVideoViewFactory2 extends PlatformViewFactory {

    private final AtomicInteger mActivityState;
    private final BinaryMessenger binaryMessenger;
    private final Application application;
    private final int activityHashCode;
    private final Lifecycle lifecycle;
    private final TextureRegistry registry;


    FlutterVideoViewFactory2(
            AtomicInteger state,
            BinaryMessenger binaryMessenger,
            Application application,
            Lifecycle lifecycle,
            TextureRegistry registry,
            int activityHashCode) {
        super(StandardMessageCodec.INSTANCE);
        mActivityState = state;
        this.binaryMessenger = binaryMessenger;
        this.application = application;
        this.activityHashCode = activityHashCode;
        this.lifecycle = lifecycle;
        this.registry = registry;
    }

    @SuppressWarnings("unchecked")
    @Override
    public PlatformView create(Context context, int id, Object args) {
        Map<String, Object> params = (Map<String, Object>) args;

        final FlutterVideoView2 videoView = new FlutterVideoView2(
                id,
                context,
                mActivityState,
                binaryMessenger,
                application,
                lifecycle,
                activityHashCode,
                registry);

        return videoView;

    }

}
