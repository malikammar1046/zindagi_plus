/// Represents a single chat message.
///
/// This is a shared model used by both [ChatRepository] and the UI.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.sources = const [],
  });

  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String> sources;

  String get timeFormatted {
    final h = timestamp.hour > 12 ? timestamp.hour - 12 : timestamp.hour;
    final m = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }
}
