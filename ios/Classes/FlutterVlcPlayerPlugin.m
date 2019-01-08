//
//  FlutterVlcIosPlugin.m
//  flutter_vlc_ios
//
//  Created by Vladimir Beloded on 12/26/18.
//

#import "FlutterVlcPlayerPlugin.h"
#import "VLCMediaPlayer.h"

@implementation FLTPlayerView
UIView *_videoView;
NSObject<FlutterBinaryMessenger> *_messenger;

+ (instancetype)initWithView:(UIView *)view{
    if (_videoView == nil){
    _videoView = view;
    }
    return [[super alloc] init];
}

- (nonnull UIView *)view {
    return _videoView;
}



@end


@implementation FLTPlayerViewFactory
NSObject<FlutterPluginRegistrar> *_registrar;
UIView *_view;

+ (instancetype)initWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar : (UIView*) view{
    _registrar = registrar;
    _view = view;
    return [[super alloc] init];
}

- (nonnull NSObject<FlutterPlatformView> *)createWithFrame:(CGRect)frame viewIdentifier:(int64_t)viewId arguments:(NSObject<FlutterBinaryMessenger> *)messenger {
    NSString *_methodCallName = [NSString stringWithFormat:@"%@_%@",@"flutter_video_plugin/getVideoView", [NSString stringWithFormat:@"%lld", viewId]];
    FlutterMethodChannel* _channel = [FlutterMethodChannel
                                      methodChannelWithName:_methodCallName
                                      binaryMessenger:[_registrar messenger]];
    [_registrar addMethodCallDelegate:[[FlutterVlcPlayerPlugin alloc] init] channel:_channel];
    return [FLTPlayerView initWithView: _view];
}


@end


@implementation FlutterVlcPlayerPlugin
VLCMediaPlayer *_player;
FlutterResult _result;
UIView *_view;

+ (void)registerWithRegistrar:(nonnull NSObject<FlutterPluginRegistrar> *)registrar {
    CGRect _rect = CGRectMake(0, 0, 700, 100);
    _view = [[UIView alloc] initWithFrame: _rect];
    _view.contentMode = UIViewContentModeScaleAspectFit;
    _view.backgroundColor = [UIColor whiteColor];
    _view.clipsToBounds = YES;
    _view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [registrar registerViewFactory: [FLTPlayerViewFactory initWithRegistrar: registrar : _view] withId:@"flutter_video_plugin/getVideoView"];
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result{
    _result = result;
    NSString* _methodName = call.method;
    if ([_methodName isEqualToString:@"playVideo"]){
        NSString *_url = call.arguments[@"url"];
        _player = [[VLCMediaPlayer alloc] init];
        VLCMedia *_media = [VLCMedia mediaWithURL:[NSURL URLWithString:_url]];
        [_player setMedia:_media];
        [_player setPosition:0.5];

        [_player setDrawable: _videoView];
        [_player addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];
        [_player play];
    } else if ([_methodName isEqualToString:@"dispose"]){
        [_player stop];
    }else if ([_methodName isEqualToString:@"getSnapshot"]){
        UIView *_drawable = _player.drawable;
        CGSize _size = _drawable.frame.size;

        UIGraphicsBeginImageContextWithOptions(_size, false, 0.0);

        CGRect rec = _drawable.frame;
        [_drawable drawViewHierarchyInRect:rec afterScreenUpdates:false];

        UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();

        NSString *_byteArray = [UIImagePNGRepresentation(image) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];

        result(@{@"snapshot" : _byteArray});
    }
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{

    if ([_player isPlaying]){
        [_player setDrawable:_view];
        [_player setVideoAspectRatio:"0.7"];
        [_player setCurrentVideoTrackIndex:0];
        [_player setScaleFactor:0.0];
        char *_aspectRatioChar = [_player videoAspectRatio];
        NSNumber *_aspectRatio = [NSString stringWithFormat:@"%s", _aspectRatioChar];

        _result(@{@"aspectRatio" : _aspectRatio});
//        _result(nil);
    }

}

@end
