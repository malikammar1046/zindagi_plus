import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

class ReportProcessingScreen extends StatefulWidget {
  const ReportProcessingScreen({super.key, this.fileName = 'lab_report.jpg'});
  final String fileName;

  @override
  State<ReportProcessingScreen> createState() => _ReportProcessingScreenState();
}

class _ReportProcessingScreenState extends State<ReportProcessingScreen>
    with TickerProviderStateMixin {
  // ── Step definitions ────────────────────────────────────────────────────────
  static const _steps = [
    (
      icon: Icons.document_scanner_outlined,
      label: 'Reading document',
      detail: 'Extracting text via OCR engine',
      color: Color(0xFF00674F), // Emerald
    ),
    (
      icon: Icons.biotech_outlined,
      label: 'Extracting biomarkers',
      detail: 'Identifying 200+ health markers',
      color: Color(0xFF00674F), // Emerald
    ),
    (
      icon: Icons.auto_awesome_outlined,
      label: 'Running AI analysis',
      detail: 'Comparing against 50M+ records',
      color: Color(0xFF00674F), // Emerald
    ),
    (
      icon: Icons.insights_outlined,
      label: 'Generating insights',
      detail: 'Personalising for your profile',
      color: Color(0xFF00674F), // Emerald
    ),
  ];

  int _currentStep = 0;
  double _stepProgress = 0.0;
  int _secondsRemaining = 12;
  bool _done = false;

  late final AnimationController _ringCtrl;
  late final AnimationController _pulseCtrl;
  late final List<AnimationController> _stepCtls;

  @override
  void initState() {
    super.initState();
    // Ring entrance — critically-damped, 1.4 s
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    // Subtle glow pulse
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    // Step reveal controllers — easeOutBack = spring-like bounce
    _stepCtls = List.generate(
      4,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 420),
      ),
    );

    // Stagger: first step reveals immediately, rest after prior steps
    _stepCtls[0].forward();
    _runProcessing();
  }

  Future<void> _runProcessing() async {
    const tickMs = 95; // 20 ticks × 95 ms ≈ 1.9 s per step
    const ticksPerStep = 20;

    for (int step = 0; step < 4; step++) {
      if (!mounted) return;
      setState(() {
        _currentStep = step;
        _stepProgress = 0;
      });

      // Reveal this step tile (Apple §7 — elements enter from their natural origin)
      if (step > 0) _stepCtls[step].forward();

      for (int t = 1; t <= ticksPerStep; t++) {
        await Future.delayed(const Duration(milliseconds: tickMs));
        if (!mounted) return;
        setState(() {
          _stepProgress = t / ticksPerStep;
          if (t % 5 == 0 && _secondsRemaining > 0) _secondsRemaining--;
        });
      }
      await Future.delayed(const Duration(milliseconds: 180));
    }

    if (!mounted) return;
    setState(() => _done = true);
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    context.go('/upload/result');
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    for (final c in _stepCtls) {
      c.dispose();
    }
    super.dispose();
  }

  double get _overallProgress =>
      (_currentStep + (_done ? 1 : _stepProgress)) / 4;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerColor;
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // ── Header ───────────────────────────────────────────────────
              Text(
                'Analysing Report',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.fileName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),

              const SizedBox(height: 44),

              // ── Progress ring ────────────────────────────────────────────
              // Apple §1: continuous feedback during operation, not just at end
              Center(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulseCtrl]),
                  builder: (_, _) {
                    final glowAlpha = 0.18 + _pulseCtrl.value * 0.08;
                    return Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyan.withValues(alpha: glowAlpha),
                            blurRadius: 48,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _RingPainter(_overallProgress, dividerColor),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(_overallProgress * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              if (!_done)
                                Text(
                                  '~${_secondsRemaining}s left',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                )
                              else
                                Text(
                                  'Done ✓',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 44),

              // ── Step list ────────────────────────────────────────────────
              // Apple §8: each step hints at the direction of processing
              ...List.generate(4, (i) {
                final done = i < _currentStep || _done;
                final active = i == _currentStep && !_done;
                return AnimatedBuilder(
                  animation: _stepCtls[i],
                  builder: (_, _) {
                    // easeOutBack gives spring-like overshoot on entry (Apple §4)
                    final t = CurvedAnimation(
                      parent: _stepCtls[i],
                      curve: Curves.easeOutBack,
                    ).value.clamp(0.0, 1.0);
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, (1 - t) * 22),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _StepTile(
                            icon: _steps[i].icon,
                            label: _steps[i].label,
                            detail: _steps[i].detail,
                            accentColor: _steps[i].color,
                            done: done,
                            active: active,
                            progress: active ? _stepProgress : (done ? 1.0 : 0.0),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step tile ──────────────────────────────────────────────────────────────────

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.icon,
    required this.label,
    required this.detail,
    required this.accentColor,
    required this.done,
    required this.active,
    required this.progress,
  });

  final IconData icon;
  final String label, detail;
  final Color accentColor;
  final bool done, active;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon bubble
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: done || active
                  ? accentColor.withValues(alpha: 0.18)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: done || active
                    ? accentColor.withValues(alpha: 0.45)
                    : theme.dividerColor,
              ),
            ),
            child: Icon(
              done ? Icons.check_rounded : icon,
              color: done || active ? accentColor : colorScheme.onSurface.withValues(alpha: 0.4),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 260),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: active || done
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  child: Text(label),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                // Apple §1: progress bar updates 1:1 with real processing
                if (active) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 4,
                        backgroundColor: theme.dividerColor,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ring painter ───────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  const _RingPainter(this.progress, this.dividerColor);
  final double progress;
  final Color dividerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 10;
    final rect = Rect.fromCircle(center: c, radius: r);

    // Track
    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..color = dividerColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );

    // Progress arc with gradient
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..shader = SweepGradient(
            colors: const [Colors.cyan, Color(0xFF00674F), Colors.teal], // Cyan to Emerald to Teal
            startAngle: 0,
            endAngle: math.pi * 2,
            transform: const GradientRotation(-math.pi / 2),
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
