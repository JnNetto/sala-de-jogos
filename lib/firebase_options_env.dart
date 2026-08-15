import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class EnvFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'Firebase não foi configurado para esta plataforma.',
        );
      default:
        throw UnsupportedError('Plataforma Firebase não suportada.');
    }
  }

  static FirebaseOptions get web {
    return FirebaseOptions(
      apiKey: _required('FIREBASE_WEB_API_KEY'),
      appId: _required('FIREBASE_WEB_APP_ID'),
      messagingSenderId: _required('FIREBASE_MESSAGING_SENDER_ID'),
      projectId: _required('FIREBASE_PROJECT_ID'),
      authDomain: _optional('FIREBASE_AUTH_DOMAIN'),
      storageBucket: _optional('FIREBASE_STORAGE_BUCKET'),
      measurementId: _optional('FIREBASE_MEASUREMENT_ID'),
    );
  }

  static FirebaseOptions get android {
    return FirebaseOptions(
      apiKey: _required('FIREBASE_ANDROID_API_KEY'),
      appId: _required('FIREBASE_ANDROID_APP_ID'),
      messagingSenderId: _required('FIREBASE_MESSAGING_SENDER_ID'),
      projectId: _required('FIREBASE_PROJECT_ID'),
      storageBucket: _optional('FIREBASE_STORAGE_BUCKET'),
    );
  }

  static FirebaseOptions get ios {
    return FirebaseOptions(
      apiKey: _required('FIREBASE_IOS_API_KEY'),
      appId: _required('FIREBASE_IOS_APP_ID'),
      messagingSenderId: _required('FIREBASE_MESSAGING_SENDER_ID'),
      projectId: _required('FIREBASE_PROJECT_ID'),
      storageBucket: _optional('FIREBASE_STORAGE_BUCKET'),
      iosBundleId: _optional('FIREBASE_IOS_BUNDLE_ID'),
    );
  }

  static String _required(String name) {
    const values = {
      'FIREBASE_WEB_API_KEY': String.fromEnvironment('FIREBASE_WEB_API_KEY'),
      'FIREBASE_WEB_APP_ID': String.fromEnvironment('FIREBASE_WEB_APP_ID'),
      'FIREBASE_ANDROID_API_KEY': String.fromEnvironment(
        'FIREBASE_ANDROID_API_KEY',
      ),
      'FIREBASE_ANDROID_APP_ID': String.fromEnvironment(
        'FIREBASE_ANDROID_APP_ID',
      ),
      'FIREBASE_IOS_API_KEY': String.fromEnvironment('FIREBASE_IOS_API_KEY'),
      'FIREBASE_IOS_APP_ID': String.fromEnvironment('FIREBASE_IOS_APP_ID'),
      'FIREBASE_MESSAGING_SENDER_ID': String.fromEnvironment(
        'FIREBASE_MESSAGING_SENDER_ID',
      ),
      'FIREBASE_PROJECT_ID': String.fromEnvironment('FIREBASE_PROJECT_ID'),
    };

    final value = values[name] ?? '';
    if (value.isEmpty) {
      throw StateError('Variável de build obrigatória ausente: $name');
    }
    return value;
  }

  static String? _optional(String name) {
    const values = {
      'FIREBASE_AUTH_DOMAIN': String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
      'FIREBASE_STORAGE_BUCKET': String.fromEnvironment(
        'FIREBASE_STORAGE_BUCKET',
      ),
      'FIREBASE_MEASUREMENT_ID': String.fromEnvironment(
        'FIREBASE_MEASUREMENT_ID',
      ),
      'FIREBASE_IOS_BUNDLE_ID': String.fromEnvironment(
        'FIREBASE_IOS_BUNDLE_ID',
      ),
    };

    final value = values[name] ?? '';
    return value.isEmpty ? null : value;
  }
}
