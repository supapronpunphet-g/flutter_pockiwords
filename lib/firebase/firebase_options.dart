// PLACEHOLDER — replace by running `flutterfire configure` from the project root.
//
// That command will overwrite this file with real options for your Firebase
// project across all platforms. Until then, FirebaseOptions.currentPlatform
// throws so you notice early.
//
// Steps:
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// (You must have created a Firebase project at https://console.firebase.google.com first.)

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    throw UnsupportedError(
      'firebase_options.dart is a placeholder. '
      'Run `flutterfire configure` to generate real options for '
      '${defaultTargetPlatform.name}.',
    );
  }
}
