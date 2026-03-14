import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class RoundedCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double elevation;

  const RoundedCard({
    super.key,
    required this.child,
    this.color,
    this.gradient,
    this.padding = const EdgeInsets.all(24.0),
    this.onTap,
    this.elevation = 4.0,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppTheme.animationFast,
      decoration: BoxDecoration(
        color: color ?? (gradient == null ? Colors.white : null),
        gradient: gradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05 + (elevation * 0.01)),
            blurRadius: 10 + elevation,
            offset: Offset(0, elevation),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
