import 'package:flutter/material.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

// ── Mock meal detail data ──────────────────────────────────────────────────────

const _mealDetails = <String, Map<String, dynamic>>{
  '0': {
    'emoji': '🍲',
    'name': 'Masoor Dal Khichdi',
    'calories': 340,
    'protein': '18g',
    'carbs': '52g',
    'fat': '6g',
    'fibre': '9g',
    'sodium': '420mg',
    'glycemicIndex': 'Low (45)',
    'prepTime': '25 min',
    'servingSize': '1 bowl (300g)',
    'healthMatch': 95,
    'healthMatchReason':
        'Low glycemic index helps manage your HbA1c. High fibre content slows glucose absorption. Lentils provide lean protein that supports muscle retention.',
    'ingredients': ['1 cup masoor dal', 'half cup rice', 'turmeric, cumin', 'salt, ghee (1 tsp)', 'onion, tomato', 'ginger-garlic paste'],
    'tags': ['Diabetic-Friendly', 'High Fibre', 'Low GI', 'Heart Healthy'],
  },
  '1': {
    'emoji': '🥗',
    'name': 'Raita & Grilled Chicken',
    'calories': 290,
    'protein': '32g',
    'carbs': '12g',
    'fat': '9g',
    'fibre': '2g',
    'sodium': '380mg',
    'glycemicIndex': 'Very Low (22)',
    'prepTime': '30 min',
    'servingSize': '1 plate (350g)',
    'healthMatch': 88,
    'healthMatchReason':
        'High protein supports lean muscle mass. Very low carbohydrate content suits your blood glucose targets. The probiotics in raita support gut microbiome health.',
    'ingredients': ['200g chicken breast', '1 cup yogurt', 'cucumber', 'mint leaves', 'cumin powder', 'salt'],
    'tags': ['High Protein', 'Low Carb', 'Gut Health'],
  },
  '2': {
    'emoji': '🫓',
    'name': 'Chickpea & Spinach Wrap',
    'calories': 310,
    'protein': '14g',
    'carbs': '44g',
    'fat': '7g',
    'fibre': '11g',
    'sodium': '340mg',
    'glycemicIndex': 'Low (42)',
    'prepTime': '15 min',
    'servingSize': '2 wraps (280g)',
    'healthMatch': 91,
    'healthMatchReason':
        'Chickpeas are one of the best foods for blood glucose control. Iron-rich spinach addresses potential anaemia. High fibre supports LDL reduction.',
    'ingredients': ['1 can chickpeas', '2 whole-wheat roti', 'spinach leaves', 'tahini (1 tbsp)', 'lemon juice', 'paprika'],
    'tags': ['Plant Protein', 'Iron Rich', 'High Fibre', 'Low GI'],
  },
};

// ── Screen ─────────────────────────────────────────────────────────────────────

class MealDetailScreen extends StatefulWidget {
  const MealDetailScreen({super.key, required this.mealIndex});
  final int mealIndex;

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen>
    with TickerProviderStateMixin {
  bool _addedToPlan = false;
  late final AnimationController _heroCtrl;
  late final AnimationController _macroCtrl;

  Map<String, dynamic> get _meal {
    final key = widget.mealIndex.clamp(0, _mealDetails.length - 1).toString();
    return _mealDetails[key]!;
  }

  @override
  void initState() {
    super.initState();
    _heroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _macroCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    Future.delayed(
      const Duration(milliseconds: 280),
      () => mounted ? _macroCtrl.forward() : null,
    );
  }

  @override
  void dispose() {
    _heroCtrl.dispose();
    _macroCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meal = _meal;
    final tags = meal['tags'] as List<String>;
    final ingredients = meal['ingredients'] as List<String>;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Sliver app bar with emoji ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: colorScheme.surface,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: Colors.black87,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.15),
                      colorScheme.surface,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Center(
                  child: AnimatedBuilder(
                    animation: _heroCtrl,
                    builder: (_, _) {
                      final t = CurvedAnimation(
                        parent: _heroCtrl,
                        curve: Curves.easeOutBack,
                      ).value.clamp(0.0, 1.0);
                      return Transform.scale(
                        scale: 0.6 + t * 0.4,
                        child: Text(
                          meal['emoji'] as String,
                          style: const TextStyle(fontSize: 80),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Title ────────────────────────────────────────────────
                Text(
                  meal['name'] as String,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 16,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          meal['prepTime'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.straighten_rounded,
                          size: 16,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          meal['servingSize'] as String,
                          style: TextStyle(
                            fontSize: 14,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Tags ─────────────────────────────────────────────────
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tags
                      .map(
                        (t) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            t,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),

                const SizedBox(height: 32),

                // ── Macro grid ────────────────────────────────────────────
                AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nutritional Info',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _MacroBar(
                        label: 'Calories',
                        value: '${meal['calories']} kcal',
                        fraction: 0.68,
                        color: colorScheme.primary,
                        controller: _macroCtrl,
                      ),
                      const SizedBox(height: 16),
                      _MacroBar(
                        label: 'Protein',
                        value: meal['protein'] as String,
                        fraction: 0.72,
                        color: colorScheme.primary,
                        controller: _macroCtrl,
                      ),
                      const SizedBox(height: 16),
                      _MacroBar(
                        label: 'Carbohydrates',
                        value: meal['carbs'] as String,
                        fraction: 0.52,
                        color: colorScheme.secondary,
                        controller: _macroCtrl,
                      ),
                      const SizedBox(height: 16),
                      _MacroBar(
                        label: 'Fat',
                        value: meal['fat'] as String,
                        fraction: 0.24,
                        color: colorScheme.secondary,
                        controller: _macroCtrl,
                      ),
                      const SizedBox(height: 16),
                      _MacroBar(
                        label: 'Fibre',
                        value: meal['fibre'] as String,
                        fraction: 0.45,
                        color: colorScheme.primary,
                        controller: _macroCtrl,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Divider(),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Glycaemic Index',
                        value: meal['glycemicIndex'] as String,
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Sodium',
                        value: meal['sodium'] as String,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Health match ──────────────────────────────────────────
                AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Health Match',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${meal['healthMatch']}%',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0,
                            end: (meal['healthMatch'] as int) / 100,
                          ),
                          duration: const Duration(milliseconds: 900),
                          curve: Curves.easeOutCubic,
                          builder: (_, v, _) => LinearProgressIndicator(
                            value: v,
                            minHeight: 10,
                            backgroundColor: theme.dividerColor,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        meal['healthMatchReason'] as String,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Ingredients ───────────────────────────────────────────
                const SectionHeader(title: 'Ingredients'),
                const SizedBox(height: 16),
                AppCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: ingredients
                        .map(
                          (ing) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    ing,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),

                const SizedBox(height: 40),

                // ── Add to plan button ────────────────────────────────────
                PrimaryButton(
                  onPressed: () => setState(() => _addedToPlan = !_addedToPlan),
                  text: _addedToPlan ? 'Added to Meal Plan' : 'Add to Plan',
                  icon: _addedToPlan ? Icons.check_rounded : Icons.add_rounded,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _MacroBar extends StatelessWidget {
  const _MacroBar({
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
    required this.controller,
  });
  final String label, value;
  final double fraction;
  final Color color;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        SizedBox(
          width: 95,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
        Expanded(
          child: AnimatedBuilder(
            animation: controller,
            builder: (_, _) {
              final t = CurvedAnimation(
                parent: controller,
                curve: Curves.easeOutCubic,
              ).value;
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction * t,
                  minHeight: 8,
                  backgroundColor: Theme.of(context).dividerColor,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 44),
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label, value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: 14, color: colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
