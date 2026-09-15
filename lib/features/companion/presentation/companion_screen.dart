import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/companion_provider.dart';
import '../models/avatar_state.dart';
import '../../../core/theme/vajra_colors.dart';
import '../../../core/intelligence/voice/voice_engine.dart';
import '../../../shared/widgets/vajra_avatar.dart' as ui;

class CompanionScreen extends ConsumerStatefulWidget {
  const CompanionScreen({super.key});

  @override
  ConsumerState<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends ConsumerState<CompanionScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isComposing = false;
  int _activeVoiceSessionId = 0;

  @override
  void initState() {
    super.initState();
    ref.read(ttsServiceProvider).initialize();
    _inputController.addListener(() {
      final isComp = _inputController.text.trim().isNotEmpty;
      if (isComp != _isComposing) {
        setState(() => _isComposing = isComp);
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage([String? customText, bool isVoice = false, int? voiceSessionId]) async {
    final text = (customText ?? _inputController.text).trim();
    if (text.isNotEmpty) {
      _inputController.clear();
      setState(() => _isComposing = false);
      _scrollToBottom();
      final response = await ref.read(companionProvider.notifier).sendMessage(text, isVoice: isVoice);
      if (isVoice && voiceSessionId != null && voiceSessionId == _activeVoiceSessionId && response != null && response.isNotEmpty && mounted) {
        ref.read(voiceEngineProvider.notifier).speak(response);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(LucideIcons.micOff, color: Colors.redAccent, size: 24),
            SizedBox(width: 12),
            Text(
              'Microphone Access',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'VAJRA needs microphone access to listen to your voice commands and conversational requests. Please enable microphone access in settings.',
          style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Not Now', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(voiceEngineProvider.notifier).openSettings();
            },
            child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  ui.AvatarState _mapState(AvatarState modelState) {
    switch (modelState) {
      case AvatarState.idle:
        return ui.AvatarState.idle;
      case AvatarState.listening:
        return ui.AvatarState.listening;
      case AvatarState.thinking:
        return ui.AvatarState.thinking;
      case AvatarState.searching:
      case AvatarState.planning:
        return ui.AvatarState.focused;
      case AvatarState.speaking:
        return ui.AvatarState.speaking;
      case AvatarState.error:
        return ui.AvatarState.sleeping;
    }
  }

  String _getStateLabel(AvatarState modelState) {
    switch (modelState) {
      case AvatarState.idle:
        return 'READY';
      case AvatarState.listening:
        return 'LISTENING';
      case AvatarState.thinking:
        return 'THINKING';
      case AvatarState.searching:
        return 'SEARCHING MEMORY';
      case AvatarState.planning:
        return 'PLANNING';
      case AvatarState.speaking:
        return 'SPEAKING...';
      case AvatarState.error:
        return 'OFFLINE / ERROR';
    }
  }

  Color _getStateColor(AvatarState modelState) {
    switch (modelState) {
      case AvatarState.listening:
        return Colors.greenAccent;
      case AvatarState.speaking:
      case AvatarState.thinking:
      case AvatarState.searching:
      case AvatarState.planning:
        return VajraColors.accent;
      case AvatarState.error:
        return Colors.redAccent;
      default:
        return Colors.greenAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companionProvider);
    final voiceState = ref.watch(voiceEngineProvider);
    final isStreaming = state.avatarState == AvatarState.thinking || state.avatarState == AvatarState.speaking;
    final isListening = voiceState.isListening;
    final isSpeaking = voiceState.isSpeaking;
    final effectiveAvatarState = isSpeaking
        ? AvatarState.speaking
        : (isListening ? AvatarState.listening : state.avatarState);

    // Auto-scroll on stream token update
    ref.listen(companionProvider, (prev, next) {
      if (prev?.activeStreamText != next.activeStreamText || prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    // Voice recognition listener - forwards final recognized text to existing AI pipeline
    ref.listen<VoiceSessionState>(voiceEngineProvider, (prev, next) {
      if (next.finalTranscript.isNotEmpty && prev?.finalTranscript != next.finalTranscript) {
        final recognizedText = next.finalTranscript.trim();
        if (recognizedText.isNotEmpty) {
          final currentSessionId = ++_activeVoiceSessionId;
          _sendMessage(recognizedText, true, currentSessionId);
          ref.read(voiceEngineProvider.notifier).reset();
        }
      }
      if (next.isPermissionDenied && prev?.isPermissionDenied != next.isPermissionDenied) {
        _showPermissionDialog();
      } else if (next.errorMessage != null && prev?.errorMessage != next.errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: const Color(0xFF2A1515),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final promptSuggestions = [
      'What is 2 + 2? Answer only the number.',
      'What is quantum mechanics?',
      'Remember that I prefer studying at night.',
      'When do I prefer studying?',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0C0C),
                border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
              ),
              child: Row(
                children: [
                  ui.VajraAvatar(
                    size: 38,
                    state: _mapState(effectiveAvatarState),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('VAJRA Companion', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _getStateColor(effectiveAvatarState),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getStateLabel(effectiveAvatarState),
                              style: TextStyle(
                                color: _getStateColor(effectiveAvatarState),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.plusCircle, color: Colors.grey, size: 20),
                    tooltip: 'New Conversation',
                    onPressed: isStreaming ? null : () => ref.read(companionProvider.notifier).startNewSession(),
                  ),
                ],
              ),
            ),

            // Main Chat Area
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: state.messages.length + (state.activeStreamText.isNotEmpty || state.avatarState == AvatarState.thinking ? 1 : 0) + (state.messages.length <= 1 ? 1 : 0),
                itemBuilder: (context, index) {
                  // Prompt suggestions if chat is empty/fresh
                  if (state.messages.length <= 1 && index == state.messages.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16, bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            child: Text(
                              'TRY ASKING:',
                              style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1),
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: promptSuggestions.map((prompt) {
                              return GestureDetector(
                                onTap: isStreaming ? null : () => _sendMessage(prompt),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A1A1A),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                                  ),
                                  child: Text(
                                    prompt,
                                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.2),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    );
                  }

                  // Active Stream Bubble
                  if (index >= state.messages.length) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141414),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: VajraColors.accent.withValues(alpha: 0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: VajraColors.accent),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  state.avatarState == AvatarState.planning
                                      ? "Planning schedule..."
                                      : state.avatarState == AvatarState.searching
                                          ? "Searching memory vault..."
                                          : state.activeStreamText.isEmpty
                                              ? "VAJRA is thinking..."
                                              : "Generating answer...",
                                  style: const TextStyle(color: VajraColors.accent, fontSize: 12, fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                            if (state.activeStreamText.isNotEmpty) ...[
                              const SizedBox(height: 10),
                              SelectableText(
                                "${state.activeStreamText} ▌",
                                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }

                  final msg = state.messages[index];
                  final isUser = msg.isUser;
                  final isErrorMsg = !isUser && (msg.text.contains("apologize") || msg.text.contains("issue") || msg.text.contains("couldn't reach"));

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
                          decoration: BoxDecoration(
                            color: isUser
                                ? const Color(0xFF2563EB)
                                : isErrorMsg
                                    ? const Color(0xFF201010)
                                    : const Color(0xFF141414),
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(16),
                              topRight: const Radius.circular(16),
                              bottomLeft: Radius.circular(isUser ? 16 : 4),
                              bottomRight: Radius.circular(isUser ? 4 : 16),
                            ),
                            border: isUser
                                ? null
                                : Border.all(
                                    color: isErrorMsg
                                        ? Colors.redAccent.withValues(alpha: 0.3)
                                        : Colors.white.withValues(alpha: 0.08),
                                  ),
                          ),
                          child: SelectableText(
                            msg.text,
                            style: TextStyle(
                              color: isUser ? Colors.white : (isErrorMsg ? const Color(0xFFFF8888) : Colors.white),
                              fontSize: 15,
                              height: 1.5,
                            ),
                          ),
                        ),
                        if (isErrorMsg)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              icon: const Icon(LucideIcons.rotateCcw, size: 12, color: VajraColors.accent),
                              label: const Text('Retry', style: TextStyle(color: VajraColors.accent, fontSize: 12)),
                              onPressed: () => ref.read(companionProvider.notifier).retryLastMessage(),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Live Listening Bar (renders when VAJRA is actively listening)
            if (isListening)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF11141A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.35), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Colors.greenAccent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'LISTENING',
                            style: TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        voiceState.partialTranscript.isNotEmpty
                            ? voiceState.partialTranscript
                            : 'Listening to your voice...',
                        style: TextStyle(
                          color: voiceState.partialTranscript.isNotEmpty ? Colors.white : Colors.white54,
                          fontSize: 13,
                          fontStyle: voiceState.partialTranscript.isEmpty ? FontStyle.italic : FontStyle.normal,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Subtle dynamic waveform bars reflecting normalized audio volume
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(4, (i) {
                        final factors = [0.6, 1.0, 0.75, 0.5];
                        final h = (6.0 + (voiceState.soundLevel * 14.0 * factors[i])).clamp(4.0, 20.0);
                        return Container(
                          width: 3,
                          height: h,
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

            // Live Speaking Bar (renders when VAJRA is actively speaking)
            if (isSpeaking)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF101726),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: VajraColors.accent.withValues(alpha: 0.4), width: 1.2),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: VajraColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: VajraColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'SPEAKING',
                            style: TextStyle(
                              color: VajraColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'VAJRA is speaking... Tap button to stop',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(4, (i) {
                        final heights = [10.0, 18.0, 14.0, 8.0];
                        return Container(
                          width: 3,
                          height: heights[i],
                          margin: const EdgeInsets.symmetric(horizontal: 1.5),
                          decoration: BoxDecoration(
                            color: VajraColors.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

            // Input Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF0C0C0C),
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181818),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: TextField(
                        controller: _inputController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        textInputAction: TextInputAction.send,
                        maxLines: 4,
                        minLines: 1,
                        decoration: const InputDecoration(
                          hintText: 'Message VAJRA...',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: isStreaming ? null : (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Accessible Voice Microphone / Interrupt Affordance (Minimum 48x48 touch target)
                  Semantics(
                    button: true,
                    label: isSpeaking
                        ? 'Stop speaking'
                        : (isListening ? 'Stop listening' : 'Start voice recognition'),
                    hint: isSpeaking
                        ? 'Double tap to stop VAJRA from speaking'
                        : (isListening ? 'Double tap to stop listening' : 'Double tap to speak with VAJRA'),
                    child: GestureDetector(
                      onTap: () {
                        if (isSpeaking) {
                          ref.read(voiceEngineProvider.notifier).stopSpeech();
                        } else if (isListening) {
                          ref.read(voiceEngineProvider.notifier).cancelListening();
                        } else if (!isStreaming) {
                          ref.read(voiceEngineProvider.notifier).startListening();
                        }
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                        decoration: BoxDecoration(
                          color: isSpeaking
                              ? VajraColors.accent.withValues(alpha: 0.2)
                              : (isListening
                                  ? Colors.redAccent.withValues(alpha: 0.2)
                                  : const Color(0xFF1C1C22)),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSpeaking
                                ? VajraColors.accent
                                : (isListening ? Colors.redAccent : Colors.white12),
                            width: (isSpeaking || isListening) ? 2.0 : 1.5,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            isSpeaking
                                ? LucideIcons.square
                                : (isListening ? LucideIcons.micOff : LucideIcons.mic),
                            color: isSpeaking
                                ? VajraColors.accent
                                : (isListening ? Colors.redAccent : Colors.white70),
                            size: isSpeaking ? 16 : 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: (isStreaming || !_isComposing) ? null : () => _sendMessage(),
                    child: Container(
                      width: 48,
                      height: 48,
                      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      decoration: BoxDecoration(
                        color: (isStreaming || !_isComposing)
                            ? const Color(0xFF222222)
                            : const Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          LucideIcons.arrowUp,
                          color: (isStreaming || !_isComposing) ? Colors.grey : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
