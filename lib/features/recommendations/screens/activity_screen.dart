import 'package:flutter/material.dart';
import 'package:zindagi_plus/core/theme/app_theme.dart';
import 'package:zindagi_plus/shared/widgets/premium_ui.dart';

// ── Mock data ──────────────────────────────────────────────────────────────────

const _activities = [
  (
    emoji: '🚶',
    name: 'Morning Walk',
    duration: '30 min',
    intensity: 'Low',
    intensityColor: AppColors.emerald,
    calories: '120 kcal',
    category: 'Cardio',
    desc: 'A brisk 30-minute walk first thing in the morning on an empty stomach maximises fat oxidation and improves insulin sensitivity.',
    benefit: 'Best for your blood sugar levels',
  ),
  (
    emoji: '🧘',
    name: 'Yoga & Stretching',
    duration: '20 min',
    intensity: 'Low',
    intensityColor: AppColors.emerald,
    calories: '65 kcal',
    category: 'Flexibility',
    desc: 'Gentle yoga reduces cortisol levels, which directly impacts blood glucose. The stretching component improves circulation to muscles.',
    benefit: 'Reduces stress & cortisol',
  ),
  (
    emoji: '🚴',
    name: 'Cycling (Stationary)',
    duration: '20 min',
    intensity: 'Medium',
    intensityColor: AppColors.warning,
    calories: '180 kcal',
    category: 'Cardio',
    desc: 'Stationary cycling is joint-friendly and provides an excellent cardiovascular workout. It significantly increases glucose uptake in muscles.',
    benefit: 'Burns 180 kcal efficiently',
  ),
  (
    emoji: '🏊',
    name: 'Swimming',
    duration: '30 min',
    intensity: 'Medium',
    intensityColor: AppColors.warning,
    calories: '240 kcal',
    category: 'Full Body',
    desc: 'Swimming engages all major muscle groups and has minimal joint impact. It is particularly beneficial for those managing weight and blood glucose.',
    benefit: 'Full body, zero joint stress',
  ),
  (
    emoji: '💪',
    name: 'Resistance Training',
    duration: '25 min',
    intensity: 'High',
    intensityColor: AppColors.error,
    calories: '200 kcal',
    category: 'Strength',
    desc: 'Building muscle mass increases your resting metabolic rate and significantly improves long-term insulin sensitivity — a key goal for your profile.',
    benefit: 'Builds insulin sensitivity',
  ),
  (
    emoji: '🤸',
    name: 'Bodyweight Circuit',
    duration: '20 min',
    intensity: 'High',
    intensityColor: AppColors.error,
    calories: '220 kcal',
    category: 'Strength',
    desc: 'Squats, push-ups and lunges performed in a circuit burns calories efficiently and requires no equipment. Great for home workouts.',
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

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Activity Plan'),
          actions: [
            // Weekly target chip
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.cyan.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cyan.withValues(alpha: .3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.cyan,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '3/5 days',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontSize: 11,
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
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: GlassPanel(
                padding: const EdgeInsets.all(18),
                radius: 24,
                gradient: LinearGradient(
                  colors: [
                    AppColors.cyan.withValues(alpha: .14),
                    AppColors.blue.withValues(alpha: .05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                child: Row(
                  children: [
                    const Text('🏃', style: TextStyle(fontSize: 34)),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'AI-Tailored Activity Plan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Personalised for blood sugar management & weight',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
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
            // Apple §1: chips respond on pointer-down
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

            const SizedBox(height: 14),

            // ── Activity cards ─────────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: indices.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (_, pos) {
                  final i = indices[pos];
                  final act = _activities[i];
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
                    child: _ActivityCard(activity: act),
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

// ── Category chip ──────────────────────────────────────────────────────────────

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
                ? AppColors.emerald.withValues(alpha: .18)
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

// ── Activity card ──────────────────────────────────────────────────────────────

class _ActivityCard extends StatefulWidget {
  const _ActivityCard({required this.activity});
  final ({
    String emoji,
    String name,
    String duration,
    String intensity,
    Color intensityColor,
    String calories,
    String category,
    String desc,
    String benefit,
  }) activity;

  @override
  State<_ActivityCard> createState() => _ActivityCardState();
}

class _ActivityCardState extends State<_ActivityCard> {
  bool _expanded = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final act = widget.activity;
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
        child: GlassPanel(
          padding: const EdgeInsets.all(18),
          radius: 22,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    act.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          act.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _Badge(act.duration, AppColors.textSecondary),
                            const SizedBox(width: 6),
                            _Badge(
                              act.intensity,
                              act.intensityColor,
                              border: true,
                            ),
                            const SizedBox(width: 6),
                            _Badge(act.calories, AppColors.textSecondary),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    duration: const Duration(milliseconds: 280),
                    turns: _expanded ? 0.5 : 0,
                    child: const Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.textTertiary,
                      size: 22,
                    ),
                  ),
                ],
              ),
              // Apple §3: interruptible expand — AnimatedSize
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeOutCubic,
                child: _expanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),
                          Container(
                            height: 1,
                            color: AppColors.divider,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            act.desc,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: AppColors.mint,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                act.benefit,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mint,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            height: 42,
                            child: ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('Add to This Week'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    AppColors.emerald.withValues(alpha: .15),
                                foregroundColor: AppColors.emerald,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: border ? 0.12 : 0.0),
        borderRadius: BorderRadius.circular(8),
        border: border ? Border.all(color: color.withValues(alpha: .35)) : null,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: border ? color : color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Nearby facilities button ───────────────────────────────────────────────────

class _NearbyButton extends StatefulWidget {
  @override
  State<_NearbyButton> createState() => _NearbyButtonState();
}

class _NearbyButtonState extends State<_NearbyButton> {
  bool _pressed = false;

  void _showNearby() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // Apple §7: sheet slides up from its natural origin (bottom)
      builder: (_) => const _NearbySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        _showNearby();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.9 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on_outlined, color: AppColors.cyan, size: 16),
              SizedBox(height: 2),
              Text(
                'Nearby',
                style: TextStyle(
                  fontSize: 9,
                  color: AppColors.cyan,
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

class _NearbySheet extends StatelessWidget {
  const _NearbySheet();

  static const _facilities = [
    (name: 'City Fitness Centre', distance: '0.4 km', type: 'Gym', rating: '4.6'),
    (name: 'Green Park Walking Track', distance: '0.7 km', type: 'Outdoor', rating: '4.8'),
    (name: 'AquaSport Pool', distance: '1.2 km', type: 'Swimming', rating: '4.5'),
    (name: 'Zen Yoga Studio', distance: '1.5 km', type: 'Yoga', rating: '4.7'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.location_on_rounded, color: AppColors.cyan, size: 20),
                SizedBox(width: 8),
                Text(
                  'Nearby Facilities',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ..._facilities.map(
            (f) => ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.place_rounded,
                  color: AppColors.emerald,
                  size: 20,
                ),
              ),
              title: Text(
                f.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                '${f.type} · ${f.distance} · ⭐ ${f.rating}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              trailing: const Icon(
                Icons.directions_rounded,
                color: AppColors.cyan,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
