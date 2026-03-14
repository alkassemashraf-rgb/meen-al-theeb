import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth/auth_service.dart';
import '../data/room_repository.dart';
import '../../../shared/components/game_button.dart';
import '../../../shared/components/page_container.dart';
import '../../../shared/components/avatar_widget.dart';
import '../../../core/theme/app_colors.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedAvatar = 'avatar_1';
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleJoin() async {
    final code = _codeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();

    if (code.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء تعبئة جميع الحقول')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authServiceProvider);
      var user = ref.read(authStateProvider).value;
      
      if (user == null) {
        user = await auth.signInAnonymously();
      }

      if (user != null && mounted) {
        final roomId = await ref.read(roomRepositoryProvider).joinRoom(
          joinCode: code,
          playerId: user.uid,
          playerName: name,
          avatarId: _selectedAvatar,
        );
        
        if (mounted) {
          context.go('/room/$roomId');
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
      child: SingleChildScrollView(
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
                      'انضمام بالرمز',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
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
              child: Column(
                children: [
                  TextField(
                    controller: _codeController,
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      labelText: 'رمز الغرفة',
                      hintText: 'A7X9B',
                    ),
                    textCapitalization: TextCapitalization.characters,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'اسم العرض',
                      prefixIcon: Icon(Icons.person_outline, color: Colors.white54),
                    ),
                  ),
                ],
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
            
            const SizedBox(height: 64),
            
            GameButton(
              text: 'دخول للغرفة',
              isLoading: _isLoading,
              onPressed: _handleJoin,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
