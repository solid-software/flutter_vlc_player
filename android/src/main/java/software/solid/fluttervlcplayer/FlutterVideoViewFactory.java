package software.solid.fluttervlcplayer;

import android.content.Context;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.StandardMessageCodec;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.platform.PlatformViewFactory;

class FlutterVideoViewFactory extends PlatformViewFactory {
    BinaryMessenger messenger;

    public FlutterVideoViewFactory(BinaryMessenger messenger) {
        super(StandardMessageCodec.INSTANCE);
        this.messenger = messenger;
    }

    @Override
    public PlatformView create(Context context, int i, Object o) {
        return new FlutterVideoView(context, messenger, i);
    }
}
