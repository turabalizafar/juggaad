import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_provider.dart';
import '../providers/orchestration_provider.dart';
import '../providers/trace_stream_provider.dart';
import 'parsed_request_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<String> _categories = [
    'Plumbing',
    'Electrical',
    'AC Repair',
    'Carpentry',
    'Cleaning'
  ];

  void _sendMessage([String? text]) {
    final message = text ?? _textController.text.trim();
    if (message.isEmpty) return;

    _textController.clear();
    ref.read(chatProvider.notifier).sendParseRequest(message);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<OrchestrationState>(orchestrationProvider, (previous, next) {
      if (next == OrchestrationState.parsedPreview) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ParsedRequestScreen()),
        );
      }
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chatMessages = ref.watch(chatProvider);
    final orchestrationState = ref.watch(orchestrationProvider);
    final orchestrationData = ref.read(orchestrationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.bolt, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'Jugaad',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: colorScheme.secondaryContainer,
              child: Icon(Icons.person, color: colorScheme.primary),
            ),
          )
        ],
        backgroundColor: colorScheme.surfaceContainerLowest,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Categories
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ActionChip(
                    label: Text(_categories[index]),
                    backgroundColor: colorScheme.surfaceContainerLow,
                    side: BorderSide(color: colorScheme.outlineVariant),
                    onPressed: () => _sendMessage('I need help with ${_categories[index]}'),
                  ),
                );
              },
            ),
          ),
          
          // Chat List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatMessages.length,
              itemBuilder: (context, index) {
                final msg = chatMessages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: msg.isUser ? colorScheme.primaryContainer : colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: msg.isUser ? const Radius.circular(4) : const Radius.circular(16),
                        bottomLeft: msg.isUser ? const Radius.circular(16) : const Radius.circular(4),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: msg.isUser ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Thinking / Agent Trace StreamBuilder
          if (orchestrationState == OrchestrationState.parsing && orchestrationData.currentRequestId != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Consumer(
                builder: (context, ref, child) {
                  final traceStream = ref.watch(traceStreamProvider(orchestrationData.currentRequestId!));
                  
                  return traceStream.when(
                    data: (traces) {
                      if (traces.isEmpty) return const SizedBox.shrink();
                      final latestTrace = traces.last;
                      return Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.tertiary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              latestTrace.message,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.tertiary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                    loading: () => Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.tertiary),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Thinking...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.tertiary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  );
                },
              ),
            ),
            
          if (orchestrationState == OrchestrationState.parsing && orchestrationData.currentRequestId == null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.tertiary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Thinking...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.tertiary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // Input Area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        hintText: 'Type your request...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.mic, color: colorScheme.outline),
                    onPressed: () {}, // MVP: no voice functionality
                  ),
                  IconButton(
                    icon: Icon(Icons.send, color: colorScheme.primary),
                    onPressed: () => _sendMessage(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
