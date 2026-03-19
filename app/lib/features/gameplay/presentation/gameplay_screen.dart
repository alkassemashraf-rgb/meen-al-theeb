import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/game_session_controller.dart';
import '../data/game_session_repository.dart';
import '../data/gameplay_service.dart';
import '../domain/category_registry.dart';
import '../domain/game_round.dart';
import '../domain/round_result.dart';
import '../presentation/result_card_widget.dart';
import '../../room/domain/room.dart';
import '../../room/data/room_repository.dart';
import '../../../services/auth/auth_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/components/page_container.dart';
import '../../../shared/components/avatar_widget.dart';
import '../../../shared/components/rounded_card.dart';
import '../domain/reaction.dart';
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
// UI State Machine (presentation-only, client-side)
// ---------------------------------------------------------------------------

/// Staged reveal states within the backend 'voting' phase.
/// These drive the hook → reveal → thinking → open flow locally
/// and never block or modify RTDB state.
enum _VotingUIState { intro, promptReveal, thinkingDelay, votingOpen }

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
  StreamSubscription<Map<String, String>>? _reactionSub;
  // Current round's reactions: playerId → emoji (persists for count badges)
  final Map<String, String> _reactionMap = {};
  final Map<String, String?> _playerEmotions = {};
  final Map<String, Timer> _emotionTimers = {};

  // Tracks the last roundId for which the local countdown was started so we
  // don't restart it on every build rebuild.
  String? _timedRoundId;

  // Cache the service so we can safely call stopWatching() in dispose().
  late final _gameplayService = ref.read(gameplayServiceProvider);

  // Guard so watchGameplay is only started once per lifecycle.
  bool _watchGameplayStarted = false;

  // Press-scale tracking for interactive elements
  final Map<String, bool> _pressedPlayers = {};
  final Map<String, bool> _pressedEmojis = {};

  // Reveal transition delay: hold loading state for 300ms before flipping
  bool _revealReady = false;
  bool _revealScheduled = false;

  // Celebration text: appears ~900ms after reveal is shown
  bool _showCelebrationText = false;
  bool _celebrationScheduled = false;
  Timer? _celebrationTimer;

  // Voting UI state machine (hook → reveal → thinking → open)
  _VotingUIState _votingUIState = _VotingUIState.intro;
  String? _sequencedRoundId;
  Timer? _introTimer;
  Timer? _thinkingTimer;

  // Waiting-for-others animated dots (cycles 0→1→2 at 500ms)
  Timer? _dotsTimer;
  int _dotsCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startReactionListener();
    });
  }

  void _startReactionListener() {
    _reactionSub?.cancel();
    _reactionSub = _gameplayService
        .observeReactionMap(widget.roomId)
        .listen((newMap) {
      if (!mounted) return;

      // Diff newMap against _reactionMap to find new/changed reactions.
      newMap.forEach((playerId, emoji) {
        if (_reactionMap[playerId] != emoji) {
          final reaction = Reaction(
            id: '${playerId}_${DateTime.now().millisecondsSinceEpoch}',
            playerId: playerId,
            emoji: emoji,
            timestamp: DateTime.now(),
          );
          setState(() {
            // Cap concurrent floating animations to avoid frame drops
            if (_activeReactions.length < 10) {
              _activeReactions.add(reaction);
            }
            _playerEmotions[playerId] = emoji;
          });

          // Remove floating bubble after 3s
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) setState(() => _activeReactions.remove(reaction));
          });

          // Clear avatar emotion overlay after 2s
          _emotionTimers[playerId]?.cancel();
          _emotionTimers[playerId] = Timer(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _playerEmotions[playerId] = null;
                _emotionTimers.remove(playerId);
              });
            }
          });
        }
      });

      // Commit the updated reaction map (also clears on round reset).
      setState(() {
        _reactionMap.clear();
        _reactionMap.addAll(newMap);
      });
    });
  }

  /// Runs the staged reveal sequence once per round (guarded by [_sequencedRoundId]).
  /// Transitions: intro → promptReveal → thinkingDelay → votingOpen.
  /// All purely presentational — never touches RTDB.
  void _startVotingSequence(String roundId) {
    if (_sequencedRoundId == roundId) return;
    _sequencedRoundId = roundId;
    _introTimer?.cancel();
    _thinkingTimer?.cancel();
    setState(() {
      _votingUIState = _VotingUIState.intro;
      _showCelebrationText = false;
    });

    // Step 1: hook text for 600ms
    _introTimer = Timer(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _votingUIState = _VotingUIState.promptReveal);

      // Step 2: prompt reveal animation (350ms), then thinking delay
      _introTimer = Timer(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        setState(() => _votingUIState = _VotingUIState.thinkingDelay);

        // Step 3: forced thinking pause for 2500ms, then voting opens
        _thinkingTimer = Timer(const Duration(milliseconds: 2500), () {
          if (!mounted) return;
          setState(() => _votingUIState = _VotingUIState.votingOpen);
        });
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _dotsTimer?.cancel();
    _introTimer?.cancel();
    _thinkingTimer?.cancel();
    _celebrationTimer?.cancel();
    _reactionSub?.cancel();
    for (final timer in _emotionTimers.values) {
      timer.cancel();
    }
    _emotionTimers.clear();
    _gameplayService.stopWatching();
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
      // Start gameplay monitoring for host. Using build (not initState) so we
      // reliably get room data even if the stream is still loading at init time.
      if (!_watchGameplayStarted && room != null && room.hostId == user?.uid) {
        _watchGameplayStarted = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _gameplayService.watchGameplay(widget.roomId);
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

        // Start countdown + voting UI sequence when round enters voting phase
        if (round.phase == 'voting') {
          _startLocalTimer(round.roundId, round.expiresAt);
          _startVotingSequence(round.roundId);
        }

        final isReveal = round.phase == 'result_ready';

        // Hold loading state for 300ms after result_ready before flipping,
        // giving a brief build-up moment before the reveal animation fires.
        if (isReveal && !_revealScheduled) {
          _revealScheduled = true;
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) setState(() => _revealReady = true);
          });
        } else if (!isReveal) {
          _revealReady = false;
          _revealScheduled = false;
          _showCelebrationText = false;
          _celebrationScheduled = false;
        }

        // Schedule celebration text ~900ms after the reveal animation plays
        if (isReveal && _revealReady && !_celebrationScheduled) {
          _celebrationScheduled = true;
          _celebrationTimer?.cancel();
          _celebrationTimer = Timer(const Duration(milliseconds: 900), () {
            if (mounted) setState(() => _showCelebrationText = true);
          });
        }

        final showReveal = isReveal && _revealReady;
        final showPreparing = round.phase == 'preparing' ||
            round.phase == 'vote_locked' ||
            (isReveal && !_revealReady);

        final isHost = roomAsync.value?.hostId == user?.uid;

        return PageContainer(
          title: showReveal ? 'النتائج' : 'اللعب المباشر',
          backgroundGradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1330), Color(0xFF2D1B69)],
          ),
          child: Stack(
            children: [
              // Main Content
              Column(
                children: [
                  if (showPreparing) ...[
                    _buildPreparingState(round.phase),
                  ] else ...[
                    Expanded(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background dimming for reveal
                          if (showReveal)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 1000),
                              color: Colors.black.withOpacity(0.6),
                            ),

                          _buildFlipTransition(
                            isReveal: showReveal,
                            child: showReveal
                                ? _buildRevealContent(round, roomAsync, key: const ValueKey(true))
                                : _buildVotingPhase(round, roomAsync, user, key: const ValueKey(false)),
                          ),
                        ],
                      ),
                    ),
                    // Reactions available during both voting and reveal phases
                    if (!showPreparing) _buildReactionPicker(),
                    if (showReveal) _buildRevealActions(round, roomAsync, isHost),
                  ],
                ],
              ),

              // Simulated Confetti Burst icons — only on normal or tie outcomes
              if (showReveal &&
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
    final displayLabel = label == 'vote_locked'
        ? 'جاري حساب النتائج...'
        : 'جاري التحضير...';
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              displayLabel,
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
    final myCurrentVote = round.votes[user?.uid];
    final allVoted =
        round.votes.length >= round.eligiblePlayerIds.length;
    final isWaiting = myCurrentVote != null && !allVoted;

    // Drive the dots timer from the build method
    if (isWaiting) {
      _startDotsTimer();
    } else {
      _stopDotsTimer();
    }

    return Column(
      key: key,
      children: [
        // Countdown + vote count header (stable across rounds)
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
                style: const TextStyle(fontSize: 18, color: Colors.white),
              ),
            ],
          ),
        ),
        // Question card + instruction + grid — fade when round changes
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: _buildVotingRoundBody(
              round,
              roomAsync,
              user,
              myCurrentVote: myCurrentVote,
              isWaiting: isWaiting,
              key: ValueKey(round.roundId),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds the question card widget (shared across reveal states).
  Widget _buildQuestionCard(GameRound round) {
    final categoryMeta =
        round.packId.isNotEmpty ? CategoryRegistry.get(round.packId) : null;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: RoundedCard(
        color: Colors.white.withOpacity(0.10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (categoryMeta != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${categoryMeta.icon}  ${categoryMeta.labelAr}',
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Text(
                round.questionAr,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The per-round content inside the voting phase: question card, instruction
  /// line (or waiting indicator), and the player grid. Keyed by [round.roundId]
  /// so the [AnimatedSwitcher] in [_buildVotingPhase] fades between rounds.
  Widget _buildVotingRoundBody(
    GameRound round,
    AsyncValue<Room?> roomAsync,
    dynamic user, {
    required String? myCurrentVote,
    required bool isWaiting,
    Key? key,
  }) {
    // --- Intro state: show hook text only, no question card or grid ---
    if (_votingUIState == _VotingUIState.intro) {
      return Column(
        key: key,
        children: [
          Expanded(
            child: Center(
              child: Text(
                'لا تلفّون…',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // --- Question card (animated in during promptReveal, static after) ---
    final questionCard = _votingUIState == _VotingUIState.promptReveal
        ? TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (ctx, v, child) => Opacity(
              opacity: v,
              child: Transform.scale(scale: 0.92 + (0.08 * v), child: child),
            ),
            child: _buildQuestionCard(round),
          )
        : _buildQuestionCard(round);

    // --- Thinking delay: show question + "فكّر زين…" text, no voting grid ---
    if (_votingUIState == _VotingUIState.thinkingDelay) {
      return Column(
        key: key,
        children: [
          questionCard,
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'فكّر زين…',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.white60,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white38),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // --- Voting open (or fallback): full question + instruction + grid ---
    return Column(
      key: key,
      children: [
        questionCard,
        const SizedBox(height: 8),
        // Waiting indicator OR instruction text
        AnimatedOpacity(
          opacity: 1.0,
          duration: const Duration(milliseconds: 200),
          child: isWaiting
              ? Text(
                  'ننتظر الآخرين${'.' * (_dotsCount + 1)}',
                  style:
                      const TextStyle(color: Colors.white54, fontSize: 14),
                )
              : Text(
                  myCurrentVote != null
                      ? 'اضغط على اسم آخر لتغيير تصويتك'
                      : 'صوّت للشخص المناسب:',
                  style: TextStyle(
                    fontSize: 14,
                    color: myCurrentVote != null
                        ? AppColors.accent
                        : Colors.white70,
                  ),
                ),
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
            final amITarget = round.votes[user?.uid] == player.playerId;
            final isPressed = _pressedPlayers[player.playerId] == true;

            return GestureDetector(
              onTapDown: (_) =>
                  setState(() => _pressedPlayers[player.playerId] = true),
              onTapUp: (_) {
                setState(() => _pressedPlayers[player.playerId] = false);
                _submitVote(player.playerId);
              },
              onTapCancel: () =>
                  setState(() => _pressedPlayers[player.playerId] = false),
              child: AnimatedScale(
                scale: isPressed ? 0.90 : 1.0,
                duration: const Duration(milliseconds: 80),
                curve: Curves.easeOut,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: amITarget
                        ? AppColors.primary.withOpacity(0.35)
                        : Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: amITarget ? AppColors.primary : Colors.white24,
                      width: amITarget ? 2 : 1,
                    ),
                    boxShadow: amITarget
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 1,
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AvatarWidget(
                        avatarUrlOrId: player.avatarId,
                        size: 40,
                        isSelected: amITarget,
                        emotionState: _playerEmotions[player.playerId],
                      ),
                      const SizedBox(height: 6),
                      _nameText(player.displayName, amITarget),
                      // Checkmark pops in with elastic bounce when selected
                      AnimatedScale(
                        scale: amITarget ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.elasticOut,
                        child: const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Icon(Icons.check_circle,
                              color: Colors.greenAccent, size: 16),
                        ),
                      ),
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
      return Center(key: key, child: const Text('جاري تحميل النتائج...', style: TextStyle(color: Colors.white)));
    }

    if (result.resultType == 'insufficient_votes') {
      return Center(
        key: key,
        child: const Text(
          'عدد الأصوات غير كافٍ لمعرفة الذيب! 🐺',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
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
            const Text('الذيب طلع...', style: TextStyle(fontSize: 24, color: Colors.white)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: winners
                  .map(
                    (p) => _RevealPopAnimation(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withOpacity(0.6),
                                    blurRadius: 28,
                                    spreadRadius: 6,
                                  ),
                                ],
                              ),
                              child: AvatarWidget(
                                avatarUrlOrId: p.avatarId,
                                size: 100,
                                isWinner: true,
                                emotionState: _playerEmotions[p.playerId],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(p.displayName,
                                style: const TextStyle(
                                    fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                            Text(
                              '${result.voteCounts[p.playerId] ?? 0} أصوات',
                              style: const TextStyle(
                                  fontSize: 16, color: Colors.white54),
                            ),
                          ],
                        ),
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
            // Celebration text — fades in ~900ms after reveal
            if (_showCelebrationText && result.resultType != 'insufficient_votes')
              AnimatedOpacity(
                opacity: 1.0,
                duration: const Duration(milliseconds: 400),
                child: Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    _getCelebrationLine(result),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  /// Returns a contextual one-liner based on the vote distribution.
  String _getCelebrationLine(RoundResult result) {
    if (result.resultType == 'tie') {
      return 'ما قدروا يتفقون على واحد… كلهم مشتبه بهم! 🕵️';
    }
    final total = result.totalValidVotes;
    final topVotes = result.winningPlayerIds.isNotEmpty
        ? (result.voteCounts[result.winningPlayerIds.first] ?? 0)
        : 0;
    if (total > 0 && topVotes / total >= 0.6) {
      return 'واضح الموضوع… كان معروف من البداية 👀';
    }
    const lines = [
      'ما كانت مفاجأة كبيرة…',
      'الجماعة عارفينك!',
      'تفاهم الكل عليك 😅',
    ];
    return lines[result.winningPlayerIds.hashCode.abs() % lines.length];
  }

  /// Host-only action area in the reveal phase.
  Widget _buildRevealActions(
    GameRound round,
    AsyncValue<Room?> roomAsync,
    bool isHost,
  ) {
    if (!isHost) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'انتظر... المضيف سينقل إلى الجولة التالية',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

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
    const emojis = ['😂', '😱', '🔥', '💀', '👀'];
    // Derive per-emoji count from current reaction map (playerId → emoji).
    final counts = <String, int>{};
    for (final emoji in _reactionMap.values) {
      counts[emoji] = (counts[emoji] ?? 0) + 1;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: emojis.map((e) {
          final count = counts[e] ?? 0;
          final isPressed = _pressedEmojis[e] == true;
          return GestureDetector(
            onTapDown: (_) => setState(() => _pressedEmojis[e] = true),
            onTapUp: (_) {
              setState(() => _pressedEmojis[e] = false);
              ref.read(gameplayServiceProvider).sendReaction(
                    widget.roomId,
                    ref.read(authStateProvider).value?.uid ?? '',
                    e,
                  );
            },
            onTapCancel: () => setState(() => _pressedEmojis[e] = false),
            child: AnimatedScale(
              scale: isPressed ? 1.35 : 1.0,
              duration: const Duration(milliseconds: 80),
              curve: Curves.easeOut,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Text(e, style: const TextStyle(fontSize: 28)),
                    if (count > 0)
                      Positioned(
                        top: -6,
                        right: -10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
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

  void _startDotsTimer() {
    if (_dotsTimer != null) return; // Already running
    _dotsTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _dotsCount = (_dotsCount + 1) % 3);
    });
  }

  void _stopDotsTimer() {
    if (_dotsTimer == null) return;
    _dotsTimer?.cancel();
    _dotsTimer = null;
    _dotsCount = 0;
  }

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
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: Colors.white),
      );
}

// ---------------------------------------------------------------------------
// Reveal Pop Animation
// ---------------------------------------------------------------------------

/// Wraps a winner card with an elastic scale-in animation on first render.
///
/// Uses [Curves.elasticOut] so the card "bounces" into view — giving each
/// winner reveal a satisfying pop rather than a plain appearance.
class _RevealPopAnimation extends StatelessWidget {
  final Widget child;
  const _RevealPopAnimation({required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.4, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.elasticOut,
      builder: (context, scale, _) => Transform.scale(scale: scale, child: child),
      child: child,
    );
  }
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
