import 'package:flutter/material.dart';
import 'package:zindagi_plus/core/theme/app_theme.dart';
import 'package:zindagi_plus/shared/widgets/premium_ui.dart';

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

    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            // ── Sliver app bar with emoji ──────────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: Colors.transparent,
              leading: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircleAvatar(
                    backgroundColor: Color(0x88181C22),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.emerald.withValues(alpha: .25),
                        AppColors.background,
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
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        meal['prepTime'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Icon(
                        Icons.straighten_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        meal['servingSize'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Tags ─────────────────────────────────────────────────
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.emerald.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.emerald.withValues(alpha: .3),
                              ),
                            ),
                            child: Text(
                              t,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.mint,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),

                  const SizedBox(height: 24),

                  // ── Macro grid ────────────────────────────────────────────
                  // Bars animate from 0 (Apple §1: continuous feedback)
                  GlassPanel(
                    padding: const EdgeInsets.all(20),
                    radius: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Nutritional Info',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _MacroBar(
                          label: 'Calories',
                          value: '${meal['calories']} kcal',
                          fraction: 0.68,
                          color: AppColors.emerald,
                          controller: _macroCtrl,
                        ),
                        const SizedBox(height: 12),
                        _MacroBar(
                          label: 'Protein',
                          value: meal['protein'] as String,
                          fraction: 0.72,
                          color: AppColors.blue,
                          controller: _macroCtrl,
                        ),
                        const SizedBox(height: 12),
                        _MacroBar(
                          label: 'Carbohydrates',
                          value: meal['carbs'] as String,
                          fraction: 0.52,
                          color: AppColors.warning,
                          controller: _macroCtrl,
                        ),
                        const SizedBox(height: 12),
                        _MacroBar(
                          label: 'Fat',
                          value: meal['fat'] as String,
                          fraction: 0.24,
                          color: AppColors.error,
                          controller: _macroCtrl,
                        ),
                        const SizedBox(height: 12),
                        _MacroBar(
                          label: 'Fibre',
                          value: meal['fibre'] as String,
                          fraction: 0.45,
                          color: AppColors.cyan,
                          controller: _macroCtrl,
                        ),
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: Divider(color: AppColors.divider),
                        ),
                        const SizedBox(height: 8),
                        _InfoRow(
                          label: 'Glycaemic Index',
                          value: meal['glycemicIndex'] as String,
                        ),
                        const SizedBox(height: 6),
                        _InfoRow(
                          label: 'Sodium',
                          value: meal['sodium'] as String,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Health match ──────────────────────────────────────────
                  GlassPanel(
                    padding: const EdgeInsets.all(20),
                    radius: 24,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.emerald.withValues(alpha: .12),
                        AppColors.cyan.withValues(alpha: .04),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: AppColors.mint,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Health Match',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${meal['healthMatch']}%',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: AppColors.emerald,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(
                              begin: 0,
                              end: (meal['healthMatch'] as int) / 100,
                            ),
                            duration: const Duration(milliseconds: 900),
                            curve: Curves.easeOutCubic,
                            builder: (_, v, _) => LinearProgressIndicator(
                              value: v,
                              minHeight: 6,
                              backgroundColor: AppColors.divider,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.emerald,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          meal['healthMatchReason'] as String,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Ingredients ───────────────────────────────────────────
                  const Text(
                    'Ingredients',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassPanel(
                    padding: const EdgeInsets.all(18),
                    radius: 20,
                    child: Column(
                      children: ingredients
                          .map(
                            (ing) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.emerald,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    ing,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Add to plan button ────────────────────────────────────
                  _AddToPlanButton(
                    added: _addedToPlan,
                    onPressed: () => setState(() => _addedToPlan = !_addedToPlan),
                  ),
                ]),
              ),
            ),
          ],
        ),
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
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
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
                  minHeight: 6,
                  backgroundColor: AppColors.divider,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 42,
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _AddToPlanButton extends StatefulWidget {
  const _AddToPlanButton({required this.added, required this.onPressed});
  final bool added;
  final VoidCallback onPressed;

  @override
  State<_AddToPlanButton> createState() => _AddToPlanButtonState();
}

class _AddToPlanButtonState extends State<_AddToPlanButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 140),
        scale: _pressed ? 0.97 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          height: 56,
          decoration: BoxDecoration(
            gradient: widget.added
                ? null
                : const LinearGradient(
                    colors: [AppColors.emerald, Color(0xFF238F87)],
                  ),
            color: widget.added ? AppColors.surface : null,
            borderRadius: BorderRadius.circular(22),
            border: widget.added
                ? Border.all(color: AppColors.divider)
                : null,
            boxShadow: widget.added
                ? null
                : [
                    BoxShadow(
                      color: AppColors.emerald.withValues(alpha: .28),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.added ? Icons.check_rounded : Icons.add_rounded,
                color: widget.added ? AppColors.emerald : AppColors.background,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                widget.added ? 'Added to Meal Plan' : 'Add to Plan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: widget.added ? AppColors.emerald : AppColors.background,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
