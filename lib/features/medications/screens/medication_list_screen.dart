import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:zindagi_plus/core/theme/app_theme.dart';
import 'package:zindagi_plus/shared/widgets/premium_ui.dart';

// ── Mock data ──────────────────────────────────────────────────────────────────

enum _MedStatus { taken, pending, missed }

class _Medication {
  _Medication({
    required this.name,
    required this.dose,
    required this.time,
    required this.status,
    required this.icon,
    required this.color,
    required this.note,
  });
  final String name, dose, time, note;
  _MedStatus status;
  final IconData icon;
  final Color color;
}

final _medications = [
  _Medication(
    name: 'Metformin',
    dose: '500mg',
    time: '8:00 AM — With breakfast',
    status: _MedStatus.taken,
    icon: Icons.medication_rounded,
    color: AppColors.emerald,
    note: 'For blood glucose control',
  ),
  _Medication(
    name: 'Vitamin D3',
    dose: '2000 IU',
    time: '1:00 PM — With lunch',
    status: _MedStatus.pending,
    icon: Icons.wb_sunny_outlined,
    color: AppColors.warning,
    note: 'Deficiency correction',
  ),
  _Medication(
    name: 'Omega-3',
    dose: '1000mg',
    time: '8:00 PM — With dinner',
    status: _MedStatus.pending,
    icon: Icons.water_drop_outlined,
    color: AppColors.cyan,
    note: 'For LDL cholesterol support',
  ),
  _Medication(
    name: 'Metformin (Evening)',
    dose: '500mg',
    time: '8:00 PM — With dinner',
    status: _MedStatus.missed,
    icon: Icons.medication_rounded,
    color: AppColors.error,
    note: 'Missed yesterday',
  ),
];

// ── Screen ─────────────────────────────────────────────────────────────────────

class MedicationListScreen extends StatefulWidget {
  const MedicationListScreen({super.key});

  @override
  State<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends State<MedicationListScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ringCtrl;
  late final List<AnimationController> _cardCtls;

  int get _takenCount =>
      _medications.where((m) => m.status == _MedStatus.taken).length;
  int get _totalCount => _medications.length;
  double get _adherence => _takenCount / _totalCount;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
    _cardCtls = List.generate(
      _medications.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    for (int i = 0; i < _cardCtls.length; i++) {
      Future.delayed(Duration(milliseconds: 250 + i * 90), () {
        if (mounted) _cardCtls[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    for (final c in _cardCtls) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggleStatus(int index) {
    setState(() {
      // Cycle: pending → taken → missed → pending
      final m = _medications[index];
      if (m.status == _MedStatus.pending) {
        m.status = _MedStatus.taken;
      } else if (m.status == _MedStatus.taken) {
        m.status = _MedStatus.missed;
      } else {
        m.status = _MedStatus.pending;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Medications'),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.history_rounded),
            ),
          ],
        ),
        floatingActionButton: _AddMedFab(),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
          children: [
            // ── Adherence ring banner ─────────────────────────────────────
            AnimatedBuilder(
              animation: _ringCtrl,
              builder: (_, _) {
                final t = CurvedAnimation(
                  parent: _ringCtrl,
                  curve: Curves.easeOutCubic,
                ).value;
                return GlassPanel(
                  padding: const EdgeInsets.all(20),
                  radius: 28,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.emerald.withValues(alpha: .13),
                      AppColors.cyan.withValues(alpha: .04),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 88,
                        height: 88,
                        child: CustomPaint(
                          painter: _AdherenceRingPainter(_adherence * t),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${(_adherence * t * 100).round()}%',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const Text(
                                  'today',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Adherence Today',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$_takenCount of $_totalCount doses taken',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                _StatusDot(AppColors.emerald, 'Taken'),
                                const SizedBox(width: 10),
                                _StatusDot(AppColors.warning, 'Pending'),
                                const SizedBox(width: 10),
                                _StatusDot(AppColors.error, 'Missed'),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 24),
            const Text(
              "Today's Schedule",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            // ── Medication cards ──────────────────────────────────────────
            ...List.generate(_medications.length, (i) {
              return AnimatedBuilder(
                animation: _cardCtls[i],
                builder: (_, child) {
                  final t = CurvedAnimation(
                    parent: _cardCtls[i],
                    curve: Curves.easeOutBack,
                  ).value.clamp(0.0, 1.0);
                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, (1 - t) * 20),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MedCard(
                    med: _medications[i],
                    onToggle: () => _toggleStatus(i),
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

// ── Medication card ────────────────────────────────────────────────────────────

class _MedCard extends StatefulWidget {
  const _MedCard({required this.med, required this.onToggle});
  final _Medication med;
  final VoidCallback onToggle;

  @override
  State<_MedCard> createState() => _MedCardState();
}

class _MedCardState extends State<_MedCard> {
  bool _pressed = false;

  Color get _statusColor {
    return switch (widget.med.status) {
      _MedStatus.taken => AppColors.emerald,
      _MedStatus.pending => AppColors.warning,
      _MedStatus.missed => AppColors.error,
    };
  }

  String get _statusLabel {
    return switch (widget.med.status) {
      _MedStatus.taken => 'Taken ✓',
      _MedStatus.pending => 'Pending',
      _MedStatus.missed => 'Missed',
    };
  }

  IconData get _statusIcon {
    return switch (widget.med.status) {
      _MedStatus.taken => Icons.check_circle_rounded,
      _MedStatus.pending => Icons.radio_button_unchecked_rounded,
      _MedStatus.missed => Icons.cancel_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onToggle();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: _pressed ? 0.97 : 1.0,
        child: GlassPanel(
          padding: const EdgeInsets.all(16),
          radius: 22,
          gradient: LinearGradient(
            colors: [
              _statusColor.withValues(alpha: .08),
              _statusColor.withValues(alpha: .02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: widget.med.color.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.med.color.withValues(alpha: .35),
                  ),
                ),
                child: Icon(widget.med.icon, color: widget.med.color, size: 22),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.med.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.med.dose,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.med.time,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.med.note,
                      style: TextStyle(
                        fontSize: 10,
                        color: widget.med.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Status toggle (Apple §1: tap → instant visual response)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: child,
                ),
                child: Column(
                  key: ValueKey(widget.med.status),
                  children: [
                    Icon(_statusIcon, color: _statusColor, size: 26),
                    const SizedBox(height: 3),
                    Text(
                      _statusLabel,
                      style: TextStyle(
                        fontSize: 9,
                        color: _statusColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add med FAB (Apple §1: respond on pointer-down) ───────────────────────────

class _AddMedFab extends StatefulWidget {
  @override
  State<_AddMedFab> createState() => _AddMedFabState();
}

class _AddMedFabState extends State<_AddMedFab> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.93 : 1.0,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.emerald, Color(0xFF238F87)],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: AppColors.emerald.withValues(alpha: .35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: AppColors.background, size: 20),
              SizedBox(width: 8),
              Text(
                'Add Medication',
                style: TextStyle(
                  color: AppColors.background,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Supporting widgets ─────────────────────────────────────────────────────────

class _StatusDot extends StatelessWidget {
  const _StatusDot(this.color, this.label);
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: color),
        ),
      ],
    );
  }
}

class _AdherenceRingPainter extends CustomPainter {
  const _AdherenceRingPainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 7;
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..color = AppColors.divider
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..color = AppColors.emerald
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_AdherenceRingPainter old) => old.progress != progress;
}
