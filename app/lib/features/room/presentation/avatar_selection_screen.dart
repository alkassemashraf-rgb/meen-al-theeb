import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/components/page_container.dart';
import '../../../shared/components/avatar_widget.dart';
import '../../../shared/components/game_button.dart';

class AvatarSelectionScreen extends ConsumerStatefulWidget {
  final String? initialAvatarId;
  final ValueChanged<String>? onSelected;

  const AvatarSelectionScreen({
    super.key,
    this.initialAvatarId,
    this.onSelected,
  });

  @override
  ConsumerState<AvatarSelectionScreen> createState() => _AvatarSelectionScreenState();
}

class _AvatarSelectionScreenState extends ConsumerState<AvatarSelectionScreen> {
  late String _selectedAvatarId;

  @override
  void initState() {
    super.initState();
    _selectedAvatarId = widget.initialAvatarId ?? 'avatar_1';
  }

  @override
  Widget build(BuildContext context) {
    final avatarIds = List.generate(24, (i) => 'avatar_${i + 1}');

    return PageContainer(
      title: 'اختر شخصيتك',
      backgroundGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1330), Color(0xFF2D1B69)],
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Preview Area
          Center(
            child: AvatarWidget(
              avatarUrlOrId: _selectedAvatarId,
              size: 150,
            ),
          ),
          const SizedBox(height: 32),
          // Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.0,
              ),
              itemCount: avatarIds.length,
              itemBuilder: (context, index) {
                final id = avatarIds[index];
                final isSelected = _selectedAvatarId == id;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAvatarId = id),
                  child: AvatarWidget(
                    avatarUrlOrId: id,
                    size: 80,
                    isSelected: isSelected,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: GameButton(
              text: 'تأكيد',
              onPressed: () {
                if (widget.onSelected != null) {
                  widget.onSelected!(_selectedAvatarId);
                }
                Navigator.pop(context, _selectedAvatarId);
              },
            ),
          ),
        ],
      ),
    );
  }
}
