import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    debugPrint('[SPLASH-01] SplashScreen initState()');
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _opacityAnim = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();

    // Auto-navigate after visual splash delay based on real session state
    _timer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      final user = ref.read(authNotifierProvider);
      debugPrint('[SPLASH-02] Splash timer fired, user=${user?.name} onboarded=${user?.isOnboardingCompleted}');
      if (user != null) {
        if (user.isOnboardingCompleted) {
          debugPrint('[SPLASH-03] Navigating to /dashboard');
          context.go('/dashboard');
        } else {
          debugPrint('[SPLASH-03] Navigating to /onboarding/setup');
          context.go('/onboarding/setup');
        }
      } else {
        debugPrint('[SPLASH-03] Navigating to /onboarding');
        context.go('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('[SPLASH-04] SplashScreen build()');
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnim.value,
              child: Transform.scale(
                scale: _scaleAnim.value,
                child: child,
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: Image.asset(
                  'assets/images/Icon.png',
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Zindagi+',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
