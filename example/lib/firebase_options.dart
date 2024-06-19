// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB9hMFGbi06-AED7MOonyjqmf5Sx1vv2_Y',
    appId: '1:70542534310:android:04052023c2facf99663667',
    messagingSenderId: '70542534310',
    projectId: 'inngage-lab',
    databaseURL: 'https://inngage-lab.firebaseio.com',
    storageBucket: 'inngage-lab.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBATazc4_oKX0SCpLKtvUTckCY_BmTnX08',
    appId: '1:70542534310:ios:bf11290b0f6852f4663667',
    messagingSenderId: '70542534310',
    projectId: 'inngage-lab',
    databaseURL: 'https://inngage-lab.firebaseio.com',
    storageBucket: 'inngage-lab.appspot.com',
    androidClientId: '70542534310-evbm1omdqlgugvrh6sn32m6phj86hc8h.apps.googleusercontent.com',
    iosClientId: '70542534310-cm5ptslt098lgra1vpdsp4280hvt7s8f.apps.googleusercontent.com',
    iosBundleId: 'br.com.inngage.demo',
  );
}
