import 'dart:io';
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
    debugPrint('[OCR-DIAG] ══════════════════════════════════════════');
    debugPrint('[OCR-DIAG] extractText() called');
    debugPrint('[OCR-DIAG] filePath        : $filePath');
    debugPrint('[OCR-DIAG] isContentUri    : ${filePath.startsWith('content://')}');

    // File system diagnostics (skip for content URIs)
    if (!filePath.startsWith('content://')) {
      final f = File(filePath);
      debugPrint('[OCR-DIAG] file.existsSync: ${f.existsSync()}');
      if (f.existsSync()) {
        debugPrint('[OCR-DIAG] file.lengthSync: ${f.lengthSync()} bytes');
      }
    }

    // Extension detection
    final lastSegment = filePath.split('/').last.split('?').first;
    final ext = lastSegment.contains('.')
        ? lastSegment.split('.').last.toLowerCase()
        : '(unknown)';
    debugPrint('[OCR-DIAG] detected ext    : $ext');

    // 1. Pre-validation
    final validation = validateFile(filePath);
    debugPrint('[OCR-DIAG] validation      : ${validation is Success ? "PASS" : "FAIL — ${(validation as Failure).message}"}');
    if (validation is Failure<bool>) {
      return OcrFailure(validation.message, code: OcrErrorCode.imageUnreadable);
    }

    try {
      // 2. InputImage creation
      debugPrint('[OCR-DIAG] Creating InputImage...');
      final InputImage inputImage;
      try {
        inputImage = InputImage.fromFilePath(filePath);
        debugPrint('[OCR-DIAG] InputImage created OK');
      } catch (e, st) {
        debugPrint('[OCR-DIAG] InputImage creation FAILED: ${e.runtimeType}: $e');
        debugPrint('[OCR-DIAG] $st');
        return OcrFailure(
          'Could not load image from path. ${_classifyError(e)}',
          code: OcrErrorCode.imageUnreadable,
        );
      }

      // 3. TextRecognizer initialization (lazy)
      debugPrint('[OCR-DIAG] Getting _lazyRecognizer (script=$script)...');
      final recognizer = _lazyRecognizer;
      debugPrint('[OCR-DIAG] TextRecognizer ready: $recognizer');

      // 4. processImage
      debugPrint('[OCR-DIAG] Calling processImage()...');
      final RecognizedText recognized;
      try {
        recognized = await recognizer.processImage(inputImage);
      } catch (e, st) {
        debugPrint('[OCR-DIAG] processImage() FAILED: ${e.runtimeType}: $e');
        debugPrint('[OCR-DIAG] $st');
        return OcrFailure(_classifyError(e), code: _errorCode(e));
      }

      debugPrint('[OCR-DIAG] processImage() OK');
      debugPrint('[OCR-DIAG] blocks         : ${recognized.blocks.length}');
      debugPrint('[OCR-DIAG] total text len : ${recognized.text.length}');
      if (recognized.blocks.isNotEmpty) {
        // Safe preview: first 120 chars only
        final previewLen = recognized.text.length.clamp(0, 120);
        final preview = recognized.text.substring(0, previewLen).replaceAll('\n', ' ');
        debugPrint('[OCR-DIAG] text preview    : $preview...');
      }
      debugPrint('[OCR-DIAG] ══════════════════════════════════════════');

      final rawText = recognized.text.trim();

      if (rawText.isEmpty) {
        debugPrint('[OCR-DIAG] RESULT: noTextFound');
        return const OcrFailure(
          'No legible text could be recognized in the image. '
          'Please ensure the document is clear, well-lit, and in focus.',
          code: OcrErrorCode.noTextFound,
        );
      }

      debugPrint('[OCR-DIAG] RESULT: SUCCESS (${rawText.length} chars, ${recognized.blocks.length} blocks)');
      return Success(rawText);
    } catch (e, stack) {
      debugPrint('[OCR-DIAG] UNEXPECTED exception: ${e.runtimeType}: $e');
      debugPrint('[OCR-DIAG] $stack');
      debugPrint('[OCR-DIAG] ══════════════════════════════════════════');
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

