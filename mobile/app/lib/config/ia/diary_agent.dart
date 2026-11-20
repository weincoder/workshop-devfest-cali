import 'dart:convert';
import 'package:app/config/firebase/firebase_options.dart';
import 'package:app/config/models/diary_entry.dart';
import 'package:app/config/state/app_state.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

class AssistantReply {
  final String text;
  final List<String> toolsCalled;

  const AssistantReply({
    required this.text,
    this.toolsCalled = const [],
  });
}

/// Agente de IA del diario con análisis de contenido + Function Calling (Tools)
/// 100% compatible con Flutter Web, Mobile y Desktop.
class DiaryAgent {
  static final DiaryAgent _instance = DiaryAgent._internal();
  factory DiaryAgent() => _instance;
  DiaryAgent._internal();

  GenerativeModel? _analysisModel;
  GenerativeModel? _assistantModel;
  ChatSession? _assistantChat;
  GenerativeModel? _imageModel;

  FirebaseAI _createFirebaseAI() {
    if (WorkshopAIConfig.useVertexAI) {
      return FirebaseAI.agentPlatform(
        location: WorkshopAIConfig.vertexAILocation,
      );
    }
    return FirebaseAI.googleAI();
  }

  GenerativeModel _getAnalysisModel() {
    _analysisModel ??= _createFirebaseAI().generativeModel(
      model: WorkshopAIConfig.chatModel,
    );
    return _analysisModel!;
  }

  GenerativeModel _getImageModel() {
    _imageModel ??= _createFirebaseAI().generativeModel(
      model: WorkshopAIConfig.imageModel,
      generationConfig: GenerationConfig(
        responseModalities: [ResponseModalities.text, ResponseModalities.image],
      ),
    );
    return _imageModel!;
  }

  ChatSession _getAssistantChat() {
    if (_assistantChat != null) return _assistantChat!;

    // 🔧 PASO 1 (TOOLS): Agrega aquí nuevas FunctionDeclaration para el workshop
    final tools = [
      Tool.functionDeclarations([
        FunctionDeclaration(
          'createDiaryEntry',
          'Crea y guarda una nueva entrada en el diario con análisis automático de sentimiento y etiquetas.',
          parameters: {
            'title': Schema.string(
              description: 'Título corto y descriptivo para la entrada (máximo 6 palabras).',
            ),
            'content': Schema.string(
              description: 'Texto principal que el usuario quiere guardar en su diario.',
            ),
          },
        ),
        FunctionDeclaration(
          'changeThemeColor',
          'Cambia el color del tema Material 3 de toda la aplicación.',
          parameters: {
            'color': Schema.string(
              description:
                  'Color deseado: azul, rojo, verde, morado, naranja, rosa, turquesa, indigo, ambar.',
            ),
          },
        ),
        FunctionDeclaration(
          'getDiarySummary',
          'Obtiene las entradas actuales del diario para generar un resumen o responder preguntas sobre ellas.',
          parameters: {
            'timeRange': Schema.string(
              description: 'Rango temporal: today, week, month o all.',
            ),
          },
        ),
        FunctionDeclaration(
          'deleteLastEntry',
          'Elimina la entrada más reciente del diario cuando el usuario lo solicita explícitamente.',
          parameters: {},
        ),
      ]),
    ];

    _assistantModel = _createFirebaseAI().generativeModel(
      model: WorkshopAIConfig.chatModel,
      systemInstruction: Content.system(
        'Eres el asistente agéntico de AI Diary (Workshop DevFest Cali). '
        'Respondes siempre en español, de forma cálida, breve y útil. '
        'Tienes herramientas reales para modificar la aplicación: '
        'usa createDiaryEntry cuando el usuario quiera anotar/guardar algo en su diario, '
        'changeThemeColor cuando pida cambiar colores/tema, '
        'getDiarySummary cuando pida resumir o consultar sus notas, '
        'y deleteLastEntry cuando pida borrar la última entrada.',
      ),
      tools: tools,
    );

    _assistantChat = _assistantModel!.startChat();
    return _assistantChat!;
  }

  /// Envía un mensaje al asistente y ejecuta automáticamente las herramientas que Gemini solicite.
  Future<AssistantReply> askAssistant(String prompt, AppState appState) async {
    if (!WorkshopAIConfig.isFirebaseConfigured) {
      return const AssistantReply(
        text:
            '⚠️ Firebase aún no está configurado. Pega tus IDs en firebase-config.json '
            'en la raíz del proyecto, ejecuta `node setup-firebase.mjs` y reinicia la app.',
      );
    }

    final toolsCalled = <String>[];

    try {
      final chat = _getAssistantChat();
      var response = await chat.sendMessage(Content.text(prompt));

      while (response.functionCalls.isNotEmpty) {
        final functionResponses = <FunctionResponse>[];

        for (final call in response.functionCalls) {
          toolsCalled.add(call.name);
          final result = await _dispatchToolCall(call, appState);
          functionResponses.add(FunctionResponse(call.name, result));
        }

        response = await chat.sendMessage(
          Content.functionResponses(functionResponses),
        );
      }

      final replyText = (response.text ?? '').trim();
      return AssistantReply(
        text: replyText.isNotEmpty
            ? replyText
            : '¡Listo! Acción ejecutada correctamente.',
        toolsCalled: toolsCalled,
      );
    } catch (e) {
      debugPrint('Error en DiaryAgent.askAssistant: $e');
      return AssistantReply(
        text:
            '❌ Error comunicándose con Firebase AI: $e\n\n'
            'Verifica tus credenciales en firebase-config.json y que el backend '
            '(${WorkshopAIConfig.useVertexAI ? "Vertex AI" : "Gemini Developer API"}) esté habilitado.',
        toolsCalled: toolsCalled,
      );
    }
  }

  // 🔧 PASO 2 (DISPATCHER): Agrega aquí el `case` de tu nueva tool
  Future<Map<String, Object?>> _dispatchToolCall(
    FunctionCall call,
    AppState appState,
  ) async {
    debugPrint('⚡ Function Call en Flutter: ${call.name} -> ${call.args}');

    switch (call.name) {
      case 'createDiaryEntry':
        return _handleCreateDiaryEntry(call.args, appState);
      case 'changeThemeColor':
        return _handleChangeThemeColor(call.args, appState);
      case 'getDiarySummary':
        return _handleGetDiarySummary(call.args, appState);
      case 'deleteLastEntry':
        return _handleDeleteLastEntry(appState);
      default:
        return {
          'status': 'error',
          'message': 'Herramienta no reconocida: ${call.name}',
        };
    }
  }

  // 🔧 PASO 3 (HANDLERS): Implementa aquí la lógica de cada tool
  Future<Map<String, Object?>> _handleCreateDiaryEntry(
    Map<String, Object?> args,
    AppState appState,
  ) async {
    final content = (args['content']?.toString() ?? '').trim();
    final title = (args['title']?.toString() ?? '').trim();

    if (content.isEmpty) {
      return {
        'status': 'error',
        'message': 'Falta el contenido de la entrada.',
      };
    }

    final entry = await createAnalyzedEntry(
      content: content,
      title: title.isNotEmpty ? title : 'Nota del asistente',
      analyzeWithAI: true,
      generateImage: false,
    );

    await appState.addEntry(entry);

    return {
      'status': 'success',
      'entryId': entry.id,
      'title': entry.title,
      'sentiment': entry.sentiment.label,
      'tags': entry.tags,
    };
  }

  Map<String, Object?> _handleChangeThemeColor(
    Map<String, Object?> args,
    AppState appState,
  ) {
    final color = (args['color']?.toString() ?? '').trim();
    final changed = appState.setAppColorByName(color);

    if (!changed) {
      return {
        'status': 'error',
        'message':
            'Color "$color" no válido. Opciones: azul, rojo, verde, morado, naranja, rosa, turquesa, indigo, ambar.',
      };
    }

    return {
      'status': 'success',
      'appliedColor': appState.colorName,
    };
  }

  Map<String, Object?> _handleGetDiarySummary(
    Map<String, Object?> args,
    AppState appState,
  ) {
    final timeRange = (args['timeRange']?.toString() ?? 'all').toLowerCase();
    final now = DateTime.now();

    final entries = appState.allEntries.where((entry) {
      final diff = now.difference(entry.createdAt);
      switch (timeRange) {
        case 'today':
          return diff.inHours < 24;
        case 'week':
          return diff.inDays < 7;
        case 'month':
          return diff.inDays < 30;
        default:
          return true;
      }
    }).toList();

    if (entries.isEmpty) {
      return {
        'status': 'empty',
        'count': 0,
        'message': 'No hay entradas registradas en ese rango temporal.',
      };
    }

    return {
      'status': 'success',
      'count': entries.length,
      'entries': entries
          .take(10)
          .map((e) => {
                'date': e.formattedDate,
                'title': e.title,
                'sentiment': e.sentiment.label,
                'tags': e.tags,
                'content': e.content,
              })
          .toList(),
    };
  }

  Future<Map<String, Object?>> _handleDeleteLastEntry(AppState appState) async {
    final deleted = await appState.deleteLastEntry();
    if (deleted == null) {
      return {
        'status': 'empty',
        'message': 'No hay entradas para eliminar.',
      };
    }

    return {
      'status': 'success',
      'deletedTitle': deleted.title.isNotEmpty ? deleted.title : deleted.id,
    };
  }

  // ==================== ANÁLISIS DE CONTENIDO E IMÁGENES ====================

  Future<DiaryEntry> createAnalyzedEntry({
    required String content,
    String? title,
    bool analyzeWithAI = true,
    bool generateImage = false,
  }) async {
    final entryId = DateTime.now().millisecondsSinceEpoch.toString();
    final cleanTitle = title?.trim() ?? '';
    final cleanContent = content.trim();

    if (!WorkshopAIConfig.isFirebaseConfigured || !analyzeWithAI) {
      return DiaryEntry(
        id: entryId,
        createdAt: DateTime.now(),
        title: cleanTitle,
        content: cleanContent,
      );
    }

    final results = await Future.wait<Object?>([
      analyzeSentiment(content: cleanContent, title: cleanTitle),
      generateTags(content: cleanContent, title: cleanTitle),
      createSummary(content: cleanContent, title: cleanTitle),
      if (generateImage)
        generateIllustrationBase64(content: cleanContent, title: cleanTitle)
      else
        Future<String?>.value(null),
    ]);

    return DiaryEntry(
      id: entryId,
      createdAt: DateTime.now(),
      title: cleanTitle,
      content: cleanContent,
      sentiment: (results[0] as Sentiment?) ?? Sentiment.neutral,
      tags: (results[1] as List<String>?) ?? const [],
      aiSummary: results[2] as String?,
      imageBase64: results[3] as String?,
    );
  }

  Future<Sentiment> analyzeSentiment({
    required String content,
    String? title,
  }) async {
    try {
      final prompt = '''
Analiza el sentimiento emocional de esta entrada de diario.
${title != null && title.isNotEmpty ? 'Título: $title\n' : ''}Contenido: $content

Responde SOLO con una de estas palabras exactas:
veryPositive, positive, neutral, negative, veryNegative, mixed
''';
      final response =
          await _getAnalysisModel().generateContent([Content.text(prompt)]);
      final text = (response.text ?? '').trim().toLowerCase();

      if (text.contains('verypositive') || text.contains('very positive')) {
        return Sentiment.veryPositive;
      }
      if (text.contains('verynegative') || text.contains('very negative')) {
        return Sentiment.veryNegative;
      }
      if (text.contains('positive')) return Sentiment.positive;
      if (text.contains('negative')) return Sentiment.negative;
      if (text.contains('mixed')) return Sentiment.mixed;
      return Sentiment.neutral;
    } catch (e) {
      debugPrint('Error en analyzeSentiment: $e');
      return Sentiment.neutral;
    }
  }

  Future<List<String>> generateTags({
    required String content,
    String? title,
  }) async {
    try {
      final prompt = '''
Genera entre 2 y 4 etiquetas cortas en español para esta entrada de diario.
${title != null && title.isNotEmpty ? 'Título: $title\n' : ''}Contenido: $content

Responde SOLO con los tags separados por comas, en minúsculas y sin # ni explicaciones.
Ejemplo: trabajo, aprendizaje, devfest
''';
      final response =
          await _getAnalysisModel().generateContent([Content.text(prompt)]);
      final text = (response.text ?? '').trim();
      return text
          .split(',')
          .map((tag) => tag.replaceAll('#', '').trim().toLowerCase())
          .where((tag) => tag.isNotEmpty && tag.length <= 24)
          .take(4)
          .toList();
    } catch (e) {
      debugPrint('Error en generateTags: $e');
      return const [];
    }
  }

  Future<String?> createSummary({
    required String content,
    String? title,
  }) async {
    if (content.length < 180) return null;

    try {
      final prompt = '''
Crea un resumen en 1 o 2 oraciones concisas de esta entrada de diario:
${title != null && title.isNotEmpty ? 'Título: $title\n' : ''}Contenido: $content

Responde SOLO con el resumen en español.
''';
      final response =
          await _getAnalysisModel().generateContent([Content.text(prompt)]);
      final summary = response.text?.trim();
      return (summary != null && summary.isNotEmpty) ? summary : null;
    } catch (e) {
      debugPrint('Error en createSummary: $e');
      return null;
    }
  }

  /// Genera una ilustración artística usando Gemini Image y devuelve base64 (Web-safe)
  Future<String?> generateIllustrationBase64({
    required String content,
    String? title,
  }) async {
    try {
      final snippet =
          content.length > 180 ? content.substring(0, 180) : content;
      final prompt =
          'Create a minimalist warm artistic illustration for a personal diary entry. '
          '${title != null && title.isNotEmpty ? "Title: $title. " : ""}'
          'Mood and context: $snippet. Clean editorial style, no text.';

      final response =
          await _getImageModel().generateContent([Content.text(prompt)]);

      for (final part in response.inlineDataParts) {
        if (part.mimeType.startsWith('image/')) {
          return base64Encode(part.bytes);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error generando ilustración con Gemini Image: $e');
      return null;
    }
  }
}
