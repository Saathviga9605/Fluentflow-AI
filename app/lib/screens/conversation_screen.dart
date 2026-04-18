import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../constants/app_colors.dart';
import '../constants/app_routes.dart';
import '../models/chat_message.dart';
import '../providers/auth_provider.dart';
import '../providers/conversation_provider.dart';
import '../providers/settings_provider.dart';
import '../services/dummy_data_service.dart';
import '../services/permission_service.dart';
import '../services/tts_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/mic_button.dart';
import '../widgets/suggestion_panel.dart';

class ConversationScreen extends StatefulWidget {
  const ConversationScreen({super.key});

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PermissionService _permissionService = PermissionService();
  final TtsService _ttsService = TtsService();
  final stt.SpeechToText _speech = stt.SpeechToText();

  late final AnimationController _waveController;
  int _lastMessageCount = 0;
  bool _speechReady = false;
  String _capturedSpeech = '';
  String? _lastAutoSpokenAssistantId;
  bool _submittingCapturedSpeech = false;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final userId = context.read<AuthProvider>().user?.userId;
      if (userId != null) {
        await context.read<ConversationProvider>().loadForUser(userId);
      }
      await _initializeSpeech();
    });
  }

  @override
  void dispose() {
    final userId = context.read<AuthProvider>().user?.userId;
    if (userId != null) {
      context.read<ConversationProvider>().persistForUser(userId);
    }
    _controller.dispose();
    _scrollController.dispose();
    _waveController.dispose();
    _ttsService.stop();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    HapticFeedback.lightImpact();
    final conversationProvider = context.read<ConversationProvider>();
    final settings = context.read<SettingsProvider>();

    if (conversationProvider.isRecording) {
      await _speech.stop();
      await conversationProvider.toggleRecording();
      await _submitCapturedSpeech();
      return;
    }

    final status = await _permissionService.requestMicrophonePermission(context);
    if (!mounted) return;

    if (status.isGranted) {
      if (!_speechReady) {
        await _initializeSpeech();
        if (!mounted) return;
      }

      if (!_speechReady) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Speech recognition unavailable on this device.'),
          ),
        );
        return;
      }

      _capturedSpeech = '';
      // ignore: deprecated_member_use
      final didStart = await _speech.listen(
        localeId: _speechLocaleFromSettings(settings.language),
        // ignore: deprecated_member_use
        partialResults: true,
        // ignore: deprecated_member_use
        listenMode: stt.ListenMode.dictation,
        pauseFor: const Duration(seconds: 3),
        listenFor: const Duration(seconds: 45),
        onResult: (result) {
          _capturedSpeech = result.recognizedWords;
          if (_capturedSpeech.trim().isNotEmpty) {
            _controller.text = _capturedSpeech;
            _controller.selection = TextSelection.fromPosition(
              TextPosition(offset: _controller.text.length),
            );
          }

          if (result.finalResult && conversationProvider.isRecording) {
            _speech.stop();
            conversationProvider.toggleRecording();
            _submitCapturedSpeech();
          }
        },
      );
      if (!mounted) return;

      if (!didStart) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start microphone capture.'),
          ),
        );
        return;
      }

      await conversationProvider.toggleRecording();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Listening... tap mic again to send your speech.'),
          duration: Duration(milliseconds: 1200),
        ),
      );
      return;
    }

    final text = status == PermissionStatus.permanentlyDenied
        ? 'Microphone permission is permanently denied.'
        : 'Microphone access was denied.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _sendTextMessage() async {
    final conversationProvider = context.read<ConversationProvider>();
    final authProvider = context.read<AuthProvider>();
    final settings = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final userId = authProvider.user?.userId;
    _controller.clear();
    await conversationProvider.sendMessage(
      text: text,
      userId: userId ?? 'anonymous',
      difficulty: settings.difficulty,
      safeMode: settings.safeMode,
      language: settings.language,
    );

    if (userId != null) {
      await conversationProvider.persistForUser(userId);
      await authProvider.refreshUserStats();
    }

    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          conversationProvider.lastError == null
              ? 'Response received'
              : 'Could not reach backend. Showing fallback response.',
        ),
        duration: const Duration(milliseconds: 1000),
      ),
    );
  }

  Future<void> _editLastMessage() async {
    final conversationProvider = context.read<ConversationProvider>();
    final messages = conversationProvider.messages;
    final lastUser = messages.lastWhere(
      (m) => m.role == MessageRole.user,
      orElse: () => const ChatMessage(id: '', role: MessageRole.user, text: ''),
    );

    if (lastUser.text.isEmpty) return;

    final editor = TextEditingController(text: lastUser.text);
    final edited = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit your last message'),
        content: TextField(
          controller: editor,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Refine your message...'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, editor.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (edited != null && edited.isNotEmpty) {
      conversationProvider.editLastUserMessage(edited);
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _retryResponse() async {
    HapticFeedback.selectionClick();
    final settings = context.read<SettingsProvider>();
    final userId = context.read<AuthProvider>().user?.userId ?? 'anonymous';
    await context.read<ConversationProvider>().retryLastResponse(
      userId: userId,
      difficulty: settings.difficulty,
      safeMode: settings.safeMode,
      language: settings.language,
    );
  }

  Future<void> _replayMessage(String text) async {
    final messenger = ScaffoldMessenger.of(context);
    final settings = context.read<SettingsProvider>();
    await _ttsService.speak(
      text,
      voiceProfile: settings.voiceProfile,
      language: _ttsLanguageFromSettings(settings.language),
      speechRate: _mapSpeechRate(settings.speechSpeed),
    );
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Replaying AI voice...'),
        duration: Duration(milliseconds: 800),
      ),
    );
  }

  double _mapSpeechRate(double sliderValue) {
    return (0.42 + (sliderValue * 0.44)).clamp(0.35, 1.0);
  }

  String _speechLocaleFromSettings(String language) {
    switch (language) {
      case 'Tamil + English':
        return 'en_IN';
      case 'English only':
      default:
        return 'en_US';
    }
  }

  String _ttsLanguageFromSettings(String language) {
    switch (language) {
      case 'Tamil + English':
        return 'en-IN';
      case 'English only':
      default:
        return 'en-US';
    }
  }

  void _scrollToBottom() {
    Future<void>.delayed(const Duration(milliseconds: 90), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _openNeedHelp() {
    final conversation = context.read<ConversationProvider>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SuggestionPanel(
        words: conversation.suggestedWords.isEmpty
            ? DummyDataService.suggestedWords()
            : conversation.suggestedWords,
        synonyms: conversation.synonyms.isEmpty
            ? DummyDataService.synonyms()
            : conversation.synonyms,
        completions: conversation.completions.isEmpty
            ? DummyDataService.completions()
            : conversation.completions,
      ),
    );
  }

  Future<void> _initializeSpeech() async {
    _speechReady = await _speech.initialize(
      onStatus: (status) {
        if (!mounted) return;
        final isStopped = status == 'done' || status == 'notListening';
        final provider = context.read<ConversationProvider>();
        if (isStopped && provider.isRecording) {
          provider.toggleRecording();
          _submitCapturedSpeech();
        }
      },
      onError: (_) {
        if (!mounted) return;
        final provider = context.read<ConversationProvider>();
        if (provider.isRecording) {
          provider.toggleRecording();
        }
      },
    );
  }

  Future<void> _submitCapturedSpeech() async {
    if (_submittingCapturedSpeech) return;
    _submittingCapturedSpeech = true;
    final spoken = _capturedSpeech.trim();
    try {
      if (spoken.isEmpty) return;
      _controller.text = spoken;
      await _sendTextMessage();
      _capturedSpeech = '';
    } finally {
      _submittingCapturedSpeech = false;
    }
  }

  void _maybeAutoSpeakLatestAssistant(List<ChatMessage> messages) {
    if (messages.isEmpty) return;
    final settings = context.read<SettingsProvider>();
    if (!settings.autoSpeakReplies) return;

    final latest = messages.last;
    if (latest.role != MessageRole.assistant || latest.isTyping) return;
    if (latest.id == _lastAutoSpokenAssistantId) return;

    _lastAutoSpokenAssistantId = latest.id;
    unawaited(_ttsService.speak(
      latest.text,
      voiceProfile: settings.voiceProfile,
      language: _ttsLanguageFromSettings(settings.language),
      speechRate: _mapSpeechRate(settings.speechSpeed),
    ));
  }

  void _loadSampleConversation() {
    HapticFeedback.mediumImpact();
    context.read<ConversationProvider>().loadDemoConversation();
  }

  @override
  Widget build(BuildContext context) {
    final conversation = context.watch<ConversationProvider>();
    final messages = conversation.messages;

    _maybeAutoSpeakLatestAssistant(messages);

    if (_lastMessageCount != messages.length) {
      _lastMessageCount = messages.length;
      _scrollToBottom();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Conversation'),
        actions: [
          IconButton(
            tooltip: 'Progress',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.progress),
            icon: const Icon(Icons.show_chart_rounded),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.settings),
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.calmGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: messages.isEmpty
                    ? _ConversationEmptyState(onStart: _loadSampleConversation)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) => TweenAnimationBuilder<double>(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOut,
                          tween: Tween(begin: 0, end: 1),
                          builder: (context, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, (1 - value) * 10),
                              child: child,
                            ),
                          ),
                          child: ChatBubble(
                            message: messages[index],
                            onReplayTap: messages[index].role == MessageRole.assistant
                                ? () => _replayMessage(messages[index].text)
                                : null,
                          ),
                        ),
                      ),
              ),
              if (conversation.isRecording)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                  child: _Waveform(controller: _waveController),
                ),
              if (conversation.isThinking)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2.1),
                      ),
                      SizedBox(width: 10),
                      Text('Crafting a natural voice reply...'),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _editLastMessage,
                      icon: const Icon(Icons.edit_note_rounded, size: 18),
                      label: const Text('Edit last message'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _retryResponse,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Retry response'),
                    ),
                  ],
                ),
              ),
              _BottomInteractionBar(
                textController: _controller,
                isRecording: conversation.isRecording,
                onMicTap: _toggleRecording,
                onSend: _sendTextMessage,
                onNeedHelp: _openNeedHelp,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationEmptyState extends StatelessWidget {
  const _ConversationEmptyState({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primary,
                size: 38,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Start your first conversation 😊',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Say a simple sentence and FluentFlow AI will gently guide your next reply.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: onStart, child: const Text('Load demo chat')),
          ],
        ),
      ),
    );
  }
}

class _BottomInteractionBar extends StatelessWidget {
  const _BottomInteractionBar({
    required this.textController,
    required this.isRecording,
    required this.onMicTap,
    required this.onSend,
    required this.onNeedHelp,
  });

  final TextEditingController textController;
  final bool isRecording;
  final VoidCallback onMicTap;
  final Future<void> Function() onSend;
  final VoidCallback onNeedHelp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A103542),
            blurRadius: 20,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: textController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Or type your thought...',
                    fillColor: AppColors.secondary,
                    filled: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: () => onSend(),
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  fixedSize: const Size(48, 48),
                ),
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: onNeedHelp,
                child: const Text('Need help?'),
              ),
              MicButton(
                isRecording: isRecording,
                onTap: onMicTap,
              ),
              const SizedBox(width: 74),
            ],
          ),
        ],
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(14),
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(20, (index) {
              final v = ((controller.value + index * 0.08) % 1.0);
              final h = 6 + (20 * (1 - (v - 0.5).abs() * 2));
              return Container(
                width: 4,
                height: h,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.72),
                  borderRadius: BorderRadius.circular(99),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
