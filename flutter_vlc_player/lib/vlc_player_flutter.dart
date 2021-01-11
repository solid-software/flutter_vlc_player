library flutter_vlc_player;

export 'package:flutter_vlc_player_platform_interface/vlc_player_flutter_platform_interface.dart'
    show
        HwAcc,
        VlcMediaEvent,
        VlcMediaEventType,
        VlcRendererEvent,
        VlcRendererEventType,
        DataSourceType,
        VlcPlayerOptions,
        VlcAdvancedOptions,
        VlcAudioOptions,
        VlcRtpOptions,
        VlcStreamOutputOptions,
        VlcVideoOptions;

export 'src/enums/playing_state.dart';
export 'src/vlc_player_controller.dart';
export 'src/flutter_vlc_player.dart';
export 'src/vlc_app_life_cycle_observer.dart';
export 'src/vlc_player_value.dart';
