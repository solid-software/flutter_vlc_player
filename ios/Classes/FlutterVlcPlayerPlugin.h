#import <Flutter/Flutter.h>
#import <MobileVLCKit/MobileVLCKit.h>

@interface FlutterVlcPlayerPlugin : NSObject<FlutterPlugin>
@end

@interface FLTPlayerView : NSObject<FlutterPlatformView>

/// View to show video over
@property (nonatomic, strong) UIView *hostedView;
/// Player showing video
@property (nonatomic, strong) VLCMediaPlayer *player;
/// result to comunicate back to Flutter
@property (nonatomic) FlutterResult result;
/// Set to indicate that aspect has been set which is only needed once.
@property (nonatomic, assign) BOOL aspectSet;


/// Initialize a new instance with the channel
/// @param methodChannel Method channel for communication from flutter
/// @param eventChannel Event channel for communication back to flutter
+ (instancetype)initWithChannels: (FlutterMethodChannel*) methodChannel andEventChannel:(FlutterEventChannel*) eventChannel;

@end

@interface FLTPlayerViewFactory : NSObject<FlutterPlatformViewFactory>
+ (instancetype)initWithRegistrar : (NSObject<FlutterPluginRegistrar>*)registrar;
@end

@interface FLTPlayerEventStreamHandler : NSObject<FlutterStreamHandler, VLCMediaPlayerDelegate>

@property (nonatomic) FlutterEventSink eventSink;

@end