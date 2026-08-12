import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/lab_report.dart';

/// Contract for the lab report data layer.
///
/// Swap implementations (mock ↔ API) via the Riverpod provider in
/// `lib/providers/repository_providers.dart` without touching business logic.
abstract class LabReportRepository {
  /// Submits a lab report for processing. In the real implementation this
  /// uploads the file to cloud storage and triggers the OCR/AI pipeline.
  ///
  /// Returns a stable [reportId] that can be used for subsequent queries.
  Future<Result<String>> uploadReport(String fileName);

  /// Fetches the full analysis result for [reportId].
  Future<Result<LabReport>> getReportById(String reportId);

  /// Returns the user's complete report history, newest first.
  Future<Result<List<LabReport>>> getReportHistory();
}
