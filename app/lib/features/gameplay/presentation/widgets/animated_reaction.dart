import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/reaction.dart';

/// Telegram-style emoji reaction animation.
///
/// Phases:
/// 1. Pop: scale 0.3 → 1.3 → 1.0 with elastic feel (first 25% of timeline)
/// 2. Burst: 5 mini-emoji particles radiate outward and fade (first 30%)
/// 3. Drift: emoji floats upward with slight rotation wobble
/// 4. Fade: opacity dissolves at the end
///
/// Total duration: 1200ms
class AnimatedReaction extends StatefulWidget {
  final Reaction reaction;
  final VoidCallback onComplete;

  const AnimatedReaction({
    super.key,
    required this.reaction,
    required this.onComplete,
  });

  @override
  State<AnimatedReaction> createState() => _AnimatedReactionState();
}

class _AnimatedReactionState extends State<AnimatedReaction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Main emoji
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<double> _yOffset;
  late double _xOffset;

  // Burst particles (driven by same controller, first 30% of timeline)
  late Animation<double> _burstOpacity;
  late Animation<double> _burstDist;

  // Burst particle angles (evenly spread in a ring)
  static const List<double> _burstAngles = [0.0, 72.0, 144.0, 216.0, 288.0];

  /// Wobble angle: sinusoidal micro-rotation during drift
  double get _wobble =>
      math.sin(_controller.value * math.pi * 3) * 0.14;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // --- Main emoji opacity: fade-in (15%), hold (55%), fade-out (30%) ---
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 55),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    // --- Main emoji scale: pop 0.3→1.3 (elastic, 25%), settle 1.3→1.0 (15%), hold (60%) ---
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.3, end: 1.3)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.3, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
    ]).animate(_controller);

    // --- Upward drift: 0 → -220px, easeOut ---
    _yOffset = Tween(begin: 0.0, end: -220.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // --- Random horizontal drift (seeded by reaction id) ---
    final rand = math.Random(widget.reaction.id.hashCode);
    _xOffset = (rand.nextDouble() - 0.5) * 120;

    // --- Burst particle distance: 0 → 55px over first 30% of timeline ---
    _burstDist = Tween(begin: 0.0, end: 55.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.30, curve: Curves.easeOut),
      ),
    );

    // --- Burst particle opacity: 1 → 0 over first 30% ---
    _burstOpacity = Tween(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.30, curve: Curves.easeIn),
      ),
    );

    _controller.forward().then((_) => widget.onComplete());
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
      builder: (context, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        final centerX = screenWidth / 2 + _xOffset;

        return Positioned(
          bottom: 100 + _yOffset.value.abs(),
          left: centerX - 20,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // Burst particles radiating outward from center
                ..._burstAngles.map((angleDeg) {
                  final rad = angleDeg * math.pi / 180;
                  final d = _burstDist.value;
                  return Positioned(
                    left: 20 + math.cos(rad) * d - 9,
                    top: 20 + math.sin(rad) * d - 9,
                    child: Opacity(
                      opacity: _burstOpacity.value,
                      child: Text(
                        widget.reaction.emoji,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  );
                }),

                // Main emoji with pop scale + wobble rotation + opacity
                Opacity(
                  opacity: _opacity.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: Transform.rotate(
                      angle: _wobble,
                      child: Text(
                        widget.reaction.emoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
