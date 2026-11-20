// Archivo generado automáticamente por setup-firebase.mjs
// Edita firebase-config.json en la raíz y vuelve a ejecutar: node setup-firebase.mjs
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class WorkshopAIConfig {
  WorkshopAIConfig._();

  static const bool isFirebaseConfigured = false;
  static const bool useVertexAI = true;
  static const String vertexAILocation = "global";
  static const String chatModel = "gemini-2.5-flash";
  static const String imageModel = "gemini-2.5-flash-image";
  static const String appCheckDebugToken = "";
  static const String appCheckRecaptchaSiteKey = "";
}

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // En el workshop usamos la misma configuración base para pruebas rápidas.
    // Para builds nativos en producción, ejecuta `flutterfire configure`.
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return web;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no está soportado para esta plataforma.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "PEGA_AQUI_TU_API_KEY",
    appId: "PEGA_AQUI_TU_APP_ID",
    messagingSenderId: "PEGA_AQUI_TU_MESSAGING_SENDER_ID",
    projectId: "PEGA_AQUI_TU_PROJECT_ID",
    authDomain: "PEGA_AQUI_TU_AUTH_DOMAIN",
    storageBucket: "PEGA_AQUI_TU_STORAGE_BUCKET",
  );
}
