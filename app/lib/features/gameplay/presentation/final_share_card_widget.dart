import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../domain/session_summary.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/share/share_service.dart';
import '../../../shared/components/avatar_widget.dart';

/// Shareable final result card widget shown at the end of a session.
///
/// Mission 10: Three visually distinct outcome states:
///   - Single wolf  → dramatic purple/gold, large centered avatar (88px)
///   - Tied wolves  → orange palette, 68px avatars in Wrap
///   - All wolves   → chaos/red palette, 56px avatars in Wrap
///
/// The card content is wrapped in a [RepaintBoundary] so [ShareService.shareWidget]
/// can capture a clean PNG without capturing the share button chrome.
///
/// Events:
///   ShareImageGenerated — raised when [boundary.toImage] completes (in ShareService)
///   ShareRequested      — raised when [Share.shareXFiles] is called (in ShareService)
class FinalShareCardWidget extends StatefulWidget {
  final SessionSummary summary;

  const FinalShareCardWidget({super.key, required this.summary});

  @override
  State<FinalShareCardWidget> createState() => _FinalShareCardWidgetState();
}

class _FinalShareCardWidgetState extends State<FinalShareCardWidget> {
  final _repaintBoundaryKey = GlobalKey();
  final _shareButtonKey = GlobalKey();
  bool _isSharing = false;

  SessionSummary get _summary => widget.summary;

  bool get _isAllWolves =>
      _summary.isSessionTie &&
      _summary.mostVotedPlayerIds.length == _summary.playerDisplayNames.length;

  bool get _isTie => _summary.isSessionTie && !_isAllWolves;

  bool get _isSingle => !_summary.isSessionTie;

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
                colors: [Color(0xFF2D1B69), Color(0xFF1A0A3D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 40,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: _borderColor.withOpacity(0.2),
                width: 1.5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                // Top-right decorative glow
                Positioned(
                  top: -60,
                  right: -60,
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Bottom-left decorative glow
                Positioned(
                  bottom: -60,
                  left: -60,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // All-wolves chaos red tint overlay
                if (_isAllWolves)
                  Positioned(
                    bottom: -40,
                    left: -40,
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [Color(0x22FF4444), Colors.transparent],
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // App branding
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
                      const SizedBox(height: 24),

                      // State-specific content
                      if (_isSingle) _buildSingleWolfContent(),
                      if (_isTie) _buildTieContent(),
                      if (_isAllWolves) _buildAllWolvesContent(),

                      const SizedBox(height: 16),

                      // Session stats strip
                      Text(
                        '${_summary.totalRounds} جولات لعبتموها',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.38),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tagline
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

  // ---------------------------------------------------------------------------
  // Single wolf state
  // ---------------------------------------------------------------------------

  Widget _buildSingleWolfContent() {
    final wolfId = _summary.mostVotedPlayerIds.first;
    final name = _summary.playerDisplayNames[wolfId] ?? 'لاعب';
    final avatarId = _summary.playerAvatarIds[wolfId] ?? '';

    return Column(
      children: [
        const Text(
          'اتُّهم الذيب! 🐺',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.accent,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        AvatarWidget(
          avatarUrlOrId: avatarId,
          size: 88,
          isWinner: true,
        ),
        const SizedBox(height: 12),
        _voteChip(_summary.mostVotedCount),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tied wolves state
  // ---------------------------------------------------------------------------

  Widget _buildTieContent() {
    return Column(
      children: [
        Text(
          'تعادل الذئاب! 🐺🐺',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.orange[300],
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'تساوى المتهمون',
          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 20,
          children: _summary.mostVotedPlayerIds
              .map((id) => _wolfChip(id, 68))
              .toList(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // All-wolves / chaos state
  // ---------------------------------------------------------------------------

  Widget _buildAllWolvesContent() {
    return Column(
      children: [
        Text(
          'الجميع ذئاب! 🌕🌕🌕',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.highlight,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'جلسة الفوضى الكاملة 🔥',
          style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13),
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: _summary.mostVotedPlayerIds
              .map((id) => _wolfChip(id, 56))
              .toList(),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Shared helpers
  // ---------------------------------------------------------------------------

  Color get _borderColor {
    if (_isAllWolves) return AppColors.highlight;
    if (_isTie) return Colors.orange;
    return AppColors.primary;
  }

  Widget _wolfChip(String playerId, double size) {
    final name = _summary.playerDisplayNames[playerId] ?? 'لاعب';
    final avatarId = _summary.playerAvatarIds[playerId] ?? '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AvatarWidget(
          avatarUrlOrId: avatarId,
          size: size,
          isWinner: true,
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        _voteChip(_summary.mostVotedCount),
      ],
    );
  }

  Widget _voteChip(int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withOpacity(0.5)),
      ),
      child: Text(
        '$count أصوات',
        style: const TextStyle(
          color: AppColors.accent,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    final wolfNames = _summary.mostVotedDisplayNames.join(' و ');
    return OutlinedButton.icon(
      key: _shareButtonKey,
      onPressed: _isSharing ? null : () => _onShareRequested(wolfNames),
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

  Future<void> _onShareRequested(String wolfNames) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    try {
      Rect? sharePositionOrigin;
      final renderBox =
          _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final offset = renderBox.localToGlobal(Offset.zero);
        sharePositionOrigin = offset & renderBox.size;
      }
      await ShareService.shareWidget(
        repaintBoundaryKey: _repaintBoundaryKey,
        shareText: 'الذيب هو $wolfNames 🐺 #مين_الذيب',
        fileName: 'meen_al_theeb_final.png',
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

/// Shows the [FinalShareCardWidget] in a draggable bottom sheet.
void showFinalShareCardSheet(BuildContext context, SessionSummary summary) {
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
          child: FinalShareCardWidget(summary: summary),
        ),
      ),
    ),
  );
}
