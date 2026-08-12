import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/chat_message.dart';
import 'package:zindagi_plus/data/repositories/interfaces/chat_repository.dart';

/// Mock implementation of [ChatRepository].
///
/// Returns deterministic template responses with simulated latency.
/// The real implementation will call an AI backend with the full message
/// history and user profile context.
class ChatRepositoryMock implements ChatRepository {
  // Seed messages — mirrors what was previously hardcoded in the UI.
  final List<ChatMessage> _history = [
    ChatMessage(
      id: 'msg_001',
      isUser: false,
      text:
          'Hi! I\'m your Zindagi AI assistant. I can answer questions about your lab results, medications, and health trends. What would you like to know?',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      sources: [],
    ),
    ChatMessage(
      id: 'msg_002',
      isUser: true,
      text: 'Why is my HbA1c borderline?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 59)),
      sources: [],
    ),
    ChatMessage(
      id: 'msg_003',
      isUser: false,
      text:
          'Your HbA1c of 6.8% is slightly above the normal range of <5.7%. This reflects your average blood sugar over the past 3 months. The main contributing factors in your profile are irregular meal timing and low fibre intake.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 58, seconds: 30)),
      sources: ['July Lab Report', 'Meal Log Analysis'],
    ),
  ];

  @override
  Future<Result<String>> sendMessage(
    List<ChatMessage> history,
    String newMessage,
  ) async {
    // Simulate AI response latency (1–1.5 s).
    await Future.delayed(const Duration(milliseconds: 1500));

    // Deterministic template response — replace with real AI call during
    // backend integration.
    final reply = newMessage.contains('?')
        ? 'Great question! Based on your recent health data and lab results, this is something we can address with small lifestyle changes. I\'ll analyse your full profile to give you a personalised recommendation.'
        : 'Let me check your health records for a tailored answer. Based on your profile, here is what I found.';

    final msg = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      isUser: false,
      text: reply,
      timestamp: DateTime.now(),
      sources: ['Health Profile', 'AI Analysis'],
    );
    _history.add(msg);
    return Success(reply);
  }

  @override
  Future<Result<List<ChatMessage>>> getChatHistory() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Success(List.unmodifiable(_history));
  }
}
