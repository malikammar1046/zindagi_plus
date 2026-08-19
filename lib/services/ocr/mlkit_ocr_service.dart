import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/services/ocr/ocr_service.dart';

/// Production on-device OCR engine using Google ML Kit Text Recognition.
///
/// Features:
/// - 100% local, on-device processing on Android & iOS.
/// - Zero external cloud API calls: medical report images never leave the device.
/// - High accuracy on printed diagnostic reports and laboratory forms.
/// - Fast sub-second inference.
class MlKitOcrService implements OcrService {
  MlKitOcrService({
    TextRecognitionScript script = TextRecognitionScript.latin,
  }) : _recognizer = TextRecognizer(script: script);

  final TextRecognizer _recognizer;

  @override
  Result<bool> validateFile(String filePath, {int? fileSizeBytes}) {
    return OcrFileValidator.validate(filePath, fileSizeBytes: fileSizeBytes);
  }

  @override
  Future<Result<String>> extractText(String filePath) async {
    // 1. File and format pre-validation
    final validation = validateFile(filePath);
    if (validation is Failure<bool>) {
      debugPrint('[OCR] File validation failed: ${validation.message}');
      return Failure(validation.message);
    }

    try {
      // 2. Load image as InputImage
      final inputImage = InputImage.fromFilePath(filePath);

      // 3. Perform on-device ML Kit recognition
      final RecognizedText recognized = await _recognizer.processImage(inputImage);

      final rawText = recognized.text.trim();

      // 4. Validate non-empty extraction
      if (rawText.isEmpty) {
        debugPrint('[OCR] ML Kit extraction failed: No legible text recognized.');
        return const Failure(
          'No legible text could be recognized in the image. '
          'Please ensure the document is clear, well-lit, and in focus.',
        );
      }

      return Success(rawText);
    } catch (e, stack) {
      debugPrint('[OCR] ML Kit extraction failed with exception: $e');
      debugPrint('$stack');
      return const Failure(
        'An error occurred during on-device text recognition. '
        'Please try again with a clear photo or scan.',
      );
    }
  }

  /// Releases underlying native recognizer resources.
  Future<void> dispose() async {
    await _recognizer.close();
  }
}
