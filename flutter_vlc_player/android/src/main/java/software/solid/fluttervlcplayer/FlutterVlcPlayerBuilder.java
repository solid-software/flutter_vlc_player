package software.solid.fluttervlcplayer;

import android.content.Context;
import android.util.LongSparseArray;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.view.TextureRegistry;
import software.solid.fluttervlcplayer.Enums.DataSourceType;
import software.solid.fluttervlcplayer.Enums.HwAcc;

public class FlutterVlcPlayerBuilder implements Messages.VlcPlayerApi {

    private final LongSparseArray<FlutterVlcPlayer> vlcPlayers = new LongSparseArray<>();
    private FlutterVlcPlayerFactory.KeyForAssetFn keyForAsset;
    private FlutterVlcPlayerFactory.KeyForAssetAndPackageName keyForAssetAndPackageName;

    void startListening(BinaryMessenger messenger) {
        Messages.VlcPlayerApi.setUp(messenger, this);
    }

    void stopListening(BinaryMessenger messenger) {
//        disposeAllPlayers();
        Messages.VlcPlayerApi.setUp(messenger, null);
    }

    FlutterVlcPlayer build(int viewId, Context context, BinaryMessenger binaryMessenger, TextureRegistry textureRegistry, FlutterVlcPlayerFactory.KeyForAssetFn keyForAsset, FlutterVlcPlayerFactory.KeyForAssetAndPackageName keyForAssetAndPackageName) {
        this.keyForAsset = keyForAsset;
        this.keyForAssetAndPackageName = keyForAssetAndPackageName;
        // only create view for player and attach channel events
        FlutterVlcPlayer vlcPlayer = new FlutterVlcPlayer(viewId, context, binaryMessenger, textureRegistry);
        vlcPlayers.append(viewId, vlcPlayer);
        return vlcPlayer;
    }

    private void disposeAllPlayers() {
        for (int i = 0; i < vlcPlayers.size(); i++) {
            vlcPlayers.valueAt(i).dispose();
        }
        vlcPlayers.clear();
    }

    private FlutterVlcPlayer getPlayer(@NonNull Long playerId) {
        if (vlcPlayers.get(playerId) == null) {
            throw new Messages.FlutterError("player_not_found", "Player with id " + playerId + " not found", null);
        }

        return vlcPlayers.get(playerId);
    }

    @Override
    public void initialize() {
//        disposeAllPlayers();
    }

    @Override
    public void create(@NonNull Messages.CreateMessage arg) {
        FlutterVlcPlayer player = getPlayer(arg.getPlayerId());

        ArrayList<String> options = new ArrayList<>();
        if (!arg.getOptions().isEmpty())
            options.addAll(arg.getOptions());
        player.initialize(options);

        var mediaMessage = new Messages.SetMediaMessage();
        mediaMessage.setPlayerId(arg.getPlayerId());
        mediaMessage.setUri(arg.getUri());
        mediaMessage.setType(arg.getType());
        mediaMessage.setAutoPlay(arg.getAutoPlay());
        mediaMessage.setHwAcc(arg.getHwAcc());
        mediaMessage.setPackageName(arg.getPackageName());

        setStreamUrl(mediaMessage);
    }

    @Override
    public void dispose(@NonNull Long playerId) {
        FlutterVlcPlayer player = getPlayer(playerId);
        player.dispose();
        vlcPlayers.remove(playerId);
    }

    @Override
    public void setStreamUrl(@NonNull Messages.SetMediaMessage arg) {
        var player = getPlayer(arg.getPlayerId());

        String mediaUrl;
        boolean isAssetUrl;
        if (arg.getType() == DataSourceType.ASSET.ordinal()) {
            String assetLookupKey;
            if (arg.getPackageName() != null)
                assetLookupKey = keyForAssetAndPackageName.get(arg.getUri(), arg.getPackageName());
            else
                assetLookupKey = keyForAsset.get(arg.getUri());
            mediaUrl = assetLookupKey;
            isAssetUrl = true;
        } else {
            mediaUrl = arg.getUri();
            isAssetUrl = false;
        }

        if (arg.getHwAcc() == null) {
            arg.setHwAcc((long) HwAcc.AUTOMATIC.ordinal());
        }

        player.setStreamUrl(mediaUrl, isAssetUrl, arg.getAutoPlay(), arg.getHwAcc());
    }

    @Override
    public void play(@NonNull Long playerId) {
        var player = getPlayer(playerId);
        player.play();
    }

    @Override
    public void pause(@NonNull Long playerId) {
        var player = getPlayer(playerId);
        player.pause();
    }

    @Override
    public void stop(@NonNull Long playerId) {
        var player = getPlayer(playerId);
        player.stop();
    }

    @NonNull
    @Override
    public Boolean isPlaying(@NonNull Long playerId) {
        return getPlayer(playerId).isPlaying();
    }

    @NonNull
    @Override
    public Boolean isSeekable(@NonNull Long playerId) {
        return getPlayer(playerId).isSeekable();
    }

    @Override
    public void setLooping(@NonNull Long playerId, @NonNull Boolean isLooping) {
        var player = getPlayer(playerId);
        player.setLooping(isLooping);
    }

    @Override
    public void seekTo(@NonNull Long playerId, @NonNull Long position) {
        var player = getPlayer(playerId);
        player.seekTo(position);
    }

    @NonNull
    @Override
    public Long position(@NonNull Long playerId) {
        return getPlayer(playerId).getPosition();
    }

    @NonNull
    @Override
    public Long duration(@NonNull Long playerId) {
        return getPlayer(playerId).getDuration();
    }

    @NonNull
    @Override
    public Long getVolume(@NonNull Long playerId) {
        return (long) getPlayer(playerId).getVolume();
    }

    @Override
    public void setVolume(@NonNull Long playerId, @NonNull Long volume) {
        var player = getPlayer(playerId);
        player.setVolume(volume.intValue());
    }

    @Override
    public void setPlaybackSpeed(@NonNull Long playerId, @NonNull Double speed) {
        var player = getPlayer(playerId);
        player.setPlaybackSpeed(speed);
    }

    @NonNull
    @Override
    public Double getPlaybackSpeed(@NonNull Long playerId) {
        return (double) getPlayer(playerId).getPlaybackSpeed();
    }

    @Nullable
    @Override
    public String takeSnapshot(@NonNull Long playerId) {
        return getPlayer(playerId).getSnapshot();
    }

    // Subtitles

    @NonNull
    @Override
    public Long getSpuTracksCount(@NonNull Long playerId) {
        return (long) getPlayer(playerId).getSpuTracksCount();
    }

    @NonNull
    @Override
    public Map<Long, String> getSpuTracks(@NonNull Long playerId) {
        Map<Integer, String> tracks = getPlayer(playerId).getSpuTracks();

        Map<Long, String> convertedTracks = new HashMap<>();
        for (Map.Entry<Integer, String> entry : tracks.entrySet()) {
            convertedTracks.put(entry.getKey().longValue(), entry.getValue());
        }

        return convertedTracks;
    }

    @NonNull
    @Override
    public Long getSpuTrack(@NonNull Long playerId) {
        return (long) getPlayer(playerId).getSpuTrack();
    }

    @Override
    public void setSpuTrack(@NonNull Long playerId, @NonNull Long spuTrackNumber) {
        var player = getPlayer(playerId);
        player.setSpuTrack(spuTrackNumber.intValue());
    }

    @Override
    public void setSpuDelay(@NonNull Long playerId, @NonNull Long delay) {
        var player = getPlayer(playerId);
        player.setSpuDelay(delay.intValue());
    }

    @NonNull
    @Override
    public Long getSpuDelay(@NonNull Long playerId) {
        return getPlayer(playerId).getSpuDelay();
    }

    @Override
    public void addSubtitleTrack(Messages.AddSubtitleMessage arg) {
        var player = getPlayer(arg.getPlayerId());
        player.addSubtitleTrack(arg.getUri(), arg.getIsSelected());
    }

    // Audio tracks

    @NonNull
    @Override
    public Long getAudioTracksCount(@NonNull Long playerId) {
        return (long) getPlayer(playerId).getAudioTracksCount();
    }

    @NonNull
    @Override
    public Map<Long, String> getAudioTracks(@NonNull Long playerId) {
        Map<Integer, String> tracks = getPlayer(playerId).getAudioTracks();

        Map<Long, String> convertedTracks = new HashMap<>();
        for (Map.Entry<Integer, String> entry : tracks.entrySet()) {
            convertedTracks.put(entry.getKey().longValue(), entry.getValue());
        }

        return convertedTracks;
    }

    @Override
    public void setAudioTrack(@NonNull Long playerId, @NonNull Long audioTrackNumber) {
        var player = getPlayer(playerId);
        player.setAudioTrack(audioTrackNumber.intValue());
    }

    @NonNull
    @Override
    public Long getAudioTrack(@NonNull Long playerId) {
        return (long) getPlayer(playerId).getAudioTrack();
    }

    @Override
    public void setAudioDelay(@NonNull Long playerId, @NonNull Long delay) {
        var player = getPlayer(playerId);
        player.setAudioDelay(delay);
    }

    @NonNull
    @Override
    public Long getAudioDelay(@NonNull Long playerId) {
        return getPlayer(playerId).getAudioDelay();
    }

    @Override
    public void addAudioTrack(Messages.AddAudioMessage arg) {
        var player = getPlayer(arg.getPlayerId());
        player.addAudioTrack(arg.getUri(), arg.getIsSelected());
    }

    // Video tracks


    @NonNull
    @Override
    public Long getVideoTracksCount(@NonNull Long playerId) {
        return (long) getPlayer(playerId).getVideoTracksCount();
    }

    @NonNull
    @Override
    public Map<Long, String> getVideoTracks(@NonNull Long playerId) {
        Map<Integer, String> tracks = getPlayer(playerId).getVideoTracks();

        Map<Long, String> convertedTracks = new HashMap<>();
        for (Map.Entry<Integer, String> entry : tracks.entrySet()) {
            convertedTracks.put(entry.getKey().longValue(), entry.getValue());
        }

        return convertedTracks;
    }

    @Override
    public void setVideoTrack(@NonNull Long playerId, @NonNull Long videoTrackNumber) {
        var player = getPlayer(playerId);
        player.setVideoTrack(videoTrackNumber.intValue());
    }

    @NonNull
    @Override
    public Long getVideoTrack(@NonNull Long playerId) {
        return (long) getPlayer(playerId).getVideoTrack();
    }

    // Video properties


    @Override
    public void setVideoScale(@NonNull Long playerId, @NonNull Double scale) {
        var player = getPlayer(playerId);
        player.setVideoScale(scale.floatValue());
    }

    @NonNull
    @Override
    public Double getVideoScale(@NonNull Long playerId) {
        return (double) getPlayer(playerId).getVideoScale();
    }

    @Override
    public void setVideoAspectRatio(@NonNull Long playerId, @NonNull String aspectRatio) {
        var player = getPlayer(playerId);
        player.setVideoAspectRatio(aspectRatio);
    }

    @NonNull
    @Override
    public String getVideoAspectRatio(@NonNull Long playerId) {
        return getPlayer(playerId).getVideoAspectRatio();
    }

    // Cast


    @NonNull
    @Override
    public List<String> getAvailableRendererServices(@NonNull Long playerId) {
        return getPlayer(playerId).getAvailableRendererServices();
    }

    @Override
    public void startRendererScanning(@NonNull Long playerId, @NonNull String rendererService) {
        var player = getPlayer(playerId);
        player.startRendererScanning(rendererService);
    }

    @Override
    public void stopRendererScanning(@NonNull Long playerId) {
        var player = getPlayer(playerId);
        player.stopRendererScanning();
    }

    @NonNull
    @Override
    public Map<String, String> getRendererDevices(@NonNull Long playerId) {
        return getPlayer(playerId).getRendererDevices();
    }

    @Override
    public void castToRenderer(@NonNull Long playerId, @NonNull String rendererId) {
        var player = getPlayer(playerId);
        player.castToRenderer(rendererId);
    }

    // Recording


    @NonNull
    @Override
    public Boolean startRecording(@NonNull Long playerId, @NonNull String saveDirectory) {
        var player = getPlayer(playerId);
        return player.startRecording(saveDirectory);
    }

    @NonNull
    @Override
    public Boolean stopRecording(@NonNull Long playerId) {
        var player = getPlayer(playerId);
        return player.stopRecording();
    }
}
