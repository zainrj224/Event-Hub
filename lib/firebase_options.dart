// File generated based on your Firebase project configuration.
// event-hub-bed3e

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCP4QsWJTCmz-aLaIpZ14rgdmE3-icMQx0',
    appId: '1:509060751776:web:acf84c3706f8ad87f9c4c5',
    messagingSenderId: '509060751776',
    projectId: 'event-hub-bed3e',
    authDomain: 'event-hub-bed3e.firebaseapp.com',
    databaseURL: 'https://event-hub-bed3e-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'event-hub-bed3e.firebasestorage.app',
    measurementId: 'G-RYCEK3WPVV',
  );

  // NOTE: For Android/iOS/macOS/Windows, download the platform-specific
  // config files from Firebase Console and replace the placeholder values:
  //   Android  → google-services.json  → android/app/
  //   iOS/macOS → GoogleService-Info.plist → ios/Runner/ and macos/Runner/
  // Then update the appId values below with the ones from those files.

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDJAqEKme2-j1Ziw57FH3_AlJ08tm8Eras',
    appId: '1:509060751776:android:e22419c787697a6ff9c4c5',
    messagingSenderId: '509060751776',
    projectId: 'event-hub-bed3e',
    databaseURL: 'https://event-hub-bed3e-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'event-hub-bed3e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBGI4jKqxQGu6PnppEh_CAM62VWUccqMDc',
    appId: '1:509060751776:ios:185e7d504333818ef9c4c5',
    messagingSenderId: '509060751776',
    projectId: 'event-hub-bed3e',
    databaseURL: 'https://event-hub-bed3e-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'event-hub-bed3e.firebasestorage.app',
    iosClientId: '509060751776-53smrkpgi141qlqp7clm1ue7cvehalvb.apps.googleusercontent.com',
    iosBundleId: 'com.example.eventDiscoveryApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBGI4jKqxQGu6PnppEh_CAM62VWUccqMDc',
    appId: '1:509060751776:ios:185e7d504333818ef9c4c5',
    messagingSenderId: '509060751776',
    projectId: 'event-hub-bed3e',
    databaseURL: 'https://event-hub-bed3e-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'event-hub-bed3e.firebasestorage.app',
    iosClientId: '509060751776-53smrkpgi141qlqp7clm1ue7cvehalvb.apps.googleusercontent.com',
    iosBundleId: 'com.example.eventDiscoveryApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCP4QsWJTCmz-aLaIpZ14rgdmE3-icMQx0',
    appId: '1:509060751776:web:cb8957bc3baeed6cf9c4c5',
    messagingSenderId: '509060751776',
    projectId: 'event-hub-bed3e',
    authDomain: 'event-hub-bed3e.firebaseapp.com',
    databaseURL: 'https://event-hub-bed3e-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'event-hub-bed3e.firebasestorage.app',
    measurementId: 'G-ZVD51R80Y6',
  );

}