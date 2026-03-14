import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/components/game_button.dart';
import '../../../shared/components/page_container.dart';
import '../../../core/theme/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo / Illustration Placeholder
              Hero(
                tag: 'logo',
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 4),
                  ),
                  child: const Center(
                    child: Text(
                      '🐺',
                      style: TextStyle(fontSize: 80),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // App Title & Tagline
              const Text(
                'مين الذيب؟',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'لعبة الذكاء، الخداع، والضحك الجماعي',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              
              const SizedBox(height: 64),
              
              // Main Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    GameButton(
                      text: 'إنشاء غرفة جديدة',
                      onPressed: () => context.push('/create-room'),
                    ),
                    const SizedBox(height: 20),
                    OutlinedButton(
                      onPressed: () => context.push('/join-room'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30, width: 2),
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'انضمام بالرمز',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Diagnostic / Debug
              TextButton(
                onPressed: () => context.push('/test-backend'),
                child: Text(
                  'Diagnostic Mode',
                  style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
