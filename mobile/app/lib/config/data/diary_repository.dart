import 'dart:convert';
import 'package:app/config/models/diary_entry.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Repositorio Web-ready respaldado por SharedPreferences (localStorage en Web).
/// Evita sqflite y dart:io para que compile y corra sin configuración extra en Flutter Web.
class DiaryRepository {
  static final DiaryRepository _instance = DiaryRepository._internal();
  factory DiaryRepository() => _instance;
  DiaryRepository._internal();

  static const String _storageKey = 'devfest_cali_diary_entries_v1';

  List<DiaryEntry> _cache = [];
  bool _initialized = false;

  Future<List<DiaryEntry>> getEntries() async {
    if (_initialized) {
      return List.unmodifiable(_cache);
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);

      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
        _cache = decoded
            .map((item) => DiaryEntry.fromJson(item as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      } else {
        _cache = _seedExampleEntries();
        await _persist();
      }
    } catch (e) {
      debugPrint('Error cargando entradas desde almacenamiento local: $e');
      _cache = _seedExampleEntries();
    }

    _initialized = true;
    return List.unmodifiable(_cache);
  }

  Future<void> saveEntry(DiaryEntry entry) async {
    await getEntries();
    final index = _cache.indexWhere((item) => item.id == entry.id);
    if (index >= 0) {
      _cache[index] = entry;
    } else {
      _cache.insert(0, entry);
    }
    _cache.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _persist();
  }

  Future<void> deleteEntry(String id) async {
    await getEntries();
    _cache.removeWhere((item) => item.id == id);
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_cache.map((e) => e.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (e) {
      // Si el almacenamiento Web (localStorage) se queda sin cuota por imágenes grandes,
      // guardamos una copia sin imágenes base64 para no perder el texto.
      debugPrint('Aviso al persistir (reintentando sin imágenes): $e');
      try {
        final prefs = await SharedPreferences.getInstance();
        final lightweight = _cache
            .map((e) => e.copyWith(imageBase64: '').toJson())
            .toList();
        await prefs.setString(_storageKey, jsonEncode(lightweight));
      } catch (inner) {
        debugPrint('Error en fallback de persistencia: $inner');
      }
    }
  }

  List<DiaryEntry> _seedExampleEntries() {
    final now = DateTime.now();
    return [
      DiaryEntry(
        id: 'seed-1',
        createdAt: now.subtract(const Duration(hours: 2)),
        title: 'Arrancando el DevFest Cali',
        content:
            'Hoy empezamos el workshop de aplicaciones agénticas con Flutter Web, Angular y Firebase Vertex AI. '
            'Me emociona aprender cómo Gemini puede controlar mi app usando Function Calling.',
        sentiment: Sentiment.veryPositive,
        tags: ['devfest', 'ia', 'flutter'],
      ),
      DiaryEntry(
        id: 'seed-2',
        createdAt: now.subtract(const Duration(days: 1)),
        title: 'Momento de reflexión',
        content:
            'A veces necesito tomarme una pausa para pensar en lo que aprendí durante la semana. '
            'No todo salió perfecto, pero cada reto me dejó una lección valiosa.',
        sentiment: Sentiment.neutral,
        tags: ['reflexión', 'aprendizaje'],
      ),
      DiaryEntry(
        id: 'seed-3',
        createdAt: now.subtract(const Duration(days: 2)),
        title: 'Café y código',
        content:
            'Estuve experimentando con nuevas ideas de arquitectura para apps con inteligencia artificial. '
            '¡Un buen café siempre ayuda a destrabar el código!',
        sentiment: Sentiment.positive,
        tags: ['código', 'café', 'arquitectura'],
      ),
    ];
  }
}
