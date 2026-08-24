import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/providers/repository_providers.dart';
import 'package:zindagi_plus/services/ocr/mlkit_ocr_service.dart';
import 'package:zindagi_plus/services/ocr/ocr_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OCR Provider Selection & Architecture Tests', () {
    test('ocrServiceProvider returns MlKitOcrService on Android mobile platform', () {
      final container = ProviderContainer();
      final ocrService = container.read(ocrServiceProvider);

      // On Android mobile runtime, ocrServiceProvider resolves directly to MlKitOcrService
      expect(ocrService, isA<MlKitOcrService>());
      container.dispose();
    });

    test('MlKitOcrService instantiates cleanly with Latin script', () {
      final mlkitService = MlKitOcrService();
      expect(mlkitService, isA<OcrService>());
      expect(mlkitService, isA<MlKitOcrService>());
    });

    test('MlKitOcrService validates image extensions correctly without mock data', () {
      final mlkitService = MlKitOcrService();
      final validation = mlkitService.validateFile('report.pdf');
      expect(validation.isFailure, isTrue);

      final emptyValidation = mlkitService.validateFile('');
      expect(emptyValidation.isFailure, isTrue);
    });
  });
}
