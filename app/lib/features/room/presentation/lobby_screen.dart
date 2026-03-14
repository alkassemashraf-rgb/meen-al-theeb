import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/room_repository.dart';
import '../domain/room.dart';
import '../domain/room_player.dart';
import '../../gameplay/data/game_session_repository.dart';
import '../../gameplay/data/question_pack_repository.dart';
import '../../gameplay/domain/question_pack.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/presence/presence_service.dart';
import '../../../shared/components/game_button.dart';
import '../../../shared/components/page_container.dart';
import '../../../shared/components/avatar_widget.dart';
import '../../../shared/components/rounded_card.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../core/theme/app_colors.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  final String roomId;
  const LobbyScreen({super.key, required this.roomId});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(presenceServiceProvider).trackPresence(widget.roomId);
    });
  }

  @override
  void dispose() {
    ref.read(presenceServiceProvider).stopTracking();
    super.dispose();
  }

  Future<void> _handleLeave(String playerId) async {
    try {
      await ref.read(roomRepositoryProvider).leaveRoom(widget.roomId, playerId);
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في المغادرة: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomStream = ref.watch(roomStreamProvider(widget.roomId));
    final currentUser = ref.watch(authStateProvider).value;

    ref.listen(roomStreamProvider(widget.roomId), (previous, next) {
      if (next.value?.status == 'gameplay') {
        context.go('/gameplay/${widget.roomId}');
      }
    });

    return roomStream.when(
      data: (room) {
        if (room == null || room.status == 'ended') {
          return const _RoomEndedView();
        }

        final players = room.players.values.toList();
        final isHost = room.hostId == currentUser?.uid;

        return PageContainer(
          title: 'غرفة الانتظار',
          child: Column(
            children: [
              RoundedCard(
                child: Column(
                  children: [
                    const Text('رمز الغرفة', style: TextStyle(color: Colors.grey)),
                    Text(
                      room.joinCode,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.builder(
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    return _PlayerTile(player: player);
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (isHost) ...[
                _PackPicker(roomId: widget.roomId),
                const SizedBox(height: 16),
                GameButton(
                  text: 'ابدأ اللعبة',
                  onPressed: players.length >= 2
                      ? () => _onStartGame(context)
                      : null,
                ),
                const SizedBox(height: 8),
                if (players.length < 2)
                  const Text(
                    'بانتظار لاعبين اثنين على الأقل...',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
              ] else
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'المضيف يختار مجموعة الأسئلة',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _handleLeave(currentUser!.uid),
                child: Text(
                  isHost ? 'إنهاء الغرفة' : 'مغادرة',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const PageContainer(
        child: LoadingState(message: 'جاري تحميل الغرفة...'),
      ),
      error: (e, st) => PageContainer(
        child: ErrorState(
          message: e.toString(),
          onRetry: () => ref.refresh(roomStreamProvider(widget.roomId)),
        ),
      ),
    );
  }

  Future<void> _onStartGame(BuildContext context) async {
    final packId = ref.read(selectedPackProvider(widget.roomId));
    try {
      await ref
          .read(gameSessionRepositoryProvider)
          .startGame(widget.roomId, packId: packId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting game: $e')),
        );
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Pack Picker
// ---------------------------------------------------------------------------

class _PackPicker extends ConsumerWidget {
  final String roomId;
  const _PackPicker({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packsAsync = ref.watch(allPacksProvider);
    final selectedPackId = ref.watch(selectedPackProvider(roomId));

    return packsAsync.when(
      loading: () => const SizedBox(
        height: 110,
        child: LoadingState(),
      ),
      error: (e, __) => ErrorState(message: e.toString()),
      data: (packs) {
        if (packs.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'اختر مجموعة الأسئلة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                itemCount: packs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final pack = packs[index];
                  final isSelected = selectedPackId == pack.packId;
                  return _PackCard(
                    pack: pack,
                    isSelected: isSelected,
                    onTap: () {
                      ref
                          .read(selectedPackProvider(roomId).notifier)
                          .state = pack.packId;
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PackCard extends StatelessWidget {
  final QuestionPack pack;
  final bool isSelected;
  final VoidCallback onTap;

  const _PackCard({
    required this.pack,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isSelected ? 1.05 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 130,
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.2),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.4)
                    : Colors.black.withOpacity(0.1),
                blurRadius: isSelected ? 16 : 8,
                spreadRadius: isSelected ? 2 : 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (isSelected)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(pack.icon, style: const TextStyle(fontSize: 32)),
                    const SizedBox(height: 8),
                    Text(
                      pack.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isSelected ? AppColors.primary : Colors.grey).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${pack.questionCount} سؤال',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared provider
// ---------------------------------------------------------------------------

final roomStreamProvider = StreamProvider.family<Room?, String>((ref, roomId) {
  return ref.watch(roomRepositoryProvider).observeRoom(roomId);
});

// ---------------------------------------------------------------------------
// Player tile
// ---------------------------------------------------------------------------

class _PlayerTile extends StatelessWidget {
  final RoomPlayer player;
  const _PlayerTile({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: player.isPresent ? Colors.white10 : Colors.white.withOpacity(0.05),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: player.isPresent ? AppColors.primary.withOpacity(0.5) : Colors.transparent,
              width: 2,
            ),
          ),
          child: AvatarWidget(avatarUrlOrId: player.avatarId, size: 48),
        ),
        title: Text(
          player.displayName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            decoration: player.isPresent ? null : TextDecoration.lineThrough,
          ),
        ),
        subtitle: Row(
          children: [
            Icon(
              player.isHost ? Icons.star : Icons.person,
              size: 14,
              color: player.isHost ? AppColors.accent : Colors.white54,
            ),
            const SizedBox(width: 4),
            Text(
              player.isHost ? 'المضيف (قائد القطيع)' : 'لاعب مستعد',
              style: TextStyle(
                color: player.isHost ? AppColors.accent : Colors.white54,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: player.isPresent ? Colors.green : Colors.grey,
            boxShadow: [
              if (player.isPresent)
                BoxShadow(
                  color: Colors.green.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Room ended view
// ---------------------------------------------------------------------------

class _RoomEndedView extends StatelessWidget {
  const _RoomEndedView();

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      title: 'انتهت الغرفة',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('لقد غادر المضيف أو تم إغلاق الغرفة.'),
          const SizedBox(height: 24),
          GameButton(
            text: 'العودة للرئيسية',
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
    );
  }
}
