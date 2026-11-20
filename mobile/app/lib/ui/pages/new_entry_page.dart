import 'package:app/config/firebase/firebase_options.dart';
import 'package:app/config/ia/diary_agent.dart';
import 'package:app/config/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NewEntryPage extends StatefulWidget {
  const NewEntryPage({super.key});

  @override
  State<NewEntryPage> createState() => _NewEntryPageState();
}

class _NewEntryPageState extends State<NewEntryPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final DiaryAgent _agent = DiaryAgent();

  bool _analyzeWithAI = true;
  bool _generateIllustration = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe algo en el contenido de tu nota.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final entry = await _agent.createAnalyzedEntry(
        content: content,
        title: _titleController.text.trim(),
        analyzeWithAI: _analyzeWithAI,
        generateImage: _generateIllustration,
      );

      if (!mounted) return;
      await context.read<AppState>().addEntry(entry);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error guardando entrada: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isConfigured = WorkshopAIConfig.isFirebaseConfigured;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva entrada'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(_isSaving ? 'Guardando...' : 'Guardar'),
            ),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _titleController,
                  enabled: !_isSaving,
                  decoration: const InputDecoration(
                    labelText: 'Título (opcional)',
                    hintText: 'Ej: Mi experiencia en el DevFest Cali',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _contentController,
                  enabled: !_isSaving,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: '¿Cómo fue tu día?',
                    hintText:
                        'Escribe tus pensamientos aquí. Gemini detectará el sentimiento y etiquetas automáticamente...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile(
                        title: const Text('Analizar con Gemini'),
                        subtitle: const Text(
                          'Detecta sentimiento emocional, etiquetas y resumen automático.',
                        ),
                        value: isConfigured && _analyzeWithAI,
                        onChanged: isConfigured && !_isSaving
                            ? (val) => setState(() => _analyzeWithAI = val)
                            : null,
                      ),
                      const Divider(height: 1),
                      SwitchListTile(
                        title: const Text('Generar ilustración (Gemini Image)'),
                        subtitle: const Text(
                          'Crea una imagen artística en memoria compatible con Flutter Web.',
                        ),
                        value: isConfigured &&
                            _analyzeWithAI &&
                            _generateIllustration,
                        onChanged: isConfigured && _analyzeWithAI && !_isSaving
                            ? (val) =>
                                setState(() => _generateIllustration = val)
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
