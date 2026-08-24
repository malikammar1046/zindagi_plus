import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

// ── Mock data ──────────────────────────────────────────────────────────────────

const _activities = [
  (
    id: 'act_001',
    emoji: '🚶',
    name: 'Morning Walk',
    duration: '30 min',
    intensity: 'Low',
    calories: '120 kcal',
    category: 'Cardio',
    desc:
        'A brisk 30-minute walk first thing in the morning on an empty stomach maximises fat oxidation and improves insulin sensitivity.',
    benefit: 'Best for your blood sugar levels',
  ),
  (
    id: 'act_002',
    emoji: '🧘',
    name: 'Yoga & Stretching',
    duration: '20 min',
    intensity: 'Low',
    calories: '65 kcal',
    category: 'Flexibility',
    desc:
        'Gentle yoga reduces cortisol levels, which directly impacts blood glucose. The stretching component improves circulation to muscles.',
    benefit: 'Reduces stress & cortisol',
  ),
  (
    id: 'act_003',
    emoji: '🚴',
    name: 'Cycling (Stationary)',
    duration: '20 min',
    intensity: 'Medium',
    calories: '180 kcal',
    category: 'Cardio',
    desc:
        'Stationary cycling is joint-friendly and provides an excellent cardiovascular workout. It significantly increases glucose uptake in muscles.',
    benefit: 'Burns 180 kcal efficiently',
  ),
  (
    id: 'act_004',
    emoji: '🏊',
    name: 'Swimming',
    duration: '30 min',
    intensity: 'Medium',
    calories: '240 kcal',
    category: 'Full Body',
    desc:
        'Swimming engages all major muscle groups and has minimal joint impact. It is particularly beneficial for those managing weight and blood glucose.',
    benefit: 'Full body, zero joint stress',
  ),
  (
    id: 'act_005',
    emoji: '💪',
    name: 'Resistance Training',
    duration: '25 min',
    intensity: 'High',
    calories: '200 kcal',
    category: 'Strength',
    desc:
        'Building muscle mass increases your resting metabolic rate and significantly improves long-term insulin sensitivity — a key goal for your profile.',
    benefit: 'Builds insulin sensitivity',
  ),
  (
    id: 'act_006',
    emoji: '🤸',
    name: 'Bodyweight Circuit',
    duration: '20 min',
    intensity: 'High',
    calories: '220 kcal',
    category: 'Strength',
    desc:
        'Squats, push-ups and lunges performed in a circuit burns calories efficiently and requires no equipment. Great for home workouts.',
    benefit: 'No equipment needed',
  ),
];

const _categories = ['All', 'Cardio', 'Flexibility', 'Strength', 'Full Body'];

// ── Screen ─────────────────────────────────────────────────────────────────────

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen>
    with TickerProviderStateMixin {
  String _selectedCategory = 'All';
  late final List<AnimationController> _cardCtls;
  final Set<String> _weeklyPlan = {'act_001', 'act_002'}; // Pre-selected activities

  List<int> get _filteredIndices {
    if (_selectedCategory == 'All') {
      return List.generate(_activities.length, (i) => i);
    }
    return [
      for (int i = 0; i < _activities.length; i++)
        if (_activities[i].category == _selectedCategory) i,
    ];
  }

  @override
  void initState() {
    super.initState();
    _cardCtls = List.generate(
      _activities.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _animateCards();
  }

  void _animateCards() {
    for (int i = 0; i < _cardCtls.length; i++) {
      _cardCtls[i].reset();
      Future.delayed(Duration(milliseconds: i * 80), () {
        if (mounted) _cardCtls[i].forward();
      });
    }
  }

  void _toggleWeeklyActivity(String id, String name) {
    setState(() {
      if (_weeklyPlan.contains(id)) {
        _weeklyPlan.remove(id);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name removed from this week\'s plan'),
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        _weeklyPlan.add(id);
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$name added to this week\'s plan!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    for (final c in _cardCtls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final indices = _filteredIndices;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const AppBackButton(fallbackLocation: '/dashboard'),
        title: const Text('Activity Plan'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: colorScheme.secondary.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_fire_department_rounded,
                  color: colorScheme.secondary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_weeklyPlan.length}/5 planned',
                  style: TextStyle(
                    color: colorScheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Summary banner ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: AppCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Text('🏃', style: TextStyle(fontSize: 34)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sample Activity Plan (Demo)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Curated exercise catalog. Dynamic AI adaptation unlocks in next phase.',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _NearbyButton(),
                ],
              ),
            ),
          ),

          // ── Category filter chips ──────────────────────────────────────
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) => _CategoryChip(
                label: _categories[i],
                selected: _selectedCategory == _categories[i],
                onTap: () {
                  setState(() => _selectedCategory = _categories[i]);
                  _animateCards();
                },
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Activity cards ─────────────────────────────────────────────
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              itemCount: indices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (_, pos) {
                final i = indices[pos];
                final act = _activities[i];
                final isAdded = _weeklyPlan.contains(act.id);
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
                        offset: Offset(0, (1 - t) * 24),
                        child: child,
                      ),
                    );
                  },
                  child: _ActivityCard(
                    activity: act,
                    isAdded: isAdded,
                    onToggleWeek: () =>
                        _toggleWeeklyActivity(act.id, act.name),
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

class _CategoryChip extends StatefulWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
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
          duration: const Duration(milliseconds: 220),
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

class _ActivityCard extends StatefulWidget {
  const _ActivityCard({
    required this.activity,
    required this.isAdded,
    required this.onToggleWeek,
  });

  final ({
    String id,
    String emoji,
    String name,
    String duration,
    String intensity,
    String calories,
    String category,
    String desc,
    String benefit,
  }) activity;

  final bool isAdded;
  final VoidCallback onToggleWeek;

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  bool _expanded = false;
  bool _pressed = false;

  Color _getIntensityColor(String intensity, ColorScheme colorScheme) {
    switch (intensity.toLowerCase()) {
      case 'low':
        return colorScheme.primary;
      case 'medium':
        return Colors.orange;
      case 'high':
        return colorScheme.secondary;
      default:
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final act = widget.activity;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() {
          _pressed = false;
          _expanded = !_expanded;
        });
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 130),
        scale: _pressed ? 0.98 : 1.0,
        child: AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    act.emoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                act.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (widget.isAdded) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'This Week',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _Badge(act.duration,
                                colorScheme.onSurface.withValues(alpha: 0.6)),
                            _Badge(
                              act.intensity,
                              _getIntensityColor(act.intensity, colorScheme),
                              border: true,
                            ),
                            _Badge(act.calories,
                                colorScheme.onSurface.withValues(alpha: 0.6)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 280),
                    turns: _expanded ? 0.5 : 0,
                    child: Icon(
                      Icons.expand_more_rounded,
                      color: colorScheme.onSurface.withValues(alpha: 0.4),
                      size: 24,
                    ),
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: _expanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Divider(),
                          const SizedBox(height: 16),
                          Text(
                            act.desc,
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.7),
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                color: colorScheme.primary,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  act.benefit,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: widget.isAdded
                                ? OutlinedButton.icon(
                                    onPressed: widget.onToggleWeek,
                                    icon: Icon(Icons.check_rounded,
                                        color: colorScheme.primary),
                                    label: Text(
                                      'Added to This Week (Tap to Remove)',
                                      style: TextStyle(
                                          color: colorScheme.primary),
                                    ),
                                  )
                                : SecondaryButton(
                                    onPressed: widget.onToggleWeek,
                                    label: 'Add to This Week',
                                    icon: Icons.add_rounded,
                                  ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, this.color, {this.border = false});
  final String text;
  final Color color;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: border ? 0.1 : 0.0),
        borderRadius: BorderRadius.circular(10),
        border: border ? Border.all(color: color.withValues(alpha: 0.3)) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NearbyButton extends StatefulWidget {
  @override
  State<_NearbyButton> createState() => _NearbyButtonState();
}

class _NearbyButtonState extends State<_NearbyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        context.push('/nearby-facilities');
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.9 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined,
                  color: colorScheme.primary, size: 18),
              const SizedBox(height: 2),
              Text(
                'Nearby',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
