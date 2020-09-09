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
    private var vlcMediaPlayer: VLCMediaPlayer!
    private var registrar: FlutterPluginRegistrar
    private var channel: FlutterMethodChannel
    private var eventChannel: FlutterEventChannel
    private var player: VLCMediaPlayer
    private var eventChannelHandler: VLCPlayerEventStreamHandler
    private var aspectSet = false

    public init(withFrame _: CGRect, withRegistrar registrar: FlutterPluginRegistrar, withId id: Int64) {
        self.registrar = registrar
        hostedView = UIView()
        player = VLCMediaPlayer()
        channel = FlutterMethodChannel(name: "flutter_video_plugin/getVideoView_\(id)", binaryMessenger: registrar.messenger())
        eventChannel = FlutterEventChannel(name: "flutter_video_plugin/getVideoEvents_\(id)", binaryMessenger: registrar.messenger())
        eventChannelHandler = VLCPlayerEventStreamHandler()
    }

    public func view() -> UIView {
        channel.setMethodCallHandler {
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in

            guard let self = self else { return }

            if let arguments = call.arguments as? [String: Any] {
                switch FlutterMethodCallOption(rawValue: call.method) {
                case .initialize:

                    guard let urlString = arguments["url"] as? String, let url = URL(string: urlString) else {
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

                    if playbackState == "play" {
                        self.player.play()
                    } else if playbackState == "pause" {
                        self.player.pause()
                    } else if playbackState == "stop" {
                        self.player.stop()
                    }

                    result(nil)
                    return

                case .dispose:
                    self.player.stop()
                    return

                case .isPlaying:
                    result(self.player.isPlaying)
                    return

                case .changeURL:
                    self.player.stop()

                    guard let urlString = arguments["url"] as? String, let url = URL(string: urlString) else {
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
                    let drawable: UIView = self.player.drawable as! UIView
                    let size = drawable.frame.size

                    UIGraphicsBeginImageContextWithOptions(size, _: false, _: 0.0)

                    let rec = drawable.frame
                    drawable.drawHierarchy(in: rec, afterScreenUpdates: false)

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
                    let time = (self.player.time ! as VLCTime).intValue
                    result(time)
                    return

                case .getDuration:
                    let length = (self.player.length ! as VLCTime).intValue
                    result(length)
                    return

                case .setVolume:
                    let setVolume = arguments["volume"] as? Int32
                    self.player.audio.volume = setVolume ?? 100
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
                    let spuTrackNames = self.player.videoSubTitlesNames
                    let spuTrackIndexes = self.player.videoSubTitlesIndexes
                    var subtitles: [Int: String] = [:]
                    if spuTrackIndexes != nil {
                        for index in spuTrackIndexes.indices {
                            subtitles.put(spuTrackIndexes[index], spuTrackNames[index])
                        }
                    }
                    result(subtitles)
                    return

                case .setSpuTrack:
                    let spuTrackNumber = arguments("spuTrackNumber") as? Int ?? 0
                    self.player.currentVideoSubTitleIndex = spuTrackNumber
                    result(nil)
                    return

                case .getSpuTrack:
                    let spuTrackNumber = self.player.currentVideoSubTitleIndex
                    result(spuTrackNumber)
                    return

                case .setSpuDelay:
                    let spuDelayAsString = arguments("delay") as? String
                    let souDelay = NSNumber(value: (spuDelayAsString! as NSString).integerValue)
                    self.player.currentVideoSubTitleDelay = souDelay
                    result(nil)
                    return

                case .getSpuDelay:
                    let souDelay = self.player.currentVideoSubTitleDelay
                    result(souDelay)
                    return

                case .addSubtitleTrack:
                    guard let  urlString = arguments["subtitlePath"] as? String, let url = URL(string: urlString) else {

                        result(FlutterError(code: "500",
                                            message: "subtitle file path failed",
                                            details: nil)
                        )
                        return
                    }
                    let isLocalSubtitle = arguments("isLocalSubtitle") as? Bool
                    let isSubtitleSelected = arguments("isSubtitleSelected") as? Bool
                    self.player.addPlaybackSlave(url, type: .subtitle, enforce: isSubtitleSelected)
                    // if isLocalSubtitle {
                    //     self.player.openVideoSubTitlesFromFile(subtitle)
                    // }
                    result(nil)
                    return

                case .getAudioTracksCount:
                    result(self.player.numberOfAudioTracks)
                    return

                case .getAudioTracks:
                    let audioTrackNames = self.player.audioTrackNames
                    let audioTrackIndexes = self.player.audioTrackIndexes
                    var audios: [Int: String] = [:]
                    if audioTrackIndexes != nil {
                        for index in audioTrackIndexes.indices {
                            audios.put(audioTrackIndexes[index], audioTrackNames[index])
                        }
                    }
                    result(audios)
                    return

                case .getAudioTrack:
                    let audioTrackNumber = self.player.currentAudioTrackIndex
                    result(audioTrackNumber)
                    return
                    return

                case .setAudioTrack:
                    let audioTrackNumber = arguments("audioTrackNumber") as? Int ?? 0
                    self.player.currentAudioTrackIndex = audioTrackNumber
                    // self.player.audioChannel = audioTrackNumber
                    result(nil)
                    return

                case .setAudioDelay:
                    let audioDelayAsString = arguments("delay") as? String
                    let audioDelay = NSNumber(value: (audioDelayAsString! as NSString).integerValue)
                    self.player.currentAudioPlaybackDelay = audioDelay
                    result(nil)
                    return

                case .getAudioDelay:
                    let audioDelay = self.player.currentAudioPlaybackDelay
                    result(souDelay)
                    return

                case .getVideoTracksCount:
                    result(self.player.numberOfVideoTracks)
                    return

                case .getVideoTracks:
                    let videoTracksNames = self.player.videoTrackNames
                    let videoTracksIndexes = self.player.videoTrackIndexes
                    var videos: [Int: String] = [:]
                    if videoTracksIndexes != nil {
                        for index in videoTracksIndexes.indices {
                            videos.put(videoTracksIndexes[index], videoTracksNames[index])
                        }
                    }
                    result(videos)
                    return

                case .getCurrentVideoTrack:
                    let videoTracks = self.player.videoTracks
                    let videoTrackIndex = self.player.currentVideoTrackIndex
                    // todo: look for videoTrackIndex in videoTracks array
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
                    let aspectRatio = arguments["aspect"] as? String
                    self.player.setVideoAspectRatio(aspectRatio)
                    result(nil)
                    return

                case .getVideoAspectRatio:
                    result(self.player.videoAspectRatio)
                    return

                case .startCastDiscovery:
                    return

                case .stopCastDiscovery:
                    return

                case .getCastDevices:
                    return

                case .startCasting:
                    return

                default:
                    result(FlutterMethodNotImplemented)
                    return
                }
            }
        }

        eventChannel.setStreamHandler(eventChannelHandler)
        return hostedView
    }
}

class VLCPlayerEventStreamHandler: NSObject, FlutterStreamHandler, VLCMediaPlayerDelegate {
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

        let audioTracksCount =  player?.numberOfAudioTracks ?? 0
        let activeAudioTrack =  player?.audioChannel ?? 0
        let spuTracksCount =  player?.numberOfSubtitlesTracks ?? 0
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

        switch player?.state {
        case .esAdded, .buffering:
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
    case initialize = "initialize"
    case dispose = "dispose"
    case changeURL = "changeURL"
    case getSnapshot = "getSnapshot"
    case setPlaybackState = "setPlaybackState"
    case isPlaying = "isPlaying"
    case setPlaybackSpeed = "setPlaybackSpeed"
    case getPlaybackSpeed = "getPlaybackSpeed"
    case setTime = "setTime"
    case getTime = "getTime"
    case getDuration = "getDuration"
    case setVolume = "setVolume"
    case getVolume = "getVolume"
    case getSpuTracksCount = "getSpuTracksCount"
    case getSpuTracks = "getSpuTracks"
    case setSpuTrack = "setSpuTrack"
    case getSpuTrack = "getSpuTrack"
    case setSpuDelay = "setSpuDelay"
    case getSpuDelay = "getSpuDelay"
    case addSubtitleTrack = "addSubtitleTrack"
    case getAudioTracksCount = "getAudioTracksCount"
    case getAudioTracks = "getAudioTracks"
    case getAudioTrack = "getAudioTrack"
    case setAudioTrack = "setAudioTrack"
    case setAudioDelay = "setAudioDelay"
    case getAudioDelay = "getAudioDelay"
    case getVideoTracksCount = "getVideoTracksCount"
    case getVideoTracks = "getVideoTracks"
    case getCurrentVideoTrack = "getCurrentVideoTrack"
    case getVideoTrack = "getVideoTrack"
    case setVideoScale = "setVideoScale"
    case getVideoScale = "getVideoScale"
    case setVideoAspectRatio = "setVideoAspectRatio"
    case getVideoAspectRatio = "getVideoAspectRatio"
    case startCastDiscovery = "startCastDiscovery"
    case stopCastDiscovery = "stopCastDiscovery"
    case getCastDevices = "getCastDevices"
    case startCasting = "startCasting"
}
