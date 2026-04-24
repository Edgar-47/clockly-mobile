import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/constants/api_constants.dart';

// ---------------------------------------------------------------------------
// CRASHLYTICS INTEGRATION — STEPS TO ENABLE:
//
// 1. Create a Firebase project at https://console.firebase.google.com
// 2. Add an Android app (package: com.clockly.mobile) and an iOS app
// 3. Download google-services.json → android/app/  (already in .gitignore)
//    Download GoogleService-Info.plist → ios/Runner/  (already in .gitignore)
// 4. Add to pubspec.yaml:
//      firebase_core: ^3.0.0
//      firebase_crashlytics: ^4.0.0
// 5. Run: flutterfire configure
// 6. In android/app/build.gradle.kts add:
//      id("com.google.gms.google-services")
//      id("com.google.firebase.crashlytics")
// 7. Uncomment the Firebase/Crashlytics code below and remove the stub.
// ---------------------------------------------------------------------------

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: uncomment after Firebase is configured
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  // Capture Flutter framework errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    // TODO: FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    if (kDebugMode) {
      FlutterError.dumpErrorToConsole(details);
    }
  };

  // Capture async errors not caught by Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    // TODO: FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    if (kDebugMode) {
      debugPrint('[PlatformDispatcher] Uncaught error: $error\n$stack');
    }
    return true;
  };

  ApiConstants.validateBaseUrl();
  await initializeDateFormatting('es', null);

  runApp(const ProviderScope(child: ClocklyApp()));
}
