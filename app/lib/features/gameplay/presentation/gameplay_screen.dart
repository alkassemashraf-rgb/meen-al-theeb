import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/game_session_controller.dart';
import '../data/game_session_repository.dart';
import '../data/gameplay_service.dart';
import '../domain/game_round.dart';
import '../presentation/result_card_widget.dart';
import '../../room/domain/room.dart';
import '../../room/data/room_repository.dart';
import '../../../services/auth/auth_service.dart';
import '../../../shared/components/page_container.dart';
import '../../../shared/components/avatar_widget.dart';
import '../../../shared/components/rounded_card.dart';
import '../domain/reaction.dart';
import '../domain/round_result.dart';
import './widgets/animated_reaction.dart';

// ---------------------------------------------------------------------------
// Stream Providers
// ---------------------------------------------------------------------------

final roundStreamProvider =
    StreamProvider.family<GameRound?, String>((ref, roomId) {
  return ref.watch(gameSessionRepositoryProvider).observeCurrentRound(roomId);
});

final roomStreamProvider = StreamProvider.family<Room?, String>((ref, roomId) {
  return ref.watch(roomRepositoryProvider).observeRoom(roomId);
});

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class GameplayScreen extends ConsumerStatefulWidget {
  final String roomId;
  const GameplayScreen({super.key, required this.roomId});

  @override
  ConsumerState<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends ConsumerState<GameplayScreen> {
  Timer? _timer;
  int _secondsLeft = 30;

  final List<Reaction> _activeReactions = [];
  StreamSubscription<Reaction>? _reactionSub;
  final Map<String, String?> _playerEmotions = {};
  final Map<String, Timer> _emotionTimers = {};

  // Tracks the last roundId for which the local countdown was started so we
  // don't restart it on every build rebuild.
  String? _timedRoundId;

  @override
  void initState() {
    super.initState();
    _initGameplayLogic();
  }

  void _initGameplayLogic() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final roomAsync = ref.read(roomStreamProvider(widget.roomId));
      final user = ref.read(authStateProvider).value;

      roomAsync.whenData((room) {
        if (room != null && room.hostId == user?.uid) {
          ref.read(gameplayServiceProvider).watchGameplay(widget.roomId);
        }
      });

      _startReactionListener();
    });
  }

  void _startReactionListener() {
    _reactionSub?.cancel();
    _reactionSub = ref
        .read(gameplayServiceProvider)
        .observeReactions(widget.roomId)
        .listen((reaction) {
      if (!mounted) return;
      setState(() {
        _activeReactions.add(reaction);
        _playerEmotions[reaction.playerId] = reaction.emoji;
      });
      
      // Clear reaction bubble after 3s
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _activeReactions.remove(reaction));
      });

      // Clear avatar emotion after 2s (managed timer)
      _emotionTimers[reaction.playerId]?.cancel();
      _emotionTimers[reaction.playerId] = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _playerEmotions[reaction.playerId] = null;
            _emotionTimers.remove(reaction.playerId);
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _reactionSub?.cancel();
    for (final timer in _emotionTimers.values) {
      timer.cancel();
    }
    _emotionTimers.clear();
    ref.read(gameplayServiceProvider).stopWatching();
    super.dispose();
  }

  void _startLocalTimer(String roundId, DateTime expiresAt) {
    if (_timedRoundId == roundId) return; // Already ticking for this round
    _timedRoundId = roundId;

    _timer?.cancel();
    final remaining = expiresAt.difference(DateTime.now()).inSeconds;
    _secondsLeft = remaining.clamp(0, 30);

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          t.cancel();
        }
      });
    });
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final roundAsync = ref.watch(roundStreamProvider(widget.roomId));
    final roomAsync = ref.watch(roomStreamProvider(widget.roomId));
    final user = ref.watch(authStateProvider).value;

    // Navigate to summary screen when room ends (session end or host departure).
    // SessionSummaryScreen reads roundHistory from RTDB before any cleanup.
    roomAsync.whenData((room) {
      if (room?.status == 'ended') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.go('/summary/${widget.roomId}');
        });
      }
    });

    return roundAsync.when(
      data: (round) {
        if (round == null) {
          return const PageContainer(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        // Start countdown only when round enters voting phase
        if (round.phase == 'voting') {
          _startLocalTimer(round.roundId, round.expiresAt);
        }

        final isReveal = round.phase == 'result_ready';
        final isPreparing =
            round.phase == 'preparing' || round.phase == 'vote_locked';
        final isHost = roomAsync.value?.hostId == user?.uid;

        return PageContainer(
          title: isReveal ? 'النتائج' : 'اللعب المباشر',
          child: Stack(
            children: [
              // Main Content
              Column(
                children: [
                  if (isPreparing) ...[
                    _buildPreparingState(round.phase),
                  ] else ...[
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background dimming for reveal
                          if (isReveal)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 1000),
                              color: Colors.black.withOpacity(0.6),
                            ),
                          
                          _buildFlipTransition(
                            isReveal: isReveal,
                            child: isReveal
                                ? _buildRevealContent(round, roomAsync, key: const ValueKey(true))
                                : _buildVotingPhase(round, roomAsync, user, key: const ValueKey(false)),
                          ),
                        ],
                      ),
                    ),
                    if (isReveal) ...[
                      _buildReactionPicker(),
                      _buildRevealActions(round, roomAsync, isHost),
                    ],
                  ],
                ],
              ),

              // Simulated Confetti Burst icons — only on normal or tie outcomes
              if (isReveal &&
                  (round.result?.resultType == 'normal' ||
                      round.result?.resultType == 'tie'))
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: _ConfettiBurst(),
                    ),
                  ),
                ),

              // Floating reaction overlay
              Positioned.fill(
                child: IgnorePointer(
                  child: Stack(
                    children:
                        _activeReactions.map(_buildAnimatedReaction).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const PageContainer(
          child: Center(child: CircularProgressIndicator())),
      error: (e, s) =>
          PageContainer(child: Center(child: Text('Error: $e'))),
    );
  }

  // -------------------------------------------------------------------------
  // Preparing / Locking states
  // -------------------------------------------------------------------------

  Widget _buildPreparingState(String label) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Animation Utils
  // -------------------------------------------------------------------------

  Widget _buildFlipTransition({
    required Widget child,
    required bool isReveal,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final rotate = Tween(begin: 3.14 / 2, end: 0.0).animate(animation);
        return AnimatedBuilder(
          animation: rotate,
          builder: (context, _) {
            final isUnder = (ValueKey(isReveal) != child.key);
            var tilt = ((animation.value - 0.5).abs() - 0.5) * 0.003;
            tilt *= isUnder ? -1.0 : 1.0;
            final value = isUnder
                ? math.min(rotate.value, 3.14 / 2)
                : rotate.value;
            return RepaintBoundary(
              child: Transform(
                transform: Matrix4.rotationY(value)..setEntry(3, 0, tilt),
                alignment: Alignment.center,
                child: child,
              ),
            );
          },
        );
      },
      child: child,
    );
  }

  // -------------------------------------------------------------------------
  // Voting Phase
  // -------------------------------------------------------------------------

  Widget _buildVotingPhase(
    GameRound round,
    AsyncValue<Room?> roomAsync,
    dynamic user, {
    Key? key,
  }) {
    return Column(
      key: key,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text(
                '$_secondsLeft ثانية',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
              Text(
                'الأصوات: ${round.votes.length}/${round.eligiblePlayerIds.length}',
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: RoundedCard(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              child: Text(
                round.questionAr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'صوّت للشخص المناسب:',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
        Expanded(child: _buildVotingGrid(round, roomAsync, user)),
      ],
    );
  }

  Widget _buildVotingGrid(
    GameRound round,
    AsyncValue<Room?> roomAsync,
    dynamic user,
  ) {
    return roomAsync.when(
      data: (room) {
        if (room == null) return const SizedBox();
        final eligiblePlayers = room.players.values
            .where((p) => round.eligiblePlayerIds.contains(p.playerId))
            .toList();

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.8,
          ),
          itemCount: eligiblePlayers.length,
          itemBuilder: (context, index) {
            final player = eligiblePlayers[index];
            final isSelf = player.playerId == user?.uid;
            final hasVoted = round.votes.containsKey(user?.uid);
            final amITarget = round.votes[user?.uid] == player.playerId;

            return GestureDetector(
              onTap: (isSelf || hasVoted)
                  ? null
                  : () => _submitVote(player.playerId),
              child: Opacity(
                opacity: (isSelf && !hasVoted) ? 0.5 : 1.0,
                child: RoundedCard(
                  color: amITarget ? Colors.green.withOpacity(0.2) : null,
                  elevation: amITarget ? 8 : 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AvatarWidget(
                        avatarUrlOrId: player.avatarId,
                        size: 40,
                        isSelected: amITarget,
                        emotionState: _playerEmotions[player.playerId],
                      ),
                      _nameText(player.displayName, amITarget),
                      if (hasVoted && amITarget)
                        const Icon(Icons.check_circle,
                            color: Colors.green, size: 16),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  // -------------------------------------------------------------------------
  // Reveal Phase
  // -------------------------------------------------------------------------

  Widget _buildRevealContent(
    GameRound round,
    AsyncValue<Room?> roomAsync, {
    Key? key,
  }) {
    final result = round.result;
    if (result == null) {
      return Center(key: key, child: const Text('جاري تحميل النتائج...'));
    }

    if (result.resultType == 'insufficient_votes') {
      return Center(
        key: key,
        child: const Text(
          'عدد الأصوات غير كافٍ لمعرفة الذيب! 🐺',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      );
    }

    return roomAsync.when(
      data: (room) {
        if (room == null) return const SizedBox();
        final winners = room.players.values
            .where((p) => result.winningPlayerIds.contains(p.playerId))
            .toList();

        return Column(
          key: key,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('الذيب طلع...', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: winners
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          AvatarWidget(
                            avatarUrlOrId: p.avatarId, 
                            size: 100,
                            isWinner: true,
                            emotionState: _playerEmotions[p.playerId],
                          ),
                          const SizedBox(height: 16),
                          Text(p.displayName,
                              style: const TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold)),
                          Text(
                            '${result.voteCounts[p.playerId] ?? 0} أصوات',
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
            if (result.resultType == 'tie')
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'تعادل! كل هؤلاء مشتبه بهم 🕵️',
                  style: TextStyle(
                      color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  /// Host-only action area in the reveal phase.
  Widget _buildRevealActions(
    GameRound round,
    AsyncValue<Room?> roomAsync,
    bool isHost,
  ) {
    if (!isHost) return const SizedBox();

    final controllerState =
        ref.watch(gameSessionControllerProvider(widget.roomId));
    final controller =
        ref.read(gameSessionControllerProvider(widget.roomId).notifier);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Share result card
          if (round.result != null)
            TextButton.icon(
              onPressed: () => _showResultCard(round, roomAsync),
              icon: const Icon(Icons.share_outlined),
              label: const Text('عرض بطاقة النتيجة'),
            ),

          const SizedBox(height: 8),

          // Next Round — disabled while transition is in progress
          ElevatedButton(
            onPressed: controllerState.isTransitioningRound
                ? null
                : () => controller.advanceToNextRound(round),
            child: controllerState.isTransitioningRound
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('الجولة التالية'),
          ),

          const SizedBox(height: 8),

          // End Session
          TextButton(
            onPressed: controllerState.isEndingSession
                ? null
                : () => _confirmEndSession(controller),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: controllerState.isEndingSession
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('إنهاء الجلسة'),
          ),

          // Error feedback
          if (controllerState.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                controllerState.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Result Card
  // -------------------------------------------------------------------------

  void _showResultCard(GameRound round, AsyncValue<Room?> roomAsync) {
    final room = roomAsync.value;
    if (room == null) return;

    final payload = ref
        .read(gameSessionControllerProvider(widget.roomId).notifier)
        .buildResultCard(round, room.players);

    if (payload == null) return;
    showResultCardSheet(context, payload);
  }

  // -------------------------------------------------------------------------
  // Reactions
  // -------------------------------------------------------------------------

  Widget _buildReactionPicker() {
    final emojis = ['🐺', '😂', '🕵️', '😳', '🤔', '🔥'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: emojis
            .map(
              (e) => IconButton(
                icon: Text(e, style: const TextStyle(fontSize: 24)),
                onPressed: () =>
                    ref.read(gameplayServiceProvider).sendReaction(
                          widget.roomId,
                          ref.read(authStateProvider).value?.uid ?? '',
                          e,
                        ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildAnimatedReaction(Reaction reaction) {
    return AnimatedReaction(
      key: ValueKey(reaction.id),
      reaction: reaction,
      onComplete: () {
        if (mounted) setState(() => _activeReactions.remove(reaction));
      },
    );
  }

  // -------------------------------------------------------------------------
  // Helpers
  // -------------------------------------------------------------------------

  Future<void> _submitVote(String targetId) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;
    try {
      await ref.read(gameSessionRepositoryProvider).submitVote(
            roomId: widget.roomId,
            voterId: user.uid,
            targetId: targetId,
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _confirmEndSession(GameSessionController controller) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('إنهاء الجلسة؟'),
        content: const Text('سيتم إنهاء اللعبة للجميع. هل أنت متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('إنهاء'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.endSession();
    }
  }

  Widget _nameText(String name, bool bold) => Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
            fontWeight: bold ? FontWeight.bold : FontWeight.normal),
      );
}

// ---------------------------------------------------------------------------
// Simulated Confetti
// ---------------------------------------------------------------------------

class _ConfettiBurst extends StatelessWidget {
  const _ConfettiBurst();

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        if (value > 0.8) return const SizedBox.shrink();
        
        return Stack(
          children: List.generate(12, (i) {
            final angle = (i * 30) * math.pi / 180;
            final dist = 100 + (value * 250);
            final opacity = (1.0 - value).clamp(0.0, 1.0);
            
            return Center(
              child: Transform.translate(
                offset: Offset(math.cos(angle) * dist, math.sin(angle) * dist),
                child: Opacity(
                  opacity: opacity,
                  child: Text(
                    ['✨', '🎉', '🎊', '⭐'][i % 4],
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
