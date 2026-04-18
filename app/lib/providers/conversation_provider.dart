import 'package:flutter/foundation.dart';
import 'dart:math';

import '../models/chat_message.dart';
import '../services/backend_api_service.dart';
import '../services/dummy_data_service.dart';
import '../services/local_storage_service.dart';

class ConversationProvider extends ChangeNotifier {
  ConversationProvider({
    required LocalStorageService storageService,
    required BackendApiService apiService,
  })  : _storageService = storageService,
        _apiService = apiService;

  final LocalStorageService _storageService;
  final BackendApiService _apiService;

  final List<ChatMessage> _messages = <ChatMessage>[];
  final Random _random = Random();
  bool _isRecording = false;
  bool _isThinking = false;
  String _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
  String? _lastError;

  List<String> _suggestedWords = <String>[];
  List<String> _synonyms = <String>[];
  List<String> _completions = <String>[];

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isRecording => _isRecording;
  bool get isThinking => _isThinking;
  String? get lastError => _lastError;
  List<String> get suggestedWords => List.unmodifiable(_suggestedWords);
  List<String> get synonyms => List.unmodifiable(_synonyms);
  List<String> get completions => List.unmodifiable(_completions);

  Future<void> loadForUser(String userId) async {
    _messages.clear();
    _lastError = null;
    final saved = _storageService.getSessionHistory(userId);
    if (saved.isEmpty) {
      notifyListeners();
      return;
    }

    for (final item in saved) {
      final roleName = item['role'] as String? ?? 'user';
      _messages.add(
        ChatMessage(
          id: item['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
          role: roleName == 'assistant' ? MessageRole.assistant : MessageRole.user,
          text: item['text'] as String? ?? '',
          timestamp: DateTime.tryParse(item['timestamp'] as String? ?? ''),
        ),
      );
    }
    notifyListeners();
  }

  void loadDemoConversation() {
    _messages
      ..clear()
      ..addAll(DummyDataService.initialConversation());
    notifyListeners();
  }

  Future<void> toggleRecording() async {
    _isRecording = !_isRecording;
    notifyListeners();
  }

  Future<void> sendMessage({
    required String text,
    required String userId,
    required double difficulty,
    required bool safeMode,
    required String language,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: MessageRole.user,
      text: trimmed,
      timestamp: DateTime.now(),
    );

    final typing = ChatMessage(
      id: 'typing-${DateTime.now().millisecondsSinceEpoch}',
      role: MessageRole.assistant,
      text: _humanThinkingPrompts[_random.nextInt(_humanThinkingPrompts.length)],
      isTyping: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    _messages.add(typing);
    _isThinking = true;
    _lastError = null;
    notifyListeners();

    try {
      final history = _messages
          .where((m) => !m.isTyping)
          .map(
            (m) => <String, String>{
              'role': m.role == MessageRole.assistant ? 'assistant' : 'user',
              'content': m.text,
            },
          )
          .toList();

      final apiResult = await _apiService.sendConversation(
        userId: userId,
        userText: trimmed,
        sessionId: _sessionId,
        conversationHistory: history,
        difficulty: difficulty,
        safeMode: safeMode,
        language: language,
      );

      _messages.removeWhere((m) => m.isTyping);
      _messages.add(
        ChatMessage(
          id: 'assistant-${DateTime.now().millisecondsSinceEpoch}',
          role: MessageRole.assistant,
          text: apiResult.response,
          correction: CorrectionData(
            original: trimmed,
            improved: apiResult.correctedText,
            tip: apiResult.tip,
          ),
          continuationQuestion: apiResult.followUpQuestion,
          timestamp: DateTime.now(),
        ),
      );

      _updateHelpBuckets(apiResult.suggestions);
    } catch (e) {
      _messages.removeWhere((m) => m.isTyping);
      _lastError = e.toString();
      _messages.add(
        ChatMessage(
          id: 'assistant-${DateTime.now().millisecondsSinceEpoch}',
          role: MessageRole.assistant,
          text: 'I could not reach the AI backend right now. Please check the server connection and try again.',
          continuationQuestion: 'Want to retry after checking backend status?',
          timestamp: DateTime.now(),
        ),
      );

      _seedHelpBucketsFromUserText(trimmed);
    }

    _isThinking = false;
    notifyListeners();
  }

  void editLastUserMessage(String newText) {
    for (var i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].role == MessageRole.user) {
        final old = _messages[i];
        _messages[i] = ChatMessage(
          id: old.id,
          role: old.role,
          text: newText,
          correction: old.correction,
          continuationQuestion: old.continuationQuestion,
          timestamp: DateTime.now(),
        );
        notifyListeners();
        return;
      }
    }
  }

  Future<void> retryLastResponse({
    required String userId,
    required double difficulty,
    required bool safeMode,
    required String language,
  }) async {
    _messages.removeWhere((m) => m.role == MessageRole.assistant);
    notifyListeners();

    final lastUser = _messages.lastWhere(
      (m) => m.role == MessageRole.user,
      orElse: () => const ChatMessage(
        id: 'none',
        role: MessageRole.user,
        text: '',
      ),
    );

    if (lastUser.text.isNotEmpty) {
      await sendMessage(
        text: lastUser.text,
        userId: userId,
        difficulty: difficulty,
        safeMode: safeMode,
        language: language,
      );
    }
  }

  Future<void> persistForUser(String userId) async {
    await _storageService.saveSessionHistory(userId, _messages);

    final assistantCount = _messages.where((m) => m.role == MessageRole.assistant).length;
    final score = assistantCount > 0 ? 80 + (assistantCount * 2).clamp(0, 18) : 80;
    final fillerCount = _messages
        .where((m) => m.role == MessageRole.user)
        .map((m) => m.text.toLowerCase())
        .where((t) => t.contains(' um ') || t.contains(' uh ') || t.contains(' like '))
        .length;

    await _storageService.saveFluencySnapshot(
      userId: userId,
      score: score.toDouble(),
      fillerCount: fillerCount,
    );
  }

  void clear() {
    _messages.clear();
    _isRecording = false;
    _isThinking = false;
    _suggestedWords = <String>[];
    _synonyms = <String>[];
    _completions = <String>[];
    _lastError = null;
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    notifyListeners();
  }

  void _updateHelpBuckets(List<BackendSuggestion> suggestions) {
    final words = <String>[];
    final synonyms = <String>[];
    final completions = <String>[];

    for (final s in suggestions) {
      final decorated = s.explanation == null
          ? s.suggestion
          : '${s.suggestion} - ${s.explanation}';

      switch (s.type.toLowerCase()) {
        case 'synonym':
          synonyms.add(decorated);
          break;
        case 'completion':
          completions.add(decorated);
          break;
        default:
          words.add(decorated);
      }
    }

    _suggestedWords = words;
    _synonyms = synonyms;
    _completions = completions;
  }

  void _seedHelpBucketsFromUserText(String text) {
    final normalized = text.trim();
    if (normalized.isEmpty) return;

    _suggestedWords = <String>[
      'Try this clearer version: "$normalized"',
      'Add one feeling word to make it richer.',
    ];
    _synonyms = DummyDataService.synonyms();
    _completions = DummyDataService.completions();
  }
}

const List<String> _humanThinkingPrompts = <String>[
  'Let me think with you for a second...',
  'Listening... crafting a natural reply...',
  'Nice point. Building your response...',
  'Got it. Finding the best way to say this...',
];
