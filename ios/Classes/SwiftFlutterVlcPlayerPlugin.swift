import Flutter
import UIKit
import MobileVLCKit

public class SwiftFlutterVlcPlayerPlugin: NSObject, FlutterPlugin {
    
    private var factory: VLCViewFactory
    public init(with registrar: FlutterPluginRegistrar) {
        self.factory = VLCViewFactory(withRegistrar: registrar)
        registrar.register(factory, withId: "flutter_video_plugin/getVideoView")
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        registrar.addApplicationDelegate(SwiftFlutterVlcPlayerPlugin(with: registrar))
    }
    
}


public class VLCView: NSObject, FlutterPlatformView {
    
    
    @IBOutlet private var hostedView: UIView!
    private var vlcMediaPlayer: VLCMediaPlayer!
    private var registrar: FlutterPluginRegistrar
    private var channel: FlutterMethodChannel
    private var eventChannel: FlutterEventChannel
    private var player: VLCMediaPlayer
    private var eventChannelHandler: VLCPlayerEventStreamHandler
    private var aspectSet = false
    
    
    
    public init(withFrame frame: CGRect, withRegistrar registrar: FlutterPluginRegistrar, withId id: Int64){
        self.registrar = registrar
        self.hostedView = UIView()
        self.player = VLCMediaPlayer()
        self.channel = FlutterMethodChannel(name: "flutter_video_plugin/getVideoView_\(id)", binaryMessenger: registrar.messenger())
        self.eventChannel = FlutterEventChannel(name: "flutter_video_plugin/getVideoEvents_\(id)", binaryMessenger: registrar.messenger())
        self.eventChannelHandler = VLCPlayerEventStreamHandler()
        
        
    }
    
    public func view() -> UIView {
        channel.setMethodCallHandler({
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            guard let self = self else { return }
            
            if let arguments = call.arguments as? Dictionary<String,Any>
            {
                switch(FlutterMethodCallOption(rawValue: call.method)){
                case .initialize:
                    
                    guard let  urlString = arguments["url"] as? String, let url = URL(string: urlString) else {
                        
                        result(FlutterError(code: "500",
                                            message: "Url is need to initialization",
                                            details: nil)
                        )
                        return
                    }
                    
                    let media = VLCMedia(url: url)
                    
                    
                    self.player.media = media
                    self.player.position = 0.5
                    self.player.drawable = self.hostedView
                    self.player.delegate = self.eventChannelHandler
                    
                    result(nil)
                    return
                case .setPlaybackState:
                    let playbackState = arguments["playbackState"] as? String
                    
                    if (playbackState == "play") {
                        self.player.play()
                    } else if (playbackState == "pause") {
                        self.player.pause()
                    } else if (playbackState == "stop") {
                        self.player.stop()
                    }
                    
                    result(nil)
                    return
                case .dispose:
                    self.player.stop()
                    return
                case .changeURL:
                    self.player.stop()
                    
                    guard let  urlString = arguments["url"] as? String, let url = URL(string: urlString) else {
                        
                        result(FlutterError(code: "500",
                                            message: "Url is need to initialization",
                                            details: nil)
                        )
                        return
                    }
                    
                    let media = VLCMedia(url: url)
                    
                    self.player.media = media
                    result(nil)
                    return
                    
                case .getSnapshot:
                    let drawable:UIView = self.player.drawable as! UIView
                    let size = drawable.frame.size
                    
                    UIGraphicsBeginImageContextWithOptions(size , _: false, _: 0.0)
                    
                    let rec = drawable.frame
                    drawable.drawHierarchy(in: rec , afterScreenUpdates: false)
                    
                    let image = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    let byteArray = (image ?? UIImage()).pngData()
                    
                    result([
                        "snapshot": byteArray?.base64EncodedString()
                    ])
                    return
                    
                case .setPlaybackSpeed:
                    
                    let playbackSpeed = arguments["speed"] as? String
                    let rate = (playbackSpeed! as NSString).floatValue
                    self.player.rate = rate
                    result(nil)
                    return
                    
                case .setTime:
                    let setTimeInMillisecondsAsString = arguments["time"] as? String
                    let newTime = NSNumber(value:(setTimeInMillisecondsAsString! as NSString).doubleValue)
                    let time = VLCTime(number: newTime )
                    self.player.time = time
                   

                    result(nil)
                    return
                    
                default:
                    result(FlutterMethodNotImplemented)
                    return
                }
            } else {
                print("no arguments")
            }
            
        })
        
        eventChannel.setStreamHandler(eventChannelHandler)
        return hostedView
        
    }
    
    
    
}

class VLCPlayerEventStreamHandler:NSObject, FlutterStreamHandler, VLCMediaPlayerDelegate {
    
    private var eventSink: FlutterEventSink?
    
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    
    func mediaPlayerStateChanged(_ aNotification: Notification?) {
        
        guard let eventSink = self.eventSink else { return }
        
        let player = aNotification?.object as? VLCMediaPlayer
        let media = player?.media
        let tracks: [Any] = media?.tracksInformation ?? [""]  //[Any]
        var track:NSDictionary
        
        var ratio = Float(0.0)
        var height = 0
        var width =  0
        
        if player?.currentVideoTrackIndex != -1 {
            if (player?.currentVideoTrackIndex) != nil {
                track =  tracks[0] as! NSDictionary
                height = (track["height"] as? Int ) ?? 0
                width = (track["width"] as? Int) ?? 0
                
                if height != 0 && width != 0  {
                    ratio = Float(width / height)
                }
                
            }
            
        }
                
        switch player?.state {
            
        case .esAdded, .buffering, .opening:
            return
        case .playing:
            eventSink([
                "name": "buffering",
                "value": NSNumber(value: false)
            ])
            if let value = media?.length.value {
                eventSink([
                    "name": "playing",
                    "value": NSNumber(value: true),
                    "ratio": NSNumber(value: ratio),
                    "height": height,
                    "width": width,
                    "length": value
                ])
            }
            return
        case .ended:
            eventSink([
                "name": "ended"
            ])
            eventSink([
                "name": "playing",
                "value": NSNumber(value: false),
                "reason": "EndReached"
            ])
            return
        case .error:
            eventSink(FlutterError(code: "500",
                                   message: "Player State got an error",
                                   details: nil)
            )
            
            return
            
        case .paused, .stopped:
            eventSink([
                "name": "buffering",
                "value": NSNumber(value: false)
            ])
            eventSink([
                "name": "playing",
                "value": NSNumber(value: false)
            ])
            return
        default:
            break
        }
        
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        
        let player = aNotification?.object as? VLCMediaPlayer
        
        if let value = player?.time.value {
            eventSink?([
                "name": "timeChanged",
                "value": value,
                "speed": NSNumber(value: player?.rate ?? 1.0)
            ])
        }
        
        
    }
}


public class VLCViewFactory: NSObject, FlutterPlatformViewFactory {
    
    private var registrar: FlutterPluginRegistrar?
    
    public init(withRegistrar registrar: FlutterPluginRegistrar){
        super.init()
        self.registrar = registrar
    }
    
    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        //Can pass args if necessary for intialization. For now default to empty Rect.
        //let dictionary =  args as! Dictionary<String, Double>
        return VLCView(withFrame: CGRect(x: 0, y: 0, width:  0, height:  0), withRegistrar: registrar!,withId: viewId)
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec(readerWriter: FlutterStandardReaderWriter())
    }
}


enum FlutterMethodCallOption :String {
    case initialize = "initialize"
    case setPlaybackState = "setPlaybackState"
    case dispose = "dispose"
    case changeURL = "changeURL"
    case getSnapshot = "getSnapshot"
    case setPlaybackSpeed = "setPlaybackSpeed"
    case setTime = "setTime"
}
