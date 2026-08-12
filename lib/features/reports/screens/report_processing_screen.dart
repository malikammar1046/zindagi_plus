import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/shared/widgets/app_components.dart';

// ── Mock scenario enum (deterministic, no randomness) ─────────────────────────

/// Controls which upload outcome is simulated during development/testing.
///
/// Pass this to [ReportProcessingScreen] to exercise specific states:
/// - [success] (default) — all 4 steps complete, navigate to result.
/// - [invalidFile] — fails at step 1 (OCR cannot read the document).
/// - [processingFailure] — fails at step 3 (AI analysis error).
enum MockProcessingScenario { success, invalidFile, processingFailure }

// ── Screen ────────────────────────────────────────────────────────────────────

class ReportProcessingScreen extends StatefulWidget {
  const ReportProcessingScreen({
    super.key,
    this.fileName = 'lab_report.jpg',
    this.reportId,
    this.scenario = MockProcessingScenario.success,
  });

  final String fileName;

  /// Stable report identifier — either from the upload repo or a session ID.
  final String? reportId;

  /// Determines which mock outcome to simulate. Default: [MockProcessingScenario.success].
  final MockProcessingScenario scenario;

  @override
  State<ReportProcessingScreen> createState() => _ReportProcessingScreenState();
}

enum _UploadState { processing, success, invalidFile, failure }

class _ReportProcessingScreenState extends State<ReportProcessingScreen>
    with TickerProviderStateMixin {
  // ── Step definitions ────────────────────────────────────────────────────────
  static const _steps = [
    (
      icon: Icons.document_scanner_outlined,
      label: 'Reading document',
      detail: 'Extracting text via OCR engine',
      color: Color(0xFF00674F),
    ),
    (
      icon: Icons.biotech_outlined,
      label: 'Extracting biomarkers',
      detail: 'Identifying 200+ health markers',
      color: Color(0xFF00674F),
    ),
    (
      icon: Icons.auto_awesome_outlined,
      label: 'Running AI analysis',
      detail: 'Comparing against 50M+ records',
      color: Color(0xFF00674F),
    ),
    (
      icon: Icons.insights_outlined,
      label: 'Generating insights',
      detail: 'Personalising for your profile',
      color: Color(0xFF00674F),
    ),
  ];

  int _currentStep = 0;
  double _stepProgress = 0.0;
  int _secondsRemaining = 12;
  _UploadState _uploadState = _UploadState.processing;
  String _errorMessage = '';

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
    _runProcessing();
  }

  Future<void> _runProcessing() async {
    setState(() {
      _uploadState = _UploadState.processing;
      _currentStep = 0;
      _stepProgress = 0;
      _secondsRemaining = 12;
      // Reset step controllers for retry
      for (final c in _stepCtls) {
        c.reset();
      }
      _stepCtls[0].forward();
    });

    const tickMs = 95;
    const ticksPerStep = 20;

    // Determine at which step to inject a deterministic failure.
    final failAtStep = switch (widget.scenario) {
      MockProcessingScenario.invalidFile => 0,
      MockProcessingScenario.processingFailure => 2,
      MockProcessingScenario.success => -1, // never fail
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

      // Inject deterministic failure at the specified step.
      if (step == failAtStep) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!mounted) return;
        setState(() {
          _uploadState = step == 0
              ? _UploadState.invalidFile
              : _UploadState.failure;
          _errorMessage = step == 0
              ? 'The document could not be read. Please upload a clear image of a blood test report.'
              : 'AI analysis failed. This may be due to an unrecognised report format or a temporary service issue.';
        });
        _pulseCtrl.stop();
        return;
      }

      await Future.delayed(const Duration(milliseconds: 180));
    }

    if (!mounted) return;
    setState(() => _uploadState = _UploadState.success);
    _pulseCtrl.stop();
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    final effectiveReportId = widget.reportId ?? 'report_session_new';
    context.go(
      '/upload/result',
      extra: {
        'reportId': effectiveReportId,
        'fileName': widget.fileName,
      },
    );
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
    if (_uploadState == _UploadState.success) return 1.0;
    return (_currentStep + _stepProgress) / 4;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final dividerColor = Theme.of(context).dividerColor;

    // ── Error / invalid-file state ──────────────────────────────────────────
    if (_uploadState == _UploadState.invalidFile ||
        _uploadState == _UploadState.failure) {
      return _ErrorView(
        isInvalidFile: _uploadState == _UploadState.invalidFile,
        message: _errorMessage,
        fileName: widget.fileName,
        onRetry: _runProcessing,
        onCancel: () => context.go('/upload'),
      );
    }

    // ── Processing / success state ──────────────────────────────────────────
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),

              // Header
              Text(
                _uploadState == _UploadState.success
                    ? 'Analysis Complete!'
                    : 'Analysing Report',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
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

              const SizedBox(height: 44),

              // Progress ring
              Center(
                child: AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, _) {
                    final glowAlpha = _uploadState == _UploadState.success
                        ? 0.0
                        : 0.18 + _pulseCtrl.value * 0.08;
                    return Container(
                      width: 180,
                      height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.cyan.withValues(alpha: glowAlpha),
                            blurRadius: 48,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: _RingPainter(_overallProgress, dividerColor),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_uploadState == _UploadState.success)
                                Icon(
                                  Icons.check_circle_rounded,
                                  size: 48,
                                  color: colorScheme.primary,
                                )
                              else
                                Text(
                                  '${(_overallProgress * 100).round()}%',
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              Text(
                                _uploadState == _UploadState.success
                                    ? 'Done ✓'
                                    : '~${_secondsRemaining}s left',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _uploadState == _UploadState.success
                                      ? colorScheme.primary
                                      : colorScheme.onSurface
                                          .withValues(alpha: 0.6),
                                  fontWeight:
                                      _uploadState == _UploadState.success
                                          ? FontWeight.w700
                                          : FontWeight.w400,
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

              const SizedBox(height: 44),

              // Step list
              ...List.generate(4, (i) {
                final done = i < _currentStep ||
                    _uploadState == _UploadState.success;
                final active = i == _currentStep &&
                    _uploadState == _UploadState.processing;
                return AnimatedBuilder(
                  animation: _stepCtls[i],
                  builder: (_, _) {
                    final t = CurvedAnimation(
                      parent: _stepCtls[i],
                      curve: Curves.easeOutBack,
                    ).value.clamp(0.0, 1.0);
                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, (1 - t) * 22),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _StepTile(
                            icon: _steps[i].icon,
                            label: _steps[i].label,
                            detail: _steps[i].detail,
                            accentColor: _steps[i].color,
                            done: done,
                            active: active,
                            progress: active ? _stepProgress : (done ? 1.0 : 0.0),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.isInvalidFile,
    required this.message,
    required this.fileName,
    required this.onRetry,
    required this.onCancel,
  });

  final bool isInvalidFile;
  final String message;
  final String fileName;
  final VoidCallback onRetry;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 96,
                height: 96,
                margin: const EdgeInsets.only(bottom: 32),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isInvalidFile
                      ? Icons.file_copy_outlined
                      : Icons.error_outline_rounded,
                  size: 48,
                  color: colorScheme.error,
                ),
              ),
              Text(
                isInvalidFile ? 'Invalid File' : 'Processing Failed',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                fileName,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: colorScheme.error.withValues(alpha: 0.2)),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              PrimaryButton(
                text: 'Try Again',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
              const SizedBox(height: 12),
              SecondaryButton(
                label: 'Upload Different File',
                icon: Icons.upload_file_rounded,
                onPressed: onCancel,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step tile ─────────────────────────────────────────────────────────────────

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.icon,
    required this.label,
    required this.detail,
    required this.accentColor,
    required this.done,
    required this.active,
    required this.progress,
  });

  final IconData icon;
  final String label, detail;
  final Color accentColor;
  final bool done, active;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: done || active
                  ? accentColor.withValues(alpha: 0.18)
                  : colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: done || active
                    ? accentColor.withValues(alpha: 0.45)
                    : theme.dividerColor,
              ),
            ),
            child: Icon(
              done ? Icons.check_rounded : icon,
              color: done || active
                  ? accentColor
                  : colorScheme.onSurface.withValues(alpha: 0.4),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 260),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: active || done
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  child: Text(label),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (active) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 4,
                        backgroundColor: theme.dividerColor,
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ring painter ──────────────────────────────────────────────────────────────

class _RingPainter extends CustomPainter {
  const _RingPainter(this.progress, this.dividerColor);
  final double progress;
  final Color dividerColor;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 10;
    final rect = Rect.fromCircle(center: c, radius: r);

    canvas.drawArc(
      rect,
      -math.pi / 2,
      math.pi * 2,
      false,
      Paint()
        ..color = dividerColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        math.pi * 2 * progress,
        false,
        Paint()
          ..shader = SweepGradient(
            colors: const [Colors.cyan, Color(0xFF00674F), Colors.teal],
            startAngle: 0,
            endAngle: math.pi * 2,
            transform: const GradientRotation(-math.pi / 2),
          ).createShader(rect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
