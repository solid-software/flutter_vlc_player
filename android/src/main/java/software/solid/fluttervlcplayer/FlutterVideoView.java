package software.solid.fluttervlcplayer;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.SurfaceTexture;
import android.net.Uri;
import android.os.Build;
import androidx.annotation.RequiresApi;
import android.util.Base64;
import android.view.TextureView;
import android.view.View;

import org.videolan.libvlc.IVLCVout;
import org.videolan.libvlc.LibVLC;
import org.videolan.libvlc.Media;
import org.videolan.libvlc.MediaPlayer;

import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.io.File;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.EventChannel.EventSink;
import io.flutter.plugin.common.EventChannel.StreamHandler;

class FlutterVideoView implements PlatformView, MethodChannel.MethodCallHandler,StreamHandler, MediaPlayer.EventListener {
    private final MethodChannel channel;
    private final EventChannel eventChannel;
    private final Context context;

    private MediaPlayer mediaPlayer;
    private TextureView textureView;
    private String url;
    private String subtitle;
    private Boolean isLocal;
    private int duration;
    private int position;
    private EventSink events;
    private Boolean isPlaying;
    private float rate;
    private IVLCVout vout;
    private MethodChannel.Result result;
    private boolean replyAlreadySubmitted = false;

    @RequiresApi(api = Build.VERSION_CODES.O)
    public FlutterVideoView(Context context, BinaryMessenger messenger, int id) {
        this.context = context;
        textureView = new TextureView(context);
        SurfaceTexture texture = new SurfaceTexture(false);
        textureView.setSurfaceTexture(texture);
        channel = new MethodChannel(messenger, "flutter_video_plugin/getVideoView_" + id);
        eventChannel = new EventChannel(messenger, "flutter_video_plugin/event_"+id);
        channel.setMethodCallHandler(this);
        eventChannel.setStreamHandler(this);
    }

    @Override
    public View getView() {
        return textureView;
    }

    @Override
    public void dispose() {
        mediaPlayer.stop();
        vout.detachViews();
    }

    @Override
    public void onListen(Object arguments, EventSink events) {
        this.events = events;
    }

    @Override
    public void onCancel(Object arguments) {
        this.events=null;
    }


    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        switch (methodCall.method) {
            case "playVideo":
                this.result = result;
                if (textureView == null) {
                    textureView = new TextureView(context);
                }
                url = methodCall.argument("url");
                isLocal = methodCall.argument("isLocal");
                subtitle = methodCall.argument("subtitle");

                ArrayList<String> options = new ArrayList<>();
                options.add("--no-drop-late-frames");
                options.add("--no-skip-frames");

                LibVLC libVLC = new LibVLC(context, options);
                Media media = null;
                if (isLocal)
                    media = new Media(libVLC, Uri.fromFile(new File(url)));
                else {
                    options.add("--rtsp-tcp");
                    media = new Media(libVLC, Uri.parse(Uri.decode(url)));
                }
                media.setHWDecoderEnabled(true, true);

                mediaPlayer = new MediaPlayer(libVLC);
                mediaPlayer.setVideoTrackEnabled(true);
                vout = mediaPlayer.getVLCVout();
                textureView.forceLayout();
                textureView.setFitsSystemWindows(true);
                vout.setVideoView(textureView);

                vout.attachViews();
                mediaPlayer.setMedia(media);
                if (!subtitle.isEmpty())
                    mediaPlayer.addSlave(Media.Slave.Type.Subtitle, subtitle, true);

                mediaPlayer.setEventListener(this);
                mediaPlayer.play();
                break;
            case "dispose":
                mediaPlayer.stop();
                vout.detachViews();
                break;
            case "getSnapshot":
                String imageBytes;
                Map<String, String> response = new HashMap<>();
                if (mediaPlayer.isPlaying()) {
                    Bitmap bitmap = textureView.getBitmap();
                    ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
                    bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);
                    imageBytes = Base64.encodeToString(outputStream.toByteArray(), Base64.DEFAULT);
                    response.put("snapshot", imageBytes);
                    textureView.setDrawingCacheEnabled(false);
                    textureView.destroyDrawingCache();
                }
                result.success(response);
                break;
            case "onTap":
                if (mediaPlayer.isPlaying()) {
                    mediaPlayer.pause();
                } else {
                    mediaPlayer.play();
                }
                break;
            case "pause":
                if (mediaPlayer.isPlaying()) {
                    mediaPlayer.pause();
                }
                break;
            case "play":
                if (!mediaPlayer.isPlaying()) {
                    mediaPlayer.play();
                }
                break;
            case "isPlaying":
                result.success(mediaPlayer.isPlaying());
                break;
            case "setRate":
                rate = methodCall.argument("rate");
                mediaPlayer.setRate(rate);
                break;
            case "getRate":
                rate = mediaPlayer.getRate();
                result.success(rate);
                break;
            case "getDuration":
                duration = (int)mediaPlayer.getLength();
                result.success(duration);
                break;
            case "getPosition":
                position = (int)mediaPlayer.getTime();
                result.success(position);
                break;
            case "addSubtitle":
                subtitle = methodCall.argument("subtitle");
                mediaPlayer.addSlave(Media.Slave.Type.Subtitle, subtitle, true);
                break;
        }
    }

    @Override
    public void onEvent(MediaPlayer.Event event) {
        Map<String, String> resultMap = new HashMap<>();

        switch (event.type) {
            case MediaPlayer.Event.EndReached:
                if (this.events!=null){
                    resultMap.put("status", "end");
					resultMap.put("value", "");
                    events.success(resultMap);
                }
                break;
            case MediaPlayer.Event.PositionChanged:
                if (this.events!=null){
                    float pos = event.getPositionChanged();
                    resultMap.put("status", "pos");
                    resultMap.put("value", Float.toString(pos));
                    events.success(resultMap);
                }
                break;
            case MediaPlayer.Event.Vout:
                String aspectRatio;
                int height = 0;
                int width = 0;
                Media.VideoTrack currentVideoTrack = mediaPlayer.getCurrentVideoTrack();
                if (currentVideoTrack != null) {
                    height = currentVideoTrack.height;
                    width = currentVideoTrack.width;
                }

                if (height != 0) {
                    aspectRatio = String.valueOf(width / height);
                    resultMap.put("aspectRatio", aspectRatio);
                }

                vout.setWindowSize(textureView.getWidth(), textureView.getHeight());
                if (!replyAlreadySubmitted) {
                    result.success(resultMap);
                    replyAlreadySubmitted = true;
                }
                break;
        }
    }
}
