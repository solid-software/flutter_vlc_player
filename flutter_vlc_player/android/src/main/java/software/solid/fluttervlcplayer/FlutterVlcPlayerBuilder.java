package software.solid.fluttervlcplayer;

import android.content.Context;
import android.util.LongSparseArray;

import java.util.ArrayList;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.view.TextureRegistry;
import software.solid.fluttervlcplayer.Enums.DataSourceType;

public class FlutterVlcPlayerBuilder implements Messages.VlcPlayerApi {

    private final LongSparseArray<FlutterVlcPlayer> vlcPlayers = new LongSparseArray<>();
    private final LongSparseArray<FlutterVlcPlayerTexture> vlcPlayersTexture = new LongSparseArray<>();
    private final TextureRegistry textureRegistry;
    private final BinaryMessenger binaryMessenger;
    private final FlutterVlcPlayerFactory.KeyForAssetFn keyForAsset;
    private final FlutterVlcPlayerFactory.KeyForAssetAndPackageName keyForAssetAndPackageName;
    private Context context;

    public FlutterVlcPlayerBuilder(BinaryMessenger messenger, TextureRegistry textureRegistry, FlutterVlcPlayerFactory.KeyForAssetFn keyForAsset, FlutterVlcPlayerFactory.KeyForAssetAndPackageName keyForAssetAndPackageName, Context context) {
        this.textureRegistry = textureRegistry;
        this.binaryMessenger = messenger;
        this.keyForAsset = keyForAsset;
        this.keyForAssetAndPackageName = keyForAssetAndPackageName;
        this.context = context;
    }

    void startListening(BinaryMessenger messenger) {
        Messages.VlcPlayerApi.setup(messenger, this);
    }

    void stopListening(BinaryMessenger messenger) {
//        disposeAllPlayers();
        Messages.VlcPlayerApi.setup(messenger, null);
    }

    FlutterVlcPlayer build(int viewId, Context context) {
        // only create view for player and attach channel events
        FlutterVlcPlayer vlcPlayer = new FlutterVlcPlayer(viewId, context, binaryMessenger, textureRegistry);
        vlcPlayers.append(viewId, vlcPlayer);
        return vlcPlayer;
    }

    public void disposeAllPlayers() {
        for (int i = 0; i < vlcPlayers.size(); i++) {
            vlcPlayers.valueAt(i).dispose();
        }
        vlcPlayers.clear();
        for (int i = 0; i < vlcPlayersTexture.size(); i++) {
            vlcPlayersTexture.valueAt(i).dispose();
        }
        vlcPlayersTexture.clear();
    }

    public void setContext(Context context) {
        this.context = context;
    }

    @Override
    public void initialize() {
//        disposeAllPlayers();
    }

    @Override
    public Messages.IntMessage createTextureEntry(Messages.CreateTextureMessage arg) {
        TextureRegistry.SurfaceTextureEntry entry = textureRegistry.createSurfaceTexture();
        vlcPlayersTexture.append(entry.id(), new FlutterVlcPlayerTexture(context, binaryMessenger, entry, arg));

        Messages.IntMessage ret = new Messages.IntMessage();
        ret.setViewId(entry.id());
        ret.setResult(entry.id());
        return ret;
    }

    @Override
    public void disposeTextureEntry(Messages.IntMessage arg) {
        FlutterVlcPlayerTexture player = vlcPlayersTexture.get(arg.getViewId());
        if (player != null) {
            player.dispose();
            vlcPlayersTexture.remove(arg.getViewId());
        }
    }

    @Override
    public void create(Messages.CreateMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        //
        ArrayList<String> options = new ArrayList<String>();
        if (arg.getOptions().size() > 0)
            for (Object option : arg.getOptions())
                options.add((String) option);
        player.initialize(options);
        //
        String mediaUrl;
        boolean isAssetUrl;
        if (arg.getType() == DataSourceType.ASSET.getNumericType()) {
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
        player.setStreamUrl(mediaUrl, isAssetUrl, arg.getAutoPlay(), arg.getHwAcc());
    }

    FlutterVlcPlayerInterface getPlayer(Long viewId, Boolean isTexture) {
        if (isTexture == null) {
            isTexture = false;
        }
        if (isTexture) {
            return vlcPlayersTexture.get(viewId);
        } else {
            return vlcPlayers.get(viewId);
        }
    }

    @Override
    public void dispose(Messages.ViewMessage arg) {
        Boolean isTexture = arg.getIsTexture();
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), isTexture);
        if (isTexture) {
            player.dispose();
            vlcPlayersTexture.remove(arg.getViewId());
        } else {
            // the player has been already disposed by platform we just remove it from players list
            vlcPlayers.remove(arg.getViewId());
        }
    }

    @Override
    public void setStreamUrl(Messages.SetMediaMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        //
        boolean isAssetUrl;
        String mediaUrl;
        if (arg.getType() == DataSourceType.ASSET.getNumericType()) {
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
        player.setStreamUrl(mediaUrl, isAssetUrl, arg.getAutoPlay(), arg.getHwAcc());
    }

    @Override
    public void play(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        player.play();
    }

    @Override
    public void pause(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        player.pause();
    }

    @Override
    public void stop(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        player.stop();
    }

    @Override
    public Messages.BooleanMessage isPlaying(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.BooleanMessage message = new Messages.BooleanMessage();
        message.setResult(player.isPlaying());
        return message;
    }

    @Override
    public Messages.BooleanMessage isSeekable(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.BooleanMessage message = new Messages.BooleanMessage();
        message.setResult(player.isSeekable());
        return message;
    }

    @Override
    public void setLooping(Messages.LoopingMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        player.setLooping(arg.getIsLooping());
    }

    @Override
    public void seekTo(Messages.PositionMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        player.seekTo(arg.getPosition().intValue());
    }

    @Override
    public Messages.PositionMessage position(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.PositionMessage message = new Messages.PositionMessage();
        message.setPosition(player.getPosition());
        return message;
    }

    @Override
    public Messages.DurationMessage duration(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.DurationMessage message = new Messages.DurationMessage();
        message.setDuration(player.getDuration());
        return message;
    }

    @Override
    public void setVolume(Messages.VolumeMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        player.setVolume(arg.getVolume());
    }

    @Override
    public Messages.VolumeMessage getVolume(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.VolumeMessage message = new Messages.VolumeMessage();
        message.setVolume((long) player.getVolume());
        return message;
    }

    @Override
    public void setPlaybackSpeed(Messages.PlaybackSpeedMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        player.setPlaybackSpeed(arg.getSpeed());
    }

    @Override
    public Messages.PlaybackSpeedMessage getPlaybackSpeed(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.PlaybackSpeedMessage message = new Messages.PlaybackSpeedMessage();
        message.setSpeed((double) player.getPlaybackSpeed());
        return message;
    }

    @Override
    public Messages.SnapshotMessage takeSnapshot(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.SnapshotMessage message = new Messages.SnapshotMessage();
        message.setSnapshot(player.getSnapshot());
        return message;
    }

    @Override
    public Messages.TrackCountMessage getSpuTracksCount(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.TrackCountMessage message = new Messages.TrackCountMessage();
        message.setCount((long) player.getSpuTracksCount());
        return message;
    }

    @Override
    public Messages.SpuTracksMessage getSpuTracks(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.SpuTracksMessage message = new Messages.SpuTracksMessage();
        message.setSubtitles(player.getSpuTracks());
        return message;
    }

    @Override
    public void setSpuTrack(Messages.SpuTrackMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        player.setSpuTrack(arg.getSpuTrackNumber().intValue());
    }

    @Override
    public Messages.SpuTrackMessage getSpuTrack(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.SpuTrackMessage message = new Messages.SpuTrackMessage();
        message.setSpuTrackNumber((long) player.getSpuTrack());
        return message;
    }

    @Override
    public void setSpuDelay(Messages.DelayMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        player.setSpuDelay(arg.getDelay());
    }

    @Override
    public Messages.DelayMessage getSpuDelay(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.DelayMessage message = new Messages.DelayMessage();
        message.setDelay(player.getSpuDelay());
        return message;
    }

    @Override
    public void addSubtitleTrack(Messages.AddSubtitleMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        player.addSubtitleTrack(arg.getUri(), arg.getIsSelected());
    }

    @Override
    public Messages.TrackCountMessage getAudioTracksCount(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.TrackCountMessage message = new Messages.TrackCountMessage();
        message.setCount((long) player.getAudioTracksCount());
        return message;
    }

    @Override
    public Messages.AudioTracksMessage getAudioTracks(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.AudioTracksMessage message = new Messages.AudioTracksMessage();
        message.setAudios(player.getAudioTracks());
        return message;
    }

    @Override
    public void setAudioTrack(Messages.AudioTrackMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        player.setAudioTrack(arg.getAudioTrackNumber().intValue());
    }

    @Override
    public Messages.AudioTrackMessage getAudioTrack(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.AudioTrackMessage message = new Messages.AudioTrackMessage();
        message.setAudioTrackNumber((long) player.getAudioTrack());
        return message;
    }

    @Override
    public void setAudioDelay(Messages.DelayMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        player.setAudioDelay(arg.getDelay());
    }

    @Override
    public Messages.DelayMessage getAudioDelay(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.DelayMessage message = new Messages.DelayMessage();
        message.setDelay(player.getAudioDelay());
        return message;
    }

    @Override
    public void addAudioTrack(Messages.AddAudioMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        player.addAudioTrack(arg.getUri(), arg.getIsSelected());
    }

    @Override
    public Messages.TrackCountMessage getVideoTracksCount(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.TrackCountMessage message = new Messages.TrackCountMessage();
        message.setCount((long) player.getVideoTracksCount());
        return message;
    }

    @Override
    public Messages.VideoTracksMessage getVideoTracks(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.VideoTracksMessage message = new Messages.VideoTracksMessage();
        message.setVideos(player.getVideoTracks());
        return message;
    }

    @Override
    public void setVideoTrack(Messages.VideoTrackMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        player.setVideoTrack(arg.getVideoTrackNumber().intValue());
    }

    @Override
    public Messages.VideoTrackMessage getVideoTrack(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.VideoTrackMessage message = new Messages.VideoTrackMessage();
        message.setVideoTrackNumber((long) player.getVideoTrack());
        return null;
    }

    @Override
    public void setVideoScale(Messages.VideoScaleMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        player.setVideoScale(arg.getScale().floatValue());
    }

    @Override
    public Messages.VideoScaleMessage getVideoScale(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.VideoScaleMessage message = new Messages.VideoScaleMessage();
        message.setScale((double) player.getVideoScale());
        return message;
    }

    @Override
    public void setVideoAspectRatio(Messages.VideoAspectRatioMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        player.setVideoAspectRatio(arg.getAspectRatio());
    }

    @Override
    public Messages.VideoAspectRatioMessage getVideoAspectRatio(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.VideoAspectRatioMessage message = new Messages.VideoAspectRatioMessage();
        message.setAspectRatio(player.getVideoAspectRatio());
        return message;
    }

    @Override
    public Messages.RendererServicesMessage getAvailableRendererServices(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.RendererServicesMessage message = new Messages.RendererServicesMessage();
        message.setServices(player.getAvailableRendererServices());
        return message;
    }

    @Override
    public void startRendererScanning(Messages.RendererScanningMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        player.startRendererScanning(arg.getRendererService());
    }

    @Override
    public void stopRendererScanning(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        player.stopRendererScanning();
    }

    @Override
    public Messages.RendererDevicesMessage getRendererDevices(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Messages.RendererDevicesMessage message = new Messages.RendererDevicesMessage();
        message.setRendererDevices(player.getRendererDevices());
        return message;
    }

    @Override
    public void castToRenderer(Messages.RenderDeviceMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        player.castToRenderer(arg.getRendererDevice());
    }

    @Override
    public Messages.BooleanMessage startRecording(Messages.RecordMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Boolean result = player.startRecording(arg.getSaveDirectory());
        Messages.BooleanMessage message = new Messages.BooleanMessage();
        message.setResult(result);
        return message;
    }

    @Override
    public Messages.BooleanMessage stopRecording(Messages.ViewMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        Boolean result = player.stopRecording();
        Messages.BooleanMessage message = new Messages.BooleanMessage();
        message.setResult(result);
        return message;
    }

    @Override
    public void updateSize(Messages.UpdateSizeMessage arg) {
        FlutterVlcPlayerInterface player = getPlayer(arg.getViewId(), arg.getIsTexture());
        if (player != null) {
            player.updateSize(arg);
        }
    }
}
