import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../providers/companion_provider.dart';
import '../models/avatar_state.dart';
import '../../../shared/widgets/vajra_avatar.dart' as ui;

class CompanionScreen extends ConsumerWidget {
  const CompanionScreen({super.key});

  ui.AvatarState _mapState(AvatarState modelState) {
    switch (modelState) {
      case AvatarState.idle: return ui.AvatarState.idle;
      case AvatarState.listening: return ui.AvatarState.listening;
      case AvatarState.thinking: return ui.AvatarState.thinking;
      case AvatarState.searching: return ui.AvatarState.focused;
      case AvatarState.planning: return ui.AvatarState.focused;
      case AvatarState.speaking: return ui.AvatarState.speaking;
      case AvatarState.error: return ui.AvatarState.sleeping;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(companionProvider);
    final notifier = ref.read(companionProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      body: SafeArea(
        child: Column(
          children: [
            // Avatar Area (Placeholder for Rive)
            Expanded(
              flex: 2,
              child: Center(
                child: ui.VajraAvatar(
                  size: 150,
                  state: _mapState(state.avatarState),
                ),
              ),
            ),
            
            // Conversation Area
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final msg = state.messages[index];
                          final isUser = msg.startsWith("User:");
                          return Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isUser ? Colors.white : const Color(0xFF111111),
                                borderRadius: BorderRadius.circular(16),
                                border: isUser ? null : Border.all(color: Colors.white.withValues(alpha: 0.05)),
                              ),
                              child: Text(
                                msg.replaceFirst(isUser ? "User: " : "VAJRA: ", ""),
                                style: TextStyle(
                                  color: isUser ? Colors.black : Colors.white,
                                  fontSize: 15,
                                  height: 1.5
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Streaming Text & Cursor
                    if (state.activeStreamText.isNotEmpty || state.avatarState == AvatarState.thinking)
                      Container(
                        padding: const EdgeInsets.all(16),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111111),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (state.avatarState == AvatarState.thinking || state.avatarState == AvatarState.searching || state.avatarState == AvatarState.planning)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      state.avatarState == AvatarState.planning ? LucideIcons.calendar 
                                      : state.avatarState == AvatarState.searching ? LucideIcons.search
                                      : LucideIcons.brain, 
                                      color: Colors.grey[500], size: 14
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      state.avatarState == AvatarState.planning ? "Planning Schedule..." 
                                      : state.avatarState == AvatarState.searching ? "Searching Memory..."
                                      : "Thinking...",
                                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            if (state.activeStreamText.isNotEmpty)
                              Text(
                                "${state.activeStreamText} █",
                                style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                              ),
                          ],
                        ),
                      ),
                      
                    // Input Area
                    Container(
                      margin: const EdgeInsets.only(bottom: 24, top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF111111),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Message VAJRA...',
                                hintStyle: TextStyle(color: Colors.grey),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (val) {
                                if (val.isNotEmpty) notifier.sendMessage(val);
                              },
                            ),
                          ),
                          // Voice Button
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(LucideIcons.mic, color: Colors.white, size: 20),
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

