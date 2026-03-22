import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../services/deep_link/deep_link_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );

    _ctrl.forward().then((_) {
      // Hold briefly, then navigate — check for pending deep link first
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        final deepLink = ref.read(deepLinkServiceProvider);
        final code = deepLink.valueOrNull?.pendingRoomCode;
        if (code != null) {
          ref.read(deepLinkServiceProvider.notifier).clearPendingCode();
          context.go('/join-room?code=$code');
        } else {
          context.go('/home');
        }
      });
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1330),
      body: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Wolf logo — glowing circular container matching home screen hero
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF6C5CE7), Color(0xFF2D1B69)],
                    ),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.6),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.45),
                        blurRadius: 40,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text('🐺', style: TextStyle(fontSize: 60)),
                  ),
                ),
                const SizedBox(height: 28),
                // App title
                const Text(
                  'مين الذيب؟',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                // Tagline
                Text(
                  'لعبة الذكاء، الخداع، والضحك',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
