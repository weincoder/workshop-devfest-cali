import 'package:app/config/firebase/firebase_options.dart';
import 'package:app/config/models/diary_entry.dart';
import 'package:app/config/state/app_state.dart';
import 'package:app/ui/pages/new_entry_page.dart';
import 'package:app/ui/widgets/ai_assistant_panel.dart';
import 'package:app/ui/widgets/entry_card.dart';
import 'package:app/ui/widgets/setup_banner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DiaryHomePage extends StatefulWidget {
  const DiaryHomePage({super.key});

  @override
  State<DiaryHomePage> createState() => _DiaryHomePageState();
}

class _DiaryHomePageState extends State<DiaryHomePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadEntries();
    });
  }

  void _openNewEntry() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => const NewEntryPage(),
      ),
    );
  }

  void _openAssistantSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: const AiAssistantPanel(),
      ),
    );
  }

  void _showEntryDetail(DiaryEntry entry) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(entry.sentiment.emoji),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                entry.title.isNotEmpty ? entry.title : 'Entrada del diario',
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${entry.formattedDate} · ${entry.sentiment.label}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Text(entry.content),
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.tags
                      .map((tag) => Chip(label: Text('#$tag')))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = Theme.of(context);
    final isWideScreen = MediaQuery.of(context).size.width >= 900;
    final backendLabel =
        WorkshopAIConfig.useVertexAI ? 'Vertex AI' : 'Gemini API';

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('📔 AI Diary'),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Flutter Web · $backendLabel',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Chip(
              avatar: CircleAvatar(backgroundColor: appState.seedColor),
              label: Text('Tema: ${appState.colorName}'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SetupBanner(),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      _buildDiaryColumn(appState),
                      if (isWideScreen)
                        Positioned(
                          left: 20,
                          bottom: 20,
                          child: FloatingActionButton.extended(
                            heroTag: 'new_entry_fab',
                            onPressed: _openNewEntry,
                            icon: const Icon(Icons.edit_note_rounded),
                            label: const Text('Nueva entrada'),
                          ),
                        ),
                    ],
                  ),
                ),
                if (isWideScreen)
                  const SizedBox(
                    width: 400,
                    child: AiAssistantPanel(),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: isWideScreen
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'assistant_fab',
                  onPressed: _openAssistantSheet,
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Asistente IA'),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.extended(
                  heroTag: 'new_entry_fab',
                  onPressed: _openNewEntry,
                  icon: const Icon(Icons.edit_note_rounded),
                  label: const Text('Nueva entrada'),
                ),
              ],
            ),
    );
  }

  Widget _buildDiaryColumn(AppState appState) {
    final entries = appState.filteredEntries;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
          child: TextField(
            onChanged: appState.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Buscar por título, contenido o #tag...',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: appState.sentimentFilter == null,
                onSelected: (_) => appState.setSentimentFilter(null),
              ),
              const SizedBox(width: 8),
              ...Sentiment.values.map(
                (sentiment) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('${sentiment.emoji} ${sentiment.label}'),
                    selected: appState.sentimentFilter == sentiment,
                    onSelected: (selected) => appState
                        .setSentimentFilter(selected ? sentiment : null),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: appState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : entries.isEmpty
                  ? const Center(
                      child: Text(
                        'No hay entradas que coincidan.\n¡Crea una nueva o pídesela al asistente IA!',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 100),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return EntryCard(
                          entry: entry,
                          onTap: () => _showEntryDetail(entry),
                          onDelete: () => appState.deleteEntry(entry.id),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
