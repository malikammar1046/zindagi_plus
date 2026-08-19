import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/services/ocr/mock_ocr_service.dart';
import 'package:zindagi_plus/services/ocr/ocr_service.dart';

void main() {
  group('OcrFileValidator', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('ocr_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('validates existing JPG image successfully', () async {
      final sampleFile = File('${tempDir.path}/blood_report.jpg');
      await sampleFile.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10]); // JPEG magic bytes

      final result = OcrFileValidator.validate(sampleFile.path);
      expect(result, isA<Success<bool>>());
      expect((result as Success<bool>).data, isTrue);
    });

    test('validates existing PNG image successfully', () async {
      final sampleFile = File('${tempDir.path}/cbc_test.png');
      await sampleFile.writeAsBytes([0x89, 0x50, 0x4E, 0x47]); // PNG magic bytes

      final result = OcrFileValidator.validate(sampleFile.path);
      expect(result, isA<Success<bool>>());
      expect((result as Success<bool>).data, isTrue);
    });

    test('returns clear guidance for PDF files without crashing', () async {
      final sampleFile = File('${tempDir.path}/report.pdf');
      await sampleFile.writeAsBytes([0x25, 0x50, 0x44, 0x46]); // %PDF

      final result = OcrFileValidator.validate(sampleFile.path);
      expect(result, isA<Failure<bool>>());
      expect(
        (result as Failure<bool>).message,
        contains('PDF format is not directly supported by on-device image OCR'),
      );
    });

    test('rejects unsupported file formats gracefully', () async {
      final sampleFile = File('${tempDir.path}/document.docx');
      await sampleFile.writeAsString('word document content');

      final result = OcrFileValidator.validate(sampleFile.path);
      expect(result, isA<Failure<bool>>());
      expect((result as Failure<bool>).message, contains('Unsupported file type'));
    });

    test('rejects empty (0-byte) files', () async {
      final emptyFile = File('${tempDir.path}/empty.jpg');
      await emptyFile.create();

      final result = OcrFileValidator.validate(emptyFile.path);
      expect(result, isA<Failure<bool>>());
      expect((result as Failure<bool>).message, contains('empty (0 bytes)'));
    });

    test('rejects non-existent file path', () {
      final result = OcrFileValidator.validate('${tempDir.path}/non_existent_file.jpg');
      expect(result, isA<Failure<bool>>());
      expect((result as Failure<bool>).message, contains('File does not exist'));
    });
  });

  group('MockOcrService Text Extraction', () {
    test('extracts authentic raw medical text on success', () async {
      final service = MockOcrService(delayMs: 0);
      final result = await service.extractText('test_report.jpg');

      expect(result, isA<Success<String>>());
      final rawText = (result as Success<String>).data;
      expect(rawText, contains('CHUGHTAI LAB'));
      expect(rawText, contains('COMPLETE BLOOD COUNT'));
      expect(rawText, contains('Haemoglobin'));
      expect(rawText, contains('HbA1c'));
      expect(rawText, contains('LIPID PANEL'));
    });

    test('handles empty result failure simulation', () async {
      final service = MockOcrService(
        behavior: MockOcrBehavior.emptyResult,
        delayMs: 0,
      );
      final result = await service.extractText('blank_image.jpg');

      expect(result, isA<Failure<String>>());
      expect((result as Failure<String>).message, contains('No legible text'));
    });

    test('handles unsupported format failure simulation', () async {
      final service = MockOcrService(
        behavior: MockOcrBehavior.unsupportedFormat,
        delayMs: 0,
      );
      final result = await service.extractText('document.pdf');

      expect(result, isA<Failure<String>>());
      expect((result as Failure<String>).message, contains('PDF format is not directly supported'));
    });

    test('handles engine failure simulation', () async {
      final service = MockOcrService(
        behavior: MockOcrBehavior.ocrEngineFailure,
        delayMs: 0,
      );
      final result = await service.extractText('corrupted.jpg');

      expect(result, isA<Failure<String>>());
      expect((result as Failure<String>).message, contains('unexpected error'));
    });
  });
}
