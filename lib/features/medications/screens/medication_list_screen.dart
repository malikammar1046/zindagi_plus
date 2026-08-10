import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

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
    color: const Color(0xFF00674F), // Emerald
    note: 'For blood glucose control',
  ),
  _Medication(
    name: 'Vitamin D3',
    dose: '2000 IU',
    time: '1:00 PM — With lunch',
    status: _MedStatus.pending,
    icon: Icons.wb_sunny_outlined,
    color: Colors.orange,
    note: 'Deficiency correction',
  ),
  _Medication(
    name: 'Omega-3',
    dose: '1000mg',
    time: '8:00 PM — With dinner',
    status: _MedStatus.pending,
    icon: Icons.water_drop_outlined,
    color: Colors.blue,
    note: 'For LDL cholesterol support',
  ),
  _Medication(
    name: 'Metformin (Evening)',
    dose: '500mg',
    time: '8:00 PM — With dinner',
    status: _MedStatus.missed,
    icon: Icons.medication_rounded,
    color: const Color(0xFF670018), // Burgundy
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
  double get _adherence => _totalCount == 0 ? 0 : _takenCount / _totalCount;

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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Scaffold(
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
              return AppCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    SizedBox(
                      width: 88,
                      height: 88,
                      child: CustomPaint(
                        painter: _AdherenceRingPainter(
                          progress: _adherence * t,
                          trackColor: theme.dividerColor,
                          progressColor: colorScheme.primary,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(_adherence * t * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                'today',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: colorScheme.onSurface.withValues(alpha: 0.6),
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
                          Text(
                            'Adherence Today',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$_takenCount of $_totalCount doses taken',
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              _StatusDot(colorScheme.primary, 'Taken'),
                              const _StatusDot(Colors.orange, 'Pending'),
                              const _StatusDot(Colors.red, 'Missed'),
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
          const SectionHeader(title: "Today's Schedule"),
          const SizedBox(height: 16),

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

  Color _getStatusColor(ColorScheme scheme) {
    return switch (widget.med.status) {
      _MedStatus.taken => scheme.primary,
      _MedStatus.pending => Colors.orange,
      _MedStatus.missed => Colors.red,
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(colorScheme);

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
        child: AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: widget.med.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: widget.med.color.withValues(alpha: 0.2),
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
                        Flexible(
                          child: Text(
                            widget.med.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          widget.med.dose,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.med.time,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.med.note,
                      style: TextStyle(
                        fontSize: 11,
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
                    Icon(_statusIcon, color: statusColor, size: 28),
                    const SizedBox(height: 4),
                    Text(
                      _statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
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
    final colorScheme = Theme.of(context).colorScheme;
    
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
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, color: colorScheme.onPrimary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Add Medication',
                style: TextStyle(
                  color: colorScheme.onPrimary,
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
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11, 
            color: colorScheme.onSurface.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AdherenceRingPainter extends CustomPainter {
  const _AdherenceRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });
  final double progress;
  final Color trackColor;
  final Color progressColor;

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
        ..color = trackColor
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
          ..color = progressColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_AdherenceRingPainter old) => old.progress != progress;
}
