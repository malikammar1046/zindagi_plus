import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/data/models/lab_report.dart';

void main() {
  group('ReportStatus', () {
    test('fromString parses all valid database statuses correctly', () {
      expect(ReportStatus.fromString('uploaded'), equals(ReportStatus.uploaded));
      expect(ReportStatus.fromString('processing'), equals(ReportStatus.processing));
      expect(ReportStatus.fromString('completed'), equals(ReportStatus.completed));
      expect(ReportStatus.fromString('processed'), equals(ReportStatus.completed));
      expect(ReportStatus.fromString('failed'), equals(ReportStatus.failed));
      expect(ReportStatus.fromString('unknown_status'), equals(ReportStatus.uploaded));
      expect(ReportStatus.fromString(null), equals(ReportStatus.uploaded));
    });

    test('toDbString maps enum values to Postgres check constraint values', () {
      expect(ReportStatus.uploaded.toDbString(), equals('uploaded'));
      expect(ReportStatus.processing.toDbString(), equals('processing'));
      expect(ReportStatus.completed.toDbString(), equals('completed'));
      expect(ReportStatus.failed.toDbString(), equals('failed'));
    });

    test('displayLabel returns human-readable labels', () {
      expect(ReportStatus.uploaded.displayLabel, equals('Uploaded'));
      expect(ReportStatus.processing.displayLabel, equals('Processing'));
      expect(ReportStatus.completed.displayLabel, equals('Completed'));
      expect(ReportStatus.failed.displayLabel, equals('Failed'));
    });
  });

  group('LabReport Model', () {
    test('serializes and deserializes complete JSON with OCR fields correctly', () {
      final now = DateTime(2026, 8, 19, 10, 30);
      final report = LabReport(
        id: 'rep_123_abc',
        userId: 'user_456',
        fileName: 'Blood_Test_Report.jpg',
        storagePath: 'user_456/rep_123_abc_Blood_Test_Report.jpg',
        fileSizeBytes: 2450000,
        mimeType: 'image/jpeg',
        status: ReportStatus.completed,
        extractedText: 'Haemoglobin: 14.2 g/dL\nPlatelets: 250,000 /uL',
        aiSummary: 'Normal blood count.',
        uploadedAt: now,
        processedAt: now.add(const Duration(seconds: 12)),
        biomarkerCount: 8,
        attentionCount: 1,
      );

      final json = report.toJson();
      expect(json['id'], equals('rep_123_abc'));
      expect(json['user_id'], equals('user_456'));
      expect(json['file_name'], equals('Blood_Test_Report.jpg'));
      expect(json['storage_path'], equals('user_456/rep_123_abc_Blood_Test_Report.jpg'));
      expect(json['status'], equals('completed'));
      expect(json['extracted_text'], contains('Haemoglobin: 14.2 g/dL'));
      expect(json['biomarker_count'], equals(8));

      final fromJson = LabReport.fromJson(json);
      expect(fromJson.id, equals(report.id));
      expect(fromJson.reportId, equals(report.id));
      expect(fromJson.fileName, equals(report.fileName));
      expect(fromJson.status, equals(ReportStatus.completed));
      expect(fromJson.extractedText, equals(report.extractedText));
      expect(fromJson.hasExtractedText, isTrue);
      expect(fromJson.isCompleted, isTrue);
      expect(fromJson.isFailed, isFalse);
    });

    test('handles failed report state with error message correctly', () {
      final report = LabReport(
        id: 'rep_failed_01',
        fileName: 'blurry_photo.jpg',
        uploadedAt: DateTime.now(),
        status: ReportStatus.failed,
        errorMessage: 'Document is blurry or unreadable.',
      );

      expect(report.isFailed, isTrue);
      expect(report.isCompleted, isFalse);
      expect(report.hasExtractedText, isFalse);
      expect(report.errorMessage, equals('Document is blurry or unreadable.'));

      final json = report.toJson();
      expect(json['status'], equals('failed'));
      expect(json['error_message'], equals('Document is blurry or unreadable.'));
    });

    test('copyWith updates fields immutably', () {
      final initial = LabReport(
        id: 'rep_001',
        fileName: 'test.jpg',
        uploadedAt: DateTime.now(),
        status: ReportStatus.uploaded,
      );

      final updated = initial.copyWith(
        status: ReportStatus.completed,
        extractedText: 'Extracted text content',
        processedAt: DateTime.now(),
      );

      expect(initial.status, equals(ReportStatus.uploaded));
      expect(updated.status, equals(ReportStatus.completed));
      expect(updated.extractedText, equals('Extracted text content'));
      expect(updated.id, equals('rep_001'));
    });
  });
}
