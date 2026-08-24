import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/lab_report.dart';
import 'package:zindagi_plus/providers/repository_providers.dart';
import 'package:zindagi_plus/services/lab_report_parser.dart';

/// Processing lifecycle stage for UI tracking.
enum ReportProcessingStage {
  idle,
  uploading,
  extractingOcr,
  finalizing,
  completed,
  failed,
}

/// State for active report upload and OCR processing.
class ReportProcessingState {
  const ReportProcessingState({
    this.stage = ReportProcessingStage.idle,
    this.progress = 0.0,
    this.statusMessage = 'Ready',
    this.report,
    this.reportId,
    this.filePath,
    this.fileName,
    this.errorMessage,
  });

  final ReportProcessingStage stage;
  final double progress;
  final String statusMessage;
  final LabReport? report;
  final String? reportId;
  final String? filePath;
  final String? fileName;
  final String? errorMessage;

  bool get isProcessing =>
      stage == ReportProcessingStage.uploading ||
      stage == ReportProcessingStage.extractingOcr ||
      stage == ReportProcessingStage.finalizing;

  bool get isCompleted => stage == ReportProcessingStage.completed;
  bool get isFailed => stage == ReportProcessingStage.failed;

  ReportProcessingState copyWith({
    ReportProcessingStage? stage,
    double? progress,
    String? statusMessage,
    LabReport? report,
    String? reportId,
    String? filePath,
    String? fileName,
    String? errorMessage,
  }) {
    return ReportProcessingState(
      stage: stage ?? this.stage,
      progress: progress ?? this.progress,
      statusMessage: statusMessage ?? this.statusMessage,
      report: report ?? this.report,
      reportId: reportId ?? this.reportId,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Notifier coordinating report upload, OCR extraction, and status transitions.
class ReportProcessingNotifier extends StateNotifier<ReportProcessingState> {
  ReportProcessingNotifier(this.ref) : super(const ReportProcessingState());

  final Ref ref;

  /// Executes the full upload and OCR text extraction pipeline:
  /// 1. Upload original document to Supabase Storage & insert record (status: uploaded)
  /// 2. Transition status to 'processing' & execute OCR via OcrService
  /// 3. On success -> save extracted text & set status: completed
  /// 4. On failure -> retain original file & set status: failed
  Future<bool> uploadAndProcessReport({
    required String filePath,
    required String fileName,
    int? fileSizeBytes,
    String? mimeType,
  }) async {
    final repo = ref.read(labReportRepositoryProvider);

    // ── Stage 1: Uploading original file ────────────────────────────────────
    state = state.copyWith(
      stage: ReportProcessingStage.uploading,
      progress: 0.25,
      statusMessage: 'Uploading original report securely...',
      filePath: filePath,
      fileName: fileName,
      errorMessage: null,
    );

    final uploadResult = await repo.uploadReport(
      filePath: filePath,
      fileName: fileName,
      fileSizeBytes: fileSizeBytes,
      mimeType: mimeType,
    );

    if (uploadResult is Failure<LabReport>) {
      state = state.copyWith(
        stage: ReportProcessingStage.failed,
        progress: 0.0,
        statusMessage: 'Upload failed',
        errorMessage: uploadResult.message,
      );
      return false;
    }

    final initialReport = (uploadResult as Success<LabReport>).data;

    // ── Stage 2: OCR Text Extraction ────────────────────────────────────────
    state = state.copyWith(
      stage: ReportProcessingStage.extractingOcr,
      progress: 0.60,
      statusMessage: 'Extracting text via on-device OCR engine...',
      report: initialReport,
      reportId: initialReport.id,
    );

    final processResult = await repo.processReport(initialReport.id, filePath);

    // ── Stage 3: Finalize or Fail ───────────────────────────────────────────
    if (processResult is Success<LabReport>) {
      final finishedReport = processResult.data;
      state = state.copyWith(
        stage: ReportProcessingStage.completed,
        progress: 1.0,
        statusMessage: 'OCR text extraction completed!',
        report: finishedReport,
      );

      // Invalidate history so list screen displays fresh report immediately
      ref.invalidate(reportHistoryProvider);
      return true;
    } else {
      final errorMsg = (processResult as Failure<LabReport>).message;
      state = state.copyWith(
        stage: ReportProcessingStage.failed,
        progress: 0.0,
        statusMessage: 'OCR text extraction failed',
        errorMessage: errorMsg,
      );
      ref.invalidate(reportHistoryProvider);
      return false;
    }
  }

  /// Retries OCR processing on a previously failed report.
  Future<bool> retryProcessing(String reportId, {String? filePath}) async {
    final repo = ref.read(labReportRepositoryProvider);
    final targetPath = filePath ?? state.filePath ?? '';

    state = state.copyWith(
      stage: ReportProcessingStage.extractingOcr,
      progress: 0.50,
      statusMessage: 'Retrying on-device OCR text extraction...',
      reportId: reportId,
      errorMessage: null,
    );

    final result = await repo.retryProcessing(reportId, filePath: targetPath);

    if (result is Success<LabReport>) {
      state = state.copyWith(
        stage: ReportProcessingStage.completed,
        progress: 1.0,
        statusMessage: 'OCR text extraction completed!',
        report: result.data,
      );
      ref.invalidate(reportHistoryProvider);
      ref.invalidate(reportDetailProvider(reportId));
      return true;
    } else {
      final errorMsg = (result as Failure<LabReport>).message;
      state = state.copyWith(
        stage: ReportProcessingStage.failed,
        progress: 0.0,
        statusMessage: 'OCR extraction retry failed',
        errorMessage: errorMsg,
      );
      return false;
    }
  }

  /// Resets state back to idle.
  void reset() {
    state = const ReportProcessingState();
  }
}

/// Provides the active report processing coordinator.
final reportProcessingNotifierProvider =
    StateNotifierProvider<ReportProcessingNotifier, ReportProcessingState>((ref) {
  return ReportProcessingNotifier(ref);
});

/// Provides the user's complete report history.
final reportHistoryProvider =
    FutureProvider.autoDispose<List<LabReport>>((ref) async {
  final repo = ref.watch(labReportRepositoryProvider);
  final result = await repo.getReportHistory();
  return switch (result) {
    Success(data: final list) => list,
    Failure(message: final msg) => throw Exception(msg),
  };
});

/// Provides a single lab report by ID.
final reportDetailProvider =
    FutureProvider.autoDispose.family<LabReport, String>((ref, reportId) async {
  final repo = ref.watch(labReportRepositoryProvider);
  final result = await repo.getReportById(reportId);
  return switch (result) {
    Success(data: final report) => report,
    Failure(message: final msg) => throw Exception(msg),
  };
});

/// Provides a secure signed URL for the original document.
final reportSignedUrlProvider =
    FutureProvider.autoDispose.family<String, String>((ref, storagePath) async {
  final repo = ref.watch(labReportRepositoryProvider);
  final result = await repo.getReportFileSignedUrl(storagePath);
  return switch (result) {
    Success(data: final url) => url,
    Failure(message: final msg) => throw Exception(msg),
  };
});

/// Provides parsed biomarker measurements for a single report.
final reportBiomarkersProvider =
    FutureProvider.autoDispose.family<List<ParsedBiomarker>, String>((ref, reportId) async {
  final repo = ref.watch(labReportRepositoryProvider);
  final result = await repo.getBiomarkers(reportId);
  return switch (result) {
    Success(data: final list) => list,
    Failure(message: final msg) => throw Exception(msg),
  };
});
