import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/session_summary_builder.dart';
import '../domain/session_summary.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/components/page_container.dart';
import '../../../shared/utils/ui_helpers.dart';

/// End-of-session summary screen displayed after a session ends.
///
/// Data source: RTDB /rooms/{roomId}/roundHistory and /players (one-shot read
/// via [sessionSummaryProvider]).
///
/// Navigation: Host and all players are routed here when room.status == 'ended'.
/// The "الصفحة الرئيسية" button navigates to /home.
///
/// Event: SessionSummaryBuilt (fired when [sessionSummaryProvider] resolves)
class SessionSummaryScreen extends ConsumerWidget {
  final String roomId;

  const SessionSummaryScreen({super.key, required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(sessionSummaryProvider(roomId));

    return summaryAsync.when(
      loading: () => const PageContainer(
        child: LoadingState(message: 'جاري تحضير ملخص الجلسة...'),
      ),
      error: (e, _) => PageContainer(
        child: ErrorState(
          message: e.toString(),
          onRetry: () => ref.refresh(sessionSummaryProvider(roomId)),
        ),
      ),
      data: (summary) {
        if (summary == null || !summary.hasAnyRounds) {
          return PageContainer(
            child: EmptyState(
              title: 'لا توجد جولات مكتملة',
              message: 'انتهت الجلسة قبل اكتمال أي جولة. العب مرة أخرى!',
              icon: '🐺',
              action: ElevatedButton(
                onPressed: () => context.go('/home'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('العودة للرئيسية'),
              ),
            ),
          );
        }
        return _SummaryContent(summary: summary);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Main content
// ---------------------------------------------------------------------------

class _SummaryContent extends StatelessWidget {
  final SessionSummary summary;

  const _SummaryContent({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('ملخص الجلسة'),
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              children: [
                const SizedBox(height: 8),
                _StatsBar(summary: summary),
                if (summary.mostVotedDisplayName != null) ...[
                  const SizedBox(height: 16),
                  _MostVotedCard(summary: summary),
                ],
                const SizedBox(height: 24),
                if (!summary.hasAnyRounds) ...[
                  const EmptyState(
                    title: 'لا توجد جولات',
                    message: 'يبدو أن هذه الجلسة لم تكتمل بعد.',
                  ),
                ] else ...[
                  const Text(
                    'الجولات',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...summary.rounds.map((r) => _RoundRecapCard(recap: r)),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _HomeButton(),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats bar
// ---------------------------------------------------------------------------

class _StatsBar extends StatelessWidget {
  final SessionSummary summary;
  const _StatsBar({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            label: 'الجولات',
            value: '${summary.totalRounds}',
            icon: Icons.loop,
            color: AppColors.primary,
          ),
          _divider(),
          _StatItem(
            label: 'تعادل',
            value: '${summary.tieRounds}',
            icon: Icons.balance,
            color: Colors.orange,
          ),
          _divider(),
          _StatItem(
            label: 'تخطّي',
            value: '${summary.skippedRounds}',
            icon: Icons.skip_next,
            color: Colors.white38,
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 40, color: Colors.grey.shade200);
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Most-voted highlight
// ---------------------------------------------------------------------------

class _MostVotedCard extends StatelessWidget {
  final SessionSummary summary;
  const _MostVotedCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C5CE7), Color(0xFF4A3AB3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C5CE7).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: const Center(
                  child: Text(
                    '🏆',
                    style: TextStyle(fontSize: 28),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'نجم الجلسة (الأكثر تصويتاً)',
                  style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                Text(
                  summary.mostVotedDisplayName ?? 'غير متوفر',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              '${summary.mostVotedCount} أصوات',
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w900,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Round recap card
// ---------------------------------------------------------------------------

class _RoundRecapCard extends StatelessWidget {
  final RoundRecap recap;
  const _RoundRecapCard({required this.recap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white.withOpacity(0.05),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'جولة ${recap.roundNumber}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Spacer(),
                    _ResultBadge(resultType: recap.resultType),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recap.questionAr,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                    if (!recap.wasSkipped && recap.winnerDisplayNames.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('🎯', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              recap.winnerDisplayNames.join('، '),
                              style: const TextStyle(
                                fontSize: 16,
                                color: AppColors.accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${recap.totalValidVotes} أصوات',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white38,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (recap.wasSkipped) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.info_outline, size: 14, color: Colors.white38),
                            SizedBox(width: 6),
                            Text(
                              'جولة متجاوزة — أصوات غير كافية',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _ResultBadge extends StatelessWidget {
  final String resultType;
  const _ResultBadge({required this.resultType});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    switch (resultType) {
      case 'tie':
        label = 'تعادل';
        color = Colors.orange;
      case 'insufficient_votes':
        label = 'تخطّي';
        color = Colors.grey;
      default:
        label = 'عادي';
        color = AppColors.primary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Standard helpers used above

// ---------------------------------------------------------------------------
// Sticky home button
// ---------------------------------------------------------------------------

class _HomeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.home_outlined),
            label: const Text(
              'الصفحة الرئيسية',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
