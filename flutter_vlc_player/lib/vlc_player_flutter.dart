library vlc_player_flutter;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_vlc_player_platform_interface/vlc_player_flutter_platform_interface.dart';

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

part 'src/enums/playing_state.dart';

part 'src/vlc_player_controller.dart';

part 'src/flutter_vlc_player.dart';

part 'src/vlc_app_life_cycle_observer.dart';

part 'src/vlc_player_value.dart';
