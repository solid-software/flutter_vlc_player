package software.solid.fluttervlcplayer;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.SurfaceTexture;
import android.net.Uri;
import android.util.Base64;
import android.view.Surface;
import android.view.TextureView;
import android.view.View;

import androidx.annotation.NonNull;

import io.flutter.plugin.common.*;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.view.TextureRegistry;

import org.videolan.libvlc.IVLCVout;
import org.videolan.libvlc.LibVLC;
import org.videolan.libvlc.Media;
import org.videolan.libvlc.MediaPlayer;

import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

class FlutterVideoView implements PlatformView, MethodChannel.MethodCallHandler, MediaPlayer.EventListener {

    // Silences player log output.
    private static final boolean DISABLE_LOG_OUTPUT = true;
    private static final int HW_ACCELERATION_AUTOMATIC = -1;
    private static final int HW_ACCELERATION_DISABLED = 0;
    private static final int HW_ACCELERATION_DECODING = 1;
    private static final int HW_ACCELERATION_FULL = 2;

    final PluginRegistry.Registrar registrar;
    private final MethodChannel methodChannel;

    private QueuingEventSink eventSink;
    private final EventChannel eventChannel;

    private final Context context;

    private LibVLC libVLC;
    private MediaPlayer mediaPlayer;
    private TextureView textureView;
    private IVLCVout vout;
    private boolean playerDisposed;

    public FlutterVideoView(Context context, PluginRegistry.Registrar _registrar, BinaryMessenger messenger, int id) {
        this.playerDisposed = false;

        this.context = context;
        this.registrar = _registrar;

        eventSink = new QueuingEventSink();
        eventChannel = new EventChannel(messenger, "flutter_video_plugin/getVideoEvents_" + id);

        eventChannel.setStreamHandler(
                new EventChannel.StreamHandler() {
                    @Override
                    public void onListen(Object o, EventChannel.EventSink sink) {
                        eventSink.setDelegate(sink);
                    }

                    @Override
                    public void onCancel(Object o) {
                        eventSink.setDelegate(null);
                    }
                }
        );

        TextureRegistry.SurfaceTextureEntry textureEntry = registrar.textures().createSurfaceTexture();
        textureView = new TextureView(context);
        textureView.setSurfaceTexture(textureEntry.surfaceTexture());
        textureView.setSurfaceTextureListener(new TextureView.SurfaceTextureListener() {

            boolean wasPaused = false;

            @Override
            public void onSurfaceTextureAvailable(SurfaceTexture surface, int width, int height) {
                if (vout == null) return;

                vout.setVideoSurface(new Surface(textureView.getSurfaceTexture()), null);
                vout.attachViews();
                textureView.forceLayout();
                if (wasPaused) {
                    mediaPlayer.play();
                    wasPaused = false;
                }
            }

            @Override
            public void onSurfaceTextureSizeChanged(SurfaceTexture surface, int width, int height) {

            }

            @Override
            public boolean onSurfaceTextureDestroyed(SurfaceTexture surface) {
                if (playerDisposed) {
                    if (mediaPlayer != null) {
                        mediaPlayer.stop();
                        mediaPlayer.release();
                        mediaPlayer = null;
                    }
                    return true;
                } else {
                    if (mediaPlayer != null && vout != null) {
                        mediaPlayer.pause();
                        wasPaused = true;
                        vout.detachViews();
                    }
                    return true;
                }
            }

            @Override
            public void onSurfaceTextureUpdated(SurfaceTexture surface) {

            }

        });

        methodChannel = new MethodChannel(messenger, "flutter_video_plugin/getVideoView_" + id);
        methodChannel.setMethodCallHandler(this);
    }

    @Override
    public View getView() {
        return textureView;
    }

    @Override
    public void dispose() {
        if (mediaPlayer != null) mediaPlayer.stop();
        if (vout != null) vout.detachViews();
        playerDisposed = true;
    }


    // Suppress WrongThread warnings from IntelliJ / Android Studio, because it looks like the advice
    // is wrong and actually breaks the library.
    @SuppressLint("WrongThread")
    @Override
    public void onMethodCall(MethodCall methodCall, @NonNull MethodChannel.Result result) {
        switch (methodCall.method) {
            case "initialize":
                if (textureView == null) {
                    textureView = new TextureView(context);
                }

                ArrayList<String> options = methodCall.argument("options");

                libVLC = new LibVLC(context, options);
                mediaPlayer = new MediaPlayer(libVLC);
                //mediaPlayer.setVideoTrackEnabled(true);
                mediaPlayer.setEventListener(this);
                vout = mediaPlayer.getVLCVout();
                textureView.forceLayout();
                textureView.setFitsSystemWindows(true);
                vout.setVideoSurface(new Surface(textureView.getSurfaceTexture()), null);
                vout.attachViews();

                String initStreamURL = methodCall.argument("url");
                Media media = new Media(libVLC, Uri.parse(initStreamURL));

                int hardwareAcceleration = methodCall.argument("hwAcc");
                if (hardwareAcceleration != HW_ACCELERATION_AUTOMATIC) 
                    if (hardwareAcceleration == HW_ACCELERATION_DISABLED) {
                        media.setHWDecoderEnabled(false, false);
                    } else if (hardwareAcceleration == HW_ACCELERATION_FULL || hardwareAcceleration == HW_ACCELERATION_DECODING) {
                        media.setHWDecoderEnabled(true, true);
                        if (hardwareAcceleration == HW_ACCELERATION_DECODING) {
                            media.addOption(":no-mediacodec-dr");
                            media.addOption(":no-omxil-dr");
                        } 
                    }

                media.addOption(":input-fast-seek");
                mediaPlayer.setMedia(media);
                result.success(null);
                break;
            case "dispose":
                this.dispose();
                break;
            case "changeURL":
                if (libVLC == null)
                    result.error("VLC_NOT_INITIALIZED", "The player has not yet been initialized.", false);

                mediaPlayer.stop();
                String newURL = methodCall.argument("url");
                Media newMedia = new Media(libVLC, Uri.parse(newURL));
                mediaPlayer.setMedia(newMedia);
                result.success(null);
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
                }
                result.success(response);
                break;
            case "setPlaybackState":

                String playbackState = methodCall.argument("playbackState");
                if (playbackState == null) result.success(null);

                switch (playbackState) {
                    case "play":
                        textureView.forceLayout();
                        mediaPlayer.play();
                        break;
                    case "pause":
                        mediaPlayer.pause();
                        break;
                    case "stop":
                        mediaPlayer.stop();
                        break;
                }

                result.success(null);
                break;

            case "setPlaybackSpeed":

                float playbackSpeed = Float.parseFloat((String) methodCall.argument("speed"));
                mediaPlayer.setRate(playbackSpeed);

                result.success(null);
                break;

            case "setTime":

                long time = Long.parseLong((String) methodCall.argument("time"));
                mediaPlayer.setTime(time);

                result.success(null);
                break;

            case "setVolume":
                int volume = 100;
                volume =  methodCall.argument("volume");
                mediaPlayer.setVolume(volume);
                result.success(null);
                break;


        }
    }

    @Override
    public void onEvent(MediaPlayer.Event event) {
        HashMap<String, Object> eventObject = new HashMap<>();

        switch (event.type) {
            case MediaPlayer.Event.Playing:
                // Insert buffering=false event first:
                eventObject.put("name", "buffering");
                eventObject.put("value", false);
                eventSink.success(eventObject.clone());
                eventObject.clear();

                // Now send playing info:
                int height = 0;
                int width = 0;

                Media.VideoTrack currentVideoTrack = (Media.VideoTrack) mediaPlayer.getMedia().getTrack(
                        mediaPlayer.getVideoTrack()
                );
                if (currentVideoTrack != null) {
                    height = currentVideoTrack.height;
                    width = currentVideoTrack.width;
                }

                eventObject.put("name", "playing");
                eventObject.put("value", true);
                eventObject.put("ratio", height > 0 ? (double) width / (double) height : 0D);
                eventObject.put("height", height);
                eventObject.put("width", width);
                eventObject.put("length", mediaPlayer.getLength());
                eventSink.success(eventObject.clone());
                break;

            case MediaPlayer.Event.EndReached:
                mediaPlayer.stop();
                eventObject.put("name", "ended");
                eventSink.success(eventObject);

                eventObject.clear();
                eventObject.put("name", "playing");
                eventObject.put("value", false);
                eventObject.put("reason", "EndReached");
                eventSink.success(eventObject);

            case MediaPlayer.Event.Vout:
                vout.setWindowSize(textureView.getWidth(), textureView.getHeight());
                break;

            case MediaPlayer.Event.TimeChanged:
                eventObject.put("name", "timeChanged");
                eventObject.put("value", mediaPlayer.getTime());
                eventObject.put("speed", mediaPlayer.getRate());
                eventSink.success(eventObject);
                break;

            case MediaPlayer.Event.EncounteredError:
                System.err.println("(flutter_vlc_plugin) A VLC error occurred.");
                eventSink.error("error", "A VLC error occurred.", null);
                break;
                
            case MediaPlayer.Event.Paused:
            case MediaPlayer.Event.Stopped:
                eventObject.put("name", "buffering");
                eventObject.put("value", false);
                eventSink.success(eventObject);

                eventObject.clear();
                eventObject.put("name", "playing");
                eventObject.put("value", false);
                eventSink.success(eventObject);
                break;
        }
    }
}
