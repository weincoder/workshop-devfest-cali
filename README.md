# 🚀 Workshop DevFest Cali: Apps Agénticas con Angular, Flutter Web y Firebase AI

Bienvenido al repositorio base del workshop. Aquí tienes **dos aplicaciones completas listas para correr** usando **Gemini + Function Calling** con Firebase AI Logic:

| Carpeta | Stack | Aplicación | Herramientas (Tools) incluidas |
| :--- | :--- | :--- | :--- |
| `angular/memoria` | **Angular 22 + Tailwind v4 + Firebase AI** | 🧠 **AI Memory Trainer (MemoPalabras)** | `saveGeneratedWords`, `changeMenuColor` |
| `mobile/app` | **Flutter Web + Material 3 + Firebase AI** | 📔 **AI Diary (Web-Ready)** | `createDiaryEntry`, `changeThemeColor`, `getDiarySummary`, `deleteLastEntry` + Análisis de sentimiento/tags e ilustraciones |

> 💡 **Cero configuraciones duplicadas:** Solo editas **`firebase-config.json`** una vez en la raíz y ejecutas `npm run setup` para sincronizar **Angular + Flutter Web + App Check**.

---

## 📋 Paso a Paso desde Ceros (10 minutos)

### Paso 1: Abre el proyecto en GitHub Codespaces (Recomendado)
No necesitas instalar Flutter, Dart, Node ni Angular en tu computador:

1. Haz clic en el botón verde **`<> Code`** → pestaña **`Codespaces`** → **`Create codespace on main`**.
2. Espera ~2 minutos mientras Codespaces construye el entorno e instala dependencias automáticamente.

<details>
<summary>💻 ¿Prefieres trabajar en tu computador local?</summary>

Asegúrate de tener **Node.js `>= 22`** y **Flutter SDK `>= 3.24`** con Web habilitado (`flutter config --enable-web`), luego ejecuta:
```bash
cd angular/memoria && npm install
cd ../../mobile/app && flutter pub get
```
</details>

---

### Paso 2: Crea tu proyecto de Firebase desde ceros
1. Entra a [Firebase Console](https://console.firebase.google.com/) con tu cuenta de Google.
2. Haz clic en **Crear un proyecto de Firebase** (ej. `devfest-cali-ai`).
   - Puedes **desactivar Google Analytics** para agilizar la creación.
3. **Crea UNA app Web** (esta misma app sirve para Angular y Flutter Web):
   - En la pantalla principal del proyecto, haz clic en el ícono Web **`</>`**.
   - Ponle un nombre (ej. `workshop-web`) → **Registrar app**.
   - **Copia el objeto `firebaseConfig`** (`apiKey`, `authDomain`, `projectId`, `storageBucket`, `messagingSenderId`, `appId`).

---

### Paso 3: Habilita Firebase AI Logic (Gemini)
1. En el menú izquierdo de Firebase Console ve a **Build → AI Logic** y haz clic en **Get started**.
2. Elige el proveedor según tu cuenta:
   - **Opción A — Vertex AI (Plan Blaze / créditos GCP):** Selecciona **Vertex AI Gemini API** y activa las APIs sugeridas. Deja `"useVertexAI": true` en `firebase-config.json`.
   - **Opción B — Plan Gratuito Spark (sin tarjeta de crédito):** Selecciona **Gemini Developer API** y actívala. Luego pon `"useVertexAI": false` en `firebase-config.json`.

---

### Paso 4: Crea tu Debug Token de App Check (⚠️ Obligatorio)
Desde noviembre de 2026, Firebase AI Logic exige **App Check** activo. Para desarrollo en Codespaces / local **no necesitas configurar reCAPTCHA**, solo un **Debug Token**:

1. En Firebase Console ve a **Build → App Check** (si es tu primera vez, haz clic en **Get started**).
2. Ve a la pestaña **`Apps`**.
3. Busca tu app **`workshop-web`**, haz clic en los tres puntos **`⋮`** → **Manage debug tokens (Administrar tokens de depuración)**.
4. Haz clic en **Add debug token** → presiona **Generate token** (nombre: `workshop`) → **Save**.
5. **Copia el UUID generado** (ejemplo: `12345678-1234-1234-1234-1234567890AB`).

---

### Paso 5: Pega tus IDs y sincroniza ambas apps
1. Abre **[firebase-config.json](firebase-config.json)** en la raíz del proyecto y pega tu `debugToken` y tu `firebaseConfig`:

```json
{
  "useVertexAI": true,
  "vertexAILocation": "global",
  "chatModel": "gemini-3.8-flash",
  "imageModel": "gemini-3.1-flash-image",
  "appCheck": {
    "debugToken": "PEGA_AQUI_TU_DEBUG_TOKEN_DE_APP_CHECK",
    "recaptchaV3SiteKey": ""
  },
  "firebase": {
    "apiKey": "TU_API_KEY",
    "authDomain": "tu-proyecto.firebaseapp.com",
    "projectId": "tu-proyecto",
    "storageBucket": "tu-proyecto.firebasestorage.app",
    "messagingSenderId": "1234567890",
    "appId": "1:1234567890:web:abcdef123456",
    "measurementId": ""
  }
}
```

2. En la terminal ejecuta:
```bash
npm run setup
```

Deberías ver:
- `✅ Archivos sincronizados`
- `🛡️ App Check: Debug Token fijo configurado`
- `🚀 ¡Listo! Tus credenciales de Firebase están configuradas.`

---

### Paso 6: Ejecuta Angular y Flutter Web

#### 🧠 App 1: Angular — AI Memory Trainer (Puerto `4200`)
```bash
# En GitHub Codespaces:
npm run angular

# En tu computador local:
npm run angular:local
```
Abre el puerto **4200** y prueba escribir:
- *"Dame 6 palabras de objetos cotidianos para memorizar"*
- *"Cambia el fondo a azul"*
- *"Pon el tema en morado"*

#### 📔 App 2: Flutter Web — AI Diary (Puerto `8080`)
Abre una **segunda terminal** y ejecuta:
```bash
# En GitHub Codespaces:
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0

# En tu computador local (Chrome):
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
```
Abre el puerto **8080** y prueba en el panel del **Asistente Agéntico**:
- *"Cambia el color a morado"*
- *"Agrega una entrada: hoy en DevFest Cali construí mi primer agente con Flutter"*
- *"Resume mi diario"*
- *"Elimina la última entrada"*

---

## 🛠️ Paso 7: Reto Práctico — Agrega tus propias Tools

Una vez que ambas apps te respondan con Gemini, sigue la guía práctica para crear nuevas herramientas (Function Calling) en 3 pasos:

👉 **[Abrir Guía de Nuevas Tools (`GUIA_NUEVAS_TOOLS.md`)](GUIA_NUEVAS_TOOLS.md)**

---

## 🛟 Solución Rápida de Problemas

| Error / Síntoma | Causa | Solución |
| :--- | :--- | :--- |
| `AppCheck: Fetch server returned HTTP status: 403` | El `debugToken` en `firebase-config.json` no coincide con el registrado en Firebase Console, o faltó correr `npm run setup`. | Verifica el UUID en Firebase Console → App Check → Apps → `⋮` → Manage debug tokens, corre `npm run setup`, reinicia `flutter run` y recarga con `Ctrl/Cmd + Shift + R`. |
| `Firebase App Check token is invalid` | App Check no está enviando un token válido. | Asegúrate de haber completado el **Paso 4** y reiniciado la app tras `npm run setup`. |
| Error de facturación / Billing al usar Vertex AI | El proyecto está en plan gratuito Spark. | En `firebase-config.json` cambia `"useVertexAI": false`, habilita **Gemini Developer API** en Firebase → AI Logic, corre `npm run setup` y reinicia. |
| Sale el banner amarillo *"Firebase aún no está configurado"* | Queda algún campo con `PEGA_AQUI_...` o no corriste `npm run setup`. | Completa todos los campos de `firebase-config.json` y ejecuta `npm run setup`. |

---

## 📂 Estructura del Repositorio

```text
workshop-devfest-cali/
├── firebase-config.json          # 👈 ÚNICO archivo donde pegas tus IDs + Debug Token
├── setup-firebase.mjs            # Sincroniza Angular + Flutter Web + App Check
├── reset-firebase.mjs            # Restaura firebase-config.json a plantilla (`npm run reset-config`)
├── package.json                  # Comandos rápidos (npm run setup / angular / flutter)
├── GUIA_NUEVAS_TOOLS.md          # Retos guiados para agregar nuevas Tools
├── .devcontainer/
│   └── devcontainer.json         # Entorno automático para GitHub Codespaces
├── angular/memoria/              # App 1: AI Memory Trainer (Angular 22 + Firebase AI)
└── mobile/app/                   # App 2: AI Diary (Flutter Web + Firebase AI)
```
