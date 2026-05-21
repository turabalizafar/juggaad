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
    // Add user message to chat
    state = [...state, ChatMessage(text: rawText, isUser: true)];

    final orchestrationNotifier = _ref.read(orchestrationProvider.notifier);
    orchestrationNotifier.setParsing();

    try {
      final locationService = _ref.read(locationServiceProvider);
      final position = await locationService.getCurrentPosition();

      // Build conversation history from state (last 8 messages)
      final messages = state.map((m) => m.toApiMap()).toList();

      final apiService = _ref.read(apiServiceProvider);
      final response = await apiService.sendChat(
        messages: messages,
        userLat: position?.latitude,
        userLng: position?.longitude,
      );

      if (response.status == 'incomplete' || response.status == 'off_topic') {
        orchestrationNotifier.setIdle();
        state = [
          ...state,
          ChatMessage(text: response.aiMessage, isUser: false),
        ];
      } else if (response.status == 'service_not_available') {
        orchestrationNotifier.setIdle();
        state = [
          ...state,
          ChatMessage(text: response.aiMessage, isUser: false),
        ];
      } else {
        // Complete — move to parsed preview
        orchestrationNotifier.setParsedPreview(response);
      }
    } catch (e) {
      orchestrationNotifier.setIdle();
      String errorMsg = 'Something went wrong. Please try again.';
      if (e.toString().contains('DioException') && e.toString().contains('detail')) {
        // Try to extract the detail message
        final detailMatch = RegExp(r'"detail"\s*:\s*"([^"]+)"').firstMatch(e.toString());
        if (detailMatch != null) {
          errorMsg = detailMatch.group(1) ?? errorMsg;
        }
      }
      state = [
        ...state,
        ChatMessage(text: errorMsg, isUser: false),
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
