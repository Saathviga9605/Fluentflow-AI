import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class BackendSuggestion {
  const BackendSuggestion({
    required this.type,
    required this.suggestion,
    this.explanation,
  });

  final String type;
  final String suggestion;
  final String? explanation;
}

class ConversationApiResult {
  const ConversationApiResult({
    required this.response,
    required this.correctedText,
    this.followUpQuestion,
    this.tip,
    this.suggestions = const <BackendSuggestion>[],
  });

  final String response;
  final String correctedText;
  final String? followUpQuestion;
  final String? tip;
  final List<BackendSuggestion> suggestions;
}

class BackendApiService {
  BackendApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  String get _baseUrl {
    const configured = String.fromEnvironment('BACKEND_URL');
    if (configured.isNotEmpty) return configured;

    if (kIsWeb) return 'http://localhost:8000';

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      default:
        return 'http://localhost:8000';
    }
  }

  Future<ConversationApiResult> sendConversation({
    required String userId,
    required String userText,
    required String sessionId,
    required List<Map<String, String>> conversationHistory,
    required double difficulty,
    required bool safeMode,
    required String language,
  }) async {
    final uri = Uri.parse('$_baseUrl/conversation');
    final payload = <String, dynamic>{
      'user_text': userText,
      'user_id': userId,
      'session_id': sessionId,
      'conversation_history': conversationHistory,
      'difficulty_level': difficulty,
      'safe_mode': safeMode,
      'language_preference': language,
    };

    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final detail = _extractErrorDetail(response.body);
      throw Exception('Backend error ${response.statusCode}: $detail');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final suggestionsRaw = decoded['suggestions'] as List<dynamic>? ?? const [];
    final tips = (decoded['tips'] as List<dynamic>? ?? const [])
        .map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();

    return ConversationApiResult(
      response: (decoded['response'] ?? '').toString(),
      correctedText: (decoded['corrected_text'] ?? userText).toString(),
      followUpQuestion: (decoded['follow_up_question'] ?? '').toString().trim().isEmpty
          ? null
          : decoded['follow_up_question'].toString(),
      tip: tips.isEmpty ? null : tips.first,
      suggestions: suggestionsRaw
          .whereType<Map<String, dynamic>>()
          .map(
            (s) => BackendSuggestion(
              type: (s['type'] ?? '').toString(),
              suggestion: (s['suggestion'] ?? '').toString(),
              explanation: (s['explanation'] ?? '').toString().trim().isEmpty
                  ? null
                  : s['explanation'].toString(),
            ),
          )
          .where((s) => s.suggestion.trim().isNotEmpty)
          .toList(),
    );
  }

  String _extractErrorDetail(String body) {
    if (body.trim().isEmpty) return 'No response body';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    } catch (_) {
      // Keep original body when response is not JSON.
    }
    return body;
  }
}
