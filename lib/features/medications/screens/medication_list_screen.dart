import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/medication.dart';
import 'package:zindagi_plus/providers/medication_provider.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

class MedicationListScreen extends ConsumerStatefulWidget {
  const MedicationListScreen({super.key});

  @override
  ConsumerState<MedicationListScreen> createState() =>
      _MedicationListScreenState();
}

class _MedicationListScreenState extends ConsumerState<MedicationListScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ringCtrl;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..forward();
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final medState = ref.watch(medicationProvider);
    final notifier = ref.read(medicationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: '/dashboard'),
        title: const Text('Medications'),
        actions: [
          IconButton(
            onPressed: () => context.push('/medication-history'),
            tooltip: 'Dose History',
            icon: const Icon(Icons.history_rounded),
          ),
        ],
      ),
      floatingActionButton: _AddMedFab(
        onTap: () => context.push('/add-medication'),
      ),
      body: medState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 48, color: colorScheme.error),
                const SizedBox(height: 12),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.error),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => notifier.refresh(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (allMeds) {
          final medications = notifier.activeMedications;
          final takenCount = notifier.takenCount;
          final missedCount = notifier.missedCount;
          final pendingCount = notifier.pendingCount;
          final totalCount = notifier.totalCount;
          final dueCount = notifier.dueCount;
          final adherence = notifier.adherence;

          final subtitleText = totalCount == 0
              ? 'No active medications'
              : dueCount == 0
                  ? '$totalCount scheduled today (all pending)'
                  : '$takenCount of $totalCount doses taken';

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            children: [
              // ── Adherence ring banner ─────────────────────────────────
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
                              progress: adherence * t,
                              trackColor: theme.dividerColor,
                              progressColor: colorScheme.primary,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${(adherence * t * 100).round()}%',
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
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.6),
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
                                subtitleText,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  _StatusDot(colorScheme.primary, '$takenCount Taken'),
                                  _StatusDot(Colors.orange, '$pendingCount Pending'),
                                  _StatusDot(Colors.red, '$missedCount Missed'),
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

              // ── Medication cards ──────────────────────────────────────
              if (medications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Text(
                      'No active medications.\nTap below to add your prescription.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, height: 1.5),
                    ),
                  ),
                )
              else
                ...List.generate(medications.length, (i) {
                  final med = medications[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _MedCard(
                      med: med,
                      onToggle: () async {
                        final result = await ref
                            .read(medicationProvider.notifier)
                            .toggleStatus(i);
                        if (result.isFailure && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to update dose: ${result.failureOrNull?.message ?? ""}'),
                              backgroundColor: Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                      },
                      onDiscontinue: () => _confirmDiscontinue(context, ref, med),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDiscontinue(
    BuildContext context,
    WidgetRef ref,
    Medication med,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'Discontinue medication?',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'This will stop future reminders for this medication.\nPrevious medication and dose history will be preserved.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discontinue'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final result = await ref
          .read(medicationProvider.notifier)
          .deleteMedication(med.id);
      if (context.mounted) {
        switch (result) {
          case Success():
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${med.name} discontinued. History is preserved.'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
          case Failure(message: final msg):
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not discontinue: $msg'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
        }
      }
    }
  }
}


// ── Medication card ────────────────────────────────────────────────────────────

class _MedCard extends StatefulWidget {
  const _MedCard({
    required this.med,
    required this.onToggle,
    required this.onDiscontinue,
  });

  final Medication med;
  final VoidCallback onToggle;
  final VoidCallback onDiscontinue;

  @override
  State<_MedCard> createState() => _MedCardState();
}

class _MedCardState extends State<_MedCard> {
  bool _pressed = false;

  Color _getStatusColor(ColorScheme scheme) {
    return switch (widget.med.status) {
      MedStatus.taken => scheme.primary,
      MedStatus.pending => Colors.orange,
      MedStatus.missed => Colors.red,
    };
  }

  String get _statusLabel {
    return switch (widget.med.status) {
      MedStatus.taken => 'Taken ✓',
      MedStatus.pending => 'Pending',
      MedStatus.missed => 'Missed',
    };
  }

  IconData get _statusIcon {
    return switch (widget.med.status) {
      MedStatus.taken => Icons.check_circle_rounded,
      MedStatus.pending => Icons.radio_button_unchecked_rounded,
      MedStatus.missed => Icons.cancel_outlined,
    };
  }

  IconData _getMedIcon(int codePoint) {
    return switch (codePoint) {
      0xe8fa => Icons.wb_sunny_outlined,
      0xe798 => Icons.water_drop_outlined,
      0xe3a3 => Icons.medication_rounded,
      _ => Icons.medication_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _getStatusColor(colorScheme);
    final itemColor = Color(widget.med.colorValue);
    final itemIcon = _getMedIcon(widget.med.iconCodePoint);

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
                  color: itemColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: itemColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(itemIcon, color: itemColor, size: 22),
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
                    if (widget.med.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.med.note,
                        style: TextStyle(
                          fontSize: 11,
                          color: itemColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Status toggle
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
              // More options menu (Discontinue)
              PopupMenuButton<String>(
                icon: Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                tooltip: 'Medication options',
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                onSelected: (val) {
                  if (val == 'discontinue') {
                    widget.onDiscontinue();
                  }
                },
                itemBuilder: (ctx) => [
                  PopupMenuItem<String>(
                    value: 'discontinue',
                    child: Row(
                      children: [
                        Icon(
                          Icons.cancel_outlined,
                          size: 18,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Discontinue Medication',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Add med FAB ───────────────────────────────────────────────────────────────

class _AddMedFab extends StatefulWidget {
  const _AddMedFab({required this.onTap});
  final VoidCallback onTap;

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
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
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
    if (size.width <= 14 || size.height <= 14) return;
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
