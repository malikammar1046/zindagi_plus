import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/providers/report_providers.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

// ── Mock scenario enum (for test / dev demo) ─────────────────────────────────

enum MockProcessingScenario { success, invalidFile, processingFailure }

// ── Screen ────────────────────────────────────────────────────────────────────

class ReportProcessingScreen extends ConsumerStatefulWidget {
  const ReportProcessingScreen({
    super.key,
    this.fileName = 'lab_report.jpg',
    this.filePath,
    this.reportId,
    this.scenario = MockProcessingScenario.success,
  });

  final String fileName;
  final String? filePath;
  final String? reportId;
  final MockProcessingScenario scenario;

  @override
  ConsumerState<ReportProcessingScreen> createState() =>
      _ReportProcessingScreenState();
}

class _ReportProcessingScreenState extends ConsumerState<ReportProcessingScreen>
    with TickerProviderStateMixin {
  // ── Step definitions ────────────────────────────────────────────────────────
  static const _steps = [
    (
      icon: Icons.cloud_upload_outlined,
      label: 'Storing Original File',
      detail: 'Encrypted storage in private bucket',
      color: Color(0xFF00674F),
    ),
    (
      icon: Icons.document_scanner_outlined,
      label: 'Initializing On-Device OCR',
      detail: 'Local privacy-preserving text recognition',
      color: Color(0xFF00674F),
    ),
    (
      icon: Icons.text_snippet_outlined,
      label: 'Extracting Raw Text',
      detail: 'Reading clinical test names and values',
      color: Color(0xFF00674F),
    ),
    (
      icon: Icons.check_circle_outline_rounded,
      label: 'Finalizing Report',
      detail: 'Storing OCR output in your record',
      color: Color(0xFF00674F),
    ),
  ];

  int _currentStep = 0;
  double _stepProgress = 0.0;
  int _secondsRemaining = 8;
  String _errorMessage = '';
  String? _effectiveReportId;

  late final AnimationController _ringCtrl;
  late final AnimationController _pulseCtrl;
  late final List<AnimationController> _stepCtls;

  @override
  void initState() {
    super.initState();
    _ringCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    _stepCtls = List.generate(
      4,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 420),
      ),
    );
    _stepCtls[0].forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startProcessing();
    });
  }

  Future<void> _startProcessing() async {
    setState(() {
      _currentStep = 0;
      _stepProgress = 0;
      _secondsRemaining = 8;
      _errorMessage = '';
      for (final c in _stepCtls) {
        c.reset();
      }
      _stepCtls[0].forward();
    });

    // Check if we should run DEV simulated mock scenario or actual pipeline
    final hasRealFile = widget.filePath != null && widget.filePath!.isNotEmpty;
    final isDevMockForced = widget.scenario != MockProcessingScenario.success;

    if (hasRealFile && !isDevMockForced) {
      _runRealProcessing();
    } else {
      _runSimulatedProcessing();
    }
  }

  Future<void> _runRealProcessing() async {
    // Step 0: Uploading original file
    _stepCtls[0].forward();
    setState(() {
      _currentStep = 0;
      _stepProgress = 0.25;
      _secondsRemaining = 6;
    });

    final notifier = ref.read(reportProcessingNotifierProvider.notifier);

    // Step 1: Initializing OCR
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _stepCtls[1].forward();
    setState(() {
      _currentStep = 1;
      _stepProgress = 0.50;
      _secondsRemaining = 4;
    });

    // Execute actual upload and OCR
    final success = await notifier.uploadAndProcessReport(
      filePath: widget.filePath!,
      fileName: widget.fileName,
    );

    if (!mounted) return;

    if (success) {
      // Step 2 & 3: Success progression
      _stepCtls[2].forward();
      setState(() {
        _currentStep = 2;
        _stepProgress = 0.75;
        _secondsRemaining = 2;
      });

      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      _stepCtls[3].forward();
      setState(() {
        _currentStep = 3;
        _stepProgress = 1.0;
        _secondsRemaining = 0;
      });

      _pulseCtrl.stop();
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;

      final state = ref.read(reportProcessingNotifierProvider);
      _effectiveReportId = state.report?.id ?? widget.reportId ?? 'report_new';

      context.pushReplacement(
        '/upload/result',
        extra: {
          'reportId': _effectiveReportId,
          'fileName': widget.fileName,
        },
      );
    } else {
      final state = ref.read(reportProcessingNotifierProvider);
      setState(() {
        _errorMessage = state.errorMessage ??
            'OCR text extraction failed. Please ensure the document is clear and readable.';
        _effectiveReportId = state.reportId;
      });
      _pulseCtrl.stop();
    }
  }

  Future<void> _runSimulatedProcessing() async {
    const tickMs = 80;
    const ticksPerStep = 15;

    final failAtStep = switch (widget.scenario) {
      MockProcessingScenario.invalidFile => 0,
      MockProcessingScenario.processingFailure => 2,
      MockProcessingScenario.success => -1,
    };

    for (int step = 0; step < 4; step++) {
      if (!mounted) return;
      setState(() {
        _currentStep = step;
        _stepProgress = 0;
      });

      if (step > 0) _stepCtls[step].forward();

      for (int t = 1; t <= ticksPerStep; t++) {
        await Future.delayed(const Duration(milliseconds: tickMs));
        if (!mounted) return;
        setState(() {
          _stepProgress = t / ticksPerStep;
          if (t % 5 == 0 && _secondsRemaining > 0) _secondsRemaining--;
        });
      }

      if (step == failAtStep) {
        await Future.delayed(const Duration(milliseconds: 200));
        if (!mounted) return;
        setState(() {
          _errorMessage = step == 0
              ? 'The document could not be read. Please upload a clear image of a medical report.'
              : 'OCR text recognition encountered an unexpected error. Please try again.';
        });
        _pulseCtrl.stop();
        return;
      }

      await Future.delayed(const Duration(milliseconds: 100));
    }

    if (!mounted) return;
    _pulseCtrl.stop();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final effectiveReportId = widget.reportId ?? 'report_session_new';
    context.pushReplacement(
      '/upload/result',
      extra: {
        'reportId': effectiveReportId,
        'fileName': widget.fileName,
      },
    );
  }

  Future<void> _handleRetry() async {
    if (_effectiveReportId != null && widget.filePath != null) {
      setState(() {
        _errorMessage = '';
        _pulseCtrl.repeat(reverse: true);
      });
      final notifier = ref.read(reportProcessingNotifierProvider.notifier);
      final success = await notifier.retryProcessing(
        _effectiveReportId!,
        filePath: widget.filePath,
      );
      if (success && mounted) {
        context.pushReplacement(
          '/upload/result',
          extra: {
            'reportId': _effectiveReportId,
            'fileName': widget.fileName,
          },
        );
      } else if (mounted) {
        final state = ref.read(reportProcessingNotifierProvider);
        setState(() {
          _errorMessage = state.errorMessage ?? 'Retry failed.';
        });
      }
    } else {
      _startProcessing();
    }
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _pulseCtrl.dispose();
    for (final c in _stepCtls) {
      c.dispose();
    }
    super.dispose();
  }

  double get _overallProgress {
    if (_errorMessage.isNotEmpty) return 0.0;
    return (_currentStep + _stepProgress) / 4;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerColor;

    // Error / failure state
    if (_errorMessage.isNotEmpty) {
      return _ErrorView(
        message: _errorMessage,
        fileName: widget.fileName,
        onRetry: _handleRetry,
        onCancel: () =>
            context.canPop() ? context.pop() : context.go('/upload'),
      );
    }

    // Processing state
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: const AppBackButton(fallbackLocation: '/upload'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Text(
                'Extracting Report Text',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.fileName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 36),

              // Progress ring
              Center(
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, _) {
                    final glowAlpha = 0.16 + _pulseCtrl.value * 0.08;
                    return Container(
                      width: 170,
                      height: 170,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withValues(alpha: glowAlpha),
                            blurRadius: 40,
                            spreadRadius: 6,
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _RingPainter(_overallProgress, dividerColor, colorScheme.primary),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(_overallProgress * 100).round()}%',
                                style: TextStyle(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                '~${_secondsRemaining}s left',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 36),

              // Steps
              for (int i = 0; i < 4; i++) ...[
                _StepRow(
                  icon: _steps[i].icon,
                  label: _steps[i].label,
                  detail: _steps[i].detail,
                  color: _steps[i].color,
                  isActive: i == _currentStep,
                  isDone: i < _currentStep,
                  animation: _stepCtls[i],
                ),
                if (i < 3)
                  Padding(
                    padding: const EdgeInsets.only(left: 35),
                    child: Container(
                      width: 2,
                      height: 16,
                      color: i < _currentStep
                          ? colorScheme.primary.withValues(alpha: 0.4)
                          : dividerColor,
                    ),
                  ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step Row Widget ──────────────────────────────────────────────────────────

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.icon,
    required this.label,
    required this.detail,
    required this.color,
    required this.isActive,
    required this.isDone,
    required this.animation,
  });

  final IconData icon;
  final String label, detail;
  final Color color;
  final bool isActive, isDone;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? colorScheme.primary
                    : isActive
                        ? colorScheme.primary.withValues(alpha: 0.15)
                        : colorScheme.onSurface.withValues(alpha: 0.06),
                border: Border.all(
                  color: isActive ? colorScheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: isDone
                  ? const Icon(Icons.check_rounded, size: 20, color: Colors.white)
                  : Icon(
                      icon,
                      size: 18,
                      color: isActive
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isActive || isDone ? FontWeight.w700 : FontWeight.w500,
                      color: isActive || isDone
                          ? colorScheme.onSurface
                          : colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    detail,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error View Widget ────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.fileName,
    required this.onRetry,
    required this.onCancel,
  });

  final String message, fileName;
  final VoidCallback onRetry, onCancel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: onCancel,
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.error.withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 44,
                  color: colorScheme.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'OCR Text Extraction Failed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Original file "$fileName" is preserved in your records.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(),
              PrimaryButton(
                text: 'Retry Processing',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text('Pick Another File'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Ring Painter ─────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress, this.trackColor, this.primaryColor);
  final double progress;
  final Color trackColor;
  final Color primaryColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 16 || size.height <= 16) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 16) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.15)
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, trackPaint);

    // Progress
    final progressPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.primaryColor != primaryColor;
}
