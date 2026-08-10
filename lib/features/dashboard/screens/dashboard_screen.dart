import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';
import 'package:zindagi_plus/providers/health_providers.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

String _greeting() {
  final hour = DateTime.now().hour;
  if (hour < 12) return 'Good morning,';
  if (hour < 17) return 'Good afternoon,';
  return 'Good evening,';
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider);
    final dashboard = ref.watch(dashboardDataProvider);
    
    return Scaffold(
      body: SafeArea(
        child: dashboard.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (e, st) => ErrorStateWidget(
            message: e.toString(),
          ),
          data: (data) => _Content(
            name: user?.name ?? 'there',
            data: data,
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.name, required this.data});
  final String name;
  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final insights = data['recentInsights'] as List<dynamic>;
    
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      children: [
        // ── Greeting row ─────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _greeting(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ),
            AppCard(
              padding: const EdgeInsets.all(12),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: colorScheme.onSurface,
                  ),
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorScheme.secondary, // Burgundy indicator
                        shape: BoxShape.circle,
                        border: Border.all(color: colorScheme.surface, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        SectionHeader(
          title: 'Your health, at a glance',
        ),
        const SizedBox(height: 16),

        // ── Score panel — tappable → /score-breakdown ─────────────────────
        _TapScorePanel(
          score: data['healthScore'] as int,
          activeMeds: data['activeMeds'] as int,
          lastReport: data['lastReport'] as String,
          weight: data['weight'] as String,
          onTap: () => context.push('/score-breakdown'),
        ),

        const SizedBox(height: 24),

        // ── Quick actions row ─────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.directions_run_rounded,
                label: 'Activities',
                onTap: () => context.push('/activities'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.medication_outlined,
                label: 'Medications',
                onTap: () => context.push('/medications'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickAction(
                icon: Icons.history_rounded,
                label: 'Timeline',
                onTap: () => context.push('/timeline'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 32),

        // ── AI insights ───────────────────────────────────────────────────
        Row(
          children: [
            Flexible(
              child: Text(
                'Zindagi intelligence',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            const StatusBadge(text: 'LIVE', status: BadgeStatus.normal),
          ],
        ),
        const SizedBox(height: 16),

        ...insights.asMap().entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _Insight(
              text: entry.value as String,
              recId: '${entry.key + 1}',
            ),
          ),
        ),
      ],
    );
  }
}

class _TapScorePanel extends StatefulWidget {
  const _TapScorePanel({
    required this.score,
    required this.activeMeds,
    required this.lastReport,
    required this.weight,
    required this.onTap,
  });
  final int score;
  final int activeMeds;
  final String lastReport, weight;
  final VoidCallback onTap;

  @override
  State<_TapScorePanel> createState() => _TapScorePanelState();
}

class _TapScorePanelState extends State<_TapScorePanel> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _pressed ? 0.98 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.primary, // Solid Emerald background
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HEALTH PULSE',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'A calm day to build on.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to see score breakdown  →',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ScoreRing(score: widget.score),
                ],
              ),
              const SizedBox(height: 24),
              Container(height: 1, color: Colors.white.withValues(alpha: 0.2)),
              const SizedBox(height: 16),
              Row(
                children: [
                  _Stat(value: '${widget.activeMeds}', label: 'medicines'),
                  _Stat(value: widget.lastReport, label: 'latest report'),
                  _Stat(value: widget.weight, label: 'current weight'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value, label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreRing extends StatefulWidget {
  const _ScoreRing({required this.score});
  final int score;

  @override
  State<_ScoreRing> createState() => _ScoreRingState();
}

class _ScoreRingState extends State<_ScoreRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..forward();

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (_, _) => SizedBox(
        width: 90,
        height: 90,
        child: CustomPaint(
          painter: _Ring(widget.score / 100 * c.value),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(widget.score * c.value).round()}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'score',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Ring extends CustomPainter {
  const _Ring(this.progress);
  final double progress;

  @override
  void paint(Canvas c, Size s) {
    final rect = Rect.fromLTWH(7, 7, s.width - 14, s.height - 14);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    p.color = Colors.white.withValues(alpha: 0.2);
    c.drawArc(rect, -math.pi / 2, math.pi * 2, false, p);
    p.color = Colors.white; // Solid white progress on top of emerald card
    c.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, p);
  }

  @override
  bool shouldRepaint(_Ring o) => o.progress != progress;
}

class _QuickAction extends StatefulWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        scale: _pressed ? 0.95 : 1.0,
        child: AppCard(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Insight extends StatefulWidget {
  const _Insight({required this.text, required this.recId});
  final String text;
  final String recId;

  @override
  State<_Insight> createState() => _InsightState();
}

class _InsightState extends State<_Insight> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        context.push('/recommendation/${widget.recId}');
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        scale: _pressed ? 0.98 : 1.0,
        child: AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  widget.text,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.3),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
