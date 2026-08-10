import 'package:flutter/material.dart';
import 'package:zindagi_plus/core/theme/app_theme.dart';
import 'package:zindagi_plus/shared/widgets/premium_ui.dart';

// ── Mock recommendations data ──────────────────────────────────────────────────

const _mockRecommendations = <String, Map<String, dynamic>>{
  '1': {
    'type': 'medication',
    'typeEmoji': '💊',
    'typeLabel': 'Medication',
    'typeColor': 0xFF6D8CFF,
    'title': 'Take Metformin 500mg',
    'subtitle': 'Reduces blood glucose levels effectively',
    'why':
        'Your HbA1c of 6.8% indicates pre-diabetic range. Metformin is the first-line medication for Type 2 Diabetes management and has been shown to reduce HbA1c by 1–2% over 3 months with minimal side effects.',
    'steps': [
      'Take 1 tablet (500mg) with your evening meal',
      'Store at room temperature, away from moisture',
      'Do not skip doses — consistency is key for effect',
      'Report any stomach discomfort to your doctor',
    ],
    'impact': 'Expected HbA1c reduction of 1–1.5% over 12 weeks',
    'priority': 'High',
    'priorityColor': 0xFFEF4444,
  },
  '2': {
    'type': 'nutrition',
    'typeEmoji': '🥗',
    'typeLabel': 'Nutrition',
    'typeColor': 0xFF43D6A2,
    'title': 'Increase Fibre Intake',
    'subtitle': 'Aids blood sugar control and gut health',
    'why':
        'Your current fibre intake is estimated at ~12g/day, well below the recommended 25–38g/day. Higher fibre slows glucose absorption, which directly supports your HbA1c goal and reduces LDL cholesterol.',
    'steps': [
      'Add 1 cup of lentils or beans to lunch daily',
      'Replace white rice with brown rice or quinoa',
      'Include 2 servings of vegetables per meal',
      'Snack on almonds or walnuts instead of packaged food',
    ],
    'impact': 'Could reduce LDL cholesterol by 5–10% in 8 weeks',
    'priority': 'Medium',
    'priorityColor': 0xFFF59E0B,
  },
  '3': {
    'type': 'activity',
    'typeEmoji': '🏃',
    'typeLabel': 'Activity',
    'typeColor': 0xFF63DDF4,
    'title': '20-Min Morning Walk',
    'subtitle': 'Improves insulin sensitivity significantly',
    'why':
        'Walking 20 minutes daily in a fasted state (morning) reduces insulin resistance by up to 30%. Given your activity score of 58/100 and pre-diabetic status, this single habit change is the most impactful lifestyle modification.',
    'steps': [
      'Walk at a brisk pace (you should be slightly breathless)',
      'Aim for 6,000 steps before breakfast',
      'Start with 10 minutes and build up over 2 weeks',
      'Track using your phone\'s health app',
    ],
    'impact': 'Boosts Activity score from 58 → 75+ in 3 weeks',
    'priority': 'High',
    'priorityColor': 0xFFEF4444,
  },
  '4': {
    'type': 'insight',
    'typeEmoji': '💡',
    'typeLabel': 'Insight',
    'typeColor': 0xFF9AF4D0,
    'title': 'Increase Vitamin D',
    'subtitle': 'Critical deficiency detected in your report',
    'why':
        'Your Vitamin D level of 18 ng/mL is clinically deficient (<20 ng/mL). Low Vitamin D is linked to insulin resistance, fatigue, and reduced immunity. This can be corrected quickly with supplementation and sunlight.',
    'steps': [
      'Take a Vitamin D3 supplement (2000 IU) daily with a meal',
      'Get 15–20 minutes of direct sunlight between 10 AM–2 PM',
      'Consume fatty fish, egg yolks, or fortified dairy',
      'Re-test Vitamin D levels in 8 weeks',
    ],
    'impact': 'Levels should normalise to 30+ ng/mL in 6–8 weeks',
    'priority': 'High',
    'priorityColor': 0xFFEF4444,
  },
};

// ── Screen ─────────────────────────────────────────────────────────────────────

class RecommendationDetailScreen extends StatefulWidget {
  const RecommendationDetailScreen({super.key, required this.id});
  final String id;

  @override
  State<RecommendationDetailScreen> createState() =>
      _RecommendationDetailScreenState();
}

class _RecommendationDetailScreenState
    extends State<RecommendationDetailScreen> with TickerProviderStateMixin {
  bool _markedDone = false;
  late final AnimationController _headerCtrl;
  late final AnimationController _contentCtrl;
  late final List<AnimationController> _stepCtls;

  Map<String, dynamic> get _rec =>
      _mockRecommendations[widget.id] ??
      _mockRecommendations['1']!;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _contentCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    Future.delayed(
      const Duration(milliseconds: 200),
      () => mounted ? _contentCtrl.forward() : null,
    );

    final steps = (_rec['steps'] as List).length;
    _stepCtls = List.generate(
      steps,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 380),
      ),
    );
    for (int i = 0; i < steps; i++) {
      Future.delayed(Duration(milliseconds: 350 + i * 90), () {
        if (mounted) _stepCtls[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _contentCtrl.dispose();
    for (final c in _stepCtls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rec = _rec;
    final accentColor = Color(rec['typeColor'] as int);
    final steps = rec['steps'] as List<String>;

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          actions: [
            // Type badge
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: .14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: accentColor.withValues(alpha: .35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    rec['typeEmoji'] as String,
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    rec['typeLabel'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: accentColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          children: [
            // ── Header ────────────────────────────────────────────────────────
            AnimatedBuilder(
              animation: _headerCtrl,
              builder: (_, _) {
                final t = CurvedAnimation(
                  parent: _headerCtrl,
                  curve: Curves.easeOutBack,
                ).value.clamp(0.0, 1.0);
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        // Priority badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Color(rec['priorityColor'] as int)
                                .withValues(alpha: .14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${rec['priority']} Priority',
                            style: TextStyle(
                              fontSize: 10,
                              color: Color(rec['priorityColor'] as int),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          rec['title'] as String,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            height: 1.2,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          rec['subtitle'] as String,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                );
              },
            ),

            // ── Why section ───────────────────────────────────────────────────
            AnimatedBuilder(
              animation: _contentCtrl,
              builder: (_, child) {
                final t = CurvedAnimation(
                  parent: _contentCtrl,
                  curve: Curves.easeOutCubic,
                ).value;
                return Opacity(opacity: t, child: child);
              },
              child: GlassPanel(
                padding: const EdgeInsets.all(20),
                radius: 24,
                gradient: LinearGradient(
                  colors: [
                    accentColor.withValues(alpha: .10),
                    accentColor.withValues(alpha: .03),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          color: accentColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Why this recommendation?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      rec['why'] as String,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.65,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface.withValues(alpha: .6),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: accentColor.withValues(alpha: .25),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.trending_up_rounded,
                            color: accentColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              rec['impact'] as String,
                              style: TextStyle(
                                fontSize: 12,
                                color: accentColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ── How to action ─────────────────────────────────────────────────
            const Text(
              'How to Action',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            // Step list with stagger (Apple §8: hint direction)
            ...List.generate(steps.length, (i) {
              return AnimatedBuilder(
                animation: _stepCtls[i],
                builder: (_, _) {
                  final t = CurvedAnimation(
                    parent: _stepCtls[i],
                    curve: Curves.easeOutBack,
                  ).value.clamp(0.0, 1.0);
                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset((1 - t) * 24, 0),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _StepCard(
                          index: i,
                          text: steps[i],
                          accentColor: accentColor,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            const SizedBox(height: 28),

            // ── Mark as Done ──────────────────────────────────────────────────
            _DoneButton(
              done: _markedDone,
              onPressed: () => setState(() => _markedDone = !_markedDone),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Step card ──────────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.text,
    required this.accentColor,
  });
  final int index;
  final String text;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(16),
      radius: 18,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: .15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accentColor.withValues(alpha: .35)),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: accentColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Done button (Apple §1: respond on pointer-down) ────────────────────────────

class _DoneButton extends StatefulWidget {
  const _DoneButton({required this.done, required this.onPressed});
  final bool done;
  final VoidCallback onPressed;

  @override
  State<_DoneButton> createState() => _DoneButtonState();
}

class _DoneButtonState extends State<_DoneButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: _pressed ? 0.97 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          height: 56,
          decoration: BoxDecoration(
            gradient: widget.done
                ? const LinearGradient(
                    colors: [AppColors.emerald, Color(0xFF238F87)],
                  )
                : null,
            color: widget.done ? null : AppColors.surface,
            borderRadius: BorderRadius.circular(22),
            border: widget.done
                ? null
                : Border.all(color: AppColors.emerald.withValues(alpha: .5)),
            boxShadow: widget.done
                ? [
                    BoxShadow(
                      color: AppColors.emerald.withValues(alpha: .3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: Icon(
                  widget.done
                      ? Icons.check_circle_rounded
                      : Icons.check_circle_outline_rounded,
                  key: ValueKey(widget.done),
                  color: widget.done ? AppColors.background : AppColors.emerald,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: widget.done ? AppColors.background : AppColors.emerald,
                ),
                child: Text(
                  widget.done ? 'Completed ✓' : 'Mark as Done',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
