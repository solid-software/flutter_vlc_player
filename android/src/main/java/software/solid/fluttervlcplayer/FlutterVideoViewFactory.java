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
import io.flutter.view.TextureRegistry;

public final class FlutterVideoViewFactory extends PlatformViewFactory {
    BinaryMessenger messenger;
    private final View containerView;
    private  final TextureRegistry textureRegistry;

    public FlutterVideoViewFactory(BinaryMessenger messenger, View containerView, TextureRegistry textureRegistry) {
        super(StandardMessageCodec.INSTANCE);
        this.messenger = messenger;
        this.containerView = containerView;
        this.textureRegistry = textureRegistry;
    }

    @Override
    public PlatformView create(Context context, int viewId, Object args) {
        Map<String, Object> params = (Map<String, Object>) args;
        return new FlutterVideoView(context, messenger, viewId, params, containerView, textureRegistry);
    }



}
