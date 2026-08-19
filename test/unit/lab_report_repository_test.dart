import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/lab_report.dart';
import 'package:zindagi_plus/data/repositories/implementations/lab_report_repository_mock.dart';
import 'package:zindagi_plus/services/ocr/mock_ocr_service.dart';

void main() {
  late MockOcrService mockOcr;
  late LabReportRepositoryMock repo;

  setUp(() {
    LabReportRepositoryMock.resetReports();
    mockOcr = MockOcrService(delayMs: 0);
    repo = LabReportRepositoryMock(ocrService: mockOcr);
  });

  group('LabReportRepository Lifecycle', () {
    test('uploadReport creates record in uploaded status with storage path', () async {
      final result = await repo.uploadReport(
        filePath: '/mock/path/test_cbc.jpg',
        fileName: 'test_cbc.jpg',
        fileSizeBytes: 204800,
        mimeType: 'image/jpeg',
      );

      expect(result, isA<Success<LabReport>>());
      final report = (result as Success<LabReport>).data;
      expect(report.id, isNotEmpty);
      expect(report.fileName, equals('test_cbc.jpg'));
      expect(report.status, equals(ReportStatus.uploaded));
      expect(report.storagePath, contains(report.id));
      expect(report.extractedText, isEmpty);
      expect(report.fileSizeBytes, equals(204800));
    });

    test('processReport successfully extracts text and transitions to completed', () async {
      final uploadResult = await repo.uploadReport(
        filePath: '/mock/path/test_lipid.jpg',
        fileName: 'test_lipid.jpg',
      );
      final reportId = (uploadResult as Success<LabReport>).data.id;

      final processResult = await repo.processReport(reportId, '/mock/path/test_lipid.jpg');
      expect(processResult, isA<Success<LabReport>>());

      final completedReport = (processResult as Success<LabReport>).data;
      expect(completedReport.status, equals(ReportStatus.completed));
      expect(completedReport.hasExtractedText, isTrue);
      expect(completedReport.extractedText, contains('CHUGHTAI LAB'));
      expect(completedReport.extractedText, contains('LIPID PANEL'));
      expect(completedReport.processedAt, isNotNull);
      expect(completedReport.errorMessage, isNull);
    });

    test('processReport on OCR failure preserves original record and transitions to failed', () async {
      mockOcr.behavior = MockOcrBehavior.invalidFile;

      final uploadResult = await repo.uploadReport(
        filePath: '/mock/path/unreadable.jpg',
        fileName: 'unreadable.jpg',
      );
      final reportId = (uploadResult as Success<LabReport>).data.id;

      final processResult = await repo.processReport(reportId, '/mock/path/unreadable.jpg');
      expect(processResult, isA<Failure<LabReport>>());

      // Fetch the preserved report from repository
      final fetchResult = await repo.getReportById(reportId);
      expect(fetchResult, isA<Success<LabReport>>());

      final failedReport = (fetchResult as Success<LabReport>).data;
      expect(failedReport.status, equals(ReportStatus.failed));
      expect(failedReport.isFailed, isTrue);
      expect(failedReport.errorMessage, isNotEmpty);
      expect(failedReport.fileName, equals('unreadable.jpg'));
      expect(failedReport.storagePath, isNotEmpty); // Original file path preserved!
    });

    test('retryProcessing successfully re-processes a failed report', () async {
      // 1. Initial failed processing
      mockOcr.behavior = MockOcrBehavior.invalidFile;
      final uploadResult = await repo.uploadReport(
        filePath: '/mock/path/retry_test.jpg',
        fileName: 'retry_test.jpg',
      );
      final reportId = (uploadResult as Success<LabReport>).data.id;
      await repo.processReport(reportId, '/mock/path/retry_test.jpg');

      var report = (await repo.getReportById(reportId) as Success<LabReport>).data;
      expect(report.status, equals(ReportStatus.failed));

      // 2. Retry with recovered OCR behavior
      mockOcr.behavior = MockOcrBehavior.success;
      final retryResult = await repo.retryProcessing(reportId, filePath: '/mock/path/retry_test.jpg');
      expect(retryResult, isA<Success<LabReport>>());

      final recoveredReport = (retryResult as Success<LabReport>).data;
      expect(recoveredReport.status, equals(ReportStatus.completed));
      expect(recoveredReport.hasExtractedText, isTrue);
    });

    test('getReportHistory returns existing reports list', () async {
      final result = await repo.getReportHistory();
      expect(result, isA<Success<List<LabReport>>>());
      final history = (result as Success<List<LabReport>>).data;
      expect(history, isNotEmpty);
    });

    test('getReportFileSignedUrl returns valid signed URL', () async {
      final result = await repo.getReportFileSignedUrl('user_1/report_001.jpg');
      expect(result, isA<Success<String>>());
      expect((result as Success<String>).data, contains('user_1/report_001.jpg'));
    });
  });
}
