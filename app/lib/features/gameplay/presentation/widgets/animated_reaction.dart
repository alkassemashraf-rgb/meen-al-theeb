import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/reaction.dart';

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
  late Animation<double> _opacity;
  late Animation<double> _scale;
  late Animation<double> _yOffset;
  late double _xOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.5, end: 1.2).setCurve(Curves.backOut), 
        weight: 30,
      ),
      TweenSequenceItem(tween: ConstantTween(1.2), weight: 70),
    ]).animate(_controller);

    _yOffset = Tween(begin: 0.0, end: -300.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Random drift
    final rand = math.Random(widget.reaction.id.hashCode);
    _xOffset = (rand.nextDouble() - 0.5) * 100;

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
      builder: (context, child) {
        return Positioned(
          bottom: 100 + _yOffset.value.abs(),
          left: MediaQuery.of(context).size.width / 2 + _xOffset,
          child: Opacity(
            opacity: _opacity.value,
            child: Transform.scale(
              scale: _scale.value,
              child: Text(
                widget.reaction.emoji,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
        );
      },
    );
  }
}
