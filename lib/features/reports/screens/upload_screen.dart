import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zindagi_plus/features/reports/screens/report_processing_screen.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _picker = ImagePicker();
  bool _picking = false;

  // DEV-only: the scenario to simulate in ReportProcessingScreen.
  MockProcessingScenario _devScenario = MockProcessingScenario.success;

  Future<void> _pickAndProcess() async {
    if (_picking) return;
    setState(() => _picking = true);

    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (!mounted) return;
      if (file == null) {
        setState(() => _picking = false);
        return;
      }
      // Pass fileName and the selected dev scenario.
      context.push(
        '/upload/processing',
        extra: {
          'fileName': file.name,
          'scenario': _devScenario,
        },
      );
    } catch (e) {
      if (!mounted) return;
      final colorScheme = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not pick file: $e'),
          backgroundColor: colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  void _showScenarioPicker() {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  '[DEV] Select Mock Scenario',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _ScenarioTile(
                label: '✅  Success',
                subtitle: 'All steps complete — navigate to result',
                selected: _devScenario == MockProcessingScenario.success,
                onTap: () {
                  setState(
                      () => _devScenario = MockProcessingScenario.success);
                  Navigator.pop(ctx);
                },
              ),
              _ScenarioTile(
                label: '🚫  Invalid File',
                subtitle: 'Fails at step 1 — OCR cannot read document',
                selected: _devScenario == MockProcessingScenario.invalidFile,
                onTap: () {
                  setState(
                      () => _devScenario = MockProcessingScenario.invalidFile);
                  Navigator.pop(ctx);
                },
              ),
              _ScenarioTile(
                label: '⚠️  Processing Failure',
                subtitle: 'Fails at step 3 — AI analysis error',
                selected:
                    _devScenario == MockProcessingScenario.processingFailure,
                onTap: () {
                  setState(() =>
                      _devScenario = MockProcessingScenario.processingFailure);
                  Navigator.pop(ctx);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Lab Report'),
        automaticallyImplyLeading: false,
        actions: [
          // View history button
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'My Reports',
            onPressed: () => context.push('/report-history'),
          ),
          // DEV scenario picker
          GestureDetector(
            onTap: _showScenarioPicker,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
              ),
              child: const Text(
                'DEV',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.orange,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Expanded(child: _UploadCard(onTap: _picking ? null : _pickAndProcess)),
            const SizedBox(height: 20),
            AppCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Supported: Blood test reports, CBC, lipid panels, HbA1c, metabolic panels, and more.',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _ScenarioTile extends StatelessWidget {
  const _ScenarioTile({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final String label, subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      title: Text(label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? colorScheme.primary : colorScheme.onSurface,
          )),
      subtitle: Text(subtitle,
          style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.6))),
      trailing: selected
          ? Icon(Icons.check_circle_rounded, color: colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

// ── Upload card (preserved exactly, only minor ref change) ────────────────────

class _UploadCard extends StatefulWidget {
  const _UploadCard({required this.onTap});
  final VoidCallback? onTap;

  @override
  State<_UploadCard> createState() => _UploadCardState();
}

class _UploadCardState extends State<_UploadCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 150),
        scale: _pressed ? 0.97 : 1.0,
        child: AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, child) => Transform.scale(
            scale: 1.0 + _pulseCtrl.value * 0.015,
            child: child,
          ),
          child: AppCard(
            padding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, _) => Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colorScheme.primary.withValues(
                          alpha: 0.06 + _pulseCtrl.value * 0.04,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(
                              alpha: 0.12 + _pulseCtrl.value * 0.06,
                            ),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.cloud_upload_outlined,
                        size: 56,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Upload Lab Report',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to select an image from your gallery',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: PrimaryButton(
                      text: 'Choose File',
                      icon: Icons.photo_library_outlined,
                      onPressed: widget.onTap ?? () {},
                    ),
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
