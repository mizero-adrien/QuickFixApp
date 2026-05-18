import 'package:flutter/material.dart';
import 'package:quickfix/services/supabase_service.dart';
import 'package:quickfix/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _navigateAfterSplash();
  }

  Future<void> _navigateAfterSplash() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Check for password recovery token or route in URL
    final uri = Uri.base;
    final fragment = uri.fragment;
    final normalizedFragment = fragment.startsWith('/') ? fragment : '/$fragment';
    final isRecovery = fragment.contains('type=recovery') ||
        uri.queryParameters['type'] == 'recovery' ||
        normalizedFragment.contains('/password-recovery') ||
        uri.path == '/password-recovery';

    if (isRecovery) {
      debugPrint('[SplashScreen] Recovery token detected in URL: $uri');
      try {
        await SupabaseService.recoverSessionFromUrl(uri);
      } catch (e) {
        debugPrint('[SplashScreen] Recovery session restore failed: $e');
      }
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/password-recovery',
        );
      }
      return;
    }

    final user = SupabaseService.currentUser;
    if (user != null) {
      await SupabaseService.loadUserSession();
    }
    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        user != null ? '/home' : '/login',
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha:0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '🔧',
                      style: TextStyle(fontSize: 52),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // App name
                const Text(
                  'QuickFix',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                // Tagline
                const Text(
                  'Find. Book. Fix.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 48),
                // Loading indicator
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white70,
                    strokeWidth: 2,
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