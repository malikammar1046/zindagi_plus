import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

class ScoreBreakdownScreen extends StatefulWidget {
  const ScoreBreakdownScreen({super.key});

  @override
  State<ScoreBreakdownScreen> createState() => _ScoreBreakdownScreenState();
}

class _ScoreBreakdownScreenState extends State<ScoreBreakdownScreen>
    with TickerProviderStateMixin {
  late List<Map<String, dynamic>> _components;
  late final AnimationController _ringCtrl;
  late final AnimationController _pulseCtrl;
  late final List<AnimationController> _barCtls;
  int? _expandedIndex;

  int get _overallScore {
    final sum = _components.map((c) => c['score'] as int).reduce((a, b) => a + b);
    return (sum / _components.length).round();
  }

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    // We use the same primary color or slightly varied semantic colors if needed.
    // For consistency with white+emerald, let's use primary for most, and maybe burgundy (secondary) for warning.
    _components = [
      {
        'label': 'Nutrition',
        'score': 72,
        'color': primary,
        'icon': Icons.restaurant_outlined,
        'desc': 'Based on your recent meal logs. Protein intake is on track but fibre could be higher.',
        'tip': 'Add 1 serving of vegetables to each meal.',
      },
      {
        'label': 'Activity',
        'score': 58,
        'color': theme.colorScheme.secondary, // Burgundy for a lower score to draw attention
        'icon': Icons.directions_run_rounded,
        'desc': 'Steps and exercise minutes tracked this week. You\'re averaging 4,200 steps/day.',
        'tip': 'A 20-min walk daily would push this to 75+.',
      },
      {
        'label': 'Lab Results',
        'score': 81,
        'color': primary,
        'icon': Icons.biotech_outlined,
        'desc': 'Latest bloodwork shows 6 of 8 markers trending normal. HbA1c remains borderline.',
        'tip': 'Schedule follow-up test in 6 weeks.',
      },
      {
        'label': 'Medication',
        'score': 90,
        'color': primary,
        'icon': Icons.medication_outlined,
        'desc': 'Excellent adherence this month. You\'ve taken 27 of 30 scheduled doses on time.',
        'tip': 'Keep it up — consistency is everything.',
      },
    ];
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Score'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          // ── Score ring ─────────────────────────────────────────────────
          AnimatedBuilder(
            animation: Listenable.merge([_ringCtrl, _pulseCtrl]),
            builder: (_, _) {
              final glow = 0.05 + _pulseCtrl.value * 0.05; // Reduced glow for light mode
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: glow),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: CustomPaint(
                      painter: _ScoreRingPainter(
                        _overallScore / 100 * _ringCtrl.value,
                        colorScheme.primary,
                        theme.dividerColor,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${(_overallScore * _ringCtrl.value).round()}',
                              style: TextStyle(
                                fontSize: 56,
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
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
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

          const SizedBox(height: 16),
          // ── Info banner ────────────────────────────────────────────────
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

          const SizedBox(height: 32),
          const SectionHeader(title: 'Score Breakdown'),
          const SizedBox(height: 16),

          // ── Component cards ────────────────────────────────────────────
          ...List.generate(4, (i) {
            final comp = _components[i];
            final expanded = _expandedIndex == i;
            final Color compColor = comp['color'] as Color;
            
            return AnimatedBuilder(
              animation: _barCtls[i],
              builder: (_, _) {
                final t = CurvedAnimation(
                  parent: _barCtls[i],
                  curve: Curves.easeOutBack,
                ).value.clamp(0.0, 1.0);
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 28),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _TapScale(
                        onTap: () => setState(
                          () => _expandedIndex = expanded ? null : i,
                        ),
                        child: AppCard(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: compColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Icon(
                                      comp['icon'] as IconData,
                                      color: compColor,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          comp['label'] as String,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        // Score bar
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: TweenAnimationBuilder<double>(
                                            tween: Tween(
                                              begin: 0,
                                              end: (comp['score'] as int) / 100,
                                            ),
                                            duration: const Duration(
                                              milliseconds: 800,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            builder: (_, v, _) =>
                                                LinearProgressIndicator(
                                              value: v,
                                              minHeight: 8,
                                              backgroundColor:
                                                  theme.dividerColor,
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                compColor,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Text(
                                    '${comp['score']}',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: compColor,
                                    ),
                                  ),
                                ],
                              ),
                              AnimatedSize(
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOutCubic,
                                child: expanded
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 20),
                                          const Divider(),
                                          const SizedBox(height: 16),
                                          Text(
                                            comp['desc'] as String,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                                              height: 1.5,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.tips_and_updates_outlined,
                                                color: compColor,
                                                size: 18,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  comp['tip'] as String,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: compColor,
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
        ..strokeWidth = 16
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
          ..strokeWidth = 16
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ScoreRingPainter old) => old.progress != progress;
}

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
        duration: const Duration(milliseconds: 140),
        scale: _pressed ? 0.97 : 1.0,
        child: widget.child,
      ),
    );
  }
}
