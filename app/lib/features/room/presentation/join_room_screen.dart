import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/auth/auth_service.dart';
import '../data/room_repository.dart';
import '../../gameplay/domain/question_enums.dart';
import '../../../shared/components/game_button.dart';
import '../../../shared/components/page_container.dart';
import '../../../shared/components/avatar_widget.dart';
import '../../../core/theme/app_colors.dart';

class JoinRoomScreen extends ConsumerStatefulWidget {
  final String? prefilledCode;
  const JoinRoomScreen({super.key, this.prefilledCode});

  @override
  ConsumerState<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends ConsumerState<JoinRoomScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedAvatar = 'avatar_1';
  bool _isLoading = false;

  static const _kNameKey = 'player_name';

  @override
  void initState() {
    super.initState();
    if (widget.prefilledCode != null) {
      _codeController.text = widget.prefilledCode!;
    }
    _loadSavedName();
  }

  Future<void> _loadSavedName() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_kNameKey) ?? '';
    if (saved.isNotEmpty && mounted) {
      setState(() => _nameController.text = saved);
    }
  }

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
        user = (await auth.signInAnonymously()).user;
      }

      if (user != null && mounted) {
        // Pre-join: check ageMode and show confirmation if mature
        final ageMode = await ref
            .read(roomRepositoryProvider)
            .fetchRoomAgeModeByCode(code);

        if (mounted &&
            (ageMode == RoomAgeMode.plus18 || ageMode == RoomAgeMode.plus21)) {
          final confirmed = await _showAgeConfirmationDialog(ageMode);
          if (!mounted || confirmed != true) {
            setState(() => _isLoading = false);
            return;
          }
        }

        // Persist name for returning users
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kNameKey, name);

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

  Future<bool?> _showAgeConfirmationDialog(String ageMode) {
    final String ageBadge =
        ageMode == RoomAgeMode.plus21 ? '🍺 21+' : '🔞 18+';
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D1B69),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '$ageBadge هذه الغرفة للبالغين',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'قد تحتوي هذه الغرفة على أسئلة جريئة أو للبالغين',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6),
            Text(
              'This room may include mature or bold questions',
              style: TextStyle(color: Colors.white54, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'دخول',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      backgroundGradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1A1330), Color(0xFF2D1B69)],
      ),
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
