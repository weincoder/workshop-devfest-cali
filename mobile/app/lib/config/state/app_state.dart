import 'package:app/config/data/diary_repository.dart';
import 'package:app/config/models/diary_entry.dart';
import 'package:flutter/material.dart';

/// Estado global de la aplicación (Provider)
class AppState with ChangeNotifier {
  final DiaryRepository _repository = DiaryRepository();

  static const Map<String, Color> allowedColors = {
    'indigo': Colors.indigo,
    'azul': Colors.blue,
    'blue': Colors.blue,
    'rojo': Colors.red,
    'red': Colors.red,
    'verde': Colors.green,
    'green': Colors.green,
    'morado': Colors.purple,
    'purple': Colors.purple,
    'naranja': Colors.orange,
    'orange': Colors.orange,
    'rosa': Colors.pink,
    'rosado': Colors.pink,
    'pink': Colors.pink,
    'turquesa': Colors.teal,
    'teal': Colors.teal,
    'ambar': Colors.amber,
    'ámbar': Colors.amber,
    'amber': Colors.amber,
  };

  Color _seedColor = Colors.indigo;
  String _colorName = 'índigo';
  double _fontSizeFactor = 1.0;
  List<DiaryEntry> _entries = [];
  bool _isLoading = true;
  Sentiment? _sentimentFilter;
  String _searchQuery = '';

  Color get seedColor => _seedColor;
  String get colorName => _colorName;
  double get fontSizeFactor => _fontSizeFactor;
  bool get isLoading => _isLoading;
  Sentiment? get sentimentFilter => _sentimentFilter;
  String get searchQuery => _searchQuery;

  List<DiaryEntry> get allEntries => List.unmodifiable(_entries);

  List<DiaryEntry> get filteredEntries {
    return _entries.where((entry) {
      final matchesSentiment =
          _sentimentFilter == null || entry.sentiment == _sentimentFilter;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          entry.title.toLowerCase().contains(query) ||
          entry.content.toLowerCase().contains(query) ||
          entry.tags.any((tag) => tag.toLowerCase().contains(query));
      return matchesSentiment && matchesSearch;
    }).toList();
  }

  ThemeData get appTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _seedColor,
          brightness: Brightness.light,
        ),
      );

  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();
    _entries = await _repository.getEntries();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEntry(DiaryEntry entry) async {
    await _repository.saveEntry(entry);
    _entries = await _repository.getEntries();
    notifyListeners();
  }

  Future<void> deleteEntry(String id) async {
    await _repository.deleteEntry(id);
    _entries = await _repository.getEntries();
    notifyListeners();
  }

  Future<DiaryEntry?> deleteLastEntry() async {
    if (_entries.isEmpty) return null;
    final last = _entries.first;
    await deleteEntry(last.id);
    return last;
  }

  bool setAppColorByName(String rawName) {
    final key = rawName.toLowerCase().trim();
    final matched = allowedColors[key];
    if (matched == null) return false;

    _seedColor = matched;
    _colorName = _spanishName(key);
    notifyListeners();
    return true;
  }

  void setFontSizeFactor(double factor) {
    _fontSizeFactor = factor.clamp(0.85, 1.35);
    notifyListeners();
  }

  void setSentimentFilter(Sentiment? sentiment) {
    _sentimentFilter = sentiment;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  String _spanishName(String key) {
    switch (key) {
      case 'blue':
      case 'azul':
        return 'azul';
      case 'red':
      case 'rojo':
        return 'rojo';
      case 'green':
      case 'verde':
        return 'verde';
      case 'purple':
      case 'morado':
        return 'morado';
      case 'orange':
      case 'naranja':
        return 'naranja';
      case 'pink':
      case 'rosa':
      case 'rosado':
        return 'rosa';
      case 'teal':
      case 'turquesa':
        return 'turquesa';
      case 'amber':
      case 'ambar':
      case 'ámbar':
        return 'ámbar';
      default:
        return 'índigo';
    }
  }
}
