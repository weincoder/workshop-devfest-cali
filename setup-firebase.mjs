#!/usr/bin/env node
/**
 * Sincroniza la configuración de Firebase + App Check desde `firebase-config.json`
 * hacia los proyectos de Angular y Flutter Web.
 *
 * Uso:
 *   node setup-firebase.mjs
 */

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const configPath = path.join(__dirname, 'firebase-config.json');

if (!fs.existsSync(configPath)) {
  console.error('❌ No se encontró firebase-config.json en la raíz del repositorio.');
  process.exit(1);
}

let rawConfig;
try {
  rawConfig = JSON.parse(fs.readFileSync(configPath, 'utf8'));
} catch (err) {
  console.error('❌ Error al leer firebase-config.json (verifica que sea JSON válido):', err.message);
  process.exit(1);
}

const fb = rawConfig.firebase ?? {};
const appCheck = rawConfig.appCheck ?? {};
const useVertexAI = rawConfig.useVertexAI ?? true;
const vertexAILocation = rawConfig.vertexAILocation ?? 'global';
const chatModel = rawConfig.chatModel ?? 'gemini-2.5-flash';
const imageModel = rawConfig.imageModel ?? 'gemini-2.5-flash-image';

const rawDebugToken = String(appCheck.debugToken ?? '').trim();
const debugToken =
  rawDebugToken.startsWith('PEGA_AQUI_') || rawDebugToken.startsWith('YOUR_')
    ? ''
    : rawDebugToken;
const recaptchaV3SiteKey = String(appCheck.recaptchaV3SiteKey ?? '').trim();

const requiredKeys = ['apiKey', 'authDomain', 'projectId', 'storageBucket', 'messagingSenderId', 'appId'];
const missingOrPlaceholder = requiredKeys.filter((key) => {
  const val = String(fb[key] ?? '').trim();
  return !val || val.startsWith('PEGA_AQUI_') || val.startsWith('YOUR_');
});

const isConfigured = missingOrPlaceholder.length === 0;

// 1. Generar archivo para Angular
const angularEnvPath = path.join(__dirname, 'angular', 'memoria', 'src', 'environments', 'environment.ts');
fs.mkdirSync(path.dirname(angularEnvPath), { recursive: true });

const angularEnvContent = `// Archivo generado automáticamente por setup-firebase.mjs
// Edita firebase-config.json en la raíz y vuelve a ejecutar: node setup-firebase.mjs

export const environment = {
  production: false,
  isFirebaseConfigured: ${isConfigured},
  useVertexAI: ${useVertexAI},
  vertexAILocation: ${JSON.stringify(vertexAILocation)},
  chatModel: ${JSON.stringify(chatModel)},
  appCheck: {
    debugToken: ${JSON.stringify(debugToken)},
    recaptchaV3SiteKey: ${JSON.stringify(recaptchaV3SiteKey)},
  },
  firebase: {
    apiKey: ${JSON.stringify(fb.apiKey ?? '')},
    authDomain: ${JSON.stringify(fb.authDomain ?? '')},
    projectId: ${JSON.stringify(fb.projectId ?? '')},
    storageBucket: ${JSON.stringify(fb.storageBucket ?? '')},
    messagingSenderId: ${JSON.stringify(fb.messagingSenderId ?? '')},
    appId: ${JSON.stringify(fb.appId ?? '')},${fb.measurementId ? `\n    measurementId: ${JSON.stringify(fb.measurementId)},` : ''}
  },
};
`;

fs.writeFileSync(angularEnvPath, angularEnvContent, 'utf8');

// 2. Generar archivo para Flutter (Web + soporte multiplataforma)
const flutterOptionsPath = path.join(
  __dirname,
  'mobile',
  'app',
  'lib',
  'config',
  'firebase',
  'firebase_options.dart',
);
fs.mkdirSync(path.dirname(flutterOptionsPath), { recursive: true });

const dartString = (value) => JSON.stringify(String(value ?? '')).replace(/\$/g, '\\$');

const flutterOptionsContent = `// Archivo generado automáticamente por setup-firebase.mjs
// Edita firebase-config.json en la raíz y vuelve a ejecutar: node setup-firebase.mjs
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class WorkshopAIConfig {
  WorkshopAIConfig._();

  static const bool isFirebaseConfigured = ${isConfigured};
  static const bool useVertexAI = ${useVertexAI};
  static const String vertexAILocation = ${dartString(vertexAILocation)};
  static const String chatModel = ${dartString(chatModel)};
  static const String imageModel = ${dartString(imageModel)};
  static const String appCheckDebugToken = ${dartString(debugToken)};
  static const String appCheckRecaptchaSiteKey = ${dartString(recaptchaV3SiteKey)};
}

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // En el workshop usamos la misma configuración base para pruebas rápidas.
    // Para builds nativos en producción, ejecuta \`flutterfire configure\`.
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
    apiKey: ${dartString(fb.apiKey ?? '')},
    appId: ${dartString(fb.appId ?? '')},
    messagingSenderId: ${dartString(fb.messagingSenderId ?? '')},
    projectId: ${dartString(fb.projectId ?? '')},
    authDomain: ${dartString(fb.authDomain ?? '')},
    storageBucket: ${dartString(fb.storageBucket ?? '')},${fb.measurementId ? `\n    measurementId: ${dartString(fb.measurementId)},` : ''}
  );
}
`;

fs.writeFileSync(flutterOptionsPath, flutterOptionsContent, 'utf8');

// 3. Generar script de App Check Debug Token para Flutter Web (se carga en web/index.html)
const flutterWebAppCheckPath = path.join(
  __dirname,
  'mobile',
  'app',
  'web',
  'firebase-appcheck-config.js',
);

let appCheckJsLine;
if (debugToken) {
  appCheckJsLine = `self.FIREBASE_APPCHECK_DEBUG_TOKEN = ${JSON.stringify(debugToken)};`;
} else if (!recaptchaV3SiteKey) {
  appCheckJsLine = 'self.FIREBASE_APPCHECK_DEBUG_TOKEN = true;';
} else {
  appCheckJsLine = '// Usando reCAPTCHA v3 en modo producción (sin debug token).';
}

const flutterWebAppCheckContent = `// Archivo generado automáticamente por setup-firebase.mjs
// Configura el Debug Token de Firebase App Check antes de inicializar Flutter Web.
${appCheckJsLine}
`;

fs.writeFileSync(flutterWebAppCheckPath, flutterWebAppCheckContent, 'utf8');

console.log('✅ Archivos sincronizados:');
console.log('   • angular/memoria/src/environments/environment.ts');
console.log('   • mobile/app/lib/config/firebase/firebase_options.dart');
console.log('   • mobile/app/web/firebase-appcheck-config.js');
console.log('');
console.log(`🔧 Backend IA: ${useVertexAI ? `Vertex AI (${vertexAILocation})` : 'Gemini Developer API (Spark / Google AI)'}`);
console.log(`🤖 Modelo Chat: ${chatModel}`);
if (debugToken) {
  console.log('🛡️  App Check: Debug Token fijo configurado');
} else if (recaptchaV3SiteKey) {
  console.log('🛡️  App Check: reCAPTCHA v3 configurado');
} else {
  console.log('🛡️  App Check: Modo Debug automático (copia el token de la consola del navegador y regístralo en Firebase Console → App Check → Apps → Manage debug tokens)');
}
console.log('');

if (isConfigured) {
  console.log('🚀 ¡Listo! Tus credenciales de Firebase están configuradas.');
  console.log('   Angular:     npm run angular');
  console.log('   Flutter Web: npm run flutter');
} else {
  console.log('⚠️  Aún hay valores pendientes en firebase-config.json:');
  console.log(`   Faltan: ${missingOrPlaceholder.join(', ')}`);
  console.log('   Pega tus IDs de Firebase Console en firebase-config.json y vuelve a ejecutar:');
  console.log('   npm run setup');
}
