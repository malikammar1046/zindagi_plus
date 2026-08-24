import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/lab_report.dart';
import 'package:zindagi_plus/data/repositories/implementations/lab_report_repository_mock.dart';
import 'package:zindagi_plus/services/ocr/mock_ocr_service.dart';
import 'package:zindagi_plus/services/ocr/ocr_service.dart';

class _CustomFailingOcrService implements OcrService {
  _CustomFailingOcrService({required this.failureToReturn});

  final OcrFailure failureToReturn;

  @override
  Result<bool> validateFile(String filePath, {int? fileSizeBytes}) {
    return OcrFileValidator.validate(filePath, fileSizeBytes: fileSizeBytes);
  }

  @override
  Future<Result<String>> extractText(String filePath) async {
    return failureToReturn;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 2 OCR Hardening & Error Categorization Tests', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ocr_test_');
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    group('1. File Validation Rules', () {
      test('Rejects non-existent files with clear message', () {
        final result = OcrFileValidator.validate('${tempDir.path}/missing.jpg');
        expect(result.isFailure, isTrue);
        expect((result as Failure<bool>).message, contains('does not exist'));
      });

      test('Rejects PDF files with explicit guidance', () {
        final pdfFile = File('${tempDir.path}/report.pdf')..writeAsStringSync('dummy pdf content');
        final result = OcrFileValidator.validate(pdfFile.path);
        expect(result.isFailure, isTrue);
        expect((result as Failure<bool>).message, contains('PDF format is not directly supported'));
      });

      test('Rejects unsupported file extensions', () {
        final txtFile = File('${tempDir.path}/report.txt')..writeAsStringSync('dummy text');
        final result = OcrFileValidator.validate(txtFile.path);
        expect(result.isFailure, isTrue);
        expect((result as Failure<bool>).message, contains('Unsupported file type'));
      });

      test('Rejects 0-byte empty files', () {
        final emptyJpg = File('${tempDir.path}/empty.jpg')..createSync();
        final result = OcrFileValidator.validate(emptyJpg.path);
        expect(result.isFailure, isTrue);
        expect((result as Failure<bool>).message, contains('empty (0 bytes)'));
      });

      test('Rejects files exceeding 15 MB limit', () {
        final sampleJpg = File('${tempDir.path}/large.jpg')..writeAsStringSync('data');
        final result = OcrFileValidator.validate(
          sampleJpg.path,
          fileSizeBytes: 16 * 1024 * 1024,
        );
        expect(result.isFailure, isTrue);
        expect((result as Failure<bool>).message, contains('exceeds the 15 MB size limit'));
      });

      test('Accepts valid JPG and PNG files', () {
        final validJpg = File('${tempDir.path}/scan.jpg')..writeAsStringSync('valid_image_bytes');
        final result = OcrFileValidator.validate(validJpg.path);
        expect(result.isSuccess, isTrue);
      });
    });

    group('2. Categorized OCR Error Codes', () {
      test('Handles model unavailable failure gracefully', () async {
        final ocr = _CustomFailingOcrService(
          failureToReturn: const OcrFailure(
            'On-device text recognition model is downloading from Google Play Services.',
            code: OcrErrorCode.modelUnavailable,
          ),
        );

        final result = await ocr.extractText('dummy.jpg');
        expect(result.isFailure, isTrue);
        final ocrFailure = result as OcrFailure;
        expect(ocrFailure.code, equals(OcrErrorCode.modelUnavailable));
        expect(ocrFailure.message, contains('Google Play Services'));
      });

      test('Handles no text found in image', () async {
        final ocr = _CustomFailingOcrService(
          failureToReturn: const OcrFailure(
            'No legible text could be recognized in the image.',
            code: OcrErrorCode.noTextFound,
          ),
        );

        final result = await ocr.extractText('blank_page.jpg');
        expect(result.isFailure, isTrue);
        final ocrFailure = result as OcrFailure;
        expect(ocrFailure.code, equals(OcrErrorCode.noTextFound));
      });
    });

    group('3. OCR Extraction & Repository Persistence', () {
      test('Mock OCR extracts clinical text and repository updates status to completed', () async {
        final repo = LabReportRepositoryMock(ocrService: MockOcrService());

        final sampleFile = File('${tempDir.path}/chughtai_report.jpg')
          ..writeAsStringSync('sample image data');

        final uploadRes = await repo.uploadReport(
          filePath: sampleFile.path,
          fileName: 'chughtai_report.jpg',
        );
        expect(uploadRes.isSuccess, isTrue);
        final uploaded = (uploadRes as Success<LabReport>).data;
        expect(uploaded.status, equals(ReportStatus.uploaded));

        final processRes = await repo.processReport(uploaded.id, sampleFile.path);
        expect(processRes.isSuccess, isTrue);
        final processed = (processRes as Success<LabReport>).data;

        expect(processed.status, equals(ReportStatus.completed));
        expect(processed.hasExtractedText, isTrue);
        expect(processed.extractedText, contains('CHUGHTAI LAB'));
        expect(processed.extractedText, contains('HbA1c'));
      });

      test('Failed OCR preserves uploaded report in failed state for retry', () async {
        final failingOcr = _CustomFailingOcrService(
          failureToReturn: const OcrFailure(
            'The image could not be decoded.',
            code: OcrErrorCode.imageUnreadable,
          ),
        );
        final repo = LabReportRepositoryMock(ocrService: failingOcr);

        final sampleFile = File('${tempDir.path}/corrupt.jpg')..writeAsStringSync('bad');
        final uploadRes = await repo.uploadReport(
          filePath: sampleFile.path,
          fileName: 'corrupt.jpg',
        );
        final uploaded = (uploadRes as Success<LabReport>).data;

        final processRes = await repo.processReport(uploaded.id, sampleFile.path);
        expect(processRes.isFailure, isTrue);

        final reportRes = await repo.getReportById(uploaded.id);
        expect(reportRes.isSuccess, isTrue);
        final fetched = (reportRes as Success<LabReport>).data;
        expect(fetched.status, equals(ReportStatus.failed));
      });
    });
  });
}
