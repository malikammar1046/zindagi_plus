import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/lab_report.dart';
import 'package:zindagi_plus/data/repositories/interfaces/lab_report_repository.dart';
import 'package:zindagi_plus/services/lab_report_parser.dart';
import 'package:zindagi_plus/services/ocr/mock_ocr_service.dart';
import 'package:zindagi_plus/services/ocr/ocr_service.dart';

/// Mock implementation of [LabReportRepository].
///
/// Provides deterministic, reproducible behavior for testing and offline development.
class LabReportRepositoryMock implements LabReportRepository {
  LabReportRepositoryMock({OcrService? ocrService})
      : _ocrService = ocrService ?? MockOcrService();

  final OcrService _ocrService;

  static final List<LabReport> _reports = [
    LabReport(
      id: 'report_001',
      fileName: 'Blood_Report_July_2025.jpg',
      storagePath: 'mock_user/report_001_Blood_Report_July_2025.jpg',
      fileSizeBytes: 2450000,
      mimeType: 'image/jpeg',
      uploadedAt: DateTime(2025, 7, 5, 10, 30),
      processedAt: DateTime(2025, 7, 5, 10, 31),
      status: ReportStatus.completed,
      extractedText: MockOcrService.defaultSampleMedicalReportText,
      biomarkerCount: 8,
      attentionCount: 3,
      aiSummary: 'HbA1c borderline, LDL elevated, Vitamin D low.',
    ),
    LabReport(
      id: 'report_002',
      fileName: 'CBC_June_2025.pdf',
      storagePath: 'mock_user/report_002_CBC_June_2025.pdf',
      fileSizeBytes: 1200000,
      mimeType: 'application/pdf',
      uploadedAt: DateTime(2025, 6, 12, 14, 15),
      processedAt: DateTime(2025, 6, 12, 14, 16),
      status: ReportStatus.completed,
      extractedText: MockOcrService.defaultSampleMedicalReportText,
      biomarkerCount: 12,
      attentionCount: 1,
      aiSummary: 'CBC mostly normal. Haemoglobin slightly low.',
    ),
    LabReport(
      id: 'report_003',
      fileName: 'Lipid_Panel_May_2025.jpg',
      storagePath: 'mock_user/report_003_Lipid_Panel_May_2025.jpg',
      fileSizeBytes: 1800000,
      mimeType: 'image/jpeg',
      uploadedAt: DateTime(2025, 5, 20, 9, 0),
      processedAt: DateTime(2025, 5, 20, 9, 1),
      status: ReportStatus.completed,
      extractedText: MockOcrService.defaultSampleMedicalReportText,
      biomarkerCount: 5,
      attentionCount: 2,
      aiSummary: 'LDL elevated, HDL low.',
    ),
  ];

  int _sessionUploadCount = 0;

  @override
  Future<Result<LabReport>> uploadReport({
    required String filePath,
    required String fileName,
    int? fileSizeBytes,
    String? mimeType,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _sessionUploadCount++;
    final reportId = 'report_session_$_sessionUploadCount';

    final report = LabReport(
      id: reportId,
      fileName: fileName,
      storagePath: 'mock_user/${reportId}_$fileName',
      fileSizeBytes: fileSizeBytes ?? 1500000,
      mimeType: mimeType ?? 'image/jpeg',
      uploadedAt: DateTime.now(),
      status: ReportStatus.uploaded,
      extractedText: '',
      biomarkerCount: 0,
      attentionCount: 0,
      aiSummary: '',
    );

    _reports.insert(0, report);
    return Success(report);
  }

  @override
  Future<Result<LabReport>> processReport(String reportId, String filePath) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final index = _reports.indexWhere((r) => r.id == reportId);
    if (index == -1) {
      return Failure('Report not found: $reportId');
    }

    // Set processing
    _reports[index] = _reports[index].copyWith(status: ReportStatus.processing);

    // Call OCR service
    final ocrResult = await _ocrService.extractText(filePath);

    if (ocrResult is Success<String>) {
      final updated = _reports[index].copyWith(
        status: ReportStatus.completed,
        extractedText: ocrResult.data,
        processedAt: DateTime.now(),
        biomarkerCount: 8,
        attentionCount: 3,
        aiSummary: 'Newly processed medical report.',
        errorMessage: null,
      );
      _reports[index] = updated;
      return Success(updated);
    } else {
      final errorMsg = (ocrResult as Failure<String>).message;
      final updated = _reports[index].copyWith(
        status: ReportStatus.failed,
        errorMessage: errorMsg,
        processedAt: DateTime.now(),
      );
      _reports[index] = updated;
      return Failure(errorMsg);
    }
  }

  @override
  Future<Result<LabReport>> retryProcessing(String reportId, {String? filePath}) async {
    return processReport(reportId, filePath ?? 'sample_report.jpg');
  }

  @override
  Future<Result<LabReport>> getReportById(String reportId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final report = _reports.firstWhere((r) => r.id == reportId);
      return Success(report);
    } catch (_) {
      return Failure('Report not found: $reportId');
    }
  }

  @override
  Future<Result<List<LabReport>>> getReportHistory() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return Success(List.unmodifiable(_reports));
  }

  @override
  Future<Result<String>> getReportFileSignedUrl(String storagePath) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return Success('https://example.com/storage/signed/$storagePath');
  }

  @override
  Future<Result<void>> saveBiomarkers(
    String reportId,
    String userId,
    List<ParsedBiomarker> biomarkers,
  ) async {
    // No-op in mock — biomarkers are derived in-memory from extractedText.
    return const Success(null);
  }

  @override
  Future<Result<List<ParsedBiomarker>>> getBiomarkers(String reportId) async {
    // Derive biomarkers on-the-fly from mock OCR text.
    final report = _reports.where((r) => r.id == reportId).firstOrNull;
    if (report == null) return const Success([]);
    final biomarkers = LabReportParser.parse(report.extractedText);
    return Success(biomarkers);
  }

  /// Helper for tests to reset mock state
  static void resetReports() {
    _reports.clear();
    _reports.addAll([
      LabReport(
        id: 'report_001',
        fileName: 'Blood_Report_July_2025.jpg',
        storagePath: 'mock_user/report_001_Blood_Report_July_2025.jpg',
        fileSizeBytes: 2450000,
        mimeType: 'image/jpeg',
        uploadedAt: DateTime(2025, 7, 5, 10, 30),
        processedAt: DateTime(2025, 7, 5, 10, 31),
        status: ReportStatus.completed,
        extractedText: MockOcrService.defaultSampleMedicalReportText,
        biomarkerCount: 8,
        attentionCount: 3,
        aiSummary: 'HbA1c borderline, LDL elevated, Vitamin D low.',
      ),
    ]);
  }
}
