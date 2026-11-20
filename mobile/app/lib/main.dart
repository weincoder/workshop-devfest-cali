import 'package:app/config/app/app.dart';
import 'package:app/config/firebase/firebase_options.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (WorkshopAIConfig.isFirebaseConfigured) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Firebase App Check (obligatorio para Firebase AI Logic desde Nov 2026).
      // En Flutter Web, `web/firebase-appcheck-config.js` configura automáticamente
      // `self.FIREBASE_APPCHECK_DEBUG_TOKEN` a partir de `firebase-config.json`.
      final siteKey = WorkshopAIConfig.appCheckRecaptchaSiteKey.isNotEmpty
          ? WorkshopAIConfig.appCheckRecaptchaSiteKey
          : 'workshop-debug-placeholder-key';

      await FirebaseAppCheck.instance.activate(
        providerWeb: ReCaptchaV3Provider(siteKey),
        providerAndroid: const AndroidDebugProvider(),
        providerApple: const AppleDebugProvider(),
      );
    } catch (e) {
      debugPrint('Error inicializando Firebase / App Check: $e');
    }
  } else {
    debugPrint(
      '⚠️ Firebase no configurado aún. Edita firebase-config.json y ejecuta: npm run setup',
    );
  }

  runApp(const App());
}
