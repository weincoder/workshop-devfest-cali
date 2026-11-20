# 🛠️ Guía Paso a Paso: Cómo Agregar Nuevas Tools (Function Calling)

En una app agéntica, **Gemini no solo responde texto**: puede decidir **qué funciones de tu aplicación ejecutar** y con qué argumentos.

```text
Usuario ("Pon el temporizador en 15 segundos")
   │
   ▼
Gemini analiza el prompt + tus FunctionDeclarations
   │
   ▼
Gemini responde: "Llama a setMemorizationTimer({ seconds: 15 })"
   │
   ▼
Tu App (Angular / Flutter) ejecuta el código real y actualiza la UI
   │
   ▼
Tu App devuelve el resultado JSON a Gemini → Gemini confirma al usuario
```

Agregar una nueva herramienta siempre sigue exactamente **3 pasos**:
1. **Declarar la tool** (nombre, descripción clara y esquema de parámetros).
2. **Conectar el `case`** en el dispatcher (`switch`).
3. **Implementar el handler** que modifica el estado/UI y retorna el resultado a Gemini.

---

## 🅰️ Parte 1: Agregar una Tool en Angular (`AI Memory Trainer`)

Archivo a editar: **`angular/memoria/src/app/services/ai.service.ts`**

### 🎯 Reto 1 (Guiado): `setMemorizationTimer`
Permitirle al usuario decir: *"Dame solo 15 segundos para memorizar"* o *"Pon el tiempo en 90 segundos"*.

> 💡 `WordsService` **ya tiene listo** el método `setMemorizationDuration(seconds)` para este reto.

#### Paso 1: Declara la herramienta en `appTools.functionDeclarations`
Busca el comentario `// 🔧 PASO 1 (TOOLS)` en `ai.service.ts` y agrega este objeto al arreglo `functionDeclarations`:

```ts
{
  name: 'setMemorizationTimer',
  description:
    'Cambia la duración en segundos del temporizador de memorización (entre 5 y 180 segundos).',
  parameters: Schema.object({
    properties: {
      seconds: Schema.integer({
        description: 'Cantidad de segundos que el usuario tendrá para memorizar las palabras.',
      }),
    },
  }),
},
```

#### Paso 2: Registra el `case` en `handleFunctionCall`
Busca `// 🔧 PASO 2 (DISPATCHER)` y agrega:

```ts
case 'setMemorizationTimer':
  return this.handleSetMemorizationTimer(functionCall.args as { seconds?: number });
```

#### Paso 3: Implementa el handler
Busca `// 🔧 PASO 3 (HANDLERS)` y agrega:

```ts
private handleSetMemorizationTimer(args: { seconds?: number }): Record<string, unknown> {
  const seconds = Number(args.seconds);
  if (!Number.isFinite(seconds) || seconds < 5 || seconds > 180) {
    return {
      status: 'error',
      message: 'Indica un tiempo válido entre 5 y 180 segundos.',
    };
  }

  this.wordsService.setMemorizationDuration(seconds);
  return {
    status: 'success',
    newDurationSeconds: this.wordsService.memorizationDuration(),
  };
}
```

#### ✅ Pruébalo
En el chat de Angular escribe:
> *"Pon el temporizador en 15 segundos y dame 5 palabras de cocina"*

Verás cómo Gemini ejecuta **dos tools en cadena** (`setMemorizationTimer` + `saveGeneratedWords`) y el modal arranca en **15 segundos** ⚡.

---

### 💡 Ideas de Tools Extra para Angular
- **`getCurrentConfig`**: Devuelve el color actual (`menuColorService.colorName()`) y el tiempo del temporizador (`wordsService.memorizationDuration()`) para que Gemini responda preguntas como *"¿Cómo está configurada mi práctica?"*.
- **`addCustomWord`**: Permite que el usuario diga *"Agrega la palabra CALI a mi práctica actual"*.
- **`createMnemonicTip`**: Una tool que guarde un consejo mnemotécnico en un signal visible en pantalla antes de empezar.

---

## 💙 Parte 2: Agregar una Tool en Flutter Web (`AI Diary`)

Archivo a editar: **`mobile/app/lib/config/ia/diary_agent.dart`**

### 🎯 Reto 1 (Guiado): `filterBySentiment`
Permitirle al usuario decir: *"Muéstrame solo mis entradas felices"* o *"Quita el filtro de sentimientos"*.

> 💡 `AppState` **ya tiene listo** el método `setSentimentFilter(Sentiment?)` para este reto.

#### Paso 1: Declara la herramienta en `Tool.functionDeclarations`
Busca el comentario `// 🔧 PASO 1 (TOOLS)` en `diary_agent.dart` y agrega:

```dart
FunctionDeclaration(
  'filterBySentiment',
  'Filtra las entradas visibles del diario por sentimiento emocional o limpia el filtro.',
  parameters: {
    'sentiment': Schema.string(
      description:
          'Sentimiento a filtrar: veryPositive, positive, neutral, negative, veryNegative, mixed, o "all" para mostrar todas.',
    ),
  },
),
```

#### Paso 2: Registra el `case` en `_dispatchToolCall`
Busca `// 🔧 PASO 2 (DISPATCHER)` y agrega:

```dart
case 'filterBySentiment':
  return _handleFilterBySentiment(call.args, appState);
```

#### Paso 3: Implementa el handler
Busca `// 🔧 PASO 3 (HANDLERS)` y agrega:

```dart
Map<String, Object?> _handleFilterBySentiment(
  Map<String, Object?> args,
  AppState appState,
) {
  final raw = (args['sentiment']?.toString() ?? 'all').trim();

  if (raw == 'all' || raw.isEmpty) {
    appState.setSentimentFilter(null);
    return {
      'status': 'success',
      'filter': 'all',
      'visibleCount': appState.filteredEntries.length,
    };
  }

  final match = Sentiment.values.where(
    (s) => s.name.toLowerCase() == raw.toLowerCase(),
  );

  if (match.isEmpty) {
    return {
      'status': 'error',
      'message': 'Sentimiento no válido: $raw',
    };
  }

  appState.setSentimentFilter(match.first);
  return {
    'status': 'success',
    'filter': match.first.label,
    'visibleCount': appState.filteredEntries.length,
  };
}
```

#### ✅ Pruébalo
En el **Asistente Agéntico** de Flutter Web escribe:
> *"Muéstrame solo mis entradas muy positivas"*

Y luego:
> *"Muestra todas las entradas de nuevo"*

---

### 🎯 Reto 2 (Accesibilidad en 3 minutos): `changeFontSize`
`AppState` también tiene listo `setFontSizeFactor(double)` (entre `0.85` y `1.35`).

1. **Tool**: `FunctionDeclaration('changeFontSize', 'Ajusta el tamaño de letra de la aplicación', parameters: {'scale': Schema.number(description: 'Factor entre 0.85 y 1.35, por ejemplo 1.2 para letra grande')})`
2. **Dispatcher**: `case 'changeFontSize': return _handleChangeFontSize(call.args, appState);`
3. **Handler**:
```dart
Map<String, Object?> _handleChangeFontSize(
  Map<String, Object?> args,
  AppState appState,
) {
  final rawScale = args['scale'];
  final scale = rawScale is num ? rawScale.toDouble() : double.tryParse('$rawScale');
  if (scale == null) {
    return {'status': 'error', 'message': 'Escala inválida'};
  }
  appState.setFontSizeFactor(scale);
  return {'status': 'success', 'fontSizeFactor': appState.fontSizeFactor};
}
```
Pruébalo escribiendo: *"Haz la letra más grande, por favor"*.

---

### 💡 Reto 3 (Libre): `getEmotionalStats`
Crea una herramienta sin parámetros que recorra `appState.allEntries`, cuente cuántas entradas hay de cada `Sentiment`, y le devuelva ese mapa a Gemini para que el asistente pueda responder:
> *"¿Cómo ha estado mi estado de ánimo últimamente?"*

---

## 🧠 Buenas Prácticas al Diseñar Tools
1. **Descripciones claras > código complejo:** Gemini decide cuándo llamar una tool leyendo su `description` y la descripción de cada parámetro.
2. **Valida siempre en el handler:** Nunca asumas que los argumentos vienen perfectos; si algo falla, devuelve `{ status: 'error', message: '...' }` y Gemini sabrá cómo corregir o explicarlo al usuario.
3. **Acciones pequeñas y atómicas:** Es mejor tener 4 tools específicas (`changeThemeColor`, `filterBySentiment`, `createDiaryEntry`, `changeFontSize`) que una sola tool gigante. Gemini sabe encadenar varias en el mismo turno.
