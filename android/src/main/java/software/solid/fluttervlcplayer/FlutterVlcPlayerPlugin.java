package software.solid.fluttervlcplayer;

import android.app.Activity;
import android.app.Application;
import android.os.Bundle;

import androidx.annotation.NonNull;
import androidx.lifecycle.DefaultLifecycleObserver;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleOwner;

import java.util.concurrent.atomic.AtomicInteger;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.PluginRegistry.Registrar;
import io.flutter.embedding.engine.plugins.lifecycle.FlutterLifecycleAdapter;

/** FlutterVlcPlayerPlugin */
public class FlutterVlcPlayerPlugin implements FlutterPlugin, ActivityAware, Application.ActivityLifecycleCallbacks, DefaultLifecycleObserver {

  private static final String VIEW_TYPE = "flutter_video_plugin/getVideoView";

  private FlutterPluginBinding pluginBinding;
  private int registrarActivityHashCode;
  private final AtomicInteger state = new AtomicInteger(0);
  private Lifecycle lifecycle;
  static final int CREATED = 1;
  static final int STARTED = 2;
  static final int RESUMED = 3;
  static final int PAUSED = 4;
  static final int STOPPED = 5;
  static final int DESTROYED = 6;


  //No Op for v2 Flutter
  public FlutterVlcPlayerPlugin() {}

  private FlutterVlcPlayerPlugin(Activity activity) {
    this.registrarActivityHashCode = activity.hashCode();
  }


  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    pluginBinding = binding;
  }

  /**
   * FLutter Plugin Callbacks
   * @param binding
   */
  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    pluginBinding = null;
  }


  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding);
    lifecycle.addObserver(this);



    pluginBinding
            .getPlatformViewRegistry()
            .registerViewFactory(
                    VIEW_TYPE,
                    new FlutterVideoViewFactory2(
                            state,
                            pluginBinding.getBinaryMessenger(),
                            binding.getActivity().getApplication(),
                            lifecycle,
                            pluginBinding.getTextureRegistry(),
                            binding.getActivity().hashCode()));

  }

  /**
   * End Flutter call backs
   */


  /**
   * Activity Aware Callbacks
   */
  @Override
  public void onDetachedFromActivity() {
    lifecycle.removeObserver(this);
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    this.onDetachedFromActivity();
  }

  @Override
  public void onReattachedToActivityForConfigChanges(ActivityPluginBinding binding) {
    lifecycle = FlutterLifecycleAdapter.getActivityLifecycle(binding);
    lifecycle.addObserver(this);
  }


  // DefaultLifecycleObserver methods

  @Override
  public void onCreate(@NonNull LifecycleOwner owner) {
    state.set(CREATED);
  }

  @Override
  public void onStart(@NonNull LifecycleOwner owner) {
    state.set(STARTED);
  }

  @Override
  public void onResume(@NonNull LifecycleOwner owner) {
    state.set(RESUMED);
  }

  @Override
  public void onPause(@NonNull LifecycleOwner owner) {
    state.set(PAUSED);
  }

  @Override
  public void onStop(@NonNull LifecycleOwner owner) {
    state.set(STOPPED);
  }

  @Override
  public void onDestroy(@NonNull LifecycleOwner owner) {
    state.set(DESTROYED);
  }

  //end

//begin

  @Override
  public void onActivityCreated(Activity activity, Bundle savedInstanceState) {
    if (activity.hashCode() != registrarActivityHashCode) {
      return;
    }
    state.set(CREATED);
  }

  @Override
  public void onActivityStarted(Activity activity) {
    if (activity.hashCode() != registrarActivityHashCode) {
      return;
    }
    state.set(STARTED);
  }

  @Override
  public void onActivityResumed(Activity activity) {
    if (activity.hashCode() != registrarActivityHashCode) {
      return;
    }
    state.set(RESUMED);
  }

  @Override
  public void onActivityPaused(Activity activity) {
    if (activity.hashCode() != registrarActivityHashCode) {
      return;
    }
    state.set(PAUSED);
  }

  @Override
  public void onActivityStopped(Activity activity) {
    if (activity.hashCode() != registrarActivityHashCode) {
      return;
    }
    state.set(STOPPED);
  }

  @Override
  public void onActivitySaveInstanceState(Activity activity, Bundle outState) {}

  @Override
  public void onActivityDestroyed(Activity activity) {
    if (activity.hashCode() != registrarActivityHashCode) {
      return;
    }
    activity.getApplication().unregisterActivityLifecycleCallbacks(this);
    state.set(DESTROYED);
  }

}
