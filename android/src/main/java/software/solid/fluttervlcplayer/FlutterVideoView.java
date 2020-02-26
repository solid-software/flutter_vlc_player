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

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

class FlutterVideoView implements PlatformView, MethodChannel.MethodCallHandler, MediaPlayer.EventListener {
    private final MethodChannel channel;
    private final Context context;

    private MediaPlayer mediaPlayer;
    private TextureView textureView;
    private String url;
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
        channel.setMethodCallHandler(this);
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
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        switch (methodCall.method) {
            case "playVideo":
                this.result = result;
                if (textureView == null) {
                    textureView = new TextureView(context);
                }
                url = methodCall.argument("url");

                ArrayList<String> options = new ArrayList<>();
                options.add("--no-drop-late-frames");
                options.add("--no-skip-frames");
                options.add("--rtsp-tcp");

                LibVLC libVLC = new LibVLC(context, options);
                Media media = new Media(libVLC, Uri.parse(Uri.decode(url)));
                mediaPlayer = new MediaPlayer(libVLC);
                mediaPlayer.setVideoTrackEnabled(true);
                vout = mediaPlayer.getVLCVout();
                textureView.forceLayout();
                textureView.setFitsSystemWindows(true);
                vout.setVideoView(textureView);

                vout.attachViews();
                mediaPlayer.setMedia(media);
                mediaPlayer.setEventListener(this);
                mediaPlayer.play();
                break;
            case "dispose":
                mediaPlayer.stop();
                vout.detachViews();
                break;
            case "play":
                mediaPlayer.play();
                Map<String, String> playResponse = new HashMap<>();
                playResponse.put("player", "palayer start play");
                result.success(playResponse);
                break;
            case "pause":
                mediaPlayer.pause();
                Map<String, String> pauseResponse = new HashMap<>();
                pauseResponse.put("pause", "pause player");
                result.success(pauseResponse);
                break;
            case "isPlaying":
                Map<String, String> isPlayingResponse = new HashMap<>();
                String isPlaying = String.valueOf(mediaPlayer.isPlaying());
                isPlayingResponse.put("isPlaying", isPlaying);
                result.success(isPlayingResponse);
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
        }
    }

    @Override
    public void onEvent(MediaPlayer.Event event) {
        Map<String, String> resultMap = new HashMap<>();

        switch (event.type) {
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
