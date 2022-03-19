import Foundation
import Flutter

public class VLCViewBuilder: NSObject, VlcPlayerApi{
    var players = [Int:VLCViewController]()
    private var registrar: FlutterPluginRegistrar
    private var messenger: FlutterBinaryMessenger
    
    init(registrar: FlutterPluginRegistrar) {
        self.registrar = registrar
        self.messenger = registrar.messenger()
        super.init()
        //
        VlcPlayerApiSetup(messenger, self)
    }
    
    public func build(frame: CGRect, viewId: Int64) -> VLCViewController{
        //
        var vlcViewController: VLCViewController
        vlcViewController = VLCViewController(frame: frame, viewId: viewId, messenger: messenger)
        players[Int(viewId)] = vlcViewController
        return vlcViewController;
    }
    
    public func initialize(_ error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        return
    }
    
    func getPlayer(viewId: NSNumber?) -> VLCViewController? {
      guard viewId != nil else {
        return nil
        
      }
        return players[Int(truncating: viewId! as NSNumber)]
    }
    
    public func create(_ input: CreateMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)
        
        var isAssetUrl: Bool = false
        var mediaUrl: String = ""
        
        if(DataSourceType(rawValue: Int(truncating: input.type!)) == DataSourceType.ASSET){
            var assetPath: String
            if input.packageName != nil {
                assetPath = registrar.lookupKey(forAsset: input.uri ?? "" , fromPackage: input.packageName ?? "")
            } else {
                assetPath = registrar.lookupKey(forAsset: input.uri ?? "")
            }
            mediaUrl = assetPath
            isAssetUrl = true
        }else{
            mediaUrl = input.uri ?? ""
            isAssetUrl = false
        }
        
        player?.setMediaPlayerUrl(
            uri: mediaUrl,
            isAssetUrl: isAssetUrl,
            autoPlay: input.autoPlay?.boolValue ?? true,
            hwAcc: input.hwAcc?.intValue ?? HWAccellerationType.HW_ACCELERATION_AUTOMATIC.rawValue,
            options: input.options as? [String] ?? []
        )
    }
    
    public func dispose(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)
        
        player?.dispose()
        players.removeValue(forKey: input.viewId as! Int)
    }
    
    public func setStreamUrl(_ input: SetMediaMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)
        
        var isAssetUrl: Bool = false
        var mediaUrl: String = ""
        
        if(DataSourceType(rawValue: Int(truncating: input.type!)) == DataSourceType.ASSET){
            var assetPath: String
            if input.packageName != nil {
                assetPath = registrar.lookupKey(forAsset: input.uri ?? "" , fromPackage: input.packageName ?? "")
            } else {
                assetPath = registrar.lookupKey(forAsset: input.uri ?? "")
            }
            mediaUrl = assetPath
            isAssetUrl = true
        }else{
            mediaUrl = input.uri ?? ""
            isAssetUrl = false
        }
        player?.setMediaPlayerUrl(
            uri: mediaUrl,
            isAssetUrl: isAssetUrl,
            autoPlay: input.autoPlay?.boolValue ?? true,
            hwAcc: input.hwAcc?.intValue ?? HWAccellerationType.HW_ACCELERATION_AUTOMATIC.rawValue,
            options: []
        )
    }
    
    public func play(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)
        
        player?.play()
    }
    
    public func pause(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)
        
        player?.pause()
    }
    
    public func stop(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)
        
        player?.stop()
    }
    
    public func isPlaying(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> BooleanMessage? {
        
        let player = getPlayer(viewId: input.viewId)

        let message: BooleanMessage = BooleanMessage()
        message.result = player?.isPlaying()
        return message
    }
    
    public func isSeekable(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> BooleanMessage? {
        
        let player = getPlayer(viewId: input.viewId)
        
        let message: BooleanMessage = BooleanMessage()
        message.result = player?.isSeekable()
        return message
    }
    
    public func setLooping(_ input: LoopingMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)

        player?.setLooping(isLooping: input.isLooping)
    }
    
    public func seek(to input: PositionMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)

        player?.seek(position: input.position)
    }
    
    public func position(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> PositionMessage? {
        
        let player = getPlayer(viewId: input.viewId)

        let message: PositionMessage = PositionMessage()
        message.position = player?.position()
        return message
    }
    
    public func duration(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> DurationMessage? {
        
        let player = getPlayer(viewId: input.viewId)
        
        let message: DurationMessage = DurationMessage()
        message.duration = player?.duration()
        return message
    }
    
    public func setVolume(_ input: VolumeMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)
        
        player?.setVolume(volume: input.volume)
    }
    
    public func getVolume(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> VolumeMessage? {
        
        let player = getPlayer(viewId: input.viewId)

        let message: VolumeMessage = VolumeMessage()
        message.volume = player?.getVolume()
        return message
    }
    
    public func setPlaybackSpeed(_ input: PlaybackSpeedMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)
        
        player?.setPlaybackSpeed(speed: input.speed)
    }
    
    public func getPlaybackSpeed(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> PlaybackSpeedMessage? {
        
        let player = getPlayer(viewId: input.viewId)
        
        let message: PlaybackSpeedMessage = PlaybackSpeedMessage()
        message.speed = player?.getPlaybackSpeed()
        return message
    }
    
    public func takeSnapshot(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> SnapshotMessage? {
        
        let player = getPlayer(viewId: input.viewId)
        
        let message: SnapshotMessage = SnapshotMessage()
        message.snapshot = player?.takeSnapshot()
        return message
    }
    
    public func getSpuTracksCount(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> TrackCountMessage? {
        
        let player = getPlayer(viewId: input.viewId)

        let message: TrackCountMessage = TrackCountMessage()
        message.count = player?.getSpuTracksCount()
        return message
    }
    
    public func getSpuTracks(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> SpuTracksMessage? {
        
        let player = getPlayer(viewId: input.viewId)

        let message: SpuTracksMessage = SpuTracksMessage()
        message.subtitles = player?.getSpuTracks()
        return message
    }
    
    public func setSpuTrack(_ input: SpuTrackMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)

        player?.setSpuTrack(spuTrackNumber: input.spuTrackNumber)
    }
    
    public func getSpuTrack(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> SpuTrackMessage? {
        
        let player = getPlayer(viewId: input.viewId)
        
        let message: SpuTrackMessage = SpuTrackMessage()
        message.spuTrackNumber = player?.getSpuTrack()
        return message
    }
    
    public func setSpuDelay(_ input: DelayMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)
        
        player?.setSpuDelay(delay: input.delay)
    }
    
    public func getSpuDelay(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> DelayMessage? {
        
        let player = getPlayer(viewId: input.viewId)
        
        let message: DelayMessage = DelayMessage()
        message.delay = player?.getSpuDelay()
        return message
    }
    
    public func addSubtitleTrack(_ input: AddSubtitleMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)
        
        player?.addSubtitleTrack(uri: input.uri, isSelected: input.isSelected)
    }
    
    public func getAudioTracksCount(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> TrackCountMessage? {
        
        let player = getPlayer(viewId: input.viewId)
        
        let message: TrackCountMessage = TrackCountMessage()
        message.count = player?.getAudioTracksCount()
        return message
    }
    
    public func getAudioTracks(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> AudioTracksMessage? {
        
        let player = getPlayer(viewId: input.viewId)
        
        let message: AudioTracksMessage = AudioTracksMessage()
        message.audios = player?.getAudioTracks()
        return message
    }
    
    public func setAudioTrack(_ input: AudioTrackMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)
        
        player?.setAudioTrack(audioTrackNumber: input.audioTrackNumber)
    }
    
    public func getAudioTrack(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> AudioTrackMessage? {
        
        let player = getPlayer(viewId: input.viewId)
        
        let message: AudioTrackMessage = AudioTrackMessage()
        message.audioTrackNumber = player?.getAudioTrack()
        return message
    }
    
    public func setAudioDelay(_ input: DelayMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)
        
        player?.setAudioDelay(delay: input.delay)
    }
    
    public func getAudioDelay(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> DelayMessage? {
        
        let player = getPlayer(viewId: input.viewId)
        
        let message: DelayMessage = DelayMessage()
        message.delay = player?.getAudioDelay()
        return message
    }
    
    public func addAudioTrack(_ input: AddAudioMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)
        
        player?.addAudioTrack(uri: input.uri, isSelected: input.isSelected)
    }
    
    public func getVideoTracksCount(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> TrackCountMessage? {
        
        let player = getPlayer(viewId: input.viewId)
        
        let message: TrackCountMessage = TrackCountMessage()
        message.count = player?.getVideoTracksCount()
        return message
    }
    
    public func getVideoTracks(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> VideoTracksMessage? {
        
        let player = getPlayer(viewId: input.viewId)
        
        let message: VideoTracksMessage = VideoTracksMessage()
        message.videos = player?.getVideoTracks()
        return message
    }
    
    public func setVideoTrack(_ input: VideoTrackMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)
        
        player?.setVideoTrack(videoTrackNumber: input.videoTrackNumber)
    }
    
    public func getVideoTrack(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> VideoTrackMessage? {
        
        let player = getPlayer(viewId: input.viewId)
        
        let message: VideoTrackMessage = VideoTrackMessage()
        message.videoTrackNumber = player?.getVideoTrack()
        return message
    }
    
    public func setVideoScale(_ input: VideoScaleMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)
        
        player?.setVideoScale(scale: input.scale)
    }
    
    public func getVideoScale(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> VideoScaleMessage? {
        
        let player = getPlayer(viewId: input.viewId)
        
        let message: VideoScaleMessage = VideoScaleMessage()
        message.scale = player?.getVideoScale()
        return message
    }
    
    public func setVideoAspectRatio(_ input: VideoAspectRatioMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)
        
        player?.setVideoAspectRatio(aspectRatio: input.aspectRatio)
    }
    
    public func getVideoAspectRatio(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> VideoAspectRatioMessage? {
        
        let player = getPlayer(viewId: input.viewId)

        let message: VideoAspectRatioMessage = VideoAspectRatioMessage()
        message.aspectRatio = player?.getVideoAspectRatio()
        return message
    }
    
    public func getAvailableRendererServices(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> RendererServicesMessage? {
        
        let player = getPlayer(viewId: input.viewId)

        let message: RendererServicesMessage = RendererServicesMessage()
        message.services = player?.getAvailableRendererServices()
        return message
    }
    
    public func startRendererScanning(_ input: RendererScanningMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)
        
        player?.startRendererScanning()
    }
    
    public func stopRendererScanning(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)

        player?.stopRendererScanning()
    }
    
    public func getRendererDevices(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> RendererDevicesMessage? {
        
        let player = getPlayer(viewId: input.viewId)
        
        let message: RendererDevicesMessage = RendererDevicesMessage()
        message.rendererDevices = player?.getRendererDevices()
        return message
    }
    
    public func cast(toRenderer input: RenderDeviceMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) {
        
        let player = getPlayer(viewId: input.viewId)
        
        player?.cast(rendererDevice: input.rendererDevice)
    }
    
    public func startRecording(_ input: RecordMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> BooleanMessage? {
        
        let player = getPlayer(viewId: input.viewId)
        
        let message: BooleanMessage = BooleanMessage()
        message.result = player?.startRecording(saveDirectory: input.saveDirectory!)
        return message
    }
    
    public func stopRecording(_ input: ViewMessage, error: AutoreleasingUnsafeMutablePointer<FlutterError?>) -> BooleanMessage? {
        
        let player = getPlayer(viewId: input.viewId)
        
        let message: BooleanMessage = BooleanMessage()
        message.result = player?.stopRecording()
        return message
    }
}
