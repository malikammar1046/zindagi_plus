import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

// ── Master lists ─────────────────────────────────────────────────────────────

const _allConditions = [
  'Type 2 Diabetes',
  'Pre-diabetes',
  'Hypertension',
  'Vitamin D Deficiency',
  'High Cholesterol',
  'Fatty Liver',
  'Thyroid Disorder',
  'Asthma',
];

const _allAllergies = [
  'Peanuts',
  'Gluten / Celiac',
  'Dairy / Lactose',
  'Shellfish',
  'Eggs',
  'Penicillin',
];

const _bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'];

const _goalsList = [
  'Improve overall health',
  'Improve blood sugar & metabolic health',
  'Lose weight sustainably',
  'Gain lean muscle & strength',
  'Improve cardiovascular fitness',
  'Build healthier daily habits',
];

const _dietStyles = [
  'No specific diet',
  'High Protein / Low Carb',
  'Vegetarian',
  'Vegan',
  'Halal',
  'Low Glycemic Index',
];

// ── Screen ─────────────────────────────────────────────────────────────────────

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _heightCtrl;
  late final TextEditingController _cityCtrl;
  String _bloodType = 'B+';
  String _primaryGoal = 'Improve overall health';
  String _dietType = 'High Protein / Low Carb';
  final Set<String> _conditions = {};
  final Set<String> _allergies = {};
  bool _isSaving = false;
  File? _profileImage;
  late final AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider);
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _ageCtrl = TextEditingController(text: user?.age?.toString() ?? '24');
    _weightCtrl = TextEditingController(
        text: user?.weightKg != null ? user!.weightKg!.toStringAsFixed(0) : '72');
    _heightCtrl = TextEditingController(
        text: user?.heightCm != null ? user!.heightCm!.toStringAsFixed(0) : '175');
    _cityCtrl = TextEditingController(text: user?.city ?? 'Lahore');

    final rawBlood = user?.bloodType?.replaceAll('−', '-').trim();
    _bloodType = _bloodTypes.firstWhere(
      (b) => b == rawBlood,
      orElse: () => _bloodTypes.first,
    );

    final rawGoal = user?.primaryGoal?.trim();
    _primaryGoal = _goalsList.firstWhere(
      (g) => g.toLowerCase() == rawGoal?.toLowerCase(),
      orElse: () => _goalsList.first,
    );

    final rawDiet = user?.dietType?.trim();
    _dietType = _dietStyles.firstWhere(
      (d) => d.toLowerCase() == rawDiet?.toLowerCase(),
      orElse: () => _dietStyles.first,
    );

    if (user?.conditions.isNotEmpty == true) {
      _conditions.addAll(user!.conditions);
    }
    if (user?.allergies.isNotEmpty == true) {
      _allergies.addAll(user!.allergies);
    }

    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    )..forward();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    _cityCtrl.dispose();
    _entranceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final currentUser = ref.read(authNotifierProvider);
    if (currentUser == null) {
      setState(() => _isSaving = false);
      return;
    }

    final updatedUser = currentUser.copyWith(
      name: _nameCtrl.text.trim(),
      age: int.tryParse(_ageCtrl.text.trim()),
      weightKg: double.tryParse(_weightCtrl.text.trim()),
      heightCm: double.tryParse(_heightCtrl.text.trim()),
      bloodType: _bloodType,
      city: _cityCtrl.text.trim(),
      primaryGoal: _primaryGoal,
      dietType: _dietType,
      conditions: _conditions.toList(),
      allergies: _allergies.toList(),
    );

    final result =
        await ref.read(authNotifierProvider.notifier).updateProfile(updatedUser);

    if (!mounted) return;
    setState(() => _isSaving = false);

    switch (result) {
      case Success():
        context.pop();
      case Failure(message: final msg):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $msg'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.close_rounded, size: 24),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _SaveButton(
              loading: _isSaving,
              onPressed: _save,
            ),
          ),
        ],
      ),
      body: AnimatedBuilder(
        animation: _entranceCtrl,
        builder: (_, child) {
          final t = CurvedAnimation(
            parent: _entranceCtrl,
            curve: Curves.easeOutCubic,
          ).value;
          return Opacity(opacity: t, child: child);
        },
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            children: [
              // ── Avatar header ─────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                        image: _profileImage != null
                            ? DecorationImage(
                                image: FileImage(_profileImage!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: _profileImage == null
                          ? Center(
                              child: Text(
                                _nameCtrl.text.isNotEmpty
                                    ? _nameCtrl.text[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontSize: 36,
                                  color: colorScheme.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(height: 10),
                    _TapScale(
                      onTap: _pickImage,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.camera_alt_outlined,
                              size: 14,
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Change Photo',
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Section: Personal ─────────────────────────────────────
              const SectionHeader(title: 'Personal Information'),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        prefixIcon: Icon(Icons.cake_outlined),
                        suffixText: 'yrs',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cityCtrl,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        prefixIcon: Icon(Icons.location_city_rounded),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Height',
                        prefixIcon: Icon(Icons.height_rounded),
                        suffixText: 'cm',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _weightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Weight',
                        prefixIcon: Icon(Icons.monitor_weight_outlined),
                        suffixText: 'kg',
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Blood type picker
              DropdownButtonFormField<String>(
                initialValue: _bloodTypes.contains(_bloodType)
                    ? _bloodType
                    : _bloodTypes.first,
                decoration: const InputDecoration(
                  labelText: 'Blood Group',
                  prefixIcon: Icon(Icons.bloodtype_outlined),
                ),
                items: _bloodTypes
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(t),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _bloodType = v ?? _bloodType),
              ),

              const SizedBox(height: 28),

              // ── Section: Goal & Diet ──────────────────────────────────
              const SectionHeader(title: 'Goals & Nutrition'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _goalsList.contains(_primaryGoal)
                    ? _primaryGoal
                    : _goalsList.first,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Primary Health Goal',
                  prefixIcon: Icon(Icons.track_changes_rounded),
                ),
                items: _goalsList
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text(g, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setState(() => _primaryGoal = v ?? _primaryGoal),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: _dietStyles.contains(_dietType)
                    ? _dietType
                    : _dietStyles.first,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Diet Style',
                  prefixIcon: Icon(Icons.restaurant_menu_rounded),
                ),
                items: _dietStyles
                    .map(
                      (d) => DropdownMenuItem(
                        value: d,
                        child: Text(d),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _dietType = v ?? _dietType),
              ),

              const SizedBox(height: 28),

              // ── Section: Conditions ───────────────────────────────────
              const SectionHeader(title: 'Active Conditions'),
              const SizedBox(height: 4),
              Text(
                'Select all that apply — this personalises your health insights.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allConditions
                    .map(
                      (c) => _ConditionChip(
                        label: c,
                        selected: _conditions.contains(c),
                        onToggle: () => setState(() {
                          if (_conditions.contains(c)) {
                            _conditions.remove(c);
                          } else {
                            _conditions.add(c);
                          }
                        }),
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 28),

              // ── Section: Allergies ────────────────────────────────────
              const SectionHeader(title: 'Known Allergies'),
              const SizedBox(height: 4),
              Text(
                'Select sensitivities to screen meal recommendations.',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allAllergies
                    .map(
                      (a) => _ConditionChip(
                        label: a,
                        selected: _allergies.contains(a),
                        onToggle: () => setState(() {
                          if (_allergies.contains(a)) {
                            _allergies.remove(a);
                          } else {
                            _allergies.add(a);
                          }
                        }),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Condition Chip ─────────────────────────────────────────────────────────────

class _ConditionChip extends StatelessWidget {
  const _ConditionChip({
    required this.label,
    required this.selected,
    required this.onToggle,
  });

  final String label;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _TapScale(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary.withValues(alpha: 0.12)
              : colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colorScheme.primary : theme.dividerColor,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              Icon(Icons.check_rounded, size: 14, color: colorScheme.primary),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Save Button ───────────────────────────────────────────────────────────────

class _SaveButton extends StatelessWidget {
  const _SaveButton({required this.loading, required this.onPressed});
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return _TapScale(
      onTap: loading ? () {} : onPressed,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: loading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.onPrimary,
                ),
              )
            : Text(
                'Save',
                style: TextStyle(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
      ),
    );
  }
}

// ── Tap-scale utility ─────────────────────────────────────────────────────────

class _TapScale extends StatefulWidget {
  const _TapScale({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_TapScale> createState() => _TapScaleState();
}

class _TapScaleState extends State<_TapScale> {
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
        duration: const Duration(milliseconds: 110),
        scale: _pressed ? 0.95 : 1.0,
        child: widget.child,
      ),
    );
  }
}
