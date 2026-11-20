#!/usr/bin/env node
/**
 * Restaura firebase-config.json a los valores de plantilla (placeholders)
 * y vuelve a sincronizar Angular + Flutter Web.
 * Úsalo antes de hacer `git push` para no subir credenciales privadas.
 */

import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const configPath = path.join(__dirname, 'firebase-config.json');

const template = {
  useVertexAI: true,
  vertexAILocation: 'global',
  chatModel: 'gemini-3.8-flash',
  imageModel: 'gemini-3.1-flash-image',
  appCheck: {
    debugToken: 'PEGA_AQUI_TU_DEBUG_TOKEN_DE_APP_CHECK',
    recaptchaV3SiteKey: '',
  },
  firebase: {
    apiKey: 'PEGA_AQUI_TU_API_KEY',
    authDomain: 'PEGA_AQUI_TU_AUTH_DOMAIN',
    projectId: 'PEGA_AQUI_TU_PROJECT_ID',
    storageBucket: 'PEGA_AQUI_TU_STORAGE_BUCKET',
    messagingSenderId: 'PEGA_AQUI_TU_MESSAGING_SENDER_ID',
    appId: 'PEGA_AQUI_TU_APP_ID',
    measurementId: '',
  },
};

fs.writeFileSync(configPath, `${JSON.stringify(template, null, 2)}\n`, 'utf8');
console.log('🧹 firebase-config.json restaurado a plantilla segura.\n');

execFileSync(process.execPath, [path.join(__dirname, 'setup-firebase.mjs')], {
  stdio: 'inherit',
});
