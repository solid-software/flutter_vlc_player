//
//  FlutterVlcIosPlugin.m
//  flutter_vlc_ios
//
//  Created by Vladimir Beloded on 12/26/18.
//

#import "FlutterVlcPlayerPlugin.h"
#import "VLCMediaPlayer.h"

@implementation FLTPlayerView

NSObject<FlutterBinaryMessenger> *_messenger;

+ (instancetype)initWithChannel: (FlutterMethodChannel*) channel
{
    FLTPlayerView *instance = [[super alloc] init];
    
    UIView *hostedView = [[UIView alloc] init];
    
    hostedView.contentMode = UIViewContentModeScaleAspectFit;
    hostedView.backgroundColor = [UIColor whiteColor];
    hostedView.clipsToBounds = YES;
    hostedView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    instance.hostedView = hostedView;
    
    [channel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
        
        instance.result = result;
        
        if([call.method isEqualToString:@"playVideo"])
        {
            NSString *url = call.arguments[@"url"];
            
            VLCMediaPlayer *player = [[VLCMediaPlayer alloc] init];
            
            instance.player = player;
            
            VLCMedia *media = [VLCMedia mediaWithURL:[NSURL URLWithString:url]];
            player.media = media;
            player.position = 0.5;
            player.drawable = instance.hostedView;
            [player addObserver:instance forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
            
            [player play];
        } else if ([call.method isEqualToString:@"play"]) {
            [instance.player play];
            result(@{@"play" : @"palayer start play"});
        } else if ([call.method isEqualToString:@"pause"]) {
            [instance.player pause];
            result(@{@"pause" : @"pause player"});
        } else if ([call.method isEqualToString:@"isPlaying"]) {
            NSString *byteArray = NSStringFromBOOL([instance.player isPlaying]);
            result(@{@"isPlaying" : byteArray});
        } else if ([call.method isEqualToString:@"dispose"]) {
            [instance.player stop];
        } else if ([call.method isEqualToString:@"getSnapshot"])
        {
           UIView *drawable =  instance.player.drawable;
           CGSize size = drawable.frame.size;

           UIGraphicsBeginImageContextWithOptions(size, false, 0.0);

           CGRect rec = drawable.frame;
           [drawable drawViewHierarchyInRect:rec afterScreenUpdates:false];

           UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
           UIGraphicsEndImageContext();

           NSString *byteArray = [UIImagePNGRepresentation(image) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];

           result(@{@"snapshot" : byteArray});
        }
        
    }];
    
    return instance;
}

NSString *NSStringFromBOOL(BOOL aBool)
{
    return aBool ? @"YES" : @"NO";
}

- (nonnull UIView *)view {
    return self.hostedView;
}
        
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{

    // Player won't play if this aspect does't get set in response to the KV changing.

    if (self.aspectSet) return;
    if (!self.player.isPlaying) return;
    
    [_player setDrawable:_hostedView];
    [_player setVideoAspectRatio:"0.7"];
    [_player setCurrentVideoTrackIndex:0];
    [_player setScaleFactor:0.0];
    NSString *aspectStr = [NSString stringWithUTF8String:[_player videoAspectRatio]];
    self.result(@{@"aspectRatio" : aspectStr});
    self.aspectSet = YES;
}


@end


@implementation FLTPlayerViewFactory
NSObject<FlutterPluginRegistrar> *_registrar;

+ (instancetype)initWithRegistrar : (NSObject<FlutterPluginRegistrar>*)registrar {
    _registrar = registrar;
    return [[super alloc] init];
}

- (nonnull NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(NSObject<FlutterBinaryMessenger> *)messenger {
    NSString *_methodCallName = [NSString stringWithFormat:@"%@_%@",@"flutter_video_plugin/getVideoView", [NSString stringWithFormat:@"%lld", viewId]];
    FlutterMethodChannel* channel = [FlutterMethodChannel
                                      methodChannelWithName:_methodCallName
                                      binaryMessenger:[_registrar messenger]];
    
    
    return [FLTPlayerView initWithChannel:channel];
}


@end


@implementation FlutterVlcPlayerPlugin

+ (void)registerWithRegistrar:(nonnull NSObject<FlutterPluginRegistrar> *)registrar {
    [registrar registerViewFactory: [FLTPlayerViewFactory initWithRegistrar: registrar] withId:@"flutter_video_plugin/getVideoView"];
}



@end
