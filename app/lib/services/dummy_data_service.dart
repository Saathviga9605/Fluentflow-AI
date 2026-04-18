import 'package:flutter/material.dart';

import '../models/chat_message.dart';
import '../models/conversation_mode.dart';
import '../models/progress_metric.dart';

class DummyDataService {
  static List<ConversationMode> modes() {
    return const [
      ConversationMode(
        title: 'Casual Chat',
        subtitle: 'Easy and natural conversations',
        icon: Icons.chat_bubble_outline_rounded,
      ),
      ConversationMode(
        title: 'Daily Situations',
        subtitle: 'Practice real-life moments',
        icon: Icons.sunny,
      ),
      ConversationMode(
        title: 'Speak Smoothly',
        subtitle: 'Reduce hesitation and pauses',
        icon: Icons.graphic_eq_rounded,
      ),
      ConversationMode(
        title: 'Build Confidence',
        subtitle: 'Gentle support while you speak',
        icon: Icons.favorite_outline,
      ),
    ];
  }

  static List<ProgressMetric> quickStats() {
    return const [
      ProgressMetric(
        title: 'Fluency Score',
        value: '82',
        subtitle: '+4 this week',
      ),
      ProgressMetric(
        title: 'Speaking Streak',
        value: '9 days',
        subtitle: 'Keep it going',
      ),
      ProgressMetric(
        title: 'Filler Reduction',
        value: '38%',
        subtitle: 'Less um/uh usage',
      ),
    ];
  }

  static List<ChatMessage> initialConversation() {
    return const [
      ChatMessage(
        id: '1',
        role: MessageRole.assistant,
        text: 'Hey, nice to talk with you again. How was your day?',
      ),
      ChatMessage(
        id: '2',
        role: MessageRole.user,
        text: 'It was good um I go yesterday to market and buy fruits.',
      ),
      ChatMessage(
        id: '3',
        role: MessageRole.assistant,
        text: 'That sounds like a productive day.',
        correction: CorrectionData(
          original: 'I go yesterday to market and buy fruits.',
          improved: 'I went to the market yesterday and bought fruits.',
          tip: 'Try saying it in one smooth sentence.',
        ),
        continuationQuestion: 'What fruits did you enjoy the most?',
      ),
    ];
  }

  static List<double> fluencyTrend() {
    return const [58, 61, 60, 66, 70, 73, 76, 79, 82];
  }

  static List<String> commonCorrections() {
    return const [
      'Use past tense for yesterday events',
      'Avoid repeating fillers at sentence start',
      'Connect ideas with one complete sentence',
      'Use article "the" for known places',
    ];
  }

  static List<String> suggestedWords() {
    return const [
      'Productive',
      'Affordable',
      'Comfortable',
      'Exciting',
      'Useful',
      'Convenient',
    ];
  }

  static List<String> synonyms() {
    return const [
      'Good -> Great, Pleasant, Lovely',
      'Big -> Large, Huge, Massive',
      'Buy -> Purchase, Pick up',
      'Happy -> Glad, Cheerful',
    ];
  }

  static List<String> completions() {
    return const [
      'I usually go there because...',
      'One thing I liked was...',
      'If I go again, I will...',
      'The best part of my day was...',
    ];
  }
}
