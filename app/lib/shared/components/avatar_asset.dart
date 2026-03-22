import 'package:flutter/material.dart';

const List<String> avatarEmojis = [
  '🐺', '🦊', '🐻', '🦁', '🐯', '🐼',
  '🐨', '🦝', '🐸', '🐙', '🦄', '🐲',
  '🦋', '🐬', '🦩', '🦉', '🦅', '🐳',
  '🦈', '🦎', '🐊', '🦜', '🐝', '🦔',
];

const List<List<Color>> _gradients = [
  [Color(0xFF6C5CE7), Color(0xFFA55EEA)], // purple
  [Color(0xFF00CEC9), Color(0xFF0984E3)], // teal-blue
  [Color(0xFFFDCB6E), Color(0xFFE17055)], // orange
  [Color(0xFFFF7675), Color(0xFFD63031)], // red-coral
  [Color(0xFF00B894), Color(0xFF00CEC9)], // green-teal
  [Color(0xFF74B9FF), Color(0xFF0984E3)], // sky-blue
];

class AvatarAsset extends StatelessWidget {
  final String avatarId;
  final double size;

  const AvatarAsset({
    super.key,
    required this.avatarId,
    required this.size,
  });

  int _getIndex() {
    final match = RegExp(r'\d+').firstMatch(avatarId);
    if (match != null) {
      return (int.parse(match.group(0)!) - 1).clamp(0, avatarEmojis.length - 1);
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _getIndex();
    final emoji = avatarEmojis[index];
    final gradientColors = _gradients[index % _gradients.length];

    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          ),
          child: Center(
            child: Text(
              emoji,
              style: TextStyle(fontSize: size * 0.52),
            ),
          ),
        ),
      ),
    );
  }
}
