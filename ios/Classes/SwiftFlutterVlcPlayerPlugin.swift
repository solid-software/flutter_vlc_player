import Flutter
import MobileVLCKit
import UIKit

public class SwiftFlutterVlcPlayerPlugin: NSObject, FlutterPlugin {
    private var factory: VLCViewFactory
    public init(with registrar: FlutterPluginRegistrar) {
        factory = VLCViewFactory(withRegistrar: registrar)
        registrar.register(factory, withId: "flutter_video_plugin/getVideoView")
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        registrar.addApplicationDelegate(SwiftFlutterVlcPlayerPlugin(with: registrar))
    }
}

public class VLCView: NSObject, FlutterPlatformView {
   

    @IBOutlet private var hostedView: UIView!
//    private var vlcMediaPlayer: VLCMediaPlayer!
    private var registrar: FlutterPluginRegistrar
    private var channel: FlutterMethodChannel
    private var eventChannel: FlutterEventChannel
    private var player: VLCMediaPlayer
    private var eventChannelHandler: VLCPlayerEventStreamHandler
    private var aspectSet = false
    //
    private static var HW_ACCELERATION_AUTOMATIC = -1
    private static var HW_ACCELERATION_DISABLED = 0
    private static var HW_ACCELERATION_DECODING = 1
    private static var HW_ACCELERATION_FULL = 2
    
    var rendererItems: [VLCRendererItem] = [VLCRendererItem]()
    var discoverers: [VLCRendererDiscoverer] = [VLCRendererDiscoverer]()
    var strongRef: VLCRendererDiscoverer?
    
    public init(withFrame _: CGRect, withRegistrar registrar: FlutterPluginRegistrar, withId id: Int64) {
        self.registrar = registrar
        hostedView = UIView()
        player = VLCMediaPlayer()
        channel = FlutterMethodChannel(name: "flutter_video_plugin/getVideoView_\(id)", binaryMessenger: registrar.messenger())
        eventChannel = FlutterEventChannel(name: "flutter_video_plugin/getVideoEvents_\(id)", binaryMessenger: registrar.messenger())
        eventChannelHandler = VLCPlayerEventStreamHandler()
    }
    
    public func startCasting(castDeviceName:String)
    {
        if (self.player.isPlaying)
        {
            self.player.pause()
        }
        let castItems = self.eventChannelHandler.getRenderItems()
        let castItemRenderItem = castItems.first { $0.name.contains(castDeviceName) }
        self.player.setRendererItem(castItemRenderItem)
        self.player.play()
    }
    
    public func view() -> UIView {
        channel.setMethodCallHandler {
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            
            guard let self = self else { return }
            
            if let arguments = call.arguments as? [String: Any] {
                
                switch FlutterMethodCallOption(rawValue: call.method) {
                case .initialize:
                    
                    var options = arguments["options"] as? [String] ?? []
//                    let autoplay = arguments["autoplay"] as? Bool ?? true
//                    let isLocalMedia = arguments["isLocalMedia"] as? Bool ?? false
                    let subtitleString = arguments["subtitle"] as? String ?? ""
//                    let isLocalSubtitle = arguments["isLocalSubtitle"] as? Bool ?? false
                    let isSubtitleSelected = arguments["isSubtitleSelected"] as? Bool ?? false
                    let loop = arguments["loop"] as? Bool ?? false
                    if loop {
                        options.append("--input-repeat=65535")
                    }
                    
                    guard let urlString = arguments["url"] as? String,
                        let url = URL(string: urlString)
                        else {
                            result(FlutterError(code: "500",
                                                message: "Url is need to initialization",
                                                details: nil)
                            )
                            return
                    }
                    let media = VLCMedia(url: url)
                    
                    for option in options {
                        media.addOption(option)
                    }
                    let hardwareAcceleration = arguments["hwAcc"] as? Int32 ?? -1
                    if hardwareAcceleration != VLCView.HW_ACCELERATION_AUTOMATIC {
                        if hardwareAcceleration == VLCView.HW_ACCELERATION_DISABLED {
                            media.addOption("--codec=avcodec")
                        } else if hardwareAcceleration == VLCView.HW_ACCELERATION_FULL || hardwareAcceleration == VLCView.HW_ACCELERATION_DECODING {
                            media.addOption("--codec=all")
                            if hardwareAcceleration == VLCView.HW_ACCELERATION_DECODING {
                                media.addOption(":no-mediacodec-dr")
                                media.addOption(":no-omxil-dr")
                            }
                        }
                    }
                    media.addOption(":input-fast-seek")
                    
                    self.player.media = media
                    self.player.position = 0.5
                    self.player.drawable = self.hostedView
                    self.player.delegate = self.eventChannelHandler
                    
                    if !subtitleString.isEmpty{
                        let subtitleUrl = URL(string: subtitleString)
                        self.player.addPlaybackSlave(subtitleUrl, type: .subtitle, enforce: isSubtitleSelected)
                    }
                    
                    result(nil)
                    return
                    
                case .dispose:
                    self.player.stop()
                    return
                    
                case .changeURL:
                    let isPlaying = self.player.isPlaying
                    self.player.stop()
                    
                    guard let urlString = arguments["url"] as? String, let url = URL(string: urlString) else {
                        result(FlutterError(code: "500",
                                            message: "Url is need for initialization",
                                            details: nil)
                        )
                        return
                    }
//                    let isLocalMedia = arguments["isLocalMedia"] as? Bool ?? false
                    let subtitleString = arguments["subtitle"] as? String ?? ""
//                    let isLocalSubtitle = arguments["isLocalSubtitle"] as? Bool ?? false
                    let isSubtitleSelected = arguments["isSubtitleSelected"] as? Bool ?? false
                    
                    let media = VLCMedia(url: url)
                    self.player.media = media
                    if !subtitleString.isEmpty
                    {
                        let subtitleUrl = URL(string: subtitleString)
                        self.player.addPlaybackSlave(subtitleUrl, type: .subtitle, enforce: isSubtitleSelected)
                    }
                    if isPlaying{
                        self.player.play()
                    }
                    result(nil)
                    return
                    
                case .getSnapshot:
                    let drawable: UIView = self.player.drawable as! UIView
                    let size = drawable.frame.size
                    
                    UIGraphicsBeginImageContextWithOptions(size, _: false, _: 0.0)
                    
                    let rec = drawable.frame
                    drawable.drawHierarchy(in: rec, afterScreenUpdates: false)
                    
                    let image = UIGraphicsGetImageFromCurrentImageContext()
                    UIGraphicsEndImageContext()
                    
                    let byteArray = (image ?? UIImage()).pngData()
                    
                    result([
                        "snapshot": byteArray?.base64EncodedString(),
                    ])
                    return
                    
                case .setPlaybackState:
                    let playbackState = arguments["playbackState"] as? String
                    
                    if playbackState == "play" {
                        self.player.play()
                    } else if playbackState == "pause" {
                        self.player.pause()
                    } else if playbackState == "stop" {
                        self.player.stop()
                    }
                    
                    result(nil)
                    return
                    
                    
                case .isPlaying:
                    result(self.player.isPlaying)
                    return
                    
                case .setPlaybackSpeed:
                    let playbackSpeed = arguments["speed"] as? String
                    let rate = (playbackSpeed! as NSString).floatValue
                    self.player.rate = rate
                    result(nil)
                    return
                    
                case .getPlaybackSpeed:
                    let playbackSpeed = self.player.rate
                    result(playbackSpeed)
                    return
                    
                case .setTime:
                    let setTimeInMillisecondsAsString = arguments["time"] as? String
                    let newTime = NSNumber(value: (setTimeInMillisecondsAsString! as NSString).doubleValue)
                    let time = VLCTime(number: newTime)
                    self.player.time = time
                    result(nil)
                    return
                    
                case .getTime:
                    let time = self.player.time.value.intValue
                    result(time)
                    return
                    
                case .getDuration:
                    let length = self.player.media.length.intValue
                    result(length)
                    return
                    
                case .setVolume:
                    var setVolume = arguments["volume"] as? Int32 ?? 100
                    setVolume = max(0, min(100, setVolume))
                    self.player.audio.volume = setVolume
                    result(nil)
                    return
                    
                case .getVolume:
                    let getVolume = self.player.audio.volume
                    result(getVolume)
                    return
                    
                case .getSpuTracksCount:
                    result(self.player.numberOfSubtitlesTracks)
                    return
                    
                case .getSpuTracks:
                    let subtitles = self.player.subtitles()
                    result(subtitles)
                    return
                    
                case .setSpuTrack:
                    let spuTrackNumber = arguments["spuTrackNumber"] as? Int ?? 0
                    self.player.currentVideoSubTitleIndex = Int32(spuTrackNumber)
                    result(nil)
                    return
                    
                case .getSpuTrack:
                    let spuTrackNumber = self.player.currentVideoSubTitleIndex
                    result(spuTrackNumber)
                    return
                    
                case .setSpuDelay:
                    let spuDelayAsString = arguments["delay"] as? String
                    let spuDelay = NSNumber(value: (spuDelayAsString! as NSString).integerValue)
                    self.player.currentVideoSubTitleDelay = Int(truncating: spuDelay)
                    result(nil)
                    return
                    
                case .getSpuDelay:
                    let spuDelay = self.player.currentVideoSubTitleDelay
                    result(spuDelay)
                    return
                    
                case .addSubtitleTrack:
//                    let isLocalSubtitle = arguments["isLocalSubtitle"] as? Bool
                    let isSubtitleSelected = arguments["isSubtitleSelected"] as? Bool ?? false
                    guard let subtitleString = arguments["subtitlePath"] as? String,
                        let subtitleUrl = URL(string: subtitleString) else {
                        result(FlutterError(code: "500",
                                            message: "subtitle file path failed",
                                            details: nil)
                        )
                        return
                    }
                    self.player.addPlaybackSlave(subtitleUrl, type: .subtitle, enforce: isSubtitleSelected)
//                     if isLocalSubtitle {
//                         self.player.openVideoSubTitlesFromFile(subtitle)
//                     }
                    result(nil)
                    return
                    
                case .getAudioTracksCount:
                    result(self.player.numberOfAudioTracks)
                    return
                    
                case .getAudioTracks:
                    let audioTracks = self.player.audioTracks()
                    result(audioTracks)
                    return
                    
                case .getAudioTrack:
                    let audioTrackNumber = self.player.currentAudioTrackIndex
                    result(audioTrackNumber)
                    return
                    
                case .setAudioTrack:
                    let audioTrackNumber = arguments["audioTrackNumber"] as? Int ?? 0
                    self.player.currentAudioTrackIndex = Int32(audioTrackNumber)
                    // self.player.audioChannel = audioTrackNumber
                    result(nil)
                    return
                    
                case .setAudioDelay:
                    let audioDelayAsString = arguments["delay"] as? String
                    let audioDelay = NSNumber(value: (audioDelayAsString! as NSString).integerValue)
                    self.player.currentAudioPlaybackDelay = Int(truncating: audioDelay)
                    result(nil)
                    return
                    
                case .getAudioDelay:
                    let audioDelay = self.player.currentAudioPlaybackDelay
                    result(audioDelay)
                    return
                    
                case .getVideoTracksCount:
                    result(self.player.numberOfVideoTracks)
                    return
                    
                case .getVideoTracks:
                    let videoTracks = self.player.videoTracks()
                    result(videoTracks)
                    return
                    
                case .getCurrentVideoTrack:
                    //                    let videoTracks = self.player.videoTracks
                    //                    let videoTrackIndex = self.player.currentVideoTrackIndex
                    // TODO: look for videoTrackIndex in videoTracks array
                    result(nil)
                    return
                    
                case .getVideoTrack:
                    let videoTrackIndex = self.player.currentVideoTrackIndex
                    result(videoTrackIndex)
                    return
                    
                case .setVideoScale:
                    let videoScale = arguments["scale"] as? String
                    let scale = (videoScale! as NSString).floatValue
                    self.player.scaleFactor = scale
                    result(nil)
                    return
                    
                case .getVideoScale:
                    result(self.player.scaleFactor)
                    return
                    
                case .setVideoAspectRatio:
                    let aspectRatio = arguments["aspect"] as? NSString
                    let aspectRatioConverted = UnsafeMutablePointer<Int8>(mutating: (aspectRatio)?.utf8String!)
                    self.player.videoAspectRatio = aspectRatioConverted
                    result(nil)
                    return
                    
                case .getVideoAspectRatio:
                    result(self.player.videoAspectRatio)
                    return
                    
                case .startCastDiscovery:
                    guard let rendererDiscoverer = VLCRendererDiscoverer(name: "Bonjour_renderer")
                    else {
                        print("VLCRendererDiscovererManager: Unable to instanciate renderer discoverer with name: Bonjour_renderer")
                        return
                    }
                    guard rendererDiscoverer.start() else {
                        print("VLCRendererDiscovererManager: Unable to start renderer discoverer with name: Bonjour_renderer")
                        return
                    }
                    rendererDiscoverer.delegate = self.eventChannelHandler
                    self.strongRef = rendererDiscoverer
                    result(nil)
                    return
                    
                case .stopCastDiscovery:
                    self.strongRef = nil
                    self.player.pause()
                    // todo : should we stop renderer discoveres also (stop is deprecated?!)
                    self.player.setRendererItem(nil)
                    self.rendererItems.removeAll()
                    self.discoverers.removeAll()
                    result(nil)
                    return
                    
                case .getCastDevices:
                    var castDescriptions: [String: String] = [:]
                    let castItems = self.eventChannelHandler.getRenderItems()
                    for (_, item) in castItems.enumerated() {
                        castDescriptions[item.name] = item.name
                    }
                    result(castDescriptions)
                    return
                    
                case .startCasting:
                    let castDeviceName = arguments["startCasting"] as? String
                    self.startCasting(castDeviceName: castDeviceName ?? "error")
                    result(nil)
                    return
                    
                default:
                    result(FlutterMethodNotImplemented)
                    return
                }
            } else {
                result(FlutterMethodNotImplemented)
                return
            }
        }
        
        eventChannel.setStreamHandler(eventChannelHandler)
        return hostedView
    }
}
/*
var strongRef: VLCRendererDiscoverer?
func startCastDiscovery(delegate:  VLCRendererDiscovererDelegate ) {

     guard let rendererDiscoverer = VLCRendererDiscoverer(name: "Bonjour_renderer")
     else {
         print("VLCRendererDiscovererManager: Unable to instanciate renderer discoverer with name: Bonjour_renderer")
         return
     }
     guard rendererDiscoverer.start() else {
         print("VLCRendererDiscovererManager: Unable to start renderer discoverer with name: Bonjour_renderer")
         return
    }
    //here
    rendererDiscoverer.delegate =  delegate
    strongRef = rendererDiscoverer
 }
*/
class VLCPlayerEventStreamHandler: NSObject, FlutterStreamHandler, VLCMediaPlayerDelegate, VLCRendererDiscovererDelegate {
    
    var renderItems:[VLCRendererItem] = [VLCRendererItem]()
    
    func getRenderItems() -> [VLCRendererItem]
    {
        return renderItems
    }
    
    func rendererDiscovererItemAdded(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        renderItems.append(item)
        //
        guard let eventSink = self.eventSink else { return }
        eventSink([
            "name": "castItemAdded",
            "value": item.name,
            "displayName" : item.name
        ])
    }
    
    func rendererDiscovererItemDeleted(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        if let index = renderItems.firstIndex(of: item) {
            renderItems.remove(at: index)
        }
        //
        guard let eventSink = self.eventSink else { return }
        eventSink([
            "name": "castItemDeleted",
            "value": item.name,
            "displayName" : item.name
        ])
    }
    
    private var eventSink: FlutterEventSink?
    
    func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }
    
    func onCancel(withArguments _: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    func mediaPlayerStateChanged(_ aNotification: Notification?) {
        guard let eventSink = self.eventSink else { return }
        
        let player = aNotification?.object as? VLCMediaPlayer
        let media = player?.media
        let tracks: [Any] = media?.tracksInformation ?? [""] // [Any]
        var track: NSDictionary
        
        var ratio = Float(0.0)
        var height = 0
        var width = 0
        
        let audioTracksCount = player?.numberOfAudioTracks ?? 0
        let activeAudioTrack = player?.currentAudioTrackIndex ?? 0
        let spuTracksCount = player?.numberOfSubtitlesTracks ?? 0
        let activeSpuTrack = player?.currentVideoSubTitleIndex ?? 0
        
        if player?.currentVideoTrackIndex != -1 {
            if (player?.currentVideoTrackIndex) != nil {
                track = tracks[0] as! NSDictionary
                height = (track["height"] as? Int) ?? 0
                width = (track["width"] as? Int) ?? 0
                
                if height != 0, width != 0 {
                    ratio = Float(width / height)
                }
            }
        }
        
        let rate = player?.rate ?? 1
        let time = player?.time?.value?.intValue ?? 0
        
        switch player?.state {
        case .esAdded:
            return
            
        case .opening:
            eventSink([
                "name": "buffering",
                "value": NSNumber(value: true),
            ])
            return
            
        case .playing:
            eventSink([
                "name": "buffering",
                "value": NSNumber(value: false),
            ])
            if let value = media?.length.value {
                eventSink([
                    "name": "playing",
                    "value": NSNumber(value: true),
                    "ratio": NSNumber(value: ratio),
                    "height": height,
                    "width": width,
                    "length": value,
                    "audioTracksCount": audioTracksCount,
                    "activeAudioTrack": activeAudioTrack,
                    "spuTracksCount": spuTracksCount,
                    "activeSpuTrack": activeSpuTrack,
                ])
            }
            return
        case .ended:
            eventSink([
                "name": "ended",
            ])
            eventSink([
                "name": "playing",
                "value": NSNumber(value: false),
                "reason": "EndReached",
            ])
            return
            
        case .buffering:
            eventSink([
                "name": "timeChanged",
                "value": NSNumber(value: time),
                "speed": NSNumber(value: rate),
            ])
            return
            
        case .error:
            eventSink(FlutterError(code: "500",
                                   message: "Player State got an error",
                                   details: nil)
            )
            
            return
            
        case .paused:
            eventSink([
                "name": "paused",
                "value": NSNumber(value: true),
            ])
            return
            
        case .stopped:
            eventSink([
                "name": "stopped",
                "value": NSNumber(value: true),
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
                "speed": NSNumber(value: player?.rate ?? 1.0),
            ])
        }
    }
    

    
}

public class VLCViewFactory: NSObject, FlutterPlatformViewFactory {
    private var registrar: FlutterPluginRegistrar?
    
    public init(withRegistrar registrar: FlutterPluginRegistrar) {
        super.init()
        self.registrar = registrar
    }
    
    public func create(withFrame _: CGRect, viewIdentifier viewId: Int64, arguments _: Any?) -> FlutterPlatformView {
        // Can pass args if necessary for intialization. For now default to empty Rect.
        // let dictionary =  args as! Dictionary<String, Double>
        return VLCView(withFrame: CGRect(x: 0, y: 0, width: 0, height: 0), withRegistrar: registrar!, withId: viewId)
    }
    
    public func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec(readerWriter: FlutterStandardReaderWriter())
    }
}

enum FlutterMethodCallOption: String {
    case initialize
    case dispose
    case changeURL
    case getSnapshot
    case setPlaybackState
    case isPlaying
    case setPlaybackSpeed
    case getPlaybackSpeed
    case setTime
    case getTime
    case getDuration
    case setVolume
    case getVolume
    case getSpuTracksCount
    case getSpuTracks
    case setSpuTrack
    case getSpuTrack
    case setSpuDelay
    case getSpuDelay
    case addSubtitleTrack
    case getAudioTracksCount
    case getAudioTracks
    case getAudioTrack
    case setAudioTrack
    case setAudioDelay
    case getAudioDelay
    case getVideoTracksCount
    case getVideoTracks
    case getCurrentVideoTrack
    case getVideoTrack
    case setVideoScale
    case getVideoScale
    case setVideoAspectRatio
    case getVideoAspectRatio
    case startCastDiscovery
    case stopCastDiscovery
    case getCastDevices
    case startCasting
}

extension VLCMediaPlayer {
    func subtitles() -> [Int: String] {
        guard let indexs = videoSubTitlesIndexes as? [Int],
            let names = videoSubTitlesNames as? [String],
            indexs.count == names.count
            else {
                return [:]
        }
        
        var subtitles: [Int: String] = [:]
        
        var i = 0
        for index in indexs {
            if index >= 0 {
                let name = names[i]
                subtitles[Int(index)] = name
            }
            i = i + 1
        }
        
        return subtitles
    }
    
    func audioTracks() -> [Int: String] {
        guard let indexs = audioTrackIndexes as? [Int],
            let names = audioTrackNames as? [String],
            indexs.count == names.count
            else {
                return [:]
        }
        
        var audios: [Int: String] = [:]
        
        var i = 0
        for index in indexs {
            if index >= 0 {
                let name = names[i]
                audios[Int(index)] = name
            }
            i = i + 1
        }
        
        return audios
    }
    
    func videoTracks() -> [Int: String]{
        
        guard let indexs = videoTrackIndexes as? [Int],
            let names = videoTrackNames as? [String],
            indexs.count == names.count
            else {
                return [:]
        }
        
        var videos: [Int: String] = [:]
        
        var i = 0
        for index in indexs {
            if index >= 0 {
                let name = names[i]
                videos[Int(index)] = name
            }
            i = i + 1
        }
        
        return videos
    }

}
