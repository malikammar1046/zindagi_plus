import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/lab_report.dart';
import 'package:zindagi_plus/data/repositories/interfaces/lab_report_repository.dart';

/// Mock implementation of [LabReportRepository].
///
/// All report IDs are stable and deterministic — no random values.
/// Swap for a real API implementation via `repository_providers.dart`.
class LabReportRepositoryMock implements LabReportRepository {
  // Stable mock report history, newest first.
  static final List<LabReport> _reports = [
    LabReport(
      reportId: 'report_001',
      fileName: 'Blood_Report_July_2025.jpg',
      uploadedAt: DateTime(2025, 7, 5, 10, 30),
      status: ReportStatus.processed,
      biomarkerCount: 8,
      attentionCount: 3,
      summary: 'HbA1c borderline, LDL elevated, Vitamin D low.',
    ),
    LabReport(
      reportId: 'report_002',
      fileName: 'CBC_June_2025.pdf',
      uploadedAt: DateTime(2025, 6, 12, 14, 15),
      status: ReportStatus.processed,
      biomarkerCount: 12,
      attentionCount: 1,
      summary: 'CBC mostly normal. Haemoglobin slightly low.',
    ),
    LabReport(
      reportId: 'report_003',
      fileName: 'Lipid_Panel_May_2025.jpg',
      uploadedAt: DateTime(2025, 5, 20, 9, 0),
      status: ReportStatus.processed,
      biomarkerCount: 5,
      attentionCount: 2,
      summary: 'LDL elevated, HDL low.',
    ),
  ];

  // Counter for reports uploaded during the current session.
  int _sessionUploadCount = 0;

  @override
  Future<Result<String>> uploadReport(String fileName) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _sessionUploadCount++;
    final reportId = 'report_session_$_sessionUploadCount';
    _reports.insert(
      0,
      LabReport(
        reportId: reportId,
        fileName: fileName,
        uploadedAt: DateTime.now(),
        status: ReportStatus.processed,
        biomarkerCount: 8,
        attentionCount: 3,
        summary: 'Newly processed report.',
      ),
    );
    return Success(reportId);
  }

  @override
  Future<Result<LabReport>> getReportById(String reportId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    try {
      final report = _reports.firstWhere((r) => r.reportId == reportId);
      return Success(report);
    } catch (_) {
      return Failure('Report not found: $reportId');
    }
  }

  @override
  Future<Result<List<LabReport>>> getReportHistory() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return Success(List.unmodifiable(_reports));
  }
}
