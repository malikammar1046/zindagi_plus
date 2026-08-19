import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/lab_report.dart';

/// Contract for the medical lab report data and OCR extraction layer.
abstract class LabReportRepository {
  /// Uploads a medical report document to secure storage, creates a database
  /// record with status [ReportStatus.uploaded], and returns the initial [LabReport].
  Future<Result<LabReport>> uploadReport({
    required String filePath,
    required String fileName,
    int? fileSizeBytes,
    String? mimeType,
  });

  /// Executes the OCR text extraction pipeline on the uploaded report:
  /// 1. Updates database status to [ReportStatus.processing].
  /// 2. Performs text recognition via the OCR service.
  /// 3. If OCR succeeds: updates status to [ReportStatus.completed], saves [extractedText], and sets [processedAt].
  /// 4. If OCR fails: preserves the original file, updates status to [ReportStatus.failed], and saves [errorMessage].
  Future<Result<LabReport>> processReport(String reportId, String filePath);

  /// Retries OCR processing on an existing report that failed.
  /// Does not require re-uploading the original file if [filePath] is accessible or fetched from storage.
  Future<Result<LabReport>> retryProcessing(String reportId, {String? filePath});

  /// Fetches a specific lab report by its unique [reportId].
  Future<Result<LabReport>> getReportById(String reportId);

  /// Returns the authenticated user's complete report history, newest first.
  Future<Result<List<LabReport>>> getReportHistory();

  /// Generates a secure, temporary signed download URL for the original report file.
  Future<Result<String>> getReportFileSignedUrl(String storagePath);
}
