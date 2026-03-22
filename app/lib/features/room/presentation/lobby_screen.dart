import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/room_repository.dart';
import '../domain/room.dart';
import '../domain/room_player.dart';
import '../../gameplay/data/game_session_repository.dart';
import '../../gameplay/data/question_pack_repository.dart';
import '../../../services/auth/auth_service.dart';
import '../../../services/presence/presence_service.dart';
import '../../../shared/components/game_button.dart';
import '../../../shared/components/page_container.dart';
import '../../../shared/components/avatar_widget.dart';
import '../../../shared/components/rounded_card.dart';
import '../../../shared/utils/ui_helpers.dart';
import '../../../core/theme/app_colors.dart';
import '../../gameplay/domain/insufficient_questions_exception.dart';
import '../../gameplay/domain/question_enums.dart';
import '../../gameplay/data/gameplay_analytics.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  final String roomId;
  const LobbyScreen({super.key, required this.roomId});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  late final _presenceService = ref.read(presenceServiceProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _presenceService.trackPresence(widget.roomId);
    });
  }

  @override
  void dispose() {
    _presenceService.stopTracking();
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
    final currentAgeMode =
        ref.watch(roomAgeModeStreamProvider(widget.roomId)).valueOrNull ??
        'standard';

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
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1330), Color(0xFF2D1B69)],
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RoundedCard(
                  color: Colors.white.withOpacity(0.12),
                  child: Column(
                    children: [
                      const Text('رمز الغرفة', style: TextStyle(color: Colors.white70)),
                      Text(
                        room.joinCode,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                          color: Colors.white,
                        ),
                      ),
                      if (currentAgeMode != 'standard') ...[
                        const SizedBox(height: 8),
                        _AgeBadge(ageMode: currentAgeMode),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final player = players[index];
                    return _PlayerTile(key: ValueKey(player.playerId), player: player);
                  },
                ),
                const SizedBox(height: 16),
                if (isHost) ...[
                  _MultiPackPicker(roomId: widget.roomId),
                  const SizedBox(height: 12),
                  _RoundCountPicker(roomId: widget.roomId),
                  const SizedBox(height: 12),
                  _IntensityPicker(roomId: widget.roomId),
                  const SizedBox(height: 12),
                  _AgeModePicker(roomId: widget.roomId),
                  const SizedBox(height: 16),
                  _RoomSummary(roomId: widget.roomId),
                  const SizedBox(height: 12),
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
                      textAlign: TextAlign.center,
                    ),
                ] else ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: Text(
                      'المضيف يختار الإعدادات',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  _NonHostCategoryDisplay(roomId: widget.roomId),
                ],
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _handleLeave(currentUser!.uid),
                  child: Text(
                    isHost ? 'إنهاء الغرفة' : 'مغادرة',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
      loading: () => const PageContainer(
        backgroundGradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1330), Color(0xFF2D1B69)],
        ),
        child: LoadingState(message: 'جاري تحميل الغرفة...'),
      ),
      error: (e, st) => PageContainer(
        backgroundGradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1330), Color(0xFF2D1B69)],
        ),
        child: ErrorState(
          message: e.toString(),
          onRetry: () => ref.refresh(roomStreamProvider(widget.roomId)),
        ),
      ),
    );
  }

  Future<void> _onStartGame(BuildContext context) async {
    final packIds = ref.read(selectedPackIdsProvider(widget.roomId));
    final maxRounds = ref.read(selectedRoundCountProvider(widget.roomId));
    final intensityLevel = ref.read(selectedIntensityProvider(widget.roomId));
    final ageMode = ref.read(selectedAgeModeProvider(widget.roomId));
    try {
      await ref
          .read(gameSessionRepositoryProvider)
          .startGame(
            widget.roomId,
            packIds: packIds.isEmpty ? null : packIds,
            maxRounds: maxRounds,
            intensityLevel: intensityLevel,
            ageMode: ageMode,
          );
    } on InsufficientQuestionsException catch (e) {
      GameplayAnalytics.insufficientQuestionsBlocked(
        roomId: widget.roomId,
        requested: e.requestedRounds,
        available: e.availableQuestions,
        packIds: e.packIds,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.messageAr,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  e.messageEn,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade800,
            duration: const Duration(seconds: 6),
          ),
        );
      }
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
// Multi Pack Picker
// ---------------------------------------------------------------------------

class _MultiPackPicker extends ConsumerWidget {
  final String roomId;
  const _MultiPackPicker({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packsAsync = ref.watch(allPacksProvider);
    final selectedIds = ref.watch(selectedPackIdsProvider(roomId));

    return packsAsync.when(
      loading: () => const SizedBox(height: 50, child: LoadingState()),
      error: (e, __) => const SizedBox.shrink(),
      data: (packs) {
        if (packs.isEmpty) return const SizedBox.shrink();

        // Auto-select all packs the first time data loads (nothing selected yet).
        // This makes "all categories" the visible default so the host can
        // deliberately deselect packs they don't want instead of starting blind.
        if (selectedIds.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedPackIdsProvider(roomId).notifier).state =
                packs.map((p) => p.packId).toList();
          });
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'فئات الأسئلة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Select-all / deselect-all toggle
                GestureDetector(
                  onTap: () {
                    final allSelected = packs.every(
                        (p) => selectedIds.contains(p.packId));
                    ref.read(selectedPackIdsProvider(roomId).notifier).state =
                        allSelected
                            ? []
                            : packs.map((p) => p.packId).toList();
                  },
                  child: Text(
                    packs.every((p) => selectedIds.contains(p.packId))
                        ? 'إلغاء تحديد الكل'
                        : 'تحديد الكل',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: packs.map((pack) {
                final isSelected = selectedIds.contains(pack.packId);
                return GestureDetector(
                  onTap: () {
                    final current = ref.read(selectedPackIdsProvider(roomId));
                    if (isSelected) {
                      ref.read(selectedPackIdsProvider(roomId).notifier).state =
                          current.where((id) => id != pack.packId).toList();
                    } else {
                      ref.read(selectedPackIdsProvider(roomId).notifier).state =
                          [...current, pack.packId];
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : Colors.white24,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(pack.icon, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          pack.name,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 13,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.check, size: 14, color: Colors.white),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Non-host category display (read-only)
// ---------------------------------------------------------------------------

class _NonHostCategoryDisplay extends ConsumerWidget {
  final String roomId;
  const _NonHostCategoryDisplay({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packsAsync = ref.watch(allPacksProvider);
    final selectedIds = ref.watch(selectedPackIdsProvider(roomId));

    return packsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (packs) {
        if (packs.isEmpty || selectedIds.isEmpty) return const SizedBox.shrink();
        final selectedPacks =
            packs.where((p) => selectedIds.contains(p.packId)).toList();
        if (selectedPacks.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selectedPacks
                .map((p) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        '${p.icon} ${p.name}',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 12),
                      ),
                    ))
                .toList(),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Round Count Picker
// ---------------------------------------------------------------------------

class _RoundCountPicker extends ConsumerWidget {
  final String roomId;
  const _RoundCountPicker({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCount = ref.watch(selectedRoundCountProvider(roomId));
    const counts = [5, 7, 10, 15, 20];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'عدد الجولات',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: counts.map((count) {
            final isSelected = selectedCount == count;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  ref
                      .read(selectedRoundCountProvider(roomId).notifier)
                      .state = count;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.white24,
                    ),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Shared providers
// ---------------------------------------------------------------------------

final roomStreamProvider = StreamProvider.family<Room?, String>((ref, roomId) {
  return ref.watch(roomRepositoryProvider).observeRoom(roomId);
});

final selectedIntensityProvider = StateProvider.family<String, String>(
  (ref, _) => IntensityLevel.medium,
);

final selectedAgeModeProvider = StateProvider.family<String, String>(
  (ref, _) => RoomAgeMode.standard,
);

final roomAgeModeStreamProvider = StreamProvider.family<String, String>(
  (ref, roomId) =>
      ref.watch(roomRepositoryProvider).observeRoomAgeMode(roomId),
);

// ---------------------------------------------------------------------------
// Player tile
// ---------------------------------------------------------------------------

class _PlayerTile extends StatefulWidget {
  final RoomPlayer player;
  const _PlayerTile({super.key, required this.player});

  @override
  State<_PlayerTile> createState() => _PlayerTileState();
}

class _PlayerTileState extends State<_PlayerTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Container(
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
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Intensity Picker
// ---------------------------------------------------------------------------

class _IntensityPicker extends ConsumerWidget {
  final String roomId;
  const _IntensityPicker({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedIntensityProvider(roomId));

    const options = [
      (value: IntensityLevel.light,  label: '🌿 خفيف'),
      (value: IntensityLevel.medium, label: '🔥 متوسط'),
      (value: IntensityLevel.spicy,  label: '💀 حار'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'شدة الأسئلة',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: options.map((opt) {
            final isSelected = selected == opt.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  ref.read(selectedIntensityProvider(roomId).notifier).state =
                      opt.value;
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.primary : Colors.white24,
                    ),
                  ),
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Age Mode Picker
// ---------------------------------------------------------------------------

class _AgeModePicker extends ConsumerWidget {
  final String roomId;
  const _AgeModePicker({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedAgeModeProvider(roomId));

    const options = [
      (
        value: RoomAgeMode.standard,
        label: '👨‍👩‍👧 للعموم',
        activeColor: AppColors.primary,
      ),
      (
        value: RoomAgeMode.plus18,
        label: '🔞 18+',
        activeColor: AppColors.accent,
      ),
      (
        value: RoomAgeMode.plus21,
        label: '🍺 21+',
        activeColor: AppColors.highlight,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'الفئة العمرية',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: options.map((opt) {
            final isSelected = selected == opt.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  ref.read(selectedAgeModeProvider(roomId).notifier).state =
                      opt.value;
                  ref
                      .read(roomRepositoryProvider)
                      .updateRoomAgeMode(roomId, opt.value);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? opt.activeColor
                        : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? opt.activeColor : Colors.white24,
                    ),
                  ),
                  child: Text(
                    opt.label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        if (selected != RoomAgeMode.standard) ...[
          const SizedBox(height: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: Colors.orange.withOpacity(0.35)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ قد تحتوي هذه الغرفة على أسئلة جريئة أو للبالغين',
                  style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 2),
                Text(
                  'This room may include mature or bold questions',
                  style: TextStyle(color: Colors.orange, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Room Summary (host-only, shown before Start Game button)
// ---------------------------------------------------------------------------

class _RoomSummary extends ConsumerWidget {
  final String roomId;
  const _RoomSummary({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rounds = ref.watch(selectedRoundCountProvider(roomId));
    final packIds = ref.watch(selectedPackIdsProvider(roomId));
    final intensity = ref.watch(selectedIntensityProvider(roomId));
    final ageMode = ref.watch(selectedAgeModeProvider(roomId));
    final packsAsync = ref.watch(allPacksProvider);

    final String intensityLabel = switch (intensity) {
      IntensityLevel.light  => '🌿 خفيف',
      IntensityLevel.medium => '🔥 متوسط',
      _                     => '💀 حار',
    };

    final String ageModeLabel = switch (ageMode) {
      RoomAgeMode.plus18 => '🔞 18+',
      RoomAgeMode.plus21 => '🍺 21+',
      _                  => '👨‍👩‍👧 للعموم',
    };

    final bool isAdult = ageMode == RoomAgeMode.plus18 || ageMode == RoomAgeMode.plus21;

    final String categoriesLabel = packsAsync.maybeWhen(
      data: (packs) {
        if (packIds.isEmpty || packIds.length == packs.length) return 'الكل';
        return packIds.length.toString();
      },
      orElse: () => '...',
    );

    return RoundedCard(
      color: Colors.white.withOpacity(0.12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ملخص الإعدادات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          _SummaryRow(label: 'الجولات', value: '$rounds'),
          _SummaryRow(label: 'الفئات', value: categoriesLabel),
          _SummaryRow(label: 'الشدة', value: intensityLabel),
          _SummaryRow(label: 'العمر', value: ageModeLabel),
          if (isAdult) ...[
            const SizedBox(height: 8),
            const Text(
              '⚠️ قد تحتوي هذه الغرفة على أسئلة جريئة أو للبالغين',
              style: TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Text(
              'This room may include mature or bold questions',
              style: TextStyle(color: AppColors.accent, fontSize: 11),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            '$label:',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Age Badge (visible to all players in lobby)
// ---------------------------------------------------------------------------

class _AgeBadge extends StatelessWidget {
  final String ageMode;
  const _AgeBadge({required this.ageMode});

  @override
  Widget build(BuildContext context) {
    final bool isPlus21 = ageMode == 'plus21';
    final String label = isPlus21 ? '🍺 21+' : '🔞 18+';
    final Color color = isPlus21 ? AppColors.highlight : AppColors.accent;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 13,
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
