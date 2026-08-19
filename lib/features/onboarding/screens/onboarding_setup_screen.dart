import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';
import 'package:zindagi_plus/providers/onboarding_provider.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

class OnboardingSetupScreen extends ConsumerStatefulWidget {
  const OnboardingSetupScreen({super.key});

  @override
  ConsumerState<OnboardingSetupScreen> createState() =>
      _OnboardingSetupScreenState();
}

class _OnboardingSetupScreenState extends ConsumerState<OnboardingSetupScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _ageCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final obState = ref.read(onboardingProvider);
    _nameCtrl = TextEditingController(text: obState.displayName);
    _heightCtrl = TextEditingController(
        text: obState.heightCm?.toStringAsFixed(0) ?? '175');
    _weightCtrl = TextEditingController(
        text: obState.weightKg?.toStringAsFixed(0) ?? '72');
    _ageCtrl =
        TextEditingController(text: obState.age?.toString() ?? '24');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_isSaving) return;
    final obState = ref.read(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    // Step-specific updates from text controllers
    if (obState.currentStep == 0) {
      if (_nameCtrl.text.trim().isEmpty) {
        _showToast('Please enter your preferred name');
        return;
      }
      notifier.setDisplayName(_nameCtrl.text.trim());
    } else if (obState.currentStep == 1) {
      final age = int.tryParse(_ageCtrl.text.trim());
      if (age == null || age < 12 || age > 120) {
        _showToast('Please enter a valid age (12–120)');
        return;
      }
      notifier.setDemographics(age: age);
    } else if (obState.currentStep == 2) {
      final h = double.tryParse(_heightCtrl.text.trim());
      final w = double.tryParse(_weightCtrl.text.trim());
      if (h == null || h < 50 || h > 250) {
        _showToast('Please enter a valid height in cm (50–250)');
        return;
      }
      if (w == null || w < 20 || w > 300) {
        _showToast('Please enter a valid weight in kg (20–300)');
        return;
      }
      notifier.setBodyMetrics(heightCm: h, weightKg: w);
    }

    if (obState.currentStep < OnboardingState.totalSteps - 1) {
      notifier.nextStep();
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final currentUser = ref.read(authNotifierProvider);
    if (currentUser == null) {
      _showToast('Session error. Please sign in again.');
      return;
    }

    setState(() => _isSaving = true);

    final updatedUser =
        ref.read(onboardingProvider.notifier).buildUser(currentUser);

    final result = await ref
        .read(authNotifierProvider.notifier)
        .completeOnboarding(updatedUser);

    if (!mounted) return;
    setState(() => _isSaving = false);

    switch (result) {
      case Success():
        context.go('/dashboard');
      case Failure(message: final msg):
        _showToast('Failed to save onboarding: $msg');
    }
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final obState = ref.watch(onboardingProvider);
    final colorScheme = Theme.of(context).colorScheme;

    final isOptionalStep =
        obState.currentStep == 3 || // Conditions/Allergies
        obState.currentStep == 5 || // Fitness
        obState.currentStep == 6;   // Nutrition

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: obState.currentStep > 0
            ? AppBackButton(
                onPressed: () =>
                    ref.read(onboardingProvider.notifier).previousStep(),
              )
            : null,
        title: Text(
          'Step ${obState.currentStep + 1} of ${OnboardingState.totalSteps}',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        centerTitle: true,
        actions: [
          if (isOptionalStep)
            TextButton(
              onPressed: () =>
                  ref.read(onboardingProvider.notifier).nextStep(),
              child: Text(
                'Skip',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: obState.progress,
            backgroundColor: colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            minHeight: 4,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: _buildStepContent(obState),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: PrimaryButton(
                text: obState.currentStep == OnboardingState.totalSteps - 1
                    ? 'Complete Setup & Launch'
                    : 'Continue',
                icon: obState.currentStep == OnboardingState.totalSteps - 1
                    ? Icons.rocket_launch_rounded
                    : Icons.arrow_forward_rounded,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _onNext,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(OnboardingState state) {
    switch (state.currentStep) {
      case 0:
        return _Step1Identity(controller: _nameCtrl);
      case 1:
        return _Step2Demographics(
          ageCtrl: _ageCtrl,
          selectedGender: state.gender ?? 'Male',
          onGenderSelected: (g) => ref
              .read(onboardingProvider.notifier)
              .setDemographics(gender: g),
        );
      case 2:
        return _Step3BodyMetrics(
          heightCtrl: _heightCtrl,
          weightCtrl: _weightCtrl,
          selectedBloodType: state.bloodType ?? 'B+',
          onBloodTypeSelected: (b) => ref
              .read(onboardingProvider.notifier)
              .setBodyMetrics(bloodType: b),
        );
      case 3:
        return _Step4HealthHistory(
          selectedConditions: state.conditions,
          selectedAllergies: state.allergies,
          onToggleCondition: (c) =>
              ref.read(onboardingProvider.notifier).toggleCondition(c),
          onToggleAllergy: (a) =>
              ref.read(onboardingProvider.notifier).toggleAllergy(a),
        );
      case 4:
        return _Step5Goals(
          selectedPrimaryGoal: state.primaryGoal ?? 'Improve overall health',
          selectedActivityLevel: state.activityLevel ?? 'Lightly active',
          onPrimaryGoalSelected: (g) =>
              ref.read(onboardingProvider.notifier).setGoals(primaryGoal: g),
          onActivityLevelSelected: (l) => ref
              .read(onboardingProvider.notifier)
              .setGoals(activityLevel: l),
        );
      case 5:
        return _Step6Fitness(
          experience: state.fitnessExperience ?? 'Beginner',
          timePerDay: state.workoutTimePerDay ?? '30 minutes',
          equipment: state.equipment ?? 'Basic home equipment',
          onChanged: (exp, time, equip) => ref
              .read(onboardingProvider.notifier)
              .setFitnessRoutine(
                experience: exp,
                timePerDay: time,
                equipment: equip,
              ),
        );
      case 6:
        return _Step7Nutrition(
          dietType: state.dietType ?? 'No specific diet',
          avoid: state.foodsToAvoid,
          onDietSelected: (d) =>
              ref.read(onboardingProvider.notifier).setNutrition(dietType: d),
          onToggleAvoid: (item) {
            final updated = Set<String>.from(state.foodsToAvoid);
            if (updated.contains(item)) {
              updated.remove(item);
            } else {
              updated.add(item);
            }
            ref
                .read(onboardingProvider.notifier)
                .setNutrition(avoid: updated);
          },
        );
      case 7:
      default:
        return _Step8Review(
          state: state,
          onEditStep: (step) =>
              ref.read(onboardingProvider.notifier).goToStep(step),
          onCitySelected: (city) =>
              ref.read(onboardingProvider.notifier).setLocation(city),
        );
    }
  }
}

// ── Step 1: Preferred Name ───────────────────────────────────────────────────

class _Step1Identity extends StatelessWidget {
  const _Step1Identity({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('👋', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 16),
        Text(
          'What should we call you?',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This will be your display name across your health scores, medication reminders, and AI consultations.',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),
        AppTextField(
          label: 'Your Preferred Name',
          hint: 'e.g. Ammar Malik',
          controller: controller,
          prefixIcon: const Icon(Icons.person_rounded),
        ),
      ],
    );
  }
}

// ── Step 2: Demographics ─────────────────────────────────────────────────────

class _Step2Demographics extends StatelessWidget {
  const _Step2Demographics({
    required this.ageCtrl,
    required this.selectedGender,
    required this.onGenderSelected,
  });

  final TextEditingController ageCtrl;
  final String selectedGender;
  final ValueChanged<String> onGenderSelected;

  static const _genders = ['Male', 'Female', 'Other', 'Prefer not to say'];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('🎂', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 16),
        Text(
          'Tell us about yourself',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Age and biological gender help calibrate clinical reference ranges for lab tests and metabolic calculations.',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        AppTextField(
          label: 'Your Age (Years)',
          hint: 'e.g. 24',
          controller: ageCtrl,
          keyboardType: TextInputType.number,
          prefixIcon: const Icon(Icons.cake_rounded),
        ),
        const SizedBox(height: 28),
        const SectionHeader(title: 'Gender'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _genders.map((g) {
            final isSelected = selectedGender == g;
            return ChoiceChip(
              label: Text(g),
              selected: isSelected,
              onSelected: (_) => onGenderSelected(g),
              selectedColor: colorScheme.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Step 3: Body Metrics ─────────────────────────────────────────────────────

class _Step3BodyMetrics extends StatelessWidget {
  const _Step3BodyMetrics({
    required this.heightCtrl,
    required this.weightCtrl,
    required this.selectedBloodType,
    required this.onBloodTypeSelected,
  });

  final TextEditingController heightCtrl;
  final TextEditingController weightCtrl;
  final String selectedBloodType;
  final ValueChanged<String> onBloodTypeSelected;

  static const _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('⚖️', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 16),
        Text(
          'Your Body Metrics',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Used to estimate caloric burn, hydration needs, and BMI benchmarks.',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 28),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                label: 'Height (cm)',
                hint: 'e.g. 175',
                controller: heightCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.height_rounded),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: AppTextField(
                label: 'Weight (kg)',
                hint: 'e.g. 72',
                controller: weightCtrl,
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.monitor_weight_rounded),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const SectionHeader(title: 'Blood Group'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _bloodTypes.map((b) {
            final isSelected = selectedBloodType == b;
            return ChoiceChip(
              label: Text(b),
              selected: isSelected,
              onSelected: (_) => onBloodTypeSelected(b),
              selectedColor: colorScheme.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Step 4: Health Conditions & Allergies ────────────────────────────────────

class _Step4HealthHistory extends StatelessWidget {
  const _Step4HealthHistory({
    required this.selectedConditions,
    required this.selectedAllergies,
    required this.onToggleCondition,
    required this.onToggleAllergy,
  });

  final Set<String> selectedConditions;
  final Set<String> selectedAllergies;
  final ValueChanged<String> onToggleCondition;
  final ValueChanged<String> onToggleAllergy;

  static const _conditionsList = [
    'None',
    'Pre-diabetes',
    'Type 2 Diabetes',
    'Hypertension',
    'High Cholesterol',
    'Vitamin D Deficiency',
    'Fatty Liver',
    'Thyroid Disorder',
    'Asthma',
  ];

  static const _allergiesList = [
    'None',
    'Peanuts',
    'Gluten / Celiac',
    'Dairy / Lactose',
    'Shellfish',
    'Eggs',
    'Penicillin',
    'Sulfa Drugs',
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('🩺', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 16),
        Text(
          'Health History & Allergies',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select any pre-existing conditions and allergies. We use this to screen meal and medication suggestions.',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Active Conditions'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _conditionsList.map((c) {
            final isSelected = selectedConditions.contains(c);
            return FilterChip(
              label: Text(c),
              selected: isSelected,
              onSelected: (_) => onToggleCondition(c),
              selectedColor: colorScheme.primary.withValues(alpha: 0.15),
              checkmarkColor: colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        const SectionHeader(title: 'Known Allergies'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _allergiesList.map((a) {
            final isSelected = selectedAllergies.contains(a);
            return FilterChip(
              label: Text(a),
              selected: isSelected,
              onSelected: (_) => onToggleAllergy(a),
              selectedColor: Colors.orange.withValues(alpha: 0.15),
              checkmarkColor: Colors.orange,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.orange.shade800
                    : colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Step 5: Goals & Activity Level ───────────────────────────────────────────

class _Step5Goals extends StatelessWidget {
  const _Step5Goals({
    required this.selectedPrimaryGoal,
    required this.selectedActivityLevel,
    required this.onPrimaryGoalSelected,
    required this.onActivityLevelSelected,
  });

  final String selectedPrimaryGoal;
  final String selectedActivityLevel;
  final ValueChanged<String> onPrimaryGoalSelected;
  final ValueChanged<String> onActivityLevelSelected;

  static const _goals = [
    (
      'Improve overall health',
      '🌟',
      'Holistic wellness, vitality, and immunity'
    ),
    (
      'Improve blood sugar & metabolic health',
      '🩸',
      'Targeted for pre-diabetes and glucose stability'
    ),
    (
      'Lose weight sustainably',
      '🔥',
      'Calorie guidance and fat-loss meal plans'
    ),
    (
      'Gain lean muscle & strength',
      '💪',
      'High-protein nutrition and resistance workouts'
    ),
    (
      'Improve cardiovascular fitness',
      '❤️',
      'Endurance pacing and blood pressure support'
    ),
    (
      'Build healthier daily habits',
      '🌱',
      'Hydration, consistent sleep, and mindful eating'
    ),
  ];

  static const _activityLevels = [
    (
      'Mostly inactive',
      '🛋️',
      'Desk job, minimal daily movement'
    ),
    (
      'Lightly active',
      '🚶',
      'Occasional walks or light exercise 1–3 days/wk'
    ),
    (
      'Moderately active',
      '🏃',
      'Regular workouts 3–5 days/wk'
    ),
    (
      'Very active',
      '⚡',
      'Heavy exercise or physically demanding work'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('🎯', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 16),
        Text(
          'Primary Health Goal',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select your main priority to tailor AI health plans and weekly targets.',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        ..._goals.map((g) {
          final isSelected = selectedPrimaryGoal == g.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(16),
              onTap: () => onPrimaryGoalSelected(g.$1),
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.08)
                  : Colors.white,
              child: Row(
                children: [
                  Text(g.$2, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          g.$1,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? colorScheme.primary
                                : colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          g.$3,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Baseline Activity Level'),
        const SizedBox(height: 12),
        ..._activityLevels.map((lvl) {
          final isSelected = selectedActivityLevel == lvl.$1;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AppCard(
              padding: const EdgeInsets.all(14),
              onTap: () => onActivityLevelSelected(lvl.$1),
              color: isSelected
                  ? colorScheme.secondary.withValues(alpha: 0.08)
                  : Colors.white,
              child: Row(
                children: [
                  Text(lvl.$2, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lvl.$1,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? colorScheme.secondary
                                : colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          lvl.$3,
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface
                                .withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: colorScheme.secondary,
                      size: 18,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Step 6: Fitness Routine ──────────────────────────────────────────────────

class _Step6Fitness extends StatelessWidget {
  const _Step6Fitness({
    required this.experience,
    required this.timePerDay,
    required this.equipment,
    required this.onChanged,
  });

  final String experience;
  final String timePerDay;
  final String equipment;
  final void Function(String exp, String time, String equip) onChanged;

  static const _experiences = ['Beginner', 'Intermediate', 'Advanced'];
  static const _times = ['15–20 minutes', '30 minutes', '45 minutes', '60+ minutes'];
  static const _equipments = [
    'No equipment (Bodyweight)',
    'Basic home equipment',
    'Full gym access'
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('💪', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 16),
        Text(
          'Workout Routine',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us how much time and gear you have for exercise.',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Experience Level'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _experiences.map((e) {
            final isSelected = experience == e;
            return ChoiceChip(
              label: Text(e),
              selected: isSelected,
              onSelected: (_) => onChanged(e, timePerDay, equipment),
              selectedColor: colorScheme.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Workout Time per Session'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _times.map((t) {
            final isSelected = timePerDay == t;
            return ChoiceChip(
              label: Text(t),
              selected: isSelected,
              onSelected: (_) => onChanged(experience, t, equipment),
              selectedColor: colorScheme.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Available Equipment'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _equipments.map((eq) {
            final isSelected = equipment == eq;
            return ChoiceChip(
              label: Text(eq),
              selected: isSelected,
              onSelected: (_) => onChanged(experience, timePerDay, eq),
              selectedColor: colorScheme.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Step 7: Nutrition & Diet Preferences ─────────────────────────────────────

class _Step7Nutrition extends StatelessWidget {
  const _Step7Nutrition({
    required this.dietType,
    required this.avoid,
    required this.onDietSelected,
    required this.onToggleAvoid,
  });

  final String dietType;
  final Set<String> avoid;
  final ValueChanged<String> onDietSelected;
  final ValueChanged<String> onToggleAvoid;

  static const _dietStyles = [
    'No specific diet',
    'High Protein / Low Carb',
    'Vegetarian',
    'Vegan',
    'Halal',
    'Low Glycemic Index'
  ];

  static const _avoidOptions = [
    'Refined sugar & sweets',
    'Fried / oily items',
    'High-sodium food',
    'White rice / refined flour',
    'Red meat',
    'Processed snacks'
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('🥗', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 16),
        Text(
          'Diet & Nutrition Style',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Helps curating desi and international healthy recipes that match your taste and health targets.',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: 'Preferred Diet Type'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _dietStyles.map((d) {
            final isSelected = dietType == d;
            return ChoiceChip(
              label: Text(d),
              selected: isSelected,
              onSelected: (_) => onDietSelected(d),
              selectedColor: colorScheme.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        const SectionHeader(title: 'Foods to Limit / Avoid'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _avoidOptions.map((item) {
            final isSelected = avoid.contains(item);
            return FilterChip(
              label: Text(item),
              selected: isSelected,
              onSelected: (_) => onToggleAvoid(item),
              selectedColor: Colors.purple.withValues(alpha: 0.15),
              checkmarkColor: Colors.purple,
              labelStyle: TextStyle(
                color: isSelected ? Colors.purple.shade800 : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ── Step 8: Location & Summary Review ────────────────────────────────────────

class _Step8Review extends StatelessWidget {
  const _Step8Review({
    required this.state,
    required this.onEditStep,
    required this.onCitySelected,
  });

  final OnboardingState state;
  final ValueChanged<int> onEditStep;
  final ValueChanged<String> onCitySelected;

  static const _cities = [
    'Lahore', 'Karachi', 'Islamabad', 'Rawalpindi', 'Faisalabad', 'Peshawar', 'Multan', 'Other'
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final conditionsStr = state.conditions.isEmpty || state.conditions.contains('None')
        ? 'None'
        : state.conditions.join(', ');
    final allergiesStr = state.allergies.isEmpty || state.allergies.contains('None')
        ? 'None'
        : state.allergies.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('📍', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 16),
        Text(
          'Location & Final Review',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: colorScheme.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your city allows us to locate nearby verified clinics and diagnostic labs.',
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface.withValues(alpha: 0.65),
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        const SectionHeader(title: 'City / Region'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _cities.map((city) {
            final isSelected = state.city == city;
            return ChoiceChip(
              label: Text(city),
              selected: isSelected,
              onSelected: (_) => onCitySelected(city),
              selectedColor: colorScheme.primary.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                color: isSelected ? colorScheme.primary : colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 28),
        const SectionHeader(title: 'Profile Summary'),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _ReviewRow(
                label: 'Name',
                value: state.displayName.isNotEmpty ? state.displayName : 'User',
                onEdit: () => onEditStep(0),
              ),
              const Divider(height: 20),
              _ReviewRow(
                label: 'Demographics',
                value: '${state.age} yrs · ${state.gender}',
                onEdit: () => onEditStep(1),
              ),
              const Divider(height: 20),
              _ReviewRow(
                label: 'Body Metrics',
                value: '${state.heightCm?.toStringAsFixed(0)} cm · ${state.weightKg?.toStringAsFixed(0)} kg · Blood ${state.bloodType}',
                onEdit: () => onEditStep(2),
              ),
              const Divider(height: 20),
              _ReviewRow(
                label: 'Health & Allergies',
                value: 'Conditions: $conditionsStr\nAllergies: $allergiesStr',
                onEdit: () => onEditStep(3),
              ),
              const Divider(height: 20),
              _ReviewRow(
                label: 'Primary Goal',
                value: '${state.primaryGoal}\nActivity: ${state.activityLevel}',
                onEdit: () => onEditStep(4),
              ),
              const Divider(height: 20),
              _ReviewRow(
                label: 'Diet Style',
                value: '${state.dietType}',
                onEdit: () => onEditStep(6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  const _ReviewRow({
    required this.label,
    required this.value,
    required this.onEdit,
  });

  final String label;
  final String value;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
              height: 1.4,
            ),
          ),
        ),
        GestureDetector(
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              'Edit',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
