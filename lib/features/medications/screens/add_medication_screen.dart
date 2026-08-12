import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/data/models/medication.dart';
import 'package:zindagi_plus/providers/medication_provider.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

class AddMedicationScreen extends ConsumerStatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  ConsumerState<AddMedicationScreen> createState() =>
      _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final timeStr = _time.format(context);

    final newMed = Medication(
      id: 'med_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      dose: _dosageCtrl.text.trim(),
      time: '$timeStr — ${_noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : 'As prescribed'}',
      status: MedStatus.pending,
      note: _noteCtrl.text.trim().isNotEmpty
          ? _noteCtrl.text.trim()
          : 'Added by user',
      iconCodePoint: 0xe3a3,
      colorValue: 0xFF00674F,
    );

    await ref.read(medicationProvider.notifier).addMedication(newMed);

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${newMed.name} added to your schedule'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medication'),
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.close_rounded, size: 24),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              AppTextField(
                label: 'Medication Name',
                hint: 'e.g. Metformin, Panadol',
                controller: _nameCtrl,
                prefixIcon: const Icon(Icons.medication_rounded),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Dosage',
                hint: 'e.g. 1 pill, 500mg',
                controller: _dosageCtrl,
                prefixIcon: const Icon(Icons.monitor_weight_rounded),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Instructions / Note (Optional)',
                hint: 'e.g. With food, Before bed',
                controller: _noteCtrl,
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
              const SizedBox(height: 24),
              const SectionHeader(title: 'Reminder Time'),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Time',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _time.format(context),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),
              PrimaryButton(
                text: 'Save Medication',
                isLoading: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
