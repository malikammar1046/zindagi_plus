import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zindagi_plus/core/theme/app_theme.dart';
import 'package:zindagi_plus/shared/widgets/premium_ui.dart';

class UploadScreen extends ConsumerStatefulWidget {
  const UploadScreen({super.key});

  @override
  ConsumerState<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends ConsumerState<UploadScreen> {
  final _picker = ImagePicker();
  bool _picking = false;

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
      // Apple §7: navigate forward along the upload flow path
      // Pass fileName so the processing screen can display it
      context.push('/upload/processing', extra: file.name);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not pick file: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Upload Lab Report'),
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // ── Upload card ──────────────────────────────────────────────
              Expanded(child: _UploadCard(onTap: _picking ? null : _pickAndProcess)),

              const SizedBox(height: 20),

              // ── Info banner ──────────────────────────────────────────────
              GlassPanel(
                padding: const EdgeInsets.all(14),
                radius: 18,
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.cyan,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Supported: Blood test reports, CBC, lipid panels, HbA1c, metabolic panels, and more.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
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
      ),
    );
  }
}

// ── Upload card ────────────────────────────────────────────────────────────────

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
    return GestureDetector(
      // Apple §1: respond on pointer-down
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
          child: GlassPanel(
            radius: 32,
            padding: EdgeInsets.zero,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: AppColors.emerald.withValues(alpha: .3),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Pulsing icon circle
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (_, _) => Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.emerald.withValues(
                          alpha: 0.06 + _pulseCtrl.value * 0.04,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.emerald.withValues(
                              alpha: 0.12 + _pulseCtrl.value * 0.06,
                            ),
                            blurRadius: 40,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.cloud_upload_outlined,
                        size: 56,
                        color: AppColors.emerald,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Upload Lab Report',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to select an image from your gallery',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: PremiumButton(
                      label: 'Choose File',
                      icon: Icons.photo_library_outlined,
                      onPressed: widget.onTap,
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
