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
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB1SwUpuVR_PETD5-3cpv1OLQf9eKaQGdE',
    appId: '1:110887096124:web:9502ec02acf35200cf5839',
    messagingSenderId: '110887096124',
    projectId: 'smart-traffic-vision-app',
    authDomain: 'smart-traffic-vision-app.firebaseapp.com',
    storageBucket: 'smart-traffic-vision-app.firebasestorage.app',
    measurementId: 'G-DMBEFDLYZ2',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCt3KfZDmbywLidmrNLU-Q53DfAG7jPkZg',
    appId: '1:110887096124:android:b305070dc43e5d31cf5839',
    messagingSenderId: '110887096124',
    projectId: 'smart-traffic-vision-app',
    storageBucket: 'smart-traffic-vision-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD-k3JLnXut3Er1sIzRRKAg-Ogtit-qfpE',
    appId: '1:110887096124:ios:67f0efb284a9cd5dcf5839',
    messagingSenderId: '110887096124',
    projectId: 'smart-traffic-vision-app',
    storageBucket: 'smart-traffic-vision-app.firebasestorage.app',
    androidClientId: '110887096124-e0255fm6h2fjifkbh9fj0edpj2u5qsor.apps.googleusercontent.com',
    iosClientId: '110887096124-4ff4bp8av32kb4e13piek8e299oklb6n.apps.googleusercontent.com',
    iosBundleId: 'com.example.smarttrafficapp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyD-k3JLnXut3Er1sIzRRKAg-Ogtit-qfpE',
    appId: '1:110887096124:ios:67f0efb284a9cd5dcf5839',
    messagingSenderId: '110887096124',
    projectId: 'smart-traffic-vision-app',
    storageBucket: 'smart-traffic-vision-app.firebasestorage.app',
    androidClientId: '110887096124-e0255fm6h2fjifkbh9fj0edpj2u5qsor.apps.googleusercontent.com',
    iosClientId: '110887096124-4ff4bp8av32kb4e13piek8e299oklb6n.apps.googleusercontent.com',
    iosBundleId: 'com.example.smarttrafficapp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyB1SwUpuVR_PETD5-3cpv1OLQf9eKaQGdE',
    appId: '1:110887096124:web:c5f1cf35cd818228cf5839',
    messagingSenderId: '110887096124',
    projectId: 'smart-traffic-vision-app',
    authDomain: 'smart-traffic-vision-app.firebaseapp.com',
    storageBucket: 'smart-traffic-vision-app.firebasestorage.app',
    measurementId: 'G-9YC6EMMD04',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'AIzaSyB1SwUpuVR_PETD5-3cpv1OLQf9eKaQGdE',
    appId: '1:110887096124:web:9502ec02acf35200cf5839',
    messagingSenderId: '110887096124',
    projectId: 'smart-traffic-vision-app',
    authDomain: 'smart-traffic-vision-app.firebaseapp.com',
    storageBucket: 'smart-traffic-vision-app.firebasestorage.app',
    measurementId: 'G-DMBEFDLYZ2',
  );
}