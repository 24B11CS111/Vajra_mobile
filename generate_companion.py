import os

def write_file(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

base_dir = r"c:\Users\LENOVO\Desktop\VAJRA WORKSPACE\Apps\vajra_mobile\lib\features\companion"

# 1. models/chat_message.dart
write_file(os.path.join(base_dir, 'models', 'chat_message.dart'), '''import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required String text,
    required bool isUser,
    required DateTime timestamp,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
}
''')

# 2. services/fake_companion_service.dart
write_file(os.path.join(base_dir, 'services', 'fake_companion_service.dart'), '''import 'dart:math';
import '../models/chat_message.dart';

class FakeCompanionService {
  final _random = Random();
  
  Future<List<String>> getSuggestions() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      "Continue Studying",
      "Plan Today",
      "Summarize Notes",
      "Remember Something",
      "Start Focus Mode",
      "Assignments"
    ];
  }

  Future<ChatMessage> sendMessage(String text) async {
    await Future.delayed(const Duration(seconds: 1));
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: "Done. Everything has been organized.\\n\\nI've updated your schedule to reflect your recent changes.",
      isUser: false,
      timestamp: DateTime.now(),
    );
  }
}
''')

# 3. providers/companion_provider.dart
write_file(os.path.join(base_dir, 'providers', 'companion_provider.dart'), '''import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message.dart';
import '../services/fake_companion_service.dart';
import '../../../shared/widgets/vajra_avatar.dart';

final companionServiceProvider = Provider((ref) => FakeCompanionService());

final companionStateProvider = StateNotifierProvider<CompanionNotifier, CompanionState>((ref) {
  return CompanionNotifier(ref.read(companionServiceProvider));
});

class CompanionState {
  final List<ChatMessage> messages;
  final List<String> suggestions;
  final bool isTyping;
  final AvatarState avatarState;
  
  CompanionState({
    required this.messages,
    required this.suggestions,
    required this.isTyping,
    required this.avatarState,
  });

  CompanionState copyWith({
    List<ChatMessage>? messages,
    List<String>? suggestions,
    bool? isTyping,
    AvatarState? avatarState,
  }) {
    return CompanionState(
      messages: messages ?? this.messages,
      suggestions: suggestions ?? this.suggestions,
      isTyping: isTyping ?? this.isTyping,
      avatarState: avatarState ?? this.avatarState,
    );
  }
}

class CompanionNotifier extends StateNotifier<CompanionState> {
  final FakeCompanionService _service;
  
  CompanionNotifier(this._service) : super(CompanionState(
    messages: [
      ChatMessage(
        id: "1",
        text: "Good morning.\\nYou completed 3 tasks yesterday.\\n\\nYou have:\\n• Physics class at 9 AM\\n• Assignment due tomorrow",
        isUser: false,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      )
    ],
    suggestions: [],
    isTyping: false,
    avatarState: AvatarState.idle,
  )) {
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    final suggestions = await _service.getSuggestions();
    state = state.copyWith(suggestions: suggestions);
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    final userMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isTyping: true,
      avatarState: AvatarState.thinking,
      suggestions: [],
    );
    
    final response = await _service.sendMessage(text);
    
    state = state.copyWith(
      messages: [...state.messages, response],
      isTyping: false,
      avatarState: AvatarState.idle,
    );
    _loadSuggestions();
  }
}
''')

# 4. presentation/widgets/companion_avatar_section.dart
write_file(os.path.join(base_dir, 'presentation', 'widgets', 'companion_avatar_section.dart'), '''import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/widgets/vajra_avatar.dart';
import '../../../../core/theme/vajra_colors.dart';

class CompanionAvatarSection extends StatelessWidget {
  final AvatarState state;

  const CompanionAvatarSection({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 32),
        VajraAvatar(
          size: 160, // A bit smaller than full screen, as it's part of chat
          state: state,
        ).animate().fadeIn(duration: 800.ms).scale(duration: 800.ms, curve: Curves.easeOutQuart),
        const SizedBox(height: 16),
        Text(
          'VAJRA',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: VajraColors.primaryText,
          ),
        ).animate().fadeIn(delay: 400.ms, duration: 600.ms),
        const SizedBox(height: 4),
        Text(
          'Always With You',
          style: TextStyle(
            fontSize: 14,
            color: VajraColors.secondaryText,
          ),
        ).animate().fadeIn(delay: 600.ms, duration: 600.ms),
      ],
    );
  }
}
''')

# 5. presentation/widgets/greeting_card.dart
write_file(os.path.join(base_dir, 'presentation', 'widgets', 'greeting_card.dart'), '''import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/vajra_colors.dart';
import '../../../../shared/widgets/glass_container.dart';

class GreetingCard extends StatelessWidget {
  const GreetingCard({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning.';
    if (hour < 17) return 'Good Afternoon.';
    if (hour < 21) return 'Good Evening.';
    return 'Good Night.';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getGreeting(), style: Theme.of(context).textTheme.displaySmall),
            const SizedBox(height: 16),
            const Text(
              "You're making great progress.\\n\\nYou have:\\n• Physics class at 9 AM\\n• Assignment due tomorrow\\n• Cricket practice at 6 PM",
              style: TextStyle(color: VajraColors.secondaryText, height: 1.6, fontSize: 15),
            ),
            const SizedBox(height: 24),
            const Text(
              "Ready to begin?",
              style: TextStyle(color: VajraColors.primaryText, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 600.ms).scaleXY(begin: 0.95, end: 1.0, curve: Curves.easeOut),
    );
  }
}
''')

# 6. presentation/widgets/message_bubble.dart
write_file(os.path.join(base_dir, 'presentation', 'widgets', 'message_bubble.dart'), '''import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/vajra_colors.dart';
import '../../../../shared/widgets/glass_container.dart';
import '../../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  // Very rudimentary markdown bullet support without adding dependencies
  List<Widget> _parseText(String text) {
    final lines = text.split('\\n');
    return lines.map((line) {
      if (line.startsWith('• ')) {
        return Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('• ', style: TextStyle(color: VajraColors.secondaryText)),
              Expanded(child: Text(line.substring(2), style: TextStyle(color: VajraColors.primaryText, height: 1.5))),
            ],
          ),
        );
      }
      return Text(line, style: TextStyle(color: message.isUser ? VajraColors.primaryText : VajraColors.secondaryText, height: 1.5));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final align = message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    
    Widget bubbleContent;
    if (message.isUser) {
      bubbleContent = Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: VajraColors.glassBorder),
          borderRadius: BorderRadius.circular(24).copyWith(bottomRight: const Radius.circular(8)),
          color: Colors.transparent,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _parseText(message.text),
        ),
      );
    } else {
      bubbleContent = GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _parseText(message.text),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: align,
        children: [
          bubbleContent,
          const SizedBox(height: 8),
          Text(
            '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 10, color: VajraColors.glassBorder),
          ),
        ],
      ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOut),
    );
  }
}
''')

# 7. presentation/widgets/suggestion_chip.dart
write_file(os.path.join(base_dir, 'presentation', 'widgets', 'suggestion_chip.dart'), '''import 'package:flutter/material.dart';
import '../../../../core/theme/vajra_colors.dart';
import '../../../../shared/widgets/glass_container.dart';

class SuggestionChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const SuggestionChip({super.key, required this.label, required this.onTap});

  @override
  State<SuggestionChip> createState() => _SuggestionChipState();
}

class _SuggestionChipState extends State<SuggestionChip> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedScale(
          scale: _isPressed ? 0.95 : (_isHovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: GlassContainer(
            borderRadius: 16,
            color: _isHovered ? VajraColors.elevatedSurface : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Center(
              child: Text(
                widget.label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: VajraColors.primaryText, fontSize: 13),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
''')

# 8. presentation/widgets/suggestion_grid.dart
write_file(os.path.join(base_dir, 'presentation', 'widgets', 'suggestion_grid.dart'), '''import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'suggestion_chip.dart';

class SuggestionGrid extends StatelessWidget {
  final List<String> suggestions;
  final Function(String) onSelected;

  const SuggestionGrid({super.key, required this.suggestions, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 2.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          return SuggestionChip(
            label: suggestions[index],
            onTap: () => onSelected(suggestions[index]),
          ).animate().fadeIn(delay: Duration(milliseconds: index * 50)).scale(duration: 300.ms, curve: Curves.easeOutBack);
        },
      ),
    );
  }
}
''')

# 9. presentation/widgets/companion_input.dart
write_file(os.path.join(base_dir, 'presentation', 'widgets', 'companion_input.dart'), '''import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/vajra_colors.dart';
import '../../../../shared/widgets/glass_container.dart';

class CompanionInput extends StatefulWidget {
  final Function(String) onSend;

  const CompanionInput({super.key, required this.onSend});

  @override
  State<CompanionInput> createState() => _CompanionInputState();
}

class _CompanionInputState extends State<CompanionInput> {
  final TextEditingController _controller = TextEditingController();

  void _submit() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSend(_controller.text);
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0).copyWith(bottom: MediaQuery.of(context).padding.bottom + 24),
      child: GlassContainer(
        borderRadius: 32,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(LucideIcons.paperclip, color: VajraColors.secondaryText),
              onPressed: () {},
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: VajraColors.primaryText),
                decoration: const InputDecoration(
                  hintText: 'Ask VAJRA anything...',
                  hintStyle: TextStyle(color: VajraColors.secondaryText),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            IconButton(
              icon: const Icon(LucideIcons.mic, color: VajraColors.secondaryText),
              onPressed: () {},
            ),
            Container(
              decoration: const BoxDecoration(shape: BoxShape.circle, color: VajraColors.primaryText),
              child: IconButton(
                icon: const Icon(LucideIcons.arrowUp, color: VajraColors.primaryBackground),
                onPressed: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
''')

# 10. presentation/widgets/typing_indicator.dart
write_file(os.path.join(base_dir, 'presentation', 'widgets', 'typing_indicator.dart'), '''import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/vajra_colors.dart';

class TypingIndicator extends StatelessWidget {
  const TypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: List.generate(3, (index) {
          return Container(
            margin: const EdgeInsets.only(right: 4),
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: VajraColors.secondaryText,
              shape: BoxShape.circle,
            ),
          ).animate(onPlay: (c) => c.repeat())
           .fade(duration: 400.ms, delay: Duration(milliseconds: index * 100))
           .scale(duration: 400.ms, delay: Duration(milliseconds: index * 100));
        }),
      ),
    );
  }
}
''')

# 11. presentation/screens/companion_screen.dart
write_file(os.path.join(base_dir, 'presentation', 'screens', 'companion_screen.dart'), '''import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/vajra_colors.dart';
import '../../providers/companion_provider.dart';
import '../widgets/companion_avatar_section.dart';
import '../widgets/greeting_card.dart';
import '../widgets/message_bubble.dart';
import '../widgets/suggestion_grid.dart';
import '../widgets/companion_input.dart';
import '../widgets/typing_indicator.dart';

class CompanionScreen extends ConsumerStatefulWidget {
  const CompanionScreen({super.key});

  @override
  ConsumerState<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends ConsumerState<CompanionScreen> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(companionStateProvider);
    ref.listen(companionStateProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length || next.isTyping) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: VajraColors.primaryBackground,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
              children: [
                CompanionAvatarSection(state: state.avatarState),
                const GreetingCard(),
                ...state.messages.map((m) => MessageBubble(message: m)),
                if (state.isTyping) const TypingIndicator(),
                if (state.suggestions.isNotEmpty)
                  SuggestionGrid(
                    suggestions: state.suggestions,
                    onSelected: (text) => ref.read(companionStateProvider.notifier).sendMessage(text),
                  ),
              ],
            ),
          ),
          CompanionInput(
            onSend: (text) => ref.read(companionStateProvider.notifier).sendMessage(text),
          ),
        ],
      ),
    );
  }
}
''')

print("Files generated.")
