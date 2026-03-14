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
/// The entire gradient container is wrapped in a [RepaintBoundary] so that
/// [ShareService.shareWidget] can capture it cleanly without capturing the
/// surrounding bottom-sheet chrome.
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
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
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
            // Decorative background patterns
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                  const SizedBox(height: 32),

                  // Question Box
                  Container(
                    padding: const EdgeInsets.all(16),
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
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Result content
                  if (!widget.payload.hasValidResult) ...[
                    _insufficientVotesContent(),
                  ] else ...[
                    _resultContent(),
                  ],

                  const SizedBox(height: 32),

                  // Social context
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

                  const SizedBox(height: 24),
                  
                  _buildShareButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _insufficientVotesContent() {
    return const Column(
      children: [
        Text('🐺', style: TextStyle(fontSize: 48)),
        SizedBox(height: 8),
        Text(
          'الأصوات غير كافية',
          style: TextStyle(
            color: Colors.white70,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _resultContent() {
    final winners = widget.payload.winners;
    final isTie = widget.payload.resultType == 'tie';

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: (isTie ? Colors.orange : AppColors.primary).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isTie ? Colors.orange : AppColors.primary).withOpacity(0.3),
            ),
          ),
          child: Text(
            isTie ? 'تعادل! المشتبه بهم:' : 'الذيب طلع من بيننا...',
            style: TextStyle(
              color: isTie ? Colors.orange[300] : AppColors.primary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 32),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 24,
          runSpacing: 24,
          children: winners.map((p) => _playerChip(p)).toList(),
        ),
        if (widget.payload.players.isNotEmpty) ...[
          const SizedBox(height: 32),
          _voteSummary(),
        ],
      ],
    );
  }

  Widget _playerChip(ResultCardPlayerInfo player) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AvatarWidget(
          avatarUrlOrId: player.avatarId,
          size: 64,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sorted
          .where((p) => p.voteCount > 0)
          .map(
            (p) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    p.displayName,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${p.voteCount}',
                    style: TextStyle(
                      color: p.isWinner ? AppColors.accent : Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildShareButton() {
    return OutlinedButton.icon(
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
      await ShareService.shareWidget(
        repaintBoundaryKey: _repaintBoundaryKey,
        shareText: 'من الذيب في مجموعتنا؟ 🐺 #مين_الذيب',
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
