import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

class ScoreBreakdownScreen extends StatefulWidget {
  const ScoreBreakdownScreen({super.key});

  @override
  State<ScoreBreakdownScreen> createState() => _ScoreBreakdownScreenState();
}

class _ScoreBreakdownScreenState extends State<ScoreBreakdownScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;
  int? _expandedIndex;

  static const List<Map<String, dynamic>> _componentData = [
    {
      'label': 'Nutrition',
      'score': 72,
      'isWarning': false,
      'icon': Icons.restaurant_outlined,
      'desc':
          'Based on your recent meal logs. Protein intake is on track but fibre could be higher.',
      'tip': 'Add 1 serving of vegetables to each meal.',
    },
    {
      'label': 'Activity',
      'score': 58,
      'isWarning': true,
      'icon': Icons.directions_run_rounded,
      'desc':
          'Steps and exercise minutes tracked this week. You\'re averaging 4,200 steps/day.',
      'tip': 'A 20-min walk daily would push this to 75+.',
    },
    {
      'label': 'Lab Results',
      'score': 81,
      'isWarning': false,
      'icon': Icons.biotech_outlined,
      'desc':
          'Latest bloodwork shows 6 of 8 markers trending normal. HbA1c remains borderline.',
      'tip': 'Schedule follow-up test in 6 weeks.',
    },
    {
      'label': 'Medication',
      'score': 90,
      'isWarning': false,
      'icon': Icons.medication_outlined,
      'desc':
          'Excellent adherence this month. You\'ve taken 27 of 30 scheduled doses on time.',
      'tip': 'Keep it up — consistency is everything.',
    },
  ];

  static final int _overallScore = () {
    final sum = _componentData.map((c) => c['score'] as int).reduce((a, b) => a + b);
    return (sum / _componentData.length).round();
  }();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Health Score'),
          leading: const AppBackButton(fallbackLocation: '/dashboard'),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Demo Calculation: This breakdown illustrates the multi-pillar model. Live scoring will calibrate once lab report analysis is enabled.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── Score ring ─────────────────────────────────────────────────
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: AnimatedBuilder(
                animation: _animation,
                builder: (_, _) => Container(
                  width: 190,
                  height: 190,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.08),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    painter: _ScoreRingPainter(
                      _overallScore / 100 * _animation.value,
                      colorScheme.primary,
                      theme.dividerColor,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${(_overallScore * _animation.value).round()}',
                            style: TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.primary,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'out of 100',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Info banner ────────────────────────────────────────────────
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your score is calculated from 4 health pillars. Tap a card to see how to improve it.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),
          const SectionHeader(title: 'Score Breakdown'),
          const SizedBox(height: 16),

          // ── Component cards ────────────────────────────────────────────
          ...List.generate(_componentData.length, (i) {
            final comp = _componentData[i];
            final expanded = _expandedIndex == i;
            final Color compColor = (comp['isWarning'] as bool)
                ? colorScheme.secondary
                : colorScheme.primary;
            final score = comp['score'] as int;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: AppCard(
                onTap: () => setState(
                  () => _expandedIndex = expanded ? null : i,
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: compColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            comp['icon'] as IconData,
                            color: compColor,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comp['label'] as String,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Score bar
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: AnimatedBuilder(
                                  animation: _animation,
                                  builder: (_, _) => LinearProgressIndicator(
                                    value: (score / 100) * _animation.value,
                                    minHeight: 7,
                                    backgroundColor: theme.dividerColor,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      compColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: compColor,
                          ),
                        ),
                      ],
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      child: expanded
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 12),
                                Text(
                                  comp['desc'] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.7,
                                    ),
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.tips_and_updates_outlined,
                                      color: compColor,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        comp['tip'] as String,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: compColor,
                                          fontWeight: FontWeight.w600,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    ),
  );
}
}

class _ScoreRingPainter extends CustomPainter {
  const _ScoreRingPainter(this.progress, this.color, this.bgColor);
  final double progress;
  final Color color;
  final Color bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 24 || size.height <= 24) return;
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 12;
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) => old.progress != progress;
}

