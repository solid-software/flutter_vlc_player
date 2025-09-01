package software.solid.fluttervlcplayer;

import android.content.Context;
import android.graphics.SurfaceTexture;
import android.os.Handler;
import android.os.Looper;
import android.util.AttributeSet;
import android.view.TextureView;
import android.view.View;
import android.view.ViewGroup;

import androidx.annotation.NonNull;

import org.videolan.libvlc.MediaPlayer;
import org.videolan.libvlc.interfaces.IVLCVout;

import io.flutter.view.TextureRegistry;

public class VLCTextureView extends TextureView implements TextureView.SurfaceTextureListener, View.OnLayoutChangeListener, IVLCVout.OnNewVideoLayoutListener {

    private MediaPlayer mMediaPlayer = null;
    private TextureRegistry.SurfaceTextureEntry mTextureEntry = null;
    protected Context mContext;
    private SurfaceTexture mSurfaceTexture = null;
    private boolean wasPlaying = false;

    private Handler mHandler;
    private Runnable mLayoutChangeRunnable = null;

    public VLCTextureView(final Context context) {
        super(context);
        mContext = context;
        initVideoView();
    }

    public VLCTextureView(final Context context, final AttributeSet attrs) {
        super(context, attrs);
        mContext = context;
        initVideoView();
    }

    public VLCTextureView(Context context, AttributeSet attrs, int defStyle) {
        super(context, attrs, defStyle);
        mContext = context;
        initVideoView();
    }

    public void dispose() {
        setSurfaceTextureListener(null);
        removeOnLayoutChangeListener(this);

        if (mLayoutChangeRunnable != null) {
            mHandler.removeCallbacks(mLayoutChangeRunnable);
            mLayoutChangeRunnable = null;
        }

        if (mSurfaceTexture != null) {
            if (!mSurfaceTexture.isReleased()) {
                mSurfaceTexture.release();
            }
            mSurfaceTexture = null;
        }
        mTextureEntry = null;
        mMediaPlayer = null;
        mContext = null;
    }

    private void initVideoView() {
        mHandler = new Handler(Looper.getMainLooper());

        setFocusable(false);
        setSurfaceTextureListener(this);
        addOnLayoutChangeListener(this);
    }

    public void setMediaPlayer(MediaPlayer mediaPlayer) {
        if (mediaPlayer == null) {
            mMediaPlayer.getVLCVout().detachViews();
        }

        mMediaPlayer = mediaPlayer;

        if (mMediaPlayer != null) {
            mMediaPlayer.getVLCVout().attachViews(this);
        }
    }

    public void setTextureEntry(TextureRegistry.SurfaceTextureEntry textureEntry) {
        this.mTextureEntry = textureEntry;
        this.updateSurfaceTexture();
    }

    private void updateSurfaceTexture() {
        if (this.mTextureEntry != null) {
            final SurfaceTexture texture = this.mTextureEntry.surfaceTexture();
            if (!texture.isReleased() && (getSurfaceTexture() != texture)) {
                setSurfaceTexture(texture);
            }
        }
    }

    @Override
    public void onSurfaceTextureAvailable(@NonNull SurfaceTexture surface, int width, int height) {
        if (mSurfaceTexture == null || mSurfaceTexture.isReleased()) {
            mSurfaceTexture = surface;

            if (mMediaPlayer != null) {
                mMediaPlayer.getVLCVout().setWindowSize(width, height);
                if (!mMediaPlayer.getVLCVout().areViewsAttached()) {
                    mMediaPlayer.getVLCVout().setVideoSurface(mSurfaceTexture);
                    if (!mMediaPlayer.getVLCVout().areViewsAttached()) {
                        mMediaPlayer.getVLCVout().attachViews(this);
                    }
                    mMediaPlayer.setVideoTrackEnabled(true);
                    if (wasPlaying) {
                        mMediaPlayer.play();
                    }
                }
            }

            wasPlaying = false;

        } else {
            if (getSurfaceTexture() != mSurfaceTexture) {
                setSurfaceTexture(mSurfaceTexture);
            }
        }

    }

    @Override
    public void onSurfaceTextureSizeChanged(@NonNull SurfaceTexture surface, int width, int height) {
        setSize(width, height);
    }

    @Override
    public boolean onSurfaceTextureDestroyed(@NonNull SurfaceTexture surface) {
        if (mMediaPlayer != null) {
            wasPlaying = mMediaPlayer.isPlaying();
        }

        if (mSurfaceTexture != surface) {
            if (mSurfaceTexture != null) {
                if (!mSurfaceTexture.isReleased()) {
                    mSurfaceTexture.release();
                }
            }
            mSurfaceTexture = surface;
        }

        return false;
    }

    @Override
    public void onSurfaceTextureUpdated(@NonNull SurfaceTexture surface) {

    }

    @Override
    public void onNewVideoLayout(IVLCVout vlcVout, int width, int height, int visibleWidth, int visibleHeight, int sarNum, int sarDen) {
        if (width * height == 0) return;

        setSize(width, height);
    }

    @Override
    public void onLayoutChange(View view, int left, int top, int right, int bottom, int oldLeft, int oldTop, int oldRight, int oldBottom) {
        if (left != oldLeft || top != oldTop || right != oldRight || bottom != oldBottom) {
            updateLayoutSize(view);
        }
    }

    public void updateLayoutSize(View view) {
        if (mMediaPlayer != null) {
            mMediaPlayer.getVLCVout().setWindowSize(view.getWidth(), view.getHeight());
            updateSurfaceTexture();
        }
    }

    private void setSize(int width, int height) {
        if (width * height <= 1) return;

        // Screen size
        int w = this.getWidth();
        int h = this.getHeight();

        // Size
        // TODO: fix this always false condition, it seems to reverse the width and height
        if (w > h && w < h) {
            int i = w;
            w = h;
            h = i;
        }

        float videoAR = (float) width / (float) height;
        float screenAR = (float) w / (float) h;

        if (screenAR < videoAR) {
            h = (int) (w / videoAR);
        } else {
            w = (int) (h * videoAR);
        }

        // Layout fit
        ViewGroup.LayoutParams lp = this.getLayoutParams();
        lp.width = ViewGroup.LayoutParams.MATCH_PARENT;
        lp.height = h;
        this.setLayoutParams(lp);
        this.invalidate();
    }

}