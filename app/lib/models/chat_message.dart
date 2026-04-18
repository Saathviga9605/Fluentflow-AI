enum MessageRole { user, assistant }

class CorrectionData {
  const CorrectionData({
    required this.original,
    required this.improved,
    this.tip,
  });

  final String original;
  final String improved;
  final String? tip;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.correction,
    this.continuationQuestion,
    this.timestamp,
    this.isTyping = false,
  });

  final String id;
  final MessageRole role;
  final String text;
  final CorrectionData? correction;
  final String? continuationQuestion;
  final DateTime? timestamp;
  final bool isTyping;
}
