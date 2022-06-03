## 7.1.5
* Fix plugin destructor (https://github.com/solid-software/flutter_vlc_player/issues/237)

## 7.1.4
* Interim release to fix Flutter 3 issues

## 7.1.3
* Added support for multi-window mode in Android.
Credits to Andy Chentsov (https://github.com/andyduke).

## 7.1.2
* Add Hybrid composition support for Android.

## 7.1.1
* Fixed to work on Android 6-.
Credits to Yury Kostov (https://github.com/kostov).

## 7.1.0
* Upgrade iOS and Android Lib VLC libraries to address performance issues. https://code.videolan.org/videolan/vlc-ios/-/issues/1240
Credits to Mitch Ross (https://github.com/mitchross)

## 7.0.1
* Improve formatting
* Modify LICENSE to use template so it parsed automatically.

## 7.0.0
* **Breaking Change**: Refactored enum parameters to follow dart naming convention 
* Fixed control overlay issue after upgrading to Flutter 2.8
* Fixed Dart analysis warnings
* Removed unnecessary initialization delay
Credits to Alireza Setayesh (https://github.com/alr2413), Mitch Ross (https://github.com/mitchross), Illia Romanenko (https://github.com/illia-romanenko) and Yurii Prykhodko (https://github.com/solid-yuriiprykhodko).

## 6.0.5
* Fix issue with options applying (Android)
* Update VLCKit for iOS and Android
Credits to Vladislav Murashko (https://github.com/mrvancor).

## 6.0.4
* Added VLC http options
Credits to Alireza Setayesh (https://github.com/alr2413).

## 6.0.3
* Added VLC recording feature
Credits to Alireza Setayesh (https://github.com/alr2413).

## 6.0.2
* Fix issue with VLC error event
* Added onInit & onRenderer listeners
Credits to Alireza Setayesh (https://github.com/alr2413) and solid-vovabeloded (https://github.com/solid-vovabeloded).

## 6.0.1
* Fix issue with black screen / offstage
Credits to Mitch Ross (https://github.com/mitchross)

## 6.0.0
* Support Flutter V2 Null Safety
Credits to Mitch Ross (https://github.com/mitchross)
  
## 5.0.5
* Added VLC Subtitle Styling. 
* Split ios swift code into multiple files for better readability.
Credits to Alireza Setayesh (https://github.com/alr2413) and Yurii Prykhodko (https://github.com/solid-yuriiprykhodko).

## 5.0.4
* Added isSeekable method
Credits to Alireza Setayesh (https://github.com/alr2413), Mitch Ross (https://github.com/mitchross).

## 5.0.3
* Fix memory leak. 
Credits to Alireza Setayesh (https://github.com/alr2413), Mitch Ross (https://github.com/mitchross).

## 5.0.2
* Fix homepage link.

## 5.0.1
* Fix pub.dev image links.

## 5.0.0
* Entire rewrite of Flutter VLC Player.
* Updates to Android v2 plugin.
* Adds Platform interface.
* Adds Pigeon for type safe method calls. 
Credits to Alireza Setayesh (https://github.com/alr2413), Mitch Ross (https://github.com/mitchross) and Yurii Prykhodko (https://github.com/solid-yuriiprykhodko).

## 4.0.3
* Update VLCKit for iOS and Android. Cleanup example Pod file. Clean up example gradle. 
* Removed dispose calls on VlcPlayerController from VlcPlayer.
* Fix argument-less functions throwing FlutterMethodNotImplemented.
Credits to Mitch Ross (https://github.com/mitchross).

## 4.0.2
* Update Cocoapods version for VLCkit on iOS. This fixes issues with iOS 12 and Simulators.
Credits to Mitch Ross (https://github.com/mitchross).

## 4.0.1
* Improved documentation.

## 4.0.0
* Improved structure (see example for breaking changes). Example code updated also.
* Fix android black screen issue
* Support playing local media/subtitle file
* Support casting media to external device
* Updated changing audio/subtitle method
* Support audio/subtitle delay
credits to Alireza Setayesh (https://github.com/alr2413) and Mitch Ross (https://github.com/mitchross)

## 3.0.7
* Updates MobileVLC to allow for changing of subtitles and adding subtiles . 
credits to @rikaweb(https://github.com/rikaweb) and Mitch Ross (https://github.com/mitchross)

## 3.0.6
* Updates MobileVLC to allow for handling of vlc error.
credits to Alireza Setayesh (https://github.com/alr2413)

## 3.0.5
* Updates MobileVLC to allow for changing of volume. Example Updated Also.
credits to  Mitch Ross (https://github.com/mitchross)

## 3.0.4
* Updates MobileVLC to allow for options as flags and hardware acceleration/
credits to pharshdev (https://github.com/pharshdev) and Mitch Ross (https://github.com/mitchross)

## 3.0.3
* Updates MobileVLC to fix a bug on iOS with Seek Time. See (https://github.com/solid-software/flutter_vlc_player/issues/72). Also adds seek bar to example player for demonstration purposes.
credits to Mitch Ross (https://github.com/mitchross)

## 3.0.2
* Updates MobileVLC to fix a bug on iOS with HLS Streaming on VLCKit itself. See (https://code.videolan.org/videolan/VLCKit/-/issues/368),
credits to Mitch Ross (https://github.com/mitchross)

## 3.0.1
* Fix a bug on Android with URL parsing. See (https://github.com/solid-software/flutter_vlc_player/issues/52),
credits to pharshdev (https://github.com/pharshdev) and Mitch Ross (https://github.com/mitchross)

## 3.0.0
* Migrated to Swift, thanks to Mitch Ross (https://github.com/mitchross), 
Amadeu Cavalcante (https://github.com/amadeu01) and pharshdev (https://github.com/pharshdev).

## 2.0.0
* Improved structure (see example for braking changes), add aspect ratio and payback controls 
support thanks to John Harker (https://github.com/NBTX) and Mitch Ross (https://github.com/mitchross).

## 1.0.0
* Added multiple players support thanks to Kraig Spear (https://github.com/kraigspear)

## 0.0.2
* Android X support added thanks to Javi Hurtado (https://github.com/ja2375)

## 0.0.1

* initial flutter vlc plugin (not working with android x)
