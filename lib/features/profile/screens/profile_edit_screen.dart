import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';
// ── Condition data ─────────────────────────────────────────────────────────────

const _allConditions = [
  'Type 2 Diabetes',
  'Hypertension',
  'Vitamin D Deficiency',
  'High Cholesterol',
  'Anaemia',
  'Thyroid Disorder',
  'Asthma',
  'Fatty Liver',
];

const _bloodTypes = ['A+', 'A−', 'B+', 'B−', 'AB+', 'AB−', 'O+', 'O−'];

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
  String _bloodType = 'B+';
  final Set<String> _conditions = {'Type 2 Diabetes', 'Vitamin D Deficiency'};
  bool _isSaving = false;
  File? _profileImage;
  late final AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authNotifierProvider);
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _ageCtrl = TextEditingController(text: '24');
    _weightCtrl = TextEditingController(text: '72');
    _heightCtrl = TextEditingController(text: '175');
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
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isSaving = false);
    // Apple §7: go back along the same path we came from
    context.pop();
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
          // Save — Apple §1: respond immediately
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
                  // Blood type picker
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _bloodType,
                          isExpanded: true,
                          dropdownColor: colorScheme.surface,
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 14,
                          ),
                          icon: Icon(
                            Icons.arrow_drop_down,
                            color: colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          hint: Text(
                            'Blood Type',
                            style: TextStyle(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                          items: _bloodTypes
                              .map(
                                (t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(t),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _bloodType = v ?? _bloodType),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Section: Conditions ───────────────────────────────────
              const SectionHeader(title: 'Active Conditions'),
              const SizedBox(height: 4),
              Text(
                'Select all that apply — this personalises your AI recommendations.',
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
                        onToggle: () {
                          setState(() {
                            if (_conditions.contains(c)) {
                              _conditions.remove(c);
                            } else {
                              _conditions.add(c);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 36),

              // ── Save button ────────────────────────────────────────────
              PrimaryButton(
                text: 'Save Changes',
                onPressed: _isSaving ? () {} : _save,
                icon: Icons.check_rounded,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Condition chip (Apple §1: spring scale on tap-down) ────────────────────────

class _ConditionChip extends StatefulWidget {
  const _ConditionChip({
    required this.label,
    required this.selected,
    required this.onToggle,
  });
  final String label;
  final bool selected;
  final VoidCallback onToggle;

  @override
  State<_ConditionChip> createState() => _ConditionChipState();
}

class _ConditionChipState extends State<_ConditionChip> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onToggle();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.93 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: widget.selected
                ? colorScheme.primary.withValues(alpha: 0.16)
                : colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.selected
                  ? colorScheme.primary.withValues(alpha: 0.55)
                  : theme.dividerColor,
              width: widget.selected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  widget.selected
                      ? Icons.check_rounded
                      : Icons.add_rounded,
                  key: ValueKey(widget.selected),
                  size: 14,
                  color: widget.selected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: widget.selected
                      ? colorScheme.primary
                      : colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Save button ────────────────────────────────────────────────────────────────

class _SaveButton extends StatefulWidget {
  const _SaveButton({required this.loading, required this.onPressed});
  final bool loading;
  final VoidCallback onPressed;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _pressed ? 0.94 : 1.0,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: widget.loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
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
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

class _TapScale extends StatefulWidget {
  const _TapScale({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

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
        duration: const Duration(milliseconds: 130),
        scale: _pressed ? 0.95 : 1.0,
        child: widget.child,
      ),
    );
  }
}
