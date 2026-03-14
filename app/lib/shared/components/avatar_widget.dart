import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'avatar_asset.dart';

class AvatarWidget extends StatelessWidget {
  final String avatarUrlOrId;
  final double size;
  final String? emotionState;
  final VoidCallback? onTap;
  final bool isSelected;
  final bool isWinner;

  const AvatarWidget({
    super.key,
    required this.avatarUrlOrId,
    this.size = 64.0,
    this.emotionState,
    this.onTap,
    this.isSelected = false,
    this.isWinner = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: _LoopingBreather(
        enabled: !isSelected && !isWinner && emotionState == null,
        child: RepaintBoundary(
          child: AnimatedScale(
            scale: isSelected ? 1.15 : 1.0,
            duration: AppTheme.animationFast,
            curve: Curves.elasticOut,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Reaction Pulse Effect
                if (emotionState != null)
                  _PulseEffect(size: size),

              // Avatar Background and Border
              AnimatedContainer(
                duration: AppTheme.animationFast,
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: isWinner 
                      ? AppColors.accent.withOpacity(0.3) 
                      : AppColors.secondary.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isWinner ? AppColors.accent : AppColors.primary, 
                    width: isWinner ? 4 : 2,
                  ),
                  boxShadow: [
                    if (isWinner)
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.6),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    if (isSelected)
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                  ],
                ),
                child: AvatarAsset(
                  avatarId: avatarUrlOrId,
                  size: size,
                ),
              ),

              // Winner Crown
              if (isWinner)
                Positioned(
                  top: -size * 0.35,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.backOut,
                    builder: (context, value, child) {
                      return Transform.translate(
                        offset: Offset(0, (1 - value) * -20),
                        child: Transform.scale(
                          scale: value,
                          child: Text(
                            '👑', 
                            style: TextStyle(fontSize: size * 0.6),
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // Emotion Overlay (Layered)
              if (emotionState != null)
                Positioned.fill(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (value * 0.4),
                        child: Opacity(
                          opacity: value.clamp(0.0, 1.0),
                          child: Center(
                            child: _getEmotionOverlay(emotionState!, size),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getEmotionOverlay(String emotion, double baseSize) {
    return Text(
      emotion,
      style: TextStyle(fontSize: baseSize * 0.7),
    );
  }
}

class _LoopingBreather extends StatefulWidget {
  final Widget child;
  final bool enabled;
  const _LoopingBreather({required this.child, required this.enabled});

  @override
  State<_LoopingBreather> createState() => _LoopingBreatherState();
}

class _LoopingBreatherState extends State<_LoopingBreather> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

class _PulseEffect extends StatefulWidget {
  final double size;
  const _PulseEffect({required this.size});

  @override
  State<_PulseEffect> createState() => _PulseEffectState();
}

class _PulseEffectState extends State<_PulseEffect> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _opacity = Tween<double>(begin: 0.4, end: 0.0).animate(_controller);
    _scale = Tween<double>(begin: 1.0, end: 1.4).animate(_controller);
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
        return Container(
          width: widget.size * _scale.value,
          height: widget.size * _scale.value,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary.withOpacity(_opacity.value),
          ),
        );
      },
    );
  }
}
