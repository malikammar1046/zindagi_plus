import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageCtrl = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> _pages = [
    {
      'title': 'Your Health, Unified',
      'description': 'Keep all your medical records, timelines, and insights in one secure place.',
      'icon': 'monitor_heart_rounded',
    },
    {
      'title': 'AI Recommendations',
      'description': 'Get personalised meal plans and activity suggestions tailored just for you.',
      'icon': 'auto_awesome_rounded',
    },
    {
      'title': 'Stay on Track',
      'description': 'Never miss a medication or an appointment with smart reminders.',
      'icon': 'schedule_rounded',
    },
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    super.dispose();
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'monitor_heart_rounded':
        return Icons.monitor_heart_rounded;
      case 'auto_awesome_rounded':
        return Icons.auto_awesome_rounded;
      case 'schedule_rounded':
        return Icons.schedule_rounded;
      default:
        return Icons.favorite_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconData(page['icon']!),
                            size: 64,
                            color: colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Text(
                          page['title']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          page['description']!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentIndex == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentIndex == index
                        ? colorScheme.primary
                        : colorScheme.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
            
            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  PrimaryButton(
                    text: _currentIndex == _pages.length - 1 ? 'Get Started' : 'Next',
                    onPressed: () {
                      if (_currentIndex == _pages.length - 1) {
                        context.go('/register');
                      } else {
                        _pageCtrl.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  SecondaryButton(
                    label: 'Already have an account? Log In',
                    onPressed: () {
                      context.go('/login');
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
