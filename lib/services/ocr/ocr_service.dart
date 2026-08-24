import 'dart:io';
import 'package:zindagi_plus/core/network/result.dart';

/// Categorized, safe OCR errors for user-facing diagnosis without leaking PHI.
enum OcrErrorCode {
  modelUnavailable,
  imageUnreadable,
  imageTooLarge,
  emptyFile,
  fileNotFound,
  unsupportedFormat,
  noTextFound,
  processingFailed,
}

/// Specialized failure type for OCR operations carrying a machine-readable [code].
final class OcrFailure extends Failure<String> {
  const OcrFailure(super.message, {required this.code});

  final OcrErrorCode code;
}

/// Contract for Optical Character Recognition (OCR) text extraction services.
///
/// Implementations must:
/// - Validate document format and accessibility
/// - Extract raw visible characters from the document
/// - Return [Success<String>] containing the unmodified extracted text
/// - Return [OcrFailure] with safe, descriptive user-facing errors
///
/// NOTE: The OCR service answers exclusively "What text exists in this document?".
/// It does NOT perform medical interpretation, value derivation, or abnormality detection.
abstract class OcrService {
  /// Extracts raw clinical text from a local document image at [filePath].
  Future<Result<String>> extractText(String filePath);

  /// Validates whether the file at [filePath] is suitable for OCR processing.
  Result<bool> validateFile(String filePath, {int? fileSizeBytes});
}

/// Common validation helper for OCR implementations.
class OcrFileValidator {
  const OcrFileValidator._();

  /// Supported image extensions for on-device OCR.
  static const supportedImageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'bmp'};

  /// Max file size allowed for on-device processing (15 MB).
  static const maxFileSizeBytes = 15 * 1024 * 1024;

  /// Validates file existence, format, and size.
  ///
  /// NOTE: Android content URIs (`content://...`) cannot be validated via
  /// [File.existsSync()] — they are only accessible through the Android
  /// content resolver. We skip filesystem existence checks for these paths
  /// and let ML Kit's [InputImage.fromFilePath] handle them natively.
  static Result<bool> validate(String filePath, {int? fileSizeBytes}) {
    if (filePath.trim().isEmpty) {
      return const Failure('File path cannot be empty.');
    }

    // Content URIs are valid on Android — skip filesystem check entirely.
    final isContentUri = filePath.startsWith('content://');

    if (!isContentUri) {
      final file = File(filePath);
      if (!file.existsSync()) {
        return Failure('File does not exist at path: $filePath');
      }
    }

    // Determine extension: content URIs may embed a filename in the last path segment.
    final lastSegment = filePath.split('/').last.split('?').first;
    final ext = lastSegment.contains('.')
        ? lastSegment.split('.').last.toLowerCase()
        : filePath.split('.').last.toLowerCase();

    // Specific handling for PDF files
    if (ext == 'pdf') {
      return const Failure(
        'PDF format is not directly supported by on-device image OCR. '
        'Please upload a clear JPEG or PNG photo/scan of the report.',
      );
    }

    // For content URIs without a determinable extension, allow through.
    // ML Kit will attempt to decode the image and report its own error if needed.
    if (!isContentUri && !supportedImageExtensions.contains(ext)) {
      return Failure(
        'Unsupported file type ".$ext". Please upload a JPG, JPEG, or PNG image.',
      );
    }

    // Skip size check for content URIs — cannot stat via dart:io.
    if (!isContentUri) {
      final int size;
      if (fileSizeBytes != null) {
        size = fileSizeBytes;
      } else {
        try {
          size = File(filePath).lengthSync();
        } catch (_) {
          return const Success(true); // Can't determine size — allow through.
        }
      }
      if (size == 0) {
        return const Failure('The selected file is empty (0 bytes).');
      }
      if (size > maxFileSizeBytes) {
        return const Failure(
          'The selected file exceeds the 15 MB size limit for processing.',
        );
      }
    }

    return const Success(true);
  }
}
