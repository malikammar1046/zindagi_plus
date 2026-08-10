import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:zindagi_plus/core/theme/app_theme.dart';
import 'package:zindagi_plus/shared/widgets/premium_ui.dart';

class ScoreBreakdownScreen extends StatefulWidget {
  const ScoreBreakdownScreen({super.key});

  @override
  State<ScoreBreakdownScreen> createState() => _ScoreBreakdownScreenState();
}

class _ScoreBreakdownScreenState extends State<ScoreBreakdownScreen>
    with TickerProviderStateMixin {
  static const _components = [
    (
      label: 'Nutrition',
      score: 72,
      color: AppColors.emerald,
      icon: Icons.restaurant_outlined,
      desc:
          'Based on your recent meal logs. Protein intake is on track but fibre could be higher.',
      tip: 'Add 1 serving of vegetables to each meal.',
    ),
    (
      label: 'Activity',
      score: 58,
      color: AppColors.cyan,
      icon: Icons.directions_run_rounded,
      desc:
          'Steps and exercise minutes tracked this week. You\'re averaging 4,200 steps/day.',
      tip: 'A 20-min walk daily would push this to 75+.',
    ),
    (
      label: 'Lab Results',
      score: 81,
      color: AppColors.blue,
      icon: Icons.biotech_outlined,
      desc:
          'Latest bloodwork shows 6 of 8 markers trending normal. HbA1c remains borderline.',
      tip: 'Schedule follow-up test in 6 weeks.',
    ),
    (
      label: 'Medication',
      score: 90,
      color: AppColors.mint,
      icon: Icons.medication_outlined,
      desc:
          'Excellent adherence this month. You\'ve taken 27 of 30 scheduled doses on time.',
      tip: 'Keep it up — consistency is everything.',
    ),
  ];

  late final AnimationController _ringCtrl;
  late final AnimationController _pulseCtrl;
  late final List<AnimationController> _barCtls;
  int? _expandedIndex;

  int get _overallScore {
    final sum = _components.map((c) => c.score).reduce((a, b) => a + b);
    return (sum / _components.length).round();
  }

  @override
  void initState() {
    super.initState();
    // Ring: critically damped, 1.4 s (Apple §4 — damping 1.0, response ~1.4 s)
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    // Bars stagger in: 300 ms base + 100 ms per index (Apple §8 — hint direction)
    _barCtls = List.generate(
      4,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 650),
      ),
    );
    for (int i = 0; i < 4; i++) {
      Future.delayed(Duration(milliseconds: 300 + i * 110), () {
        if (mounted) _barCtls[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    for (final c in _barCtls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Health Score'),
          leading: GestureDetector(
            // Apple §1: respond on pointer-down, not release
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          children: [
            // ── Score ring ─────────────────────────────────────────────────
            AnimatedBuilder(
              animation: Listenable.merge([_ringCtrl, _pulseCtrl]),
              builder: (_, _) {
                final glow = 0.18 + _pulseCtrl.value * 0.07;
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald.withValues(alpha: glow),
                            blurRadius: 56,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _ScoreRingPainter(
                          _overallScore / 100 * _ringCtrl.value,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(_overallScore * _ringCtrl.value).round()}',
                                style: const TextStyle(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                  height: 1,
                                ),
                              ),
                              const Text(
                                'out of 100',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.emerald.withValues(alpha: .15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'HEALTH SCORE',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.mint,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            // ── Info banner ────────────────────────────────────────────────
            GlassPanel(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              radius: 18,
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.cyan,
                    size: 17,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Your score is calculated from 4 health pillars. Tap a card to see how to improve it.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'Score Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            // ── Component cards ────────────────────────────────────────────
            ...List.generate(4, (i) {
              final comp = _components[i];
              final expanded = _expandedIndex == i;
              return AnimatedBuilder(
                animation: _barCtls[i],
                builder: (_, _) {
                  // easeOutBack = spring bounce on enter (Apple §4)
                  final t = CurvedAnimation(
                    parent: _barCtls[i],
                    curve: Curves.easeOutBack,
                  ).value.clamp(0.0, 1.0);
                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, (1 - t) * 28),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _TapScale(
                          onTap: () => setState(
                            () => _expandedIndex = expanded ? null : i,
                          ),
                          child: GlassPanel(
                            padding: const EdgeInsets.all(18),
                            radius: 24,
                            gradient: LinearGradient(
                              colors: [
                                comp.color.withValues(alpha: expanded ? .14 : .07),
                                comp.color.withValues(alpha: .02),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: comp.color.withValues(alpha: .18),
                                        borderRadius: BorderRadius.circular(13),
                                        border: Border.all(
                                          color: comp.color.withValues(alpha: .4),
                                        ),
                                      ),
                                      child: Icon(
                                        comp.icon,
                                        color: comp.color,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            comp.label,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          // Score bar
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: TweenAnimationBuilder<double>(
                                              tween: Tween(
                                                begin: 0,
                                                end: comp.score / 100,
                                              ),
                                              duration: const Duration(
                                                milliseconds: 800,
                                              ),
                                              curve: Curves.easeOutCubic,
                                              builder: (_, v, _) =>
                                                  LinearProgressIndicator(
                                                value: v,
                                                minHeight: 6,
                                                backgroundColor:
                                                    AppColors.divider,
                                                valueColor:
                                                    AlwaysStoppedAnimation<Color>(
                                                  comp.color,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Text(
                                      '${comp.score}',
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: comp.color,
                                      ),
                                    ),
                                  ],
                                ),
                                // Expand section (Apple §3: interruptible, instant)
                                AnimatedSize(
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeOutCubic,
                                  child: expanded
                                      ? Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const SizedBox(height: 14),
                                            Container(
                                              height: 1,
                                              color: comp.color
                                                  .withValues(alpha: .2),
                                            ),
                                            const SizedBox(height: 14),
                                            Text(
                                              comp.desc,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textSecondary,
                                                height: 1.6,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.tips_and_updates_outlined,
                                                  color: comp.color,
                                                  size: 15,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    comp.tip,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: comp.color,
                                                      fontWeight: FontWeight.w600,
                                                      height: 1.5,
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
                        ),
                      ),
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Ring painter ───────────────────────────────────────────────────────────────

class _ScoreRingPainter extends CustomPainter {
  const _ScoreRingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 12;
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..color = AppColors.divider
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
          ..shader = SweepGradient(
            colors: const [AppColors.cyan, AppColors.emerald, AppColors.mint],
            transform: const GradientRotation(-math.pi / 2),
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 14
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) => old.progress != progress;
}

// ── Tap-scale wrapper (Apple §1: respond on pointer-down) ──────────────────────

class _TapScale extends StatefulWidget {
  const _TapScale({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        // Apple §1: instant, 140 ms settle (critically damped)
        duration: const Duration(milliseconds: 140),
        scale: _pressed ? 0.97 : 1.0,
        child: widget.child,
      ),
    );
  }
}
