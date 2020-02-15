#import <Flutter/Flutter.h>
#import <MobileVLCKit/MobileVLCKit.h>

@interface FlutterVlcPlayerPlugin : NSObject<FlutterPlugin>
@end

@interface FLTPlayerView : NSObject<FlutterPlatformView>

@property (nonatomic, strong) UIView *hostedView;
// Don't hate the player, hate the game.
@property (nonatomic, strong) VLCMediaPlayer *player;

@property (nonatomic) FlutterResult result;

+ (instancetype)initWithChannel: (FlutterMethodChannel*) channel;

@end

@interface FLTPlayerViewFactory : NSObject<FlutterPlatformViewFactory>
+ (instancetype)initWithRegistrar : (NSObject<FlutterPluginRegistrar>*)registrar;
@end
