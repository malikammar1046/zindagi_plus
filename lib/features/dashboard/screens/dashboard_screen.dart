import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/core/theme/app_theme.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';
import 'package:zindagi_plus/providers/health_providers.dart';
import 'package:zindagi_plus/shared/widgets/premium_ui.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider);
    final dashboard = ref.watch(dashboardDataProvider);
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: dashboard.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.mint),
            ),
            error: (e, _) => Center(
              child: Text(
                e.toString(),
                style: const TextStyle(color: AppColors.error),
              ),
            ),
            data: (data) => _Content(
              name: user?.name ?? 'there',
              data: data,
            ),
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
    final insights = data['recentInsights'] as List<dynamic>;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 116),
      children: [
        // ── Greeting row ─────────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning,',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1,
                        ),
                  ),
                ],
              ),
            ),
            GlassPanel(
              radius: 18,
              padding: const EdgeInsets.all(12),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: AppColors.textPrimary,
                  ),
                  Positioned(
                    right: -1,
                    top: -1,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: AppColors.cyan,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        Text(
          'Your health, at a glance',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 12),

        // ── Score panel — tappable → /score-breakdown ─────────────────────
        // Apple §1: GestureDetector.onTapDown for instant response
        _TapScorePanel(
          score: data['healthScore'] as int,
          activeMeds: data['activeMeds'] as int,
          lastReport: data['lastReport'] as String,
          weight: data['weight'] as String,
          onTap: () => context.push('/score-breakdown'),
        ),

        const SizedBox(height: 20),

        // ── Quick actions row ─────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _QuickAction(
                icon: Icons.directions_run_rounded,
                label: 'Activities',
                color: AppColors.cyan,
                onTap: () => context.push('/activities'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.medication_outlined,
                label: 'Medications',
                color: AppColors.blue,
                onTap: () => context.push('/medications'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickAction(
                icon: Icons.history_rounded,
                label: 'Timeline',
                color: AppColors.mint,
                onTap: () => context.push('/timeline'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 28),

        // ── AI insights ───────────────────────────────────────────────────
        Row(
          children: [
            Text(
              'Zindagi intelligence',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(width: 8),
            const _LivePill(),
          ],
        ),
        const SizedBox(height: 12),

        ...insights.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
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

// ── Tappable score panel (Apple §1: respond on pointer-down) ──────────────────

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
        child: GlassPanel(
          padding: const EdgeInsets.all(22),
          radius: 32,
          gradient: const LinearGradient(
            colors: [Color(0xFF174D46), Color(0xFF162A31)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
                        const Text(
                          'HEALTH PULSE',
                          style: TextStyle(
                            color: AppColors.mint,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.3,
                          ),
                        ),
                        const SizedBox(height: 9),
                        const Text(
                          'A calm day to build on.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Tap to see score breakdown  →',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .62),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _ScoreRing(score: widget.score),
                ],
              ),
              const SizedBox(height: 22),
              Container(height: 1, color: Colors.white.withValues(alpha: .12)),
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
  Widget build(BuildContext context) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      );
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
        width: 104,
        height: 104,
        child: CustomPaint(
          painter: _Ring(widget.score / 100 * c.value),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${(widget.score * c.value).round()}',
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Text(
                  'score',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
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
    p.color = Colors.white.withValues(alpha: .12);
    c.drawArc(rect, -math.pi / 2, math.pi * 2, false, p);
    p.shader = const SweepGradient(
      colors: [AppColors.cyan, AppColors.mint, AppColors.emerald],
    ).createShader(rect);
    c.drawArc(rect, -math.pi / 2, math.pi * 2 * progress, false, p);
  }

  @override
  bool shouldRepaint(_Ring o) => o.progress != progress;
}

class _LivePill extends StatefulWidget {
  const _LivePill();

  @override
  State<_LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<_LivePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: c,
        builder: (_, _) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.emerald.withValues(alpha: .1 + c.value * .06),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 12, color: AppColors.mint),
              SizedBox(width: 4),
              Text(
                'LIVE',
                style: TextStyle(
                  color: AppColors.mint,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      );
}

// ── Quick action tile ──────────────────────────────────────────────────────────

class _QuickAction extends StatefulWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
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
        duration: const Duration(milliseconds: 130),
        scale: _pressed ? 0.95 : 1.0,
        child: GlassPanel(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          radius: 20,
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.color.withValues(alpha: .35)),
                ),
                child: Icon(widget.icon, color: widget.color, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Insight card ───────────────────────────────────────────────────────────────

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
        child: GlassPanel(
          padding: const EdgeInsets.all(16),
          radius: 24,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.cyan,
                  size: 17,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.text,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_outward_rounded,
                color: Colors.white.withValues(alpha: .45),
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
