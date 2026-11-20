import 'package:app/config/ia/diary_agent.dart';
import 'package:app/config/state/app_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class _ChatBubble {
  final bool isUser;
  final String text;
  final List<String> toolsCalled;

  const _ChatBubble({
    required this.isUser,
    required this.text,
    this.toolsCalled = const [],
  });
}

/// Panel interactivo del asistente agéntico con Function Calling
class AiAssistantPanel extends StatefulWidget {
  const AiAssistantPanel({super.key});

  @override
  State<AiAssistantPanel> createState() => _AiAssistantPanelState();
}

class _AiAssistantPanelState extends State<AiAssistantPanel> {
  final DiaryAgent _agent = DiaryAgent();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<_ChatBubble> _messages = [
    const _ChatBubble(
      isUser: false,
      text:
          '¡Hola! Soy tu asistente agéntico con Gemini. Puedes pedirme crear entradas, '
          'cambiar el color de la app, resumir tu diario o eliminar la última nota.',
    ),
  ];

  static const List<String> _suggestions = [
    'Cambia el color a morado',
    'Agrega una entrada: hoy en DevFest Cali construí mi primer agente con Flutter',
    'Resume mi diario',
    'Pon la app en verde',
  ];

  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send(String rawText) async {
    final prompt = rawText.trim();
    if (prompt.isEmpty || _isSending) return;

    final appState = context.read<AppState>();

    setState(() {
      _isSending = true;
      _controller.clear();
      _messages.add(_ChatBubble(isUser: true, text: prompt));
    });
    _scrollToBottom();

    final reply = await _agent.askAssistant(prompt, appState);

    if (!mounted) return;
    setState(() {
      _messages.add(
        _ChatBubble(
          isUser: false,
          text: reply.text,
          toolsCalled: reply.toolsCalled,
        ),
      );
      _isSending = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          left: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.45),
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  radius: 18,
                  child: const Icon(Icons.auto_awesome, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asistente Agéntico',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Function Calling en tiempo real',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Sugerencias rápidas
          SizedBox(
            height: 46,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: _suggestions.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final text = _suggestions[index];
                return ActionChip(
                  label: Text(text, style: const TextStyle(fontSize: 12)),
                  onPressed: _isSending ? null : () => _send(text),
                );
              },
            ),
          ),

          // Mensajes
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(14),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 340),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? colorScheme.primary
                          : colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: message.isUser
                          ? null
                          : Border.all(
                              color: colorScheme.outlineVariant
                                  .withValues(alpha: 0.6),
                            ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.text,
                          style: TextStyle(
                            color: message.isUser
                                ? colorScheme.onPrimary
                                : colorScheme.onSurface,
                            height: 1.35,
                          ),
                        ),
                        if (message.toolsCalled.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: message.toolsCalled
                                .map(
                                  (tool) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: Colors.green.withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Text(
                                      '⚡ $tool()',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontFamily: 'monospace',
                                        color: Colors.green.shade800,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (_isSending)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Gemini está ejecutando herramientas...',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),

          // Input
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isSending,
                    textInputAction: TextInputAction.send,
                    onSubmitted: _send,
                    decoration: InputDecoration(
                      hintText: 'Ej: Cambia el color a turquesa...',
                      filled: true,
                      fillColor: colorScheme.surface,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed:
                      _isSending ? null : () => _send(_controller.text),
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
