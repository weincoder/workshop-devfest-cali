import 'package:flutter/material.dart';

/// Sentimientos posibles detectados por Gemini para una entrada del diario
enum Sentiment {
  veryPositive,
  positive,
  neutral,
  negative,
  veryNegative,
  mixed;

  String get emoji {
    switch (this) {
      case Sentiment.veryPositive:
        return '😄';
      case Sentiment.positive:
        return '😊';
      case Sentiment.neutral:
        return '😐';
      case Sentiment.negative:
        return '😔';
      case Sentiment.veryNegative:
        return '😢';
      case Sentiment.mixed:
        return '🤔';
    }
  }

  Color get color {
    switch (this) {
      case Sentiment.veryPositive:
        return const Color(0xFF10B981);
      case Sentiment.positive:
        return const Color(0xFF34D399);
      case Sentiment.neutral:
        return const Color(0xFF6B7280);
      case Sentiment.negative:
        return const Color(0xFFF59E0B);
      case Sentiment.veryNegative:
        return const Color(0xFFEF4444);
      case Sentiment.mixed:
        return const Color(0xFF8B5CF6);
    }
  }

  String get label {
    switch (this) {
      case Sentiment.veryPositive:
        return 'Muy Positivo';
      case Sentiment.positive:
        return 'Positivo';
      case Sentiment.neutral:
        return 'Neutral';
      case Sentiment.negative:
        return 'Negativo';
      case Sentiment.veryNegative:
        return 'Muy Negativo';
      case Sentiment.mixed:
        return 'Mixto';
    }
  }
}

/// Modelo de datos 100% compatible con Flutter Web, Mobile y Desktop
class DiaryEntry {
  final String id;
  final DateTime createdAt;
  final String title;
  final String content;
  final Sentiment sentiment;
  final List<String> tags;
  final String? aiSummary;
  final String? imageBase64;

  const DiaryEntry({
    required this.id,
    required this.createdAt,
    required this.title,
    required this.content,
    this.sentiment = Sentiment.neutral,
    this.tags = const [],
    this.aiSummary,
    this.imageBase64,
  });

  bool get hasImage => imageBase64 != null && imageBase64!.isNotEmpty;

  String get contentPreview {
    final lines = content.split('\n');
    if (lines.length <= 3) return content;
    return '${lines.take(3).join('\n')}...';
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays == 0) {
      return 'Hoy ${_formatTime(createdAt)}';
    } else if (difference.inDays == 1) {
      return 'Ayer ${_formatTime(createdAt)}';
    } else if (difference.inDays < 7) {
      return '${_getWeekday(createdAt)} ${_formatTime(createdAt)}';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _getWeekday(DateTime date) {
    const weekdays = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo',
    ];
    return weekdays[date.weekday - 1];
  }

  DiaryEntry copyWith({
    String? id,
    DateTime? createdAt,
    String? title,
    String? content,
    Sentiment? sentiment,
    List<String>? tags,
    String? aiSummary,
    String? imageBase64,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      title: title ?? this.title,
      content: content ?? this.content,
      sentiment: sentiment ?? this.sentiment,
      tags: tags ?? this.tags,
      aiSummary: aiSummary ?? this.aiSummary,
      imageBase64: imageBase64 ?? this.imageBase64,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAt': createdAt.toIso8601String(),
      'title': title,
      'content': content,
      'sentiment': sentiment.name,
      'tags': tags,
      'aiSummary': aiSummary,
      'imageBase64': imageBase64,
    };
  }

  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    return DiaryEntry(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      title: (json['title'] as String?) ?? '',
      content: (json['content'] as String?) ?? '',
      sentiment: Sentiment.values.firstWhere(
        (e) => e.name == json['sentiment'],
        orElse: () => Sentiment.neutral,
      ),
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      aiSummary: json['aiSummary'] as String?,
      imageBase64: json['imageBase64'] as String?,
    );
  }
}
