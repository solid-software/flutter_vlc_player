package software.solid.fluttervlcplayer;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

interface FlutterVlcPlayerInterface {

    void dispose();

    void initialize(List<String> options);

    void play();

    void pause();

    void stop();

    boolean isPlaying();

    boolean isSeekable();

    void setStreamUrl(String url, boolean isAssetUrl, boolean autoPlay, long hwAcc);

    void setLooping(boolean value);

    void setVolume(long value);

    int getVolume();

    void setPlaybackSpeed(double value);

    float getPlaybackSpeed();

    void seekTo(int location);

    long getPosition();

    long getDuration();

    int getSpuTracksCount();

    HashMap<Integer, String> getSpuTracks();

    void setSpuTrack(int index);

    int getSpuTrack();

    void setSpuDelay(long delay);

    long getSpuDelay();

    void addSubtitleTrack(String url, boolean isSelected);

    int getAudioTracksCount();

    HashMap<Integer, String> getAudioTracks();

    void setAudioTrack(int index);

    int getAudioTrack();

    void setAudioDelay(long delay);

    long getAudioDelay();

    void addAudioTrack(String url, boolean isSelected);

    int getVideoTracksCount();

    HashMap<Integer, String> getVideoTracks();

    void setVideoTrack(int index);

    int getVideoTrack();

    void setVideoScale(float scale);

    float getVideoScale();

    void setVideoAspectRatio(String aspectRatio);

    String getVideoAspectRatio();

    void startRendererScanning(String rendererService);

    void stopRendererScanning();

    ArrayList<String> getAvailableRendererServices();

    HashMap<String, String> getRendererDevices();

    void castToRenderer(String rendererDevice);

    String getSnapshot();

    Boolean startRecording(String directory);

    Boolean stopRecording();

}
