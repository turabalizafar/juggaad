import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../models/chat_message.dart';

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier()
    : super([
        ChatMessage(
          text:
              'Hi there! What do you need help with today? (e.g., "Mujhe AC theek karwana hai DHA Lahore mein")',
          isUser: false,
        ),
      ]);

  void addUserMessage(String text) {
    state = [...state, ChatMessage(text: text, isUser: true)];
    // Later we will trigger the API call to /parse here
  }

  void addSystemMessage(String text) {
    state = [...state, ChatMessage(text: text, isUser: false)];
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((
  ref,
) {
  return ChatNotifier();
});
