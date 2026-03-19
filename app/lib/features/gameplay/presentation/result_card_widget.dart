import 'package:flutter/material.dart';

import '../domain/result_card_payload.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/share/share_service.dart';
import '../../../shared/components/avatar_widget.dart';

/// Shareable round result card widget.
///
/// Converted to [StatefulWidget] in Mission 8 to hold a [GlobalKey] for
/// [RepaintBoundary]-based image capture used by [ShareService].
///
/// Mission 10: Visual hierarchy improved — result headline dominates,
/// question demoted to secondary, vote bars replace plain text rows,
/// category badge shown when available.
///
/// Events:
///   ShareImageGenerated — raised when [boundary.toImage] completes (in ShareService)
///   ShareRequested      — raised when [Share.shareXFiles] is called (in ShareService)
class ResultCardWidget extends StatefulWidget {
  final ResultCardPayload payload;

  const ResultCardWidget({super.key, required this.payload});

  @override
  State<ResultCardWidget> createState() => _ResultCardWidgetState();
}

class _ResultCardWidgetState extends State<ResultCardWidget> {
  final _repaintBoundaryKey = GlobalKey();
  final _shareButtonKey = GlobalKey();
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          key: _repaintBoundaryKey,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: const LinearGradient(
                colors: [Color(0xFF2D3436), Color(0xFF000000)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: Colors.white.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Decorative background glow
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [AppColors.primary.withOpacity(0.1), Colors.transparent],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App Branding
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Text('🐺', style: TextStyle(fontSize: 16)),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'مين الذيب؟',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),

                      // Optional category badge
                      if (widget.payload.categoryLabel != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.payload.categoryLabel!,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Question box (secondary)
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.05)),
                            ),
                            child: Text(
                              widget.payload.questionAr,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Result content
                      if (!widget.payload.hasValidResult) ...[
                        _insufficientVotesContent(),
                      ] else ...[
                        _resultContent(),
                      ],

                      const SizedBox(height: 28),

                      // Social context tagline
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Text(
                          'لعبة الذكاء والخداع الجماعية 🎭',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildShareButton(),
      ],
    );
  }

  Widget _insufficientVotesContent() {
    return Column(
      children: [
        const Text('🐺', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 8),
        const Text(
          'تفرقت الأصوات...',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'لم يتوصل اللاعبون إلى قرار',
          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
        ),
      ],
    );
  }

  Widget _resultContent() {
    final winners = widget.payload.winners;
    final isTie = widget.payload.resultType == 'tie';
    final titleColor = isTie ? Colors.orange[300]! : Colors.white;
    final titleText = isTie ? 'تساوى عليهم الاتهام!' : 'الذيب طلع من بيننا...';

    return Column(
      children: [
        // Dominant result headline
        Text(
          titleText,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: titleColor,
            fontSize: 22,
            fontWeight: FontWeight.w900,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 24),

        // Winner chips
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          runSpacing: 24,
          children: winners.map((p) => _playerChip(p, isTie)).toList(),
        ),

        if (widget.payload.players.isNotEmpty) ...[
          const SizedBox(height: 28),
          _voteSummary(),
        ],
      ],
    );
  }

  Widget _playerChip(ResultCardPlayerInfo player, bool isTie) {
    final avatarSize = (!isTie && widget.payload.winners.length == 1) ? 80.0 : 64.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AvatarWidget(
          avatarUrlOrId: player.avatarId,
          size: avatarSize,
          isWinner: true,
        ),
        const SizedBox(height: 12),
        Text(
          player.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withOpacity(0.5)),
          ),
          child: Text(
            '${player.voteCount} أصوات',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _voteSummary() {
    final sorted = [...widget.payload.players]
      ..sort((a, b) => b.voteCount.compareTo(a.voteCount));
    final withVotes = sorted.where((p) => p.voteCount > 0).toList();
    if (withVotes.isEmpty) return const SizedBox.shrink();

    final maxVotes = withVotes.first.voteCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxBarWidth = constraints.maxWidth * 0.4;
        return Column(
          children: withVotes.map((p) {
            final fraction = maxVotes > 0 ? p.voteCount / maxVotes : 0.0;
            final barColor = p.isWinner ? AppColors.accent : AppColors.primary;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    p.displayName,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  // Vote bar track
                  Container(
                    width: maxBarWidth,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: FractionallySizedBox(
                        widthFactor: fraction,
                        child: Container(
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${p.voteCount}',
                    style: TextStyle(
                      color: p.isWinner ? AppColors.accent : Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildShareButton() {
    return OutlinedButton.icon(
      key: _shareButtonKey,
      onPressed: _isSharing ? null : _onShareRequested,
      icon: _isSharing
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.share, color: Colors.white),
      label: Text(
        _isSharing ? 'جاري المشاركة...' : 'مشاركة النتيجة',
        style: const TextStyle(color: Colors.white),
      ),
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: Colors.white38),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      ),
    );
  }

  /// Captures the card as PNG and opens the native share sheet.
  ///
  /// Guards against concurrent execution via [_isSharing].
  Future<void> _onShareRequested() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      // Resolve the share button's position for iOS popover anchoring.
      Rect? sharePositionOrigin;
      final renderBox =
          _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final offset = renderBox.localToGlobal(Offset.zero);
        sharePositionOrigin = offset & renderBox.size;
      }
      await ShareService.shareWidget(
        repaintBoundaryKey: _repaintBoundaryKey,
        shareText: 'من الذيب في مجموعتنا؟ 🐺 #مين_الذيب',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل المشاركة: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }
}

/// Shows the [ResultCardWidget] in a draggable bottom sheet.
void showResultCardSheet(BuildContext context, ResultCardPayload payload) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) => SingleChildScrollView(
        controller: controller,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: ResultCardWidget(payload: payload),
        ),
      ),
    ),
  );
}
