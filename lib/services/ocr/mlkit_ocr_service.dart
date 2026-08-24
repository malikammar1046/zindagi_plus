import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/services/ocr/ocr_layout_reconstructor.dart';
import 'package:zindagi_plus/services/ocr/ocr_service.dart';

/// Production on-device OCR engine using Google ML Kit Text Recognition.
///
/// Features:
/// - 100% local, on-device processing on Android & iOS.
/// - Zero external cloud API calls: medical report images never leave the device.
/// - High accuracy on printed diagnostic reports and laboratory forms.
///
/// The [TextRecognizer] is initialised **lazily** on the first [extractText]
/// call so that constructing this service at startup (via Riverpod provider
/// graph) does not trigger the blocking ML Kit model load.
class MlKitOcrService implements OcrService {
  MlKitOcrService({
    this.script = TextRecognitionScript.latin,
  });

  /// Recognition script; stored so the recognizer can be created on demand.
  final TextRecognitionScript script;

  /// Lazily created — null until the first call to [extractText].
  TextRecognizer? _recognizer;

  /// Returns the shared [TextRecognizer], creating it on first access.
  TextRecognizer get _lazyRecognizer =>
      _recognizer ??= TextRecognizer(script: script);

  @override
  Result<bool> validateFile(String filePath, {int? fileSizeBytes}) {
    return OcrFileValidator.validate(filePath, fileSizeBytes: fileSizeBytes);
  }

  @override
  Future<Result<String>> extractText(String filePath) async {
    final platformName = defaultTargetPlatform.name;
    final isContentUri = filePath.startsWith('content://');
    bool fileExists = false;
    int fileSizeBytes = 0;

    if (!isContentUri) {
      final f = File(filePath);
      fileExists = f.existsSync();
      if (fileExists) {
        fileSizeBytes = f.lengthSync();
      }
    }

    final lastSegment = filePath.split('/').last.split('?').first;
    final ext = lastSegment.contains('.')
        ? lastSegment.split('.').last.toLowerCase()
        : '(unknown)';

    debugPrint('════════════════════════════════════════════════════════════');
    debugPrint('[OCR] Service: MlKitOcrService');
    debugPrint('[OCR] Platform: $platformName');
    debugPrint('[OCR] File: $filePath');
    debugPrint('[OCR] Exists: $fileExists');
    debugPrint('[OCR] Size: $fileSizeBytes bytes');
    debugPrint('[OCR] Extension: $ext');
    debugPrint('[OCR] Starting Google ML Kit text recognition...');
    debugPrint('════════════════════════════════════════════════════════════');

    // 1. Pre-validation
    final validation = validateFile(filePath, fileSizeBytes: fileSizeBytes > 0 ? fileSizeBytes : null);
    if (validation is Failure<bool>) {
      debugPrint('[OCR] Pre-validation FAILED: ${validation.message}');
      return OcrFailure(validation.message, code: OcrErrorCode.imageUnreadable);
    }

    try {
      // 2. InputImage creation
      final InputImage inputImage;
      try {
        inputImage = InputImage.fromFilePath(filePath);
      } catch (e, st) {
        debugPrint('[OCR] InputImage creation FAILED: $e\n$st');
        return OcrFailure(
          'Could not load image file into ML Kit. ${_classifyError(e)}',
          code: OcrErrorCode.imageUnreadable,
        );
      }

      // 3. TextRecognizer execution
      final recognizer = _lazyRecognizer;
      final RecognizedText recognized;
      try {
        recognized = await recognizer.processImage(inputImage);
      } catch (e, st) {
        debugPrint('[OCR] ML Kit processImage FAILED: $e\n$st');
        return OcrFailure(_classifyError(e), code: _errorCode(e));
      }

      // Collect all TextLines from all TextBlocks
      final allLines = <TextLine>[];
      for (final block in recognized.blocks) {
        allLines.addAll(block.lines);
      }

      // Reconstruct 2D visual layout using bounding-box spatial coordinates
      final String rawText;
      if (allLines.isNotEmpty) {
        final spatiallyOrdered = OcrLayoutReconstructor.reconstructFromMlKitLines(allLines);
        rawText = spatiallyOrdered.isNotEmpty ? spatiallyOrdered : recognized.text.trim();
      } else {
        rawText = recognized.text.trim();
      }

      debugPrint('════════════════════════════════════════════════════════════');
      debugPrint('[OCR] Recognition completed');
      debugPrint('[OCR] Character count: ${rawText.length}');
      debugPrint('[OCR] Blocks count: ${recognized.blocks.length}');
      debugPrint('[OCR] Lines count: ${allLines.length}');
      debugPrint('[OCR] Spatially Reconstructed Raw text:');
      debugPrint('----------------------------------------');
      debugPrint(rawText);
      debugPrint('----------------------------------------');
      debugPrint('════════════════════════════════════════════════════════════');

      if (rawText.isEmpty) {
        debugPrint('[OCR] RESULT: No legible text recognized in image.');
        return const OcrFailure(
          'No legible text could be recognized in the image. '
          'Please ensure the document is clear, well-lit, and in focus.',
          code: OcrErrorCode.noTextFound,
        );
      }

      return Success(rawText);
    } catch (e, stack) {
      debugPrint('[OCR] Unexpected exception during recognition: $e\n$stack');
      return OcrFailure(_classifyError(e), code: _errorCode(e));
    }
  }

  /// Maps an exception to a user-facing error message.
  String _classifyError(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('model') || s.contains('waiting') ||
        s.contains('download') || s.contains('unavailable')) {
      return 'On-device text recognition model is downloading from Google Play Services. '
          'Please ensure an active internet connection and try again in a few seconds.';
    }
    if (s.contains('format') || s.contains('decode') ||
        s.contains('corrupt') || s.contains('invalid image')) {
      return 'The image could not be decoded. Please upload a clear JPG or PNG photo.';
    }
    if (s.contains('memory') || s.contains('oom') ||
        s.contains('out of memory')) {
      return 'The image is too large for device memory. Please upload a resized or cropped photo.';
    }
    if (s.contains('permission') || s.contains('denied')) {
      return 'Permission denied. Please grant storage/media access and try again.';
    }
    return 'On-device text recognition could not process this document. '
        'Please ensure the photo is clear, well-lit, and try again.';
  }

  /// Maps an exception to an [OcrErrorCode].
  OcrErrorCode _errorCode(Object e) {
    final s = e.toString().toLowerCase();
    if (s.contains('model') || s.contains('waiting') || s.contains('download')) {
      return OcrErrorCode.modelUnavailable;
    }
    if (s.contains('format') || s.contains('decode') || s.contains('corrupt')) {
      return OcrErrorCode.imageUnreadable;
    }
    if (s.contains('memory') || s.contains('oom')) {
      return OcrErrorCode.imageTooLarge;
    }
    return OcrErrorCode.processingFailed;
  }

  /// Releases underlying native recognizer resources.
  ///
  /// Safe to call even if [extractText] was never invoked (recognizer was
  /// never created).
  Future<void> dispose() async {
    await _recognizer?.close();
  }
}

