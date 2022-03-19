#  Flutter VLC Player Plugin
[![Join the chat at https://discord.gg/mNY4fjVk](https://img.shields.io/discord/716939396464508958?label=discord)](https://discord.gg/mNY4fjVk)
[![Support me on Patreon](https://img.shields.io/endpoint.svg?url=https%3A%2F%2Fshieldsio-patreon.vercel.app%2Fapi%3Fusername%3Dsolidsoftwarehq%26type%3Dpatrons&style=flat)](https://patreon.com/solidsoftwarehq)

A VLC-powered alternative to Flutter's video_player that supports iOS and Android.

<div>
  <img src="/flutter_vlc_player/doc/single.jpg" height="400">
  <img src="/flutter_vlc_player/doc/multiple.jpg" height="400">
</div>

<br>


## Installation

### iOS

If you're unable to view media loaded from an external source, you should also add the following:
```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```
For more information, or for more granular control over your App Transport Security (ATS) restrictions, you should
[read Apple's documentation](https://developer.apple.com/documentation/bundleresources/information_property_list/nsapptransportsecurity/nsallowsarbitraryloads).

Make sure that following line in `<project root>/ios/Podfile` uncommented:

`platform :ios, '9.0'`

> NOTE: While the Flutter `video_player` is not functional on iOS Simulators, this package (`flutter_vlc_player`) **is**
> fully functional on iOS simulators.

To enable vlc cast functionality for external displays (chromecast), you should also add the following:

```xml
<key>NSLocalNetworkUsageDescription</key>
<string>Used to search for chromecast devices</string>
<key>NSBonjourServices</key>
<array>
  <string>_googlecast._tcp</string>
</array>
```

<hr>

### Android
To load media/subitle from an internet source, your app will need the `INTERNET` permission.  
This is done by ensuring your `<project root>/android/app/src/main/AndroidManifest.xml` file contains a `uses-permission`
declaration for `android.permission.INTERNET`:
```xml
<uses-permission android:name="android.permission.INTERNET" />
```

As Flutter includes this permission by default, the permission is likely already declared in the file.

Note that if you got "Cleartext HTTP traffic to * is not permitted"
you need to add the `android:usesClearTextTraffic="true"` flag in the AndroidManifest.xml file, or define a new "Network Security Configuration" file. For more information, check https://developer.android.com/training/articles/security-config

<br>

In order to load media/subtitle from internal device storage, you should put the storage permissions as follows:
```xml
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
```
In some cases you also need to add the `android:requestLegacyExternalStorage="true"` flag to the Application tag in AndroidManifest.xml file to avoid acess denied errors. Android 10 apps can't acess storage without that flag. [reference](https://stackoverflow.com/a/60917774/14919621)

After that you can access the media/subtitle file by 

    "/storage/emulated/0/{FilePath}"
    "/sdcard/{FilePath}"

<hr>

#### Android build configuration

1. In `android/app/build.gradle`:
```groovy
android {
    packagingOptions {
       // Fixes duplicate libraries build issue, 
       // when your project uses more than one plugin that depend on C++ libs.
        pickFirst 'lib/**/libc++_shared.so'
    }
   
   buildTypes {
      release {
         minifyEnabled true
         useProguard true
         proguardFiles getDefaultProguardFile(
                 'proguard-android-optimize.txt'),
                 'proguard-rules.pro'
      }
   }
}
```

2. Create `android/app/proguard-rules.pro`, add the following lines:
```proguard
-keep class org.videolan.libvlc.** { *; }
```

<br>

## Quick Start
To start using the plugin, copy this code or follow the example project in 'flutter_vlc_player/example'

```dart
import 'package:flutter/material.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  VlcPlayerController _videoPlayerController;

  @override
  void initState() {
    super.initState();

    _videoPlayerController = VlcPlayerController.network(
      'https://media.w3.org/2010/05/sintel/trailer.mp4',
      hwAcc: HwAcc.full,
      autoPlay: false,
      options: VlcPlayerOptions(),
    );
  }

  @override
  void dispose() async {
    super.dispose();
    await _videoPlayerController.stopRendererScanning();
    await _videoPlayerController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: VlcPlayer(
          controller: _videoPlayerController,
          aspectRatio: 16 / 9,
          placeholder: Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
```
<br>

### Recording feature
To start/stop video recording, you have to call the `startRecording(String saveDirectory)` and `stopRecording()` methods, respectively. By calling the stop method you can get the path of recorded file from `vlcPlayerController.value.recordPath`.

<hr>

## Upgrade instructions

### Version 5.0 Upgrade For Existing Apps
To upgrade to version 5.0 first you need to migrate the existing project to swift.

1. Clean the repo:

     ```git clean -xdf```
     
2. Delete existing ios folder from root of flutter project. If you have some custom changes made to the iOS app - rename it or copy somewhere outside the project.

3. Re-create the iOS app: This command will create only ios directory with swift support. See https://stackoverflow.com/questions/52244346/how-to-enable-swift-support-for-existing-project-in-flutter


    ```flutter create -i swift .```


    
4. Make sure to update the project according to warnings shown by the flutter tools. (Update Info.plist, Podfile).

If you have some changes made to the iOS app, recreate the app using above method and copy in the changed files.

Be sure to follow instructions above after 

<br>

### Breaking Changes (from V4 to V5)
Entire platform has been refactored in v5. It will require a refactor of your app to follow v5. 

<hr>

## Known Issues
<b>1)</b> The video recording feature is problematic in iOS/Android: if the video reaches its end while you're recording it, the underlying `vlckit`/`libvlc` library fails to finalize the recording process, and we cannot retrieve the recorded file. 
The issue is reported and tracked here: 
<br>
[https://code.videolan.org/videolan/VLCKit/-/issues/394](https://code.videolan.org/videolan/VLCKit/-/issues/394) (see last comment from September 22, 2020)

<hr>

## Current issues
Current issues list [is here](https://github.com/solid-software/flutter_vlc_player/issues).   
Found a bug? [Open the issue](https://github.com/solid-software/flutter_vlc_player/issues/new).
