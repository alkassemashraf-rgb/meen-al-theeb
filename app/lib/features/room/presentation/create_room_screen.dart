import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../services/auth/auth_service.dart';
import '../data/room_repository.dart';
import '../../../shared/components/game_button.dart';
import '../../../shared/components/page_container.dart';
import '../../../shared/components/avatar_widget.dart';
import '../../../core/theme/app_colors.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final _nameController = TextEditingController();
  String _selectedAvatar = 'avatar_1';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال اسمك')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authServiceProvider);
      var user = ref.read(authStateProvider).value;
      
      if (user == null) {
        user = (await auth.signInAnonymously()).user;
      }

      if (user != null && mounted) {
        final room = await ref.read(roomRepositoryProvider).createRoom(
          hostId: user.uid,
          hostName: name,
          avatarId: _selectedAvatar,
        );
        
        if (mounted) {
          context.go('/room/${room.roomId}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      backgroundGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1330), Color(0xFF2D1B69)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                onPressed: () => context.pop(),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'إنشاء غرفة',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 48), // Spacer for balance
            ],
          ),
          const SizedBox(height: 32),
          
          Hero(
            tag: 'logo',
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(child: Text('🐺', style: TextStyle(fontSize: 40))),
            ),
          ),
          const SizedBox(height: 32),

          Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.white10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
                labelStyle: const TextStyle(color: Colors.white70),
                hintStyle: const TextStyle(color: Colors.white30),
              ),
            ),
            child: TextField(
              controller: _nameController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: const InputDecoration(
                labelText: 'اسم العرض',
                hintText: 'أدخل اسمك هنا',
                prefixIcon: Icon(Icons.person_outline, color: Colors.white54),
              ),
            ),
          ),
          
          const SizedBox(height: 48),
          
          const Text(
            'اختر شخصيتك',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          GestureDetector(
            onTap: () async {
              final result = await context.push<String>(
                '/select-avatar?initialId=$_selectedAvatar',
              );
              if (result != null) {
                setState(() => _selectedAvatar = result);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: AvatarWidget(
                avatarUrlOrId: _selectedAvatar,
                size: 110,
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'اضغط للتغيير',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
          
          const Spacer(),
          
          GameButton(
            text: 'إنشاء الغرفة والدخول',
            isLoading: _isLoading,
            onPressed: _handleCreate,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
