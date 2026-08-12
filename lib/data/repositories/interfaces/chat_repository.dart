import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/chat_message.dart';

/// Contract for the AI chat data layer.
///
/// Swap implementations (mock ↔ API) via the Riverpod provider in
/// `lib/providers/repository_providers.dart` without touching business logic.
abstract class ChatRepository {
  /// Sends [newMessage] with the conversation [history] as context and returns
  /// the AI's reply text.
  ///
  /// The real implementation will pass the history and user profile context
  /// to the AI backend. The mock returns a deterministic template response.
  Future<Result<String>> sendMessage(
    List<ChatMessage> history,
    String newMessage,
  );

  /// Returns the stored chat history for the current user, oldest first.
  ///
  /// In the mock this returns the in-memory list. The real implementation
  /// will fetch from a database.
  Future<Result<List<ChatMessage>>> getChatHistory();
}
