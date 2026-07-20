import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:rive/rive.dart';


enum AvatarState {
  idle,
  listening,
  thinking,
  speaking,
  charging,
  sleeping,
  focused,
  happy
}

class VajraAvatar extends StatefulWidget {
  final double size;
  final AvatarState state;

  const VajraAvatar({
    super.key,
    this.size = 200,
    this.state = AvatarState.idle,
  });

  @override
  State<VajraAvatar> createState() => _VajraAvatarState();
}

class _VajraAvatarState extends State<VajraAvatar> {
  StateMachineController? _controller;
  SMIBool? _isListening;
  SMIBool? _isThinking;
  SMIBool? _isSpeaking;
  
  bool _isLoading = true;
  bool _assetExists = false;

  @override
  void initState() {
    super.initState();
    _checkAsset();
  }

  Future<void> _checkAsset() async {
    try {
      await rootBundle.load('assets/animations/avatar.riv');
      if (mounted) {
        setState(() {
          _assetExists = true;
          _isLoading = false;
        });
      }
    } catch (_) {
      // Asset missing - gracefully fallback to pure Flutter implementation
      if (mounted) {
        setState(() {
          _assetExists = false;
          _isLoading = false;
        });
      }
    }
  }

  void _onRiveInit(Artboard artboard) {
    final controller = StateMachineController.fromArtboard(
      artboard,
      'AvatarStateMachine',
    );
    if (controller != null) {
      artboard.addController(controller);
      _controller = controller;
      _isListening = _controller?.findInput<bool>('isListening') as SMIBool?;
      _isThinking = _controller?.findInput<bool>('isThinking') as SMIBool?;
      _isSpeaking = _controller?.findInput<bool>('isSpeaking') as SMIBool?;
      _updateState();
    }
  }

  @override
  void didUpdateWidget(VajraAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state && _assetExists) {
      _updateState();
    }
  }

  void _updateState() {
    _isListening?.value = widget.state == AvatarState.listening;
    _isThinking?.value = widget.state == AvatarState.thinking;
    _isSpeaking?.value = widget.state == AvatarState.speaking;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(width: widget.size, height: widget.size);
    }

    if (!_assetExists) {
      return _FallbackAvatar(size: widget.size, state: widget.state);
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: RiveAnimation.asset(
        'assets/animations/avatar.riv',
        fit: BoxFit.contain,
        onInit: _onRiveInit,
      ),
    );
  }
}

class _FallbackAvatar extends StatefulWidget {
  final double size;
  final AvatarState state;

  const _FallbackAvatar({required this.size, required this.state});

  @override
  State<_FallbackAvatar> createState() => _FallbackAvatarState();
}

class _FallbackAvatarState extends State<_FallbackAvatar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _updateAnimationForState();
  }

  @override
  void didUpdateWidget(covariant _FallbackAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) {
      _updateAnimationForState();
    }
  }

  void _updateAnimationForState() {
    _controller.stop();
    switch (widget.state) {
      case AvatarState.idle:
        _controller.duration = const Duration(seconds: 3);
        _controller.repeat(reverse: true);
        break;
      case AvatarState.listening:
        _controller.duration = const Duration(seconds: 1);
        _controller.repeat(reverse: true);
        break;
      case AvatarState.thinking:
        _controller.duration = const Duration(seconds: 4);
        _controller.repeat(); 
        break;
      case AvatarState.speaking:
        _controller.duration = const Duration(milliseconds: 500);
        _controller.repeat(reverse: true);
        break;
      case AvatarState.sleeping:
        _controller.duration = const Duration(seconds: 4);
        _controller.repeat(reverse: true);
        break;
      case AvatarState.focused:
        _controller.duration = const Duration(seconds: 2);
        _controller.repeat(reverse: true);
        break;
      case AvatarState.happy:
        _controller.duration = const Duration(milliseconds: 800);
        _controller.repeat(reverse: true);
        break;
      case AvatarState.charging:
        _controller.duration = const Duration(seconds: 2);
        _controller.repeat(reverse: true);
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        double scale = 1.0;
        double glowOpacity = 0.3;
        double rotation = 0.0;
        double borderWidth = 2.0;

        switch (widget.state) {
          case AvatarState.idle:
            scale = 0.95 + (_controller.value * 0.05);
            break;
          case AvatarState.listening:
            glowOpacity = 0.3 + (_controller.value * 0.5);
            scale = 1.0;
            break;
          case AvatarState.thinking:
            rotation = _controller.value * 2 * math.pi;
            break;
          case AvatarState.speaking:
            scale = 1.0 + (_controller.value * 0.15);
            glowOpacity = 0.4 + (_controller.value * 0.4);
            break;
          case AvatarState.sleeping:
            glowOpacity = 0.1 + (_controller.value * 0.1);
            scale = 0.98;
            break;
          case AvatarState.focused:
            borderWidth = 2.0 + (_controller.value * 2.0);
            glowOpacity = 0.5;
            break;
          case AvatarState.happy:
            scale = 0.9 + (_controller.value * 0.2);
            glowOpacity = 0.4 + (_controller.value * 0.2);
            break;
          case AvatarState.charging:
            glowOpacity = 0.2 + (_controller.value * 0.6);
            scale = 1.0 + (_controller.value * 0.05);
            break;
        }

        return Transform.scale(
          scale: scale,
          child: Transform.rotate(
            angle: rotation,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF050505),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: glowOpacity),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.state == AvatarState.thinking)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.0),
                            Colors.white.withValues(alpha: 0.8),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  if (widget.state == AvatarState.thinking)
                    Container(
                      margin: const EdgeInsets.all(2), // Defines the thickness of the light ring
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF050505),
                      ),
                    ),
                  if (widget.state != AvatarState.thinking)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                          width: borderWidth,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

