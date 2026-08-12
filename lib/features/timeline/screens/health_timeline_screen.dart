import 'package:flutter/material.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

// ── Mock timeline events ───────────────────────────────────────────────────────

class _Event {
  const _Event({
    required this.daysAgo,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.category,
  });

  final int daysAgo;
  final String title, subtitle, category;
  final IconData icon;
  final Color color;

  String get dateLabel {
    if (daysAgo == 0) return 'Today';
    if (daysAgo == 1) return 'Yesterday';
    final dt = DateTime.now().subtract(Duration(days: daysAgo));
    final months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month]}';
  }
}

const _events = [
  _Event(
    daysAgo: 0,
    title: 'Morning walk completed',
    subtitle: '4,800 steps · 28 min · 110 kcal burned',
    icon: Icons.directions_walk_rounded,
    color: Colors.blue,
    category: 'Activity',
  ),
  _Event(
    daysAgo: 0,
    title: 'Metformin taken',
    subtitle: '500mg · On time at 8:03 AM',
    icon: Icons.medication_rounded,
    color: Color(0xFF00674F),
    category: 'Medication',
  ),
  _Event(
    daysAgo: 1,
    title: 'Blood report analysed',
    subtitle: '8 biomarkers extracted · 3 require attention',
    icon: Icons.biotech_outlined,
    color: Colors.purple,
    category: 'Report',
  ),
  _Event(
    daysAgo: 1,
    title: 'Meal plan followed',
    subtitle: 'Masoor Dal Khichdi · Matched your targets',
    icon: Icons.restaurant_outlined,
    color: Color(0xFF00674F),
    category: 'Nutrition',
  ),
  _Event(
    daysAgo: 5,
    title: 'HbA1c borderline alert',
    subtitle: '6.8% detected — action recommended',
    icon: Icons.warning_amber_rounded,
    color: Colors.orange,
    category: 'Alert',
  ),
  _Event(
    daysAgo: 5,
    title: 'Yoga session completed',
    subtitle: '20 min · Cortisol reduction logged',
    icon: Icons.self_improvement_rounded,
    color: Colors.blue,
    category: 'Activity',
  ),
  _Event(
    daysAgo: 6,
    title: 'Vitamin D supplement added',
    subtitle: '2000 IU daily · Starting today',
    icon: Icons.wb_sunny_outlined,
    color: Colors.orange,
    category: 'Medication',
  ),
  _Event(
    daysAgo: 14,
    title: 'Profile completed',
    subtitle: 'Height, weight, blood type recorded',
    icon: Icons.person_rounded,
    color: Color(0xFF00674F),
    category: 'Profile',
  ),
  _Event(
    daysAgo: 45,
    title: 'Account created',
    subtitle: 'Welcome to Zindagi+! 🎉',
    icon: Icons.favorite_rounded,
    color: Color(0xFF670018),
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
  String _selectedPeriod = 'All';
  String _selectedCategory = 'All';
  late final List<AnimationController> _itemCtls;

  List<_Event> get _filteredEvents {
    return _events.where((e) {
      // Category filter
      if (_selectedCategory != 'All' && e.category != _selectedCategory) {
        return false;
      }
      // Period filter
      if (_selectedPeriod == 'This Week' && e.daysAgo > 7) {
        return false;
      }
      if (_selectedPeriod == 'This Month' && e.daysAgo > 30) {
        return false;
      }
      if (_selectedPeriod == '3 Months' && e.daysAgo > 90) {
        return false;
      }
      return true;
    }).toList();
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

    return Scaffold(
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
                onTap: () {
                  setState(() => _selectedPeriod = _periods[i]);
                  _animateItems();
                },
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
            child: filtered.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.history_toggle_off_rounded,
                    title: 'No Events in this Period',
                    subtitle:
                        'Try choosing another period or filter category to see your health timeline events.',
                  )
                : ListView.builder(
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
                              filtered[i].dateLabel !=
                                  filtered[i - 1].dateLabel,
                        ),
                      );
                    },
                  ),
          ),
        ],
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDateLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 10, left: 52),
            child: Text(
              event.dateLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
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
                        color: event.color.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: event.color.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Icon(event.icon, color: event.color, size: 17),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Center(
                          child: Container(
                            width: 2,
                            color: theme.dividerColor,
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
                  child: AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: event.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                event.category,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: event.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          event.subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.7),
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
        scale: _pressed ? 0.94 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selected
                ? colorScheme.primary
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.selected
                  ? colorScheme.primary
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.selected
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface.withValues(alpha: 0.7),
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: widget.selected
                ? Colors.blue.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.selected
                  ? Colors.blue.withValues(alpha: 0.4)
                  : Theme.of(context).dividerColor,
            ),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: widget.selected
                  ? Colors.blue
                  : colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }
}
