// package software.solid.fluttervlcplayer;

// import android.content.Context;
// import android.os.Build;
// import android.util.Log;
// import android.util.LongSparseArray;

// import androidx.annotation.NonNull;
// import androidx.annotation.RequiresApi;

// import io.flutter.embedding.engine.loader.FlutterLoader;
// import io.flutter.embedding.engine.plugins.activity.ActivityAware;
// import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
// import io.flutter.plugin.common.BinaryMessenger;
// import io.flutter.plugin.common.EventChannel;
// import io.flutter.view.TextureRegistry;
// import software.solid.fluttervlcplayer.Messages.CreateMessage;
// import software.solid.fluttervlcplayer.Messages.LoopingMessage;
// import software.solid.fluttervlcplayer.Messages.PlaybackSpeedMessage;
// import software.solid.fluttervlcplayer.Messages.PositionMessage;
// import software.solid.fluttervlcplayer.Messages.TextureMessage;
// import software.solid.fluttervlcplayer.Messages.VlcPlayerApi;
// import software.solid.fluttervlcplayer.Messages.VolumeMessage;
// import software.solid.fluttervlcplayer.Messages.AddSubtitleMessage;
// import software.solid.fluttervlcplayer.Messages.AudioTrackMessage;
// import software.solid.fluttervlcplayer.Messages.AudioTracksMessage;
// import software.solid.fluttervlcplayer.Messages.BooleanMessage;
// import software.solid.fluttervlcplayer.Messages.RenderDeviceMessage;
// import software.solid.fluttervlcplayer.Messages.RendererServicesMessage;
// import software.solid.fluttervlcplayer.Messages.RendererDevicesMessage;
// import software.solid.fluttervlcplayer.Messages.RendererScanningMessage;
// import software.solid.fluttervlcplayer.Messages.DelayMessage;
// import software.solid.fluttervlcplayer.Messages.DurationMessage;
// import software.solid.fluttervlcplayer.Messages.SetMediaMessage;
// import software.solid.fluttervlcplayer.Messages.SnapshotMessage;
// import software.solid.fluttervlcplayer.Messages.SpuTrackMessage;
// import software.solid.fluttervlcplayer.Messages.SpuTracksMessage;
// import software.solid.fluttervlcplayer.Messages.TrackCountMessage;
// import software.solid.fluttervlcplayer.Messages.VideoAspectRatioMessage;
// import software.solid.fluttervlcplayer.Messages.VideoScaleMessage;
// import software.solid.fluttervlcplayer.Messages.VideoTrackMessage;
// import software.solid.fluttervlcplayer.Messages.VideoTracksMessage;

// import io.flutter.embedding.engine.plugins.FlutterPlugin;

// /**
//  * Android platform implementation of the VlcPlayerPlugin.
//  */
// public class VlcPlayerPlugin implements FlutterPlugin, ActivityAware, VlcPlayerApi {
//     private static final String TAG = "VlcPlayerPlugin";
//     private final LongSparseArray<VlcPlayer> vlcPlayers = new LongSparseArray<>();
//     private FlutterState flutterState;
//     private VlcPlayerOptions options = new VlcPlayerOptions();
//     private FlutterPluginBinding flutterPluginBinding;

//     /**
//      * Register this with the v2 embedding for the plugin to respond to lifecycle callbacks.
//      */
//     public VlcPlayerPlugin() {
//     }

//     @RequiresApi(api = Build.VERSION_CODES.N)
//     @SuppressWarnings("deprecation")
//     private VlcPlayerPlugin(io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
//         this.flutterState =
//                 new FlutterState(
//                         registrar.context(),
//                         registrar.messenger(),
//                         registrar::lookupKeyForAsset,
//                         registrar::lookupKeyForAsset,
//                         registrar.textures());
//         flutterState.startListening(this, registrar.messenger());
//     }

//     /**
//      * Registers this with the stable v1 embedding. Will not respond to lifecycle events.
//      */
//     @RequiresApi(api = Build.VERSION_CODES.N)
//     @SuppressWarnings("deprecation")
//     public static void registerWith(io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
//         final VlcPlayerPlugin plugin = new VlcPlayerPlugin(registrar);
//         registrar.addViewDestroyListener(
//                 view -> {
//                     plugin.onDestroy();
//                     return false; // We are not interested in assuming ownership of the NativeView.
//                 });
//     }

//     @RequiresApi(api = Build.VERSION_CODES.N)
//     @Override
//     public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
//         flutterPluginBinding = binding;
//     }

//     @RequiresApi(api = Build.VERSION_CODES.N)
//     @Override
//     public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
//         flutterPluginBinding = null;
//     }

//     // activity aware

//     @RequiresApi(api = Build.VERSION_CODES.N)
//     @Override
//     public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
//         @SuppressWarnings("deprecation") final FlutterLoader flutterLoader = FlutterLoader.getInstance();
//         this.flutterState =
//                 new FlutterState(
//                         flutterPluginBinding.getApplicationContext(),
//                         flutterPluginBinding.getBinaryMessenger(),
//                         flutterLoader::getLookupKeyForAsset,
//                         flutterLoader::getLookupKeyForAsset,
//                         flutterPluginBinding.getTextureRegistry());
//         flutterState.startListening(this, flutterPluginBinding.getBinaryMessenger());

//     }

//     @RequiresApi(api = Build.VERSION_CODES.N)
//     @Override
//     public void onDetachedFromActivity() {

//         if (flutterState == null) {
//             Log.wtf(TAG, "Detached from the engine before registering to it.");
//         }
//         flutterState.stopListening(flutterPluginBinding.getBinaryMessenger());
//         flutterState = null;
//     }

//     @RequiresApi(api = Build.VERSION_CODES.N)
//     @Override
//     public void onDetachedFromActivityForConfigChanges() {
//         onDetachedFromActivity();
//     }

//     @RequiresApi(api = Build.VERSION_CODES.N)
//     @Override
//     public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
//         onAttachedToActivity(binding);
//     }

//     // vlc methods

//     private void disposeAllPlayers() {
//         for (int i = 0; i < vlcPlayers.size(); i++) {
//             vlcPlayers.valueAt(i).dispose();
//         }
//         vlcPlayers.clear();
//     }

//     private void onDestroy() {
//         disposeAllPlayers();
//     }

//     @Override
//     public void initialize() {
//         disposeAllPlayers();
//     }

//     @Override
//     public void create(CreateMessage arg) {

//         TextureRegistry.SurfaceTextureEntry handle =
//                 flutterState.textureRegistry.createSurfaceTexture();

//         EventChannel eventChannel =
//                 new EventChannel(
//                         flutterState.binaryMessenger, "flutter_video_plugin/getVideoEvents_" + handle.id());

//         //todo: check for local file
//         VlcPlayer player;
//         // if (arg.getIsLocalMedia() != null) {
//         //     player =
//         //             new VlcPlayer(
//         //                     flutterState.applicationContext,
//         //                     eventChannel,
//         //                     handle,
//         //                     arg.getUri(),
//         //                     options);
//         //     vlcPlayers.put(handle.id(), player);
//         // } else {
//             player =
//                     new VlcPlayer(
//                             flutterState.applicationContext,
//                             eventChannel,
//                             handle,
//                             arg.getUri(),
//                             options);
//             vlcPlayers.put(handle.id(), player);
//         // }
// //        TextureMessage message = new TextureMessage();
// //        message.setTextureId(handle.id());
//         return;
//     }

//     @Override
//     public void dispose(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         player.dispose();
//         vlcPlayers.remove(arg.getTextureId());
//     }

//     @Override
//     public void setStreamUrl(SetMediaMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         player.changeUrl(arg.getUri());
//     }

//     @Override
//     public void play(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         player.play();
//     }

//     @Override
//     public void pause(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         player.pause();
//     }

//     @Override
//     public void stop(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         player.stop();
//     }

//     @Override
//     public BooleanMessage isPlaying(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         BooleanMessage message = new BooleanMessage();
//         message.setResult(player.isPlaying());
//         return message;
//     }

//     @Override
//     public void setLooping(LoopingMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         player.setLooping(arg.getIsLooping());
//     }

//     @Override
//     public void seekTo(PositionMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         player.seekTo(arg.getPosition().intValue());
//     }

//     @Override
//     public PositionMessage position(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         PositionMessage message = new PositionMessage();
//         message.setPosition(player.getPosition());
//         return message;
//     }

//     @Override
//     public DurationMessage duration(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         DurationMessage message = new DurationMessage();
//         message.setDuration(player.getDuration());
//         return message;
//     }

//     @Override
//     public void setVolume(VolumeMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         player.setVolume(arg.getVolume());
//     }

//     @Override
//     public VolumeMessage getVolume(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         VolumeMessage message = new VolumeMessage();
//         message.setVolume((long) player.getVolume());
//         return message;
//     }

//     @Override
//     public void setPlaybackSpeed(PlaybackSpeedMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         player.setPlaybackSpeed(arg.getSpeed());
//     }

//     @Override
//     public PlaybackSpeedMessage getPlaybackSpeed(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         PlaybackSpeedMessage message = new PlaybackSpeedMessage();
//         message.setSpeed((double) player.getPlaybackSpeed());
//         return message;
//     }

//     @Override
//     public SnapshotMessage takeSnapshot(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         SnapshotMessage message = new SnapshotMessage();
//         message.setSnapshot(player.getSnapshot());
//         return message;
//     }

//     @Override
//     public TrackCountMessage getSpuTracksCount(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         TrackCountMessage message = new TrackCountMessage();
//         message.setCount((long) player.getSpuTracksCount());
//         return message;
//     }

//     @Override
//     public SpuTracksMessage getSpuTracks(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         SpuTracksMessage message = new SpuTracksMessage();
//         message.setSubtitles(player.getSpuTracks());
//         return message;
//     }

//     @Override
//     public void setSpuTrack(SpuTrackMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         player.setSpuTrack(arg.getSpuTrackNumber().intValue());
//     }

//     @Override
//     public SpuTrackMessage getSpuTrack(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         SpuTrackMessage message = new SpuTrackMessage();
//         message.setSpuTrackNumber((long) player.getSpuTrack());
//         return message;
//     }

//     @Override
//     public void setSpuDelay(DelayMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         player.setSpuDelay(arg.getDelay());
//     }

//     @Override
//     public DelayMessage getSpuDelay(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         DelayMessage message = new DelayMessage();
//         message.setDelay(player.getSpuDelay());
//         return message;
//     }

//     @Override
//     public void addSubtitleTrack(AddSubtitleMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         player.addSubtitleTrack(arg.getUri(), arg.getIsLocal(), arg.getIsSelected());
//     }

//     @Override
//     public TrackCountMessage getAudioTracksCount(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         TrackCountMessage message = new TrackCountMessage();
//         message.setCount((long) player.getAudioTracksCount());
//         return message;
//     }

//     @Override
//     public AudioTracksMessage getAudioTracks(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         AudioTracksMessage message = new AudioTracksMessage();
//         message.setAudios(player.getAudioTracks());
//         return message;
//     }

//     @Override
//     public void setAudioTrack(AudioTrackMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         player.setAudioTrack(arg.getAudioTrackNumber().intValue());
//     }

//     @Override
//     public AudioTrackMessage getAudioTrack(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         AudioTrackMessage message = new AudioTrackMessage();
//         message.setAudioTrackNumber((long) player.getAudioTrack());
//         return message;
//     }

//     @Override
//     public void setAudioDelay(DelayMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         player.setAudioDelay(arg.getDelay());
//     }

//     @Override
//     public DelayMessage getAudioDelay(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         DelayMessage message = new DelayMessage();
//         message.setDelay(player.getAudioDelay());
//         return message;
//     }

//     @Override
//     public TrackCountMessage getVideoTracksCount(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         TrackCountMessage message = new TrackCountMessage();
//         message.setCount((long) player.getVideoTracksCount());
//         return message;
//     }

//     @Override
//     public VideoTracksMessage getVideoTracks(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         VideoTracksMessage message = new VideoTracksMessage();
//         message.setVideos(player.getVideoTracks());
//         return message;
//     }

//     @Override
//     public void setVideoTrack(VideoTrackMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         player.setVideoTrack(arg.getVideoTrackNumber().intValue());
//     }

//     @Override
//     public VideoTrackMessage getVideoTrack(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         VideoTrackMessage message = new VideoTrackMessage();
//         message.setVideoTrackNumber((long) player.getVideoTrack());
//         return null;
//     }

//     @Override
//     public void setVideoScale(VideoScaleMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         player.setVideoScale(arg.getScale().floatValue());
//     }

//     @Override
//     public VideoScaleMessage getVideoScale(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         VideoScaleMessage message = new VideoScaleMessage();
//         message.setScale((double) player.getVideoScale());
//         return message;
//     }

//     @Override
//     public void setVideoAspectRatio(VideoAspectRatioMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         player.setVideoAspectRatio(arg.getAspectRatio());
//     }

//     @Override
//     public VideoAspectRatioMessage getVideoAspectRatio(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         VideoAspectRatioMessage message = new VideoAspectRatioMessage();
//         message.setAspectRatio(player.getVideoAspectRatio());
//         return message;
//     }

//     @Override
//     public RendererServicesMessage getAvailableRendererServices(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         RendererServicesMessage message = new RendererServicesMessage();
//         message.setServices(player.getAvailableRendererServices());
//         return message;
//     }

//     @Override
//     public void startRendererScanning(RendererScanningMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         player.startRendererScanning(arg.getRendererService());
//     }

//     @Override
//     public void stopRendererScanning(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         player.stopRendererScanning();
//     }

//     @Override
//     public RendererDevicesMessage getRendererDevices(TextureMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         RendererDevicesMessage message = new RendererDevicesMessage();
//         message.setRendererDevices(player.getRendererDevices());
//         return message;
//     }

//     @Override
//     public void castToRenderer(RenderDeviceMessage arg) {
//         VlcPlayer player = vlcPlayers.get(arg.getTextureId());
//         player.castToRenderer(arg.getRendererDevice());
//     }

//     // extra helpers

//     private interface KeyForAssetFn {
//         String get(String asset);
//     }

//     private interface KeyForAssetAndPackageName {
//         String get(String asset, String packageName);
//     }

//     private static final class FlutterState {
//         private final Context applicationContext;
//         private final BinaryMessenger binaryMessenger;
//         private final KeyForAssetFn keyForAsset;
//         private final KeyForAssetAndPackageName keyForAssetAndPackageName;
//         private final TextureRegistry textureRegistry;

//         FlutterState(
//                 Context applicationContext,
//                 BinaryMessenger messenger,
//                 KeyForAssetFn keyForAsset,
//                 KeyForAssetAndPackageName keyForAssetAndPackageName,
//                 TextureRegistry textureRegistry) {
//             this.applicationContext = applicationContext;
//             this.binaryMessenger = messenger;
//             this.keyForAsset = keyForAsset;
//             this.keyForAssetAndPackageName = keyForAssetAndPackageName;
//             this.textureRegistry = textureRegistry;
//         }

//         @RequiresApi(api = Build.VERSION_CODES.N)
//         void startListening(VlcPlayerPlugin methodCallHandler, BinaryMessenger messenger) {
//             VlcPlayerApi.setup(messenger, methodCallHandler);
//         }

//         @RequiresApi(api = Build.VERSION_CODES.N)
//         void stopListening(BinaryMessenger messenger) {
//             VlcPlayerApi.setup(messenger, null);
//         }
//     }
// }
