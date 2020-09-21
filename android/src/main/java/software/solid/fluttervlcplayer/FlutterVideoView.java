package software.solid.fluttervlcplayer;

import android.annotation.SuppressLint;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.PixelFormat;
import android.graphics.SurfaceTexture;
import android.net.Uri;
import android.util.Base64;
import android.util.Log;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.SurfaceView;
import android.view.TextureView;
import android.view.View;
import android.view.ViewGroup;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;

import io.flutter.plugin.common.*;
import io.flutter.plugin.platform.PlatformView;
import io.flutter.view.TextureRegistry;

import org.videolan.libvlc.interfaces.IVLCVout;
import org.videolan.libvlc.LibVLC;
import org.videolan.libvlc.Media;
import org.videolan.libvlc.MediaPlayer;
import org.videolan.libvlc.RendererDiscoverer;
import org.videolan.libvlc.RendererItem;

import java.io.ByteArrayOutputStream;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;
import java.util.List;
import java.lang.Math;
import java.io.File;

class FlutterVideoView implements PlatformView, MethodChannel.MethodCallHandler, MediaPlayer.EventListener {

    // Silences player log output.
    private static final String TAG = "Flutter VLC";
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
    private RendererDiscoverer rendererDiscoverer;
    private List<RendererItem> rendererItems;
    private boolean playerDisposed;
    private boolean autoplay = true;
    private boolean firstRun = true;

    /**
     * HACK: handler to call updateVideoSurfaces as soon as a video output
     * is created. It is currently mandatory to have the video being displayed
     * instead of a black screen.
     */
    Handler mHandler = new Handler(Looper.getMainLooper());

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

            boolean wasPlaying = false;

            private final Runnable mRunnable = new Runnable() {
                @Override
                public void run() {
                    if (vout == null) return;
                    vout.setVideoSurface(new Surface(textureView.getSurfaceTexture()), null);
                    vout.attachViews();
                    textureView.forceLayout();
                    mediaPlayer.play();
                    wasPlaying = false;
                }
            };

            @Override
            public void onSurfaceTextureAvailable(SurfaceTexture surface, int width, int height) {
                mHandler.removeCallbacks(mRunnable);
                mHandler.postDelayed(mRunnable, 1000);
            }

            @Override
            public void onSurfaceTextureSizeChanged(SurfaceTexture surface, int width, int height) {

            }

            @Override
            public boolean onSurfaceTextureDestroyed(SurfaceTexture surface) {
                if (playerDisposed) {
                    if (mediaPlayer != null) {
                        mediaPlayer.stop();
                        mediaPlayer.setEventListener(null);
                        mediaPlayer.getVLCVout().detachViews();
                        mediaPlayer.release();
                        libVLC.release();
                        libVLC = null;
                        mediaPlayer = null;
                        vout = null;
                    }
                    return true;
                } else {
                    if (mediaPlayer != null && vout != null) {
                        wasPlaying = mediaPlayer.isPlaying();
                        mediaPlayer.pause();
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
        if (mediaPlayer != null) {
            mediaPlayer.stop();
            mediaPlayer.setEventListener(null);
        }
        if (vout != null) {
            vout.detachViews();
        }
        playerDisposed = true;
    }


    // Suppress WrongThread warnings from IntelliJ / Android Studio, because it looks like the advice
    // is wrong and actually breaks the library.
    @SuppressLint("WrongThread")
    @Override
    public void onMethodCall(MethodCall methodCall, @NonNull MethodChannel.Result result) {

        boolean isLocalMedia = false;
        String subtitle = "";
        boolean isLocalSubtitle = false;
        boolean isSubtitleSelected = true;
        boolean loop = false;

        switch (methodCall.method) {
            case "initialize":
                if (textureView == null) {
                    textureView = new TextureView(context);
                }
                //
                ArrayList<String> options = methodCall.argument("options");
                autoplay = methodCall.argument("autoplay");
                isLocalMedia = methodCall.argument("isLocalMedia");
                subtitle = methodCall.argument("subtitle");
                isLocalSubtitle = methodCall.argument("isLocalSubtitle");
                isSubtitleSelected = methodCall.argument("isSubtitleSelected");
                loop = methodCall.argument("loop");
                if (loop)
                    options.add("--input-repeat=65535");
                //
                libVLC = new LibVLC(context, options);
                mediaPlayer = new MediaPlayer(libVLC);
                mediaPlayer.setVideoTrackEnabled(true);
                mediaPlayer.setEventListener(this);
                vout = mediaPlayer.getVLCVout();
                textureView.forceLayout();
                textureView.setFitsSystemWindows(true);
                vout.setVideoSurface(new Surface(textureView.getSurfaceTexture()), null);
                vout.attachViews();
                //
                String initStreamURL = methodCall.argument("url");
                Media media = new Media(libVLC, getStreamUri(initStreamURL, isLocalMedia));
                //
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
                //
                media.addOption(":input-fast-seek");
                mediaPlayer.setMedia(media);
                if (!subtitle.isEmpty())
                    mediaPlayer.addSlave(Media.Slave.Type.Subtitle, getStreamUri(subtitle, isLocalSubtitle), isSubtitleSelected);
                //
                media.release();
                result.success(null);
                break;

            case "dispose":
                this.dispose();
                break;

            case "changeURL":
                if (libVLC == null)
                    result.error("VLC_NOT_INITIALIZED", "The player has not yet been initialized.", false);

                boolean isPlaying = mediaPlayer.isPlaying();
                mediaPlayer.stop();
                String newURL = methodCall.argument("url");
                isLocalMedia = methodCall.argument("isLocalMedia");
                subtitle = methodCall.argument("subtitle");
                isLocalSubtitle = methodCall.argument("isLocalSubtitle");
                isSubtitleSelected = methodCall.argument("isSubtitleSelected");
                //
                Media newMedia = new Media(libVLC, getStreamUri(newURL, isLocalMedia));
                mediaPlayer.setMedia(newMedia);
                if (!subtitle.isEmpty())
                    mediaPlayer.addSlave(Media.Slave.Type.Subtitle, getStreamUri(subtitle, isLocalSubtitle), isSubtitleSelected);
                newMedia.release();
                if (isPlaying)
                    mediaPlayer.play();
                result.success(null);
                break;

            case "getSnapshot":
                String imageBytes;
                Map<String, String> response = new HashMap<>();
                Bitmap bitmap = textureView.getBitmap();
                ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
                bitmap.compress(Bitmap.CompressFormat.JPEG, 100, outputStream);
                imageBytes = Base64.encodeToString(outputStream.toByteArray(), Base64.DEFAULT);
                response.put("snapshot", imageBytes);
                result.success(response);
                break;

            case "setPlaybackState":
                String playbackState = methodCall.argument("playbackState");
                if (playbackState == null) result.success(null);

                switch (playbackState) {
                    case "play":
                        firstRun = false;
                        textureView.forceLayout();
                        if (!mediaPlayer.isPlaying())
                            mediaPlayer.play();
                        break;
                    case "pause":
                        if (mediaPlayer.isPlaying())
                            mediaPlayer.pause();
                        break;
                    case "stop":
                        mediaPlayer.stop();
                        break;
                }
                result.success(null);
                break;

            case "isPlaying":
                result.success(mediaPlayer.isPlaying());
                break;

            case "setPlaybackSpeed":
                float playbackSpeed = Float.parseFloat((String) methodCall.argument("speed"));
                mediaPlayer.setRate(playbackSpeed);
                result.success(null);
                break;

            case "getPlaybackSpeed":
                playbackSpeed = mediaPlayer.getRate();
                result.success(playbackSpeed);
                break;

            case "setTime":
                long time = Long.parseLong((String) methodCall.argument("time"));
                mediaPlayer.setTime(time);
                result.success(null);
                break;

            case "getTime":
                time = mediaPlayer.getTime();
                result.success(time);
                break;

            case "getDuration":
                long duration = mediaPlayer.getLength();
                result.success(duration);
                break;

            case "setVolume":
                int volume = methodCall.argument("volume");
                volume = Math.max(0, Math.min(100, volume));
                mediaPlayer.setVolume(volume);
                result.success(null);
                break;

            case "getVolume":
                volume = mediaPlayer.getVolume();
                result.success(volume);
                break;

            case "getSpuTracksCount":
                result.success(mediaPlayer.getSpuTracksCount());
                break;

            case "getSpuTracks":
                MediaPlayer.TrackDescription[] spuTracks = mediaPlayer.getSpuTracks();
                Map<Integer, String> subtitles = new HashMap<>();
                if (spuTracks != null)
                    for (MediaPlayer.TrackDescription trackDescription : spuTracks) {
                        if (trackDescription.id >= 0)
                            subtitles.put(trackDescription.id, trackDescription.name);
                    }
                result.success(subtitles);
                break;

            case "setSpuTrack":
                int spuTrackNumber = methodCall.argument("spuTrackNumber");
                mediaPlayer.setSpuTrack(spuTrackNumber);
                result.success(null);
                break;

            case "getSpuTrack":
                result.success(mediaPlayer.getSpuTrack());
                break;

            case "setSpuDelay":
                long spuDelay = Long.parseLong((String) methodCall.argument("delay"));
                mediaPlayer.setSpuDelay(spuDelay);
                result.success(null);
                break;

            case "getSpuDelay":
                spuDelay = mediaPlayer.getSpuDelay();
                result.success(spuDelay);
                break;

            case "addSubtitleTrack":
                subtitle = methodCall.argument("subtitlePath");
                isLocalSubtitle = methodCall.argument("isLocalSubtitle");
                isSubtitleSelected = methodCall.argument("isSubtitleSelected");
                if (!subtitle.isEmpty())
                    mediaPlayer.addSlave(Media.Slave.Type.Subtitle, getStreamUri(subtitle, isLocalSubtitle), isSubtitleSelected);
                result.success(null);
                break;

            case "getAudioTracksCount":
                result.success(mediaPlayer.getAudioTracksCount());
                break;

            case "getAudioTracks":
                MediaPlayer.TrackDescription[] audioTracks = mediaPlayer.getAudioTracks();
                Map<Integer, String> audios = new HashMap<>();
                if (audioTracks != null)
                    for (MediaPlayer.TrackDescription trackDescription : audioTracks) {
                        if (trackDescription.id >= 0)
                            audios.put(trackDescription.id, trackDescription.name);
                    }
                result.success(audios);
                break;

            case "getAudioTrack":
                result.success(mediaPlayer.getAudioTrack());
                break;

            case "setAudioTrack":
                int audioTrackNumber = methodCall.argument("audioTrackNumber");
                mediaPlayer.setAudioTrack(audioTrackNumber);
                result.success(null);
                break;

            case "setAudioDelay":
                long audioDelay = Long.parseLong((String) methodCall.argument("delay"));
                mediaPlayer.setAudioDelay(audioDelay);
                result.success(null);
                break;

            case "getAudioDelay":
                audioDelay = mediaPlayer.getAudioDelay();
                result.success(audioDelay);
                break;

            case "getVideoTracksCount":
                result.success(mediaPlayer.getVideoTracksCount());
                break;

            case "getVideoTracks":
                MediaPlayer.TrackDescription[] videoTracks = mediaPlayer.getVideoTracks();
                Map<Integer, String> videos = new HashMap<>();
                if (videoTracks != null)
                    for (MediaPlayer.TrackDescription trackDescription : videoTracks) {
                        if (trackDescription.id >= 0)
                            videos.put(trackDescription.id, trackDescription.name);
                    }
                result.success(videos);
                break;

            case "getCurrentVideoTrack":
                result.success(mediaPlayer.getCurrentVideoTrack());
                break;

            case "getVideoTrack":
                result.success(mediaPlayer.getVideoTrack());
                break;

            case "setVideoScale":
                float videoScale = Float.parseFloat((String) methodCall.argument("scale"));
                mediaPlayer.setScale(videoScale);
                result.success(null);
                break;

            case "getVideoScale":
                result.success(mediaPlayer.getScale());
                break;

            case "setVideoAspectRatio":
                String aspect = methodCall.argument("aspect");
                mediaPlayer.setAspectRatio(aspect);
                result.success(null);
                break;

            case "getVideoAspectRatio":
                result.success(mediaPlayer.getAspectRatio());
                break;

            case "startCastDiscovery":
                startCastsDiscovery();
                result.success(null);
                break;

            case "stopCastDiscovery":
                stopCastsDiscovery();
                result.success(null);
                break;

            case "getCastDevices":
                Map<String, String> casts = new HashMap<>();
                if (rendererItems != null)
                    for (RendererItem item : rendererItems) {
                        casts.put(item.name, item.displayName);
                    }
                result.success(casts);
                break;

            case "startCasting":
                String castDevice = methodCall.argument("startCasting");
                startCasting(castDevice);
                result.success(null);
                break;
        }
    }

    @Override
    public void onEvent(MediaPlayer.Event event) {
        HashMap<String, Object> eventObject = new HashMap<>();
        switch (event.type) {

            case MediaPlayer.Event.Opening:
                eventObject.put("name", "buffering");
                eventObject.put("value", true);
                eventSink.success(eventObject);
                break;

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
                // add support for changing audio tracks and subtitles
                eventObject.put("audioTracksCount", mediaPlayer.getAudioTracksCount());
                eventObject.put("activeAudioTrack", mediaPlayer.getAudioTrack());
                eventObject.put("spuTracksCount", mediaPlayer.getSpuTracksCount());
                eventObject.put("activeSpuTrack", mediaPlayer.getSpuTrack());
                //
                eventSink.success(eventObject.clone());
                //
                if (firstRun && !autoplay)
                    mediaPlayer.pause();
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

            case MediaPlayer.Event.Buffering:
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
                eventObject.clear();
                eventObject.put("name", "paused");
                eventObject.put("value", true);
                eventSink.success(eventObject);
                break;

            case MediaPlayer.Event.Stopped:
                eventObject.clear();
                eventObject.put("name", "stopped");
                eventObject.put("value", true);
                eventSink.success(eventObject);
                break;
        }
    }

    private Uri getStreamUri(String streamPath, boolean isLocal) {
        return isLocal ? Uri.fromFile(new File(streamPath)) : Uri.parse(streamPath);
    }

    private void startCastsDiscovery() {
        if (libVLC == null)
            return;

        // create list of renderer items
        rendererItems = new ArrayList<>();

        // create a renderer discoverer
        rendererDiscoverer = new RendererDiscoverer(libVLC, "microdns");

        // register callback when a new renderer is found
        rendererDiscoverer.setEventListener(new RendererDiscoverer.EventListener() {
            @Override
            public void onEvent(RendererDiscoverer.Event event) {
                HashMap<String, Object> eventObject = new HashMap<>();
                //
                RendererItem item = event.getItem();
                switch (event.type) {

                    case RendererDiscoverer.Event.ItemAdded:
                        rendererItems.add(item);
                        //
                        eventObject.put("name", "castItemAdded");
                        eventObject.put("value", item.name);
                        eventObject.put("displayName", item.displayName);
                        eventSink.success(eventObject);
                        break;

                    case RendererDiscoverer.Event.ItemDeleted:
                        rendererItems.remove(item);
                        //
                        eventObject.put("name", "castItemDeleted");
                        eventObject.put("value", item.name);
                        eventObject.put("displayName", item.displayName);
                        eventSink.success(eventObject);
                        break;

                    default:
                        break;
                }
            }
        });

        // start discovery on the local network
        rendererDiscoverer.start();
    }

    private void stopCastsDiscovery() {
        if (rendererDiscoverer != null) {
            rendererDiscoverer.stop();
            rendererDiscoverer.setEventListener(null);
            rendererDiscoverer = null;
            //
            rendererItems.clear();
            rendererItems = null;
            //
            // return back to locally
            if (mediaPlayer != null) {
                mediaPlayer.pause();
                mediaPlayer.setRenderer(null);
                mediaPlayer.play();
            }
        }
    }

    private void startCasting(String castDevice) {
        if ((libVLC == null) || (mediaPlayer == null))
            return;
        //
        boolean isPlaying = mediaPlayer.isPlaying();
        if (isPlaying)
            mediaPlayer.pause();
        //
        // set the first discovered renderer item (chromecast) on the mediaplayer
        // if you set it to null, it will start to render normally (i.e. locally) again
        RendererItem castItem = null;
        for (RendererItem item : rendererItems) {
            if (item.name.equals(castDevice)) {
                castItem = item;
                break;
            }
        }
        mediaPlayer.setRenderer(castItem);

        // start the playback
        mediaPlayer.play();
    }
}
