//
//  FlutterVlcPlayerPlugin.m
//  flutter_vlc_player
//

#import "FlutterVlcPlayerPlugin.h"
#import "VLCMediaPlayer.h"

@implementation FLTPlayerView

NSObject<FlutterBinaryMessenger> *_messenger;

+ (instancetype)initWithChannels: (FlutterMethodChannel*) methodChannel andEventChannel:(FlutterEventChannel*) eventChannel {

    // Initialize hostedView and set relevant parameters.
    FLTPlayerView *instance = [[super alloc] init];
    UIView *hostedView = [[UIView alloc] init];
    hostedView.contentMode = UIViewContentModeScaleAspectFit;
    hostedView.backgroundColor = [UIColor blackColor];
    hostedView.clipsToBounds = YES;
    hostedView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    instance.hostedView = hostedView;

    // Create event channel handler.
    FLTPlayerEventStreamHandler* eventChannelHandler = [[FLTPlayerEventStreamHandler alloc] init];
    [eventChannel setStreamHandler:eventChannelHandler];

    // Set method channel handler.
    [methodChannel setMethodCallHandler:^(FlutterMethodCall * _Nonnull call, FlutterResult  _Nonnull result) {
        
        instance.result = result;
        
        if([call.method isEqualToString:@"initialize"]) {

            NSString *url = call.arguments[@"url"];
            bool isLocal = call.arguments[@"isLocal"];
            NSString *subtitle = call.arguments[@"subtitle"];
            bool loop = call.arguments[@"loop"];
            NSMutableArray *options= [[NSMutableArray alloc] init];
            if (!isLocal)
               [options addObject:@"--rtsp-tcp"];
            if (loop)
               [options addObject:@"--input-repeat=65535"];
            VLCMediaPlayer *player = [[VLCMediaPlayer alloc] initWithOptions:options];
            player.delegate = eventChannelHandler;

            instance.player = player;
            
            VLCMedia *media = nil;
            if (isLocal)
                media = [VLCMedia mediaWithPath:url];
            else
                media = [VLCMedia mediaWithURL:[NSURL URLWithString:url]];

            //add subtitle
            if ([subtitle length] > 0)
                [player addPlaybackSlave:[NSURL URLWithString:subtitle] type:VLCMediaPlaybackSlaveTypeSubtitle enforce:true];
            player.media = media;
            player.position = 0.5;
            player.drawable = instance.hostedView;
            [player addObserver:instance forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:nil];

            result(nil);
            return;

        } else if ([call.method isEqualToString:@"dispose"]) {

             [instance.player stop];
             return;

         } else if ([call.method isEqualToString:@"changeURL"]) {

            if(instance.player == nil) {
                result([FlutterError errorWithCode:@"VLC_NOT_INITIALIZED"
                                        message:@"The player has not yet been initialized."
                                        details:nil]);

                return;
            }

            [instance.player stop];

            NSString *url = call.arguments[@"url"];
            VLCMedia *media = [VLCMedia mediaWithURL:[NSURL URLWithString:url]];
            instance.player.media = media;

            result(nil);
            return;

         } else if ([call.method isEqualToString:@"getSnapshot"]) {

             UIView *drawable =  instance.player.drawable;
             CGSize size = drawable.frame.size;

             UIGraphicsBeginImageContextWithOptions(size, false, 0.0);

             CGRect rec = drawable.frame;
             [drawable drawViewHierarchyInRect:rec afterScreenUpdates:false];

             UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
             UIGraphicsEndImageContext();

             NSString *byteArray = [UIImagePNGRepresentation(image) base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
             result(@{@"snapshot" : byteArray});

          } else if ([call.method isEqualToString:@"setPlaybackState"]) {

            NSString *playbackState = call.arguments[@"playbackState"];

            if([playbackState isEqualToString:@"play"]) {
                if (![instance.player isPlaying])
                    [instance.player play];
            } else if ([playbackState isEqualToString:@"pause"]) {
                if ([instance.player isPlaying])
                    [instance.player pause];
            } else if ([playbackState isEqualToString:@"stop"]) {
                if ([instance.player isPlaying])
                    [instance.player stop];
            }

            result(nil);
            return;

          } else if ([call.method isEqualToString:@"setPlaybackSpeed"]) {

            NSNumber *playbackSpeed = call.arguments[@"speed"];
            float rate = playbackSpeed.floatValue;
            instance.player.rate = rate;

            result(nil);
            return;

          } else if ([call.method isEqualToString:@"getPlaybackSpeed"]) {

            float rate= instance.player.rate;

            result([NSNumber numberWithDouble:rate]);
            return;

           }else if ([call.method isEqualToString:@"setTime"]) {

            VLCTime *time = [VLCTime timeWithNumber:call.arguments[@"time"]];
            instance.player.time = time;

            result(nil);
            return;

          } else if ([call.method isEqualToString:@"getTime"]) {

            int value= instance.player.time.intValue;

            result([NSNumber numberWithInt:value]);
            return;

          } else if ([call.method isEqualToString:@"getDuration"]) {

            int value= instance.player.media.length.intValue;

            result([NSNumber numberWithInt:value]);
            return;

          }else if ([call.method isEqualToString:@"isPlaying"]) {

           bool value= [instance.player isPlaying];

           result([NSNumber numberWithBool:value]);
           return;

         }else if ([call.method isEqualToString:@"setSubtitleTrack"]) {

           NSNumber* value=call.arguments[@"track"];
           int track = value.intValue;
           instance.player.currentVideoSubTitleIndex = track;

           return;
         }else if ([call.method isEqualToString:@"getSubtitleTracks"]) {

             NSArray *videoSubTitlesNames = instance.player.videoTrackIndexes;
             NSMutableArray *subtitles=[NSMutableArray array];
             for (NSNumber* n in videoSubTitlesNames){
                if (n.intValue>=0)
                    [subtitles addObject:n];
             }

             result(subtitles);
             return;
         }else if ([call.method isEqualToString:@"addSubtitle"]) {

             NSString* subtitle = call.arguments[@"subtitle"];
             [instance.player addPlaybackSlave:[NSURL URLWithString:subtitle] type:VLCMediaPlaybackSlaveTypeSubtitle enforce:true];

             return;
         }
        
    }];
    
    return instance;

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
    // Create method channel.
    NSString *_methodChannelName = [NSString stringWithFormat:@"%@_%@",@"flutter_video_plugin/getVideoView", [NSString stringWithFormat:@"%lld", viewId]];
    FlutterMethodChannel* methodChannel = [FlutterMethodChannel
                                      methodChannelWithName:_methodChannelName
                                      binaryMessenger:[_registrar messenger]];

    // Create event channel.
    NSString *_eventChannelName = [NSString stringWithFormat:@"%@_%@",@"flutter_video_plugin/getVideoEvents", [NSString stringWithFormat:@"%lld", viewId]];
    FlutterEventChannel* eventChannel = [FlutterEventChannel
                                      eventChannelWithName:_eventChannelName
                                      binaryMessenger:[_registrar messenger]];

    return [FLTPlayerView initWithChannels:methodChannel andEventChannel:eventChannel];
}


@end


@implementation FlutterVlcPlayerPlugin

+ (void)registerWithRegistrar:(nonnull NSObject<FlutterPluginRegistrar> *)registrar {
    [registrar registerViewFactory: [FLTPlayerViewFactory initWithRegistrar: registrar] withId:@"flutter_video_plugin/getVideoView"];
}

@end

@implementation FLTPlayerEventStreamHandler

- (FlutterError*)onListenWithArguments:(id)arguments eventSink:(FlutterEventSink)eventSink {
    _eventSink = eventSink;
    return nil;
}

- (FlutterError*)onCancelWithArguments:(id)arguments {
    _eventSink = nil;
    return nil;
}

- (void)mediaPlayerStateChanged:(NSNotification *)aNotification {

    VLCMediaPlayer *player = aNotification.object;
    VLCMedia *media = player.media;

    NSArray* tracks = media.tracksInformation;
    NSDictionary* track;

    float ratio = 0.0;
    NSNumber* height = @0;
    NSNumber* width = @0;

    if(player.currentVideoTrackIndex != -1){
        track = tracks[player.currentVideoTrackIndex];

        height = [track objectForKey:@"height"];
        width = [track objectForKey:@"width"];

        if(height != nil && width != nil && height > 0) {
            ratio = width.floatValue / height.floatValue;
        }
    }

    switch(player.state){
        case VLCMediaPlayerStateESAdded:
        case VLCMediaPlayerStateBuffering:
        case VLCMediaPlayerStateOpening:
            return;

        case VLCMediaPlayerStatePlaying:
            _eventSink(@{
                @"name": @"playing",
                @"value": @(YES),
                @"ratio": @(ratio),
                @"height": height,
                @"width": width,
                @"length": media.length.value ?: @0
            });
            return;

        case VLCMediaPlayerStateEnded:
            _eventSink(@{
                @"name": @"ended"
            });

            _eventSink(@{
                @"name": @"playing",
                @"value": @(NO),
                @"reason": @"EndReached"
            });
            return;

        case VLCMediaPlayerStateError:
            NSLog(@"(flutter_vlc_plugin) A VLC error occurred.");
            return;

        case VLCMediaPlayerStatePaused:
            _eventSink(@{
                @"name": @"paused",
                @"value": @(YES)
            });
            return;
        case VLCMediaPlayerStateStopped:
            _eventSink(@{
                @"name": @"stopped",
                @"value": @(YES)
            });

            return;
    }
}

- (void)mediaPlayerTimeChanged:(NSNotification *)aNotification {

    VLCMediaPlayer *player = aNotification.object;

    _eventSink(@{
        @"name": @"timeChanged",
        @"value": player.time.value,
        @"speed": @(player.rate),
        @"length": player.media.length.value ?: @0
    });

    _eventSink(@{
        @"name": @"position",
        @"value": player.time.value,
        @"speed": @(player.rate),
        @"length": player.media.length.value ?: @0
    });

    return;
}

@end
