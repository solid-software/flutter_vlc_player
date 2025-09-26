import Foundation
import Flutter
import MobileVLCKit
import UIKit


public class VLCViewController: NSObject, FlutterPlatformView {
    
    var hostedView: UIView
    var vlcMediaPlayer: VLCMediaPlayer
    var mediaEventChannel: FlutterEventChannel
    let mediaEventChannelHandler: VLCPlayerEventStreamHandler
    var rendererEventChannel: FlutterEventChannel
    let rendererEventChannelHandler: VLCRendererEventStreamHandler
    var rendererdiscoverers: [VLCRendererDiscoverer] = [VLCRendererDiscoverer]()
    
    public func view() -> UIView {
        return hostedView
    }
    
    init(frame: CGRect, viewId: Int64, messenger:FlutterBinaryMessenger) {
        
        let mediaEventChannel = FlutterEventChannel(
            name: "flutter_video_plugin/getVideoEvents_\(viewId)",
            binaryMessenger: messenger
        )
        let rendererEventChannel = FlutterEventChannel(
            name: "flutter_video_plugin/getRendererEvents_\(viewId)",
            binaryMessenger: messenger
        )
        
        self.hostedView = UIView(frame: frame)
        self.vlcMediaPlayer = VLCMediaPlayer()
//        self.vlcMediaPlayer.libraryInstance.debugLogging = true
//        self.vlcMediaPlayer.libraryInstance.debugLoggingLevel = 3
        self.mediaEventChannel = mediaEventChannel
        self.mediaEventChannelHandler = VLCPlayerEventStreamHandler()
        self.rendererEventChannel = rendererEventChannel
        self.rendererEventChannelHandler = VLCRendererEventStreamHandler()
        //
        self.mediaEventChannel.setStreamHandler(mediaEventChannelHandler)
        self.rendererEventChannel.setStreamHandler(rendererEventChannelHandler)
        self.vlcMediaPlayer.drawable = self.hostedView
        self.vlcMediaPlayer.delegate = self.mediaEventChannelHandler
    }
    
    public func play() {
        self.vlcMediaPlayer.play()
    }
    
    public func pause() {
        
        self.vlcMediaPlayer.pause()
    }
    
    public func stop() {
        
        self.vlcMediaPlayer.stop()
    }
    
    public func isPlaying() -> NSNumber?{
        
        return self.vlcMediaPlayer.isPlaying as NSNumber
    }
    
    public func isSeekable() -> NSNumber? {
        
        return self.vlcMediaPlayer.isSeekable as NSNumber
    }
    
    public func setLooping(isLooping: NSNumber?) {
        
        let enableLooping = isLooping?.boolValue ?? false;
        self.vlcMediaPlayer.media?.addOption(enableLooping ? "--loop" : "--no-loop")
    }
    
    public func seek(position: NSNumber?) {
        
        self.vlcMediaPlayer.time = VLCTime(number: position ?? 0)
    }
    
    public func position() -> NSNumber? {
        
        return self.vlcMediaPlayer.time.value
    }
    
    public func duration() -> NSNumber? {
        
        return self.vlcMediaPlayer.media?.length.value ?? 0
        
    }
    
    public func setVolume(volume: NSNumber?) {
        
        self.vlcMediaPlayer.audio?.volume = volume?.int32Value ?? 100
    }
    
    public func getVolume() -> NSNumber? {
        
        return NSNumber(value: self.vlcMediaPlayer.audio?.volume ?? 100)
    }
    
    public func setPlaybackSpeed(speed: NSNumber?) {
        
        self.vlcMediaPlayer.rate = speed?.floatValue ?? 1
    }
    
    public func getPlaybackSpeed() -> NSNumber? {
        
        return NSNumber(value: self.vlcMediaPlayer.rate)
    }
    
    public func takeSnapshot() -> String? {
        
        let drawable: UIView = self.vlcMediaPlayer.drawable as! UIView
        let size = drawable.frame.size
        UIGraphicsBeginImageContextWithOptions(size, _: false, _: 0.0)
        let rec = drawable.frame
        drawable.drawHierarchy(in: rec, afterScreenUpdates: false)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        let byteArray = (image ?? UIImage()).pngData()
        //
        return byteArray?.base64EncodedString()
    }
    
    public func getSpuTracksCount() -> NSNumber? {
        
        return NSNumber(value: self.vlcMediaPlayer.numberOfSubtitlesTracks)
    }
    
    public func getSpuTracks() -> [Int:String]? {
        
        return self.vlcMediaPlayer.subtitles()
    }
    
    public func setSpuTrack(spuTrackNumber: NSNumber?) {
        
        self.vlcMediaPlayer.currentVideoSubTitleIndex = spuTrackNumber?.int32Value ?? 0
    }
    
    public func getSpuTrack() -> NSNumber? {
        
        return NSNumber(value: self.vlcMediaPlayer.currentVideoSubTitleIndex)
    }
    
    public func setSpuDelay(delay: NSNumber?) {
        
        self.vlcMediaPlayer.currentVideoSubTitleDelay = delay?.intValue ?? 0
    }
    
    public func getSpuDelay() -> NSNumber? {
        
        return NSNumber(value: self.vlcMediaPlayer.currentVideoSubTitleDelay)
    }
    
    public func addSubtitleTrack(uri: String?, isSelected: NSNumber?) {
        
        // todo: check for file type
        guard let urlString = uri,
              let url = URL(string: urlString)
        else {
            return
        }
        self.vlcMediaPlayer.addPlaybackSlave(
            url,
            type: VLCMediaPlaybackSlaveType.subtitle,
            enforce: isSelected?.boolValue ?? true
        )
    }
    
    public func getAudioTracksCount() -> NSNumber? {
        
        return NSNumber(value: self.vlcMediaPlayer.numberOfAudioTracks)
    }
    
    public func getAudioTracks() -> [Int:String]? {
        
        return self.vlcMediaPlayer.audioTracks()
    }
    
    public func setAudioTrack(audioTrackNumber: NSNumber?) {
        
        self.vlcMediaPlayer.currentAudioTrackIndex = audioTrackNumber?.int32Value ?? 0
    }
    
    public func getAudioTrack() -> NSNumber? {
        
        return NSNumber(value: self.vlcMediaPlayer.currentAudioTrackIndex)
    }
    
    public func setAudioDelay(delay: NSNumber?) {
        
        self.vlcMediaPlayer.currentAudioPlaybackDelay = delay?.intValue ?? 0
    }
    
    public func getAudioDelay() -> NSNumber? {
        
        return NSNumber(value: self.vlcMediaPlayer.currentAudioPlaybackDelay)
    }
    
    public func addAudioTrack(uri: String?, isSelected: NSNumber?) {
        
        // todo: check for file type
        guard let urlString = uri,
              let url = URL(string: urlString)
        else {
            return
        }
        self.vlcMediaPlayer.addPlaybackSlave(
            url,
            type: VLCMediaPlaybackSlaveType.audio,
            enforce: isSelected?.boolValue ?? true
        )
    }
    
    public func getVideoTracksCount() -> NSNumber? {
        
        return NSNumber(value: self.vlcMediaPlayer.numberOfVideoTracks)
    }
    
    public func getVideoTracks() -> [Int:String]? {
        
        return self.vlcMediaPlayer.videoTracks()
    }
    
    public func setVideoTrack(videoTrackNumber: NSNumber?) {
        
        self.vlcMediaPlayer.currentVideoTrackIndex = videoTrackNumber?.int32Value ?? 0
    }
    
    public func getVideoTrack() -> NSNumber? {
        
        return NSNumber(value: self.vlcMediaPlayer.currentVideoTrackIndex)
    }
    
    public func setVideoScale(scale: NSNumber?) {
        
        self.vlcMediaPlayer.scaleFactor = scale?.floatValue ?? 1
    }
    
    public func getVideoScale() -> NSNumber? {
        
        return NSNumber(value: self.vlcMediaPlayer.scaleFactor)
    }
    
    public func setVideoAspectRatio(aspectRatio: String?) {
        
        let aspectRatio = UnsafeMutablePointer<Int8>(
            mutating: (aspectRatio as NSString?)?.utf8String!
        )
        self.vlcMediaPlayer.videoAspectRatio = aspectRatio
    }
    
    public func getVideoAspectRatio() -> String? {
        
        guard let aspectRatio = self.vlcMediaPlayer.videoAspectRatio else { return "1"};
        
        return String(cString: aspectRatio)
    }
    
    public func getAvailableRendererServices() -> [String]? {
        
        return self.vlcMediaPlayer.rendererServices()
    }
    
    public func startRendererScanning() {
        
        rendererdiscoverers.removeAll()
        rendererEventChannelHandler.renderItems.removeAll()
        // chromecast service name: "Bonjour_renderer"
        let rendererServices = self.vlcMediaPlayer.rendererServices()
        for rendererService in rendererServices{
            guard let rendererDiscoverer
                    = VLCRendererDiscoverer(name: rendererService) else {
                continue
            }
            rendererDiscoverer.delegate = self.rendererEventChannelHandler
            rendererDiscoverer.start()
            rendererdiscoverers.append(rendererDiscoverer)
        }
    }
    
    public func stopRendererScanning() {
        
        for rendererDiscoverer in rendererdiscoverers {
            rendererDiscoverer.stop()
            rendererDiscoverer.delegate = nil
        }
        rendererdiscoverers.removeAll()
        rendererEventChannelHandler.renderItems.removeAll()
        if(self.vlcMediaPlayer.isPlaying){
            self.vlcMediaPlayer.pause()
        }
        self.vlcMediaPlayer.setRendererItem(nil)
    }
    
    public func getRendererDevices() -> [String: String]? {
        
        var rendererDevices: [String: String] = [:]
        let rendererItems = rendererEventChannelHandler.renderItems
        for (_, item) in rendererItems.enumerated() {
            rendererDevices[item.name] = item.name
        }
        return rendererDevices
    }
    
    public func cast(rendererDevice: String?) {
        
        if (self.vlcMediaPlayer.isPlaying){
            self.vlcMediaPlayer.pause()
        }
        let rendererItems = self.rendererEventChannelHandler.renderItems
        let rendererItem = rendererItems.first{
            $0.name.contains(rendererDevice ?? "")
        }
        self.vlcMediaPlayer.setRendererItem(rendererItem)
        self.vlcMediaPlayer.play()
    }
    
    public func startRecording(saveDirectory: String) -> NSNumber{
        return (!self.vlcMediaPlayer.startRecording(atPath: saveDirectory)) as NSNumber
    }
    
    public func stopRecording() -> NSNumber{
        return (!self.vlcMediaPlayer.stopRecording()) as NSNumber
    }
    
    public func dispose(){
        self.mediaEventChannel.setStreamHandler(nil);
        self.rendererEventChannel.setStreamHandler(nil);
        self.rendererdiscoverers.removeAll()
        self.rendererEventChannelHandler.renderItems.removeAll()
        self.vlcMediaPlayer.stop()
    }
    
    func setMediaPlayerUrl(uri: String, isAssetUrl: Bool, autoPlay: Bool, hwAcc: Int, options: [String]){
        self.vlcMediaPlayer.stop()
        
        var media: VLCMedia
        if(isAssetUrl){
            guard let path = Bundle.main.path(forResource: uri, ofType: nil)
            else {
                return
            }
            media = VLCMedia(path: path)
        }
        else{
            guard let url = URL(string: uri)
            else {
                return
            }
            media = VLCMedia(url: url)
        }
        
        if(!options.isEmpty){
            for option in options {
                media.addOption(option)
            }
        }
        
        switch HWAccellerationType.init(rawValue: hwAcc)
        {
        case .HW_ACCELERATION_DISABLED:
            media.addOption("--codec=avcodec")
            break

        case .HW_ACCELERATION_DECODING:
            media.addOption("--codec=all")
            media.addOption(":no-mediacodec-dr")
            media.addOption(":no-omxil-dr")
            break

        case .HW_ACCELERATION_FULL:
            media.addOption("--codec=all")
            break

        case .HW_ACCELERATION_AUTOMATIC:
            break

        case .none:
            break
        }
        
        self.vlcMediaPlayer.media = media
//        self.vlcMediaPlayer.media.parse(withOptions: VLCMediaParsingOptions(VLCMediaParseLocal | VLCMediaFetchLocal | VLCMediaParseNetwork | VLCMediaFetchNetwork))
        self.vlcMediaPlayer.play()
        if(!autoPlay){
            self.vlcMediaPlayer.stop()
        }
    }
}

class VLCRendererEventStreamHandler: NSObject, FlutterStreamHandler, VLCRendererDiscovererDelegate {
    
    private var rendererEventSink: FlutterEventSink?
    var renderItems:[VLCRendererItem] = [VLCRendererItem]()
    
    
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        
        rendererEventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        
        rendererEventSink = nil
        return nil
    }
    
    func rendererDiscovererItemAdded(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        
        self.renderItems.append(item)
        
        guard let rendererEventSink = self.rendererEventSink else { return }
        rendererEventSink([
            "event": "attached",
            "id": item.name,
            "name" : item.name,
        ])
    }
    
    func rendererDiscovererItemDeleted(_ rendererDiscoverer: VLCRendererDiscoverer, item: VLCRendererItem) {
        
        if let index = renderItems.firstIndex(of: item) {
            renderItems.remove(at: index)
        }
        
        guard let rendererEventSink = self.rendererEventSink else { return }
        rendererEventSink([
            "event": "detached",
            "id": item.name,
            "name" : item.name,
        ])
    }
}

class VLCPlayerEventStreamHandler: NSObject, FlutterStreamHandler, VLCMediaPlayerDelegate, VLCMediaDelegate  {
    
    private var mediaEventSink: FlutterEventSink?
    
    func onListen(withArguments _: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        
        mediaEventSink = events
        return nil
    }
    
    func onCancel(withArguments _: Any?) -> FlutterError? {
        
        mediaEventSink = nil
        return nil
    }
    
    func mediaPlayerStateChanged(_ aNotification: Notification) {
        guard let mediaEventSink = self.mediaEventSink else { return }
        
        let player = aNotification.object as? VLCMediaPlayer
        let media = player?.media
        let height = player?.videoSize.height ?? 0
        let width = player?.videoSize.width ?? 0
        let audioTracksCount = player?.numberOfAudioTracks ?? 0
        let activeAudioTrack = player?.currentAudioTrackIndex ?? 0
        let spuTracksCount = player?.numberOfSubtitlesTracks ?? 0
        let activeSpuTrack = player?.currentVideoSubTitleIndex ?? 0
        let duration =  media?.length.value ?? 0
        let speed = player?.rate ?? 1
        let position = player?.time.value?.intValue ?? 0
        let buffering = 100.0
        let isPlaying = player?.isPlaying ?? false
                
        switch player?.state
        {
        case .opening:
            mediaEventSink([
                "event":"opening",
            ])
            break
            
        case .paused:
            mediaEventSink([
                "event":"paused",
            ])
            break
            
        case .stopped:
            mediaEventSink([
                "event": "stopped",
            ])
            break
            
        case .playing:
            mediaEventSink([
                "event": "playing",
                "height": height,
                "width":  width,
                "speed": speed,
                "duration": duration,
                "audioTracksCount": audioTracksCount,
                "activeAudioTrack": activeAudioTrack,
                "spuTracksCount": spuTracksCount,
                "activeSpuTrack": activeSpuTrack,
            ])
            break
            
        case .ended:
            mediaEventSink([
                "event": "ended",
                "position": position
            ])
            break
            
        case .buffering:
            mediaEventSink([
                "event": "timeChanged",
                "height": height,
                "width":  width,
                "speed": speed,
                "duration": duration,
                "position": position,
                "buffer": buffering,
                "audioTracksCount": audioTracksCount,
                "activeAudioTrack": activeAudioTrack,
                "spuTracksCount": spuTracksCount,
                "activeSpuTrack": activeSpuTrack,
                "isPlaying": isPlaying,
            ])
            break
            
        case .error:
            /*mediaEventSink(
             FlutterError(
             code: "500",
             message: "Player State got an error",
             details: nil)
             )*/
            mediaEventSink([
                "event": "error",
            ])
            break
            
        case .esAdded:
            break
            
        default:
            break
        }
    }
    
    func mediaPlayerStartedRecording(_ player: VLCMediaPlayer) {
        guard let mediaEventSink = self.mediaEventSink else { return }
                
        mediaEventSink([
            "event": "recording",
            "isRecording": true,
            "recordPath": "",
        ])
    }
    
    func mediaPlayer(_ player: VLCMediaPlayer, recordingStoppedAtPath path: String) {
        guard let mediaEventSink = self.mediaEventSink else { return }
        
        mediaEventSink([
            "event": "recording",
            "isRecording": false,
            "recordPath": path ,
        ])
    }
    
    func mediaPlayerTimeChanged(_ aNotification: Notification) {
        guard let mediaEventSink = self.mediaEventSink else { return }
        
        let player = aNotification.object as? VLCMediaPlayer
        //
        let height = player?.videoSize.height ?? 0
        let width = player?.videoSize.width ?? 0
        let speed = player?.rate ?? 1
        let duration = player?.media?.length.value ?? 0
        let audioTracksCount = player?.numberOfAudioTracks ?? 0
        let activeAudioTrack = player?.currentAudioTrackIndex ?? 0
        let spuTracksCount = player?.numberOfSubtitlesTracks ?? 0
        let activeSpuTrack = player?.currentVideoSubTitleIndex ?? 0
        let buffering = 100.0
        let isPlaying = player?.isPlaying ?? false
        //
        if let position = player?.time.value {
            mediaEventSink([
                "event": "timeChanged",
                "height": height,
                "width":  width,
                "speed": speed,
                "duration": duration,
                "position": position,
                "buffer": buffering,
                "audioTracksCount": audioTracksCount,
                "activeAudioTrack": activeAudioTrack,
                "spuTracksCount": spuTracksCount,
                "activeSpuTrack": activeSpuTrack,
                "isPlaying": isPlaying,
            ])
        }
    }
}

enum DataSourceType: Int
{
    case ASSET = 0
    case NETWORK = 1
    case FILE = 2
}

enum HWAccellerationType: Int
{
    case HW_ACCELERATION_AUTOMATIC = 0
    case HW_ACCELERATION_DISABLED = 1
    case HW_ACCELERATION_DECODING = 2
    case HW_ACCELERATION_FULL = 3
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
    
    func rendererServices() -> [String]{
        
        let renderers = VLCRendererDiscoverer.list()
        var services : [String] = []
        
        renderers?.forEach({ (VLCRendererDiscovererDescription) in
            services.append(VLCRendererDiscovererDescription.name)
        })
        return services
    }
    
}

