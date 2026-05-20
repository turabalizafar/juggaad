import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import 'service_providers.dart';
import 'orchestration_provider.dart';
import 'package:flutter_riverpod/legacy.dart';

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final Ref _ref;

  ChatNotifier(this._ref)
    : super([
        ChatMessage(
          text:
              'Hi there! What do you need help with today? (e.g., "Mujhe AC theek karwana hai DHA Lahore mein")',
          isUser: false,
        ),
      ]);

  Future<void> sendParseRequest(String rawText, {String? languageHint}) async {
    state = [...state, ChatMessage(text: rawText, isUser: true)];

    final orchestrationNotifier = _ref.read(orchestrationProvider.notifier);
    orchestrationNotifier.setParsing();

    try {
      final locationService = _ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();

      final apiService = _ref.read(apiServiceProvider);
      final response = await apiService.parseRequest(
        rawText: rawText,
        languageHint: languageHint,
        userLat: position?.latitude,
        userLng: position?.longitude,
      );

      if (response.status == 'incomplete') {
        orchestrationNotifier.setIdle();
        state = [
          ...state,
          ChatMessage(text: response.aiMessage, isUser: false),
        ];
      } else {
        orchestrationNotifier.setParsedPreview(response);
      }
    } catch (e) {
      orchestrationNotifier.setIdle();
      state = [
        ...state,
        ChatMessage(text: 'Error processing request: $e', isUser: false),
      ];
    }
  }

  void addSystemMessage(String text) {
    state = [...state, ChatMessage(text: text, isUser: false)];
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((
  ref,
) {
  return ChatNotifier(ref);
});
