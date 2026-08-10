import 'package:flutter/material.dart';
import 'package:zindagi_plus/core/theme/app_theme.dart';
import 'package:zindagi_plus/shared/widgets/premium_ui.dart';

// ── Mock timeline events ───────────────────────────────────────────────────────

class _Event {
  const _Event({
    required this.date,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.category,
  });
  final String date, title, subtitle, category;
  final IconData icon;
  final Color color;
}

const _events = [
  _Event(
    date: 'Today',
    title: 'Morning walk completed',
    subtitle: '4,800 steps · 28 min · 110 kcal burned',
    icon: Icons.directions_walk_rounded,
    color: AppColors.cyan,
    category: 'Activity',
  ),
  _Event(
    date: 'Today',
    title: 'Metformin taken',
    subtitle: '500mg · On time at 8:03 AM',
    icon: Icons.medication_rounded,
    color: AppColors.emerald,
    category: 'Medication',
  ),
  _Event(
    date: 'Yesterday',
    title: 'Blood report analysed',
    subtitle: '8 biomarkers extracted · 3 require attention',
    icon: Icons.biotech_outlined,
    color: AppColors.blue,
    category: 'Report',
  ),
  _Event(
    date: 'Yesterday',
    title: 'Meal plan followed',
    subtitle: 'Masoor Dal Khichdi · Matched your targets',
    icon: Icons.restaurant_outlined,
    color: AppColors.mint,
    category: 'Nutrition',
  ),
  _Event(
    date: '7 Aug',
    title: 'HbA1c borderline alert',
    subtitle: '6.8% detected — action recommended',
    icon: Icons.warning_amber_rounded,
    color: AppColors.warning,
    category: 'Alert',
  ),
  _Event(
    date: '7 Aug',
    title: 'Yoga session completed',
    subtitle: '20 min · Cortisol reduction logged',
    icon: Icons.self_improvement_rounded,
    color: AppColors.cyan,
    category: 'Activity',
  ),
  _Event(
    date: '6 Aug',
    title: 'Vitamin D supplement added',
    subtitle: '2000 IU daily · Starting today',
    icon: Icons.wb_sunny_outlined,
    color: AppColors.warning,
    category: 'Medication',
  ),
  _Event(
    date: '5 Aug',
    title: 'Profile completed',
    subtitle: 'Height, weight, blood type recorded',
    icon: Icons.person_rounded,
    color: AppColors.emerald,
    category: 'Profile',
  ),
  _Event(
    date: '4 Aug',
    title: 'Account created',
    subtitle: 'Welcome to Zindagi+! 🎉',
    icon: Icons.favorite_rounded,
    color: AppColors.error,
    category: 'Profile',
  ),
];

const _periods = ['All', 'This Week', 'This Month', '3 Months'];
const _filterCategories = [
  'All',
  'Activity',
  'Nutrition',
  'Medication',
  'Report',
  'Alert',
];

// ── Screen ─────────────────────────────────────────────────────────────────────

class HealthTimelineScreen extends StatefulWidget {
  const HealthTimelineScreen({super.key});

  @override
  State<HealthTimelineScreen> createState() => _HealthTimelineScreenState();
}

class _HealthTimelineScreenState extends State<HealthTimelineScreen>
    with TickerProviderStateMixin {
  String _selectedPeriod = 'This Week';
  String _selectedCategory = 'All';
  late final List<AnimationController> _itemCtls;

  List<_Event> get _filteredEvents {
    if (_selectedCategory == 'All') return _events;
    return _events.where((e) => e.category == _selectedCategory).toList();
  }

  @override
  void initState() {
    super.initState();
    _itemCtls = List.generate(
      _events.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 380),
      ),
    );
    _animateItems();
  }

  void _animateItems() {
    for (int i = 0; i < _itemCtls.length; i++) {
      _itemCtls[i].reset();
      Future.delayed(Duration(milliseconds: i * 75), () {
        if (mounted) _itemCtls[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _itemCtls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredEvents;

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          leading: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          ),
          title: const Text('Health Timeline'),
        ),
        body: Column(
          children: [
            // ── Period filter ────────────────────────────────────────────
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _periods.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => _FilterChip(
                  label: _periods[i],
                  selected: _selectedPeriod == _periods[i],
                  onTap: () =>
                      setState(() => _selectedPeriod = _periods[i]),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // ── Category filter ──────────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _filterCategories.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (_, i) => _SmallChip(
                  label: _filterCategories[i],
                  selected: _selectedCategory == _filterCategories[i],
                  onTap: () {
                    setState(() => _selectedCategory = _filterCategories[i]);
                    _animateItems();
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Timeline ─────────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final event = filtered[i];
                  final globalIndex = _events.indexOf(event);
                  final ctlIndex =
                      globalIndex < _itemCtls.length ? globalIndex : 0;
                  final isLast = i == filtered.length - 1;

                  return AnimatedBuilder(
                    animation: _itemCtls[ctlIndex],
                    builder: (_, child) {
                      final t = CurvedAnimation(
                        parent: _itemCtls[ctlIndex],
                        curve: Curves.easeOutBack,
                      ).value.clamp(0.0, 1.0);
                      return Opacity(
                        opacity: t,
                        child: Transform.translate(
                          offset: Offset((1 - t) * 20, 0),
                          child: child,
                        ),
                      );
                    },
                    child: _TimelineItem(
                      event: event,
                      isLast: isLast,
                      showDateLabel: i == 0 ||
                          filtered[i].date != filtered[i - 1].date,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Timeline item ──────────────────────────────────────────────────────────────

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.event,
    required this.isLast,
    required this.showDateLabel,
  });
  final _Event event;
  final bool isLast, showDateLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDateLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 52),
            child: Text(
              event.date,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Timeline spine
              SizedBox(
                width: 36,
                child: Column(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: event.color.withValues(alpha: .16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: event.color.withValues(alpha: .4),
                        ),
                      ),
                      child: Icon(event.icon, color: event.color, size: 17),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 2,
                            color: AppColors.divider,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                  child: GlassPanel(
                    padding: const EdgeInsets.all(14),
                    radius: 18,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: event.color.withValues(alpha: .12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                event.category,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: event.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          event.subtitle,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Filter chips ───────────────────────────────────────────────────────────────

class _FilterChip extends StatefulWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends State<_FilterChip> {
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
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.94 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.emerald.withValues(alpha: .16)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.selected
                  ? AppColors.emerald.withValues(alpha: .5)
                  : AppColors.divider,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: widget.selected ? AppColors.mint : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallChip extends StatefulWidget {
  const _SmallChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SmallChip> createState() => _SmallChipState();
}

class _SmallChipState extends State<_SmallChip> {
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
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.93 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: widget.selected
                ? AppColors.blue.withValues(alpha: .15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.selected
                  ? AppColors.blue.withValues(alpha: .4)
                  : AppColors.divider,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.selected ? AppColors.blue : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
