import 'package:flutter/material.dart';

class AvatarConfig {
  final int sheetIndex; // 1, 2, or 3
  final int row; // 0 or 1
  final int col; // 0, 1, or 2

  const AvatarConfig({
    required this.sheetIndex,
    required this.row,
    required this.col,
  });

  String get assetPath => 'assets/avatars/set$sheetIndex.png';

  // Each sheet has 3 columns and 2 rows
  Alignment get alignment {
    // col 0 = -1.0, col 1 = 0.0, col 2 = 1.0
    // row 0 = -1.0, row 1 = 1.0
    final x = (col - 1).toDouble();
    final y = row == 0 ? -1.0 : 1.0;
    return Alignment(x, y);
  }
}

const Map<String, AvatarConfig> avatarRegistry = {
  // Set 1
  'avatar_1': AvatarConfig(sheetIndex: 1, row: 0, col: 0),
  'avatar_2': AvatarConfig(sheetIndex: 1, row: 0, col: 1),
  'avatar_3': AvatarConfig(sheetIndex: 1, row: 0, col: 2),
  'avatar_4': AvatarConfig(sheetIndex: 1, row: 1, col: 0),
  'avatar_5': AvatarConfig(sheetIndex: 1, row: 1, col: 1),
  'avatar_6': AvatarConfig(sheetIndex: 1, row: 1, col: 2),
  // Set 2
  'avatar_7': AvatarConfig(sheetIndex: 2, row: 0, col: 0),
  'avatar_8': AvatarConfig(sheetIndex: 2, row: 0, col: 1),
  'avatar_9': AvatarConfig(sheetIndex: 2, row: 0, col: 2),
  'avatar_10': AvatarConfig(sheetIndex: 2, row: 1, col: 0),
  'avatar_11': AvatarConfig(sheetIndex: 2, row: 1, col: 1),
  'avatar_12': AvatarConfig(sheetIndex: 2, row: 1, col: 2),
  // Set 3
  'avatar_13': AvatarConfig(sheetIndex: 3, row: 0, col: 0),
  'avatar_14': AvatarConfig(sheetIndex: 3, row: 0, col: 1),
  'avatar_15': AvatarConfig(sheetIndex: 3, row: 0, col: 2),
  'avatar_16': AvatarConfig(sheetIndex: 3, row: 1, col: 0),
  'avatar_17': AvatarConfig(sheetIndex: 3, row: 1, col: 1),
  'avatar_18': AvatarConfig(sheetIndex: 3, row: 1, col: 2),
  // Set 4
  'avatar_19': AvatarConfig(sheetIndex: 4, row: 0, col: 0),
  'avatar_20': AvatarConfig(sheetIndex: 4, row: 0, col: 1),
  'avatar_21': AvatarConfig(sheetIndex: 4, row: 0, col: 2),
  'avatar_22': AvatarConfig(sheetIndex: 4, row: 1, col: 0),
  'avatar_23': AvatarConfig(sheetIndex: 4, row: 1, col: 1),
  'avatar_24': AvatarConfig(sheetIndex: 4, row: 1, col: 2),
};

class AvatarAsset extends StatelessWidget {
  final String avatarId;
  final double size;

  const AvatarAsset({
    super.key,
    required this.avatarId,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final config = avatarRegistry[avatarId] ?? avatarRegistry['avatar_1']!;
    
    return SizedBox(
      width: size,
      height: size,
      child: ClipOval(
        child: Container(
          color: _getBackgroundColor(avatarId),
          child: OverflowBox(
            maxWidth: size * 3, // Each sheet is 3 columns wide
            maxHeight: size * 2, // Each sheet is 2 rows high
            alignment: config.alignment,
            child: Image.asset(
              config.assetPath,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(String id) {
    // Map of colors from the design palette
    final colors = [
      const Color(0xFF6C5CE7), // Purple
      const Color(0xFF00CEC9), // Teal
      const Color(0xFFFDCB6E), // Yellow
      const Color(0xFFFF7675), // Coral
    ];
    
    // Deterministic color based on avatar ID
    final index = id.hashCode.abs() % colors.length;
    return colors[index];
  }
}
