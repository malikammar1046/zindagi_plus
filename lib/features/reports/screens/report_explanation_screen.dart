import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

class ReportExplanationScreen extends StatelessWidget {
  const ReportExplanationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Explanation'),
        leading: const AppBackButton(fallbackLocation: '/upload/result'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI Explanations will translate medical biomarkers into easy-to-understand language. Always consult your doctor.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Clinical Report Interpretation',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status: On-device OCR captured · AI summary pending release',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'What will this section provide?'),
            const SizedBox(height: 12),
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FeatureBullet(
                    icon: Icons.biotech_outlined,
                    title: 'Structured Biomarker Highlights',
                    description: 'Pinpoints out-of-range blood metrics like HbA1c, lipids, and vitamins with clinically vetted Pakistani reference ranges.',
                  ),
                  const SizedBox(height: 16),
                  _FeatureBullet(
                    icon: Icons.menu_book_outlined,
                    title: 'Plain-English Clinical Summaries',
                    description: 'Explains what elevated or reduced values mean for your day-to-day energy and long-term metabolic health.',
                  ),
                  const SizedBox(height: 16),
                  _FeatureBullet(
                    icon: Icons.lightbulb_outline_rounded,
                    title: 'Actionable Dietary Adjustments',
                    description: 'Provides personalized meal suggestions and habit adjustments tailored to your specific lab results.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Ask AI Health Assistant',
              icon: Icons.chat_bubble_outline_rounded,
              onPressed: () {
                context.go('/chat');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  const _FeatureBullet({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: colorScheme.primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
