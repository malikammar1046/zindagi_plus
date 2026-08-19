import 'dart:io';
import 'package:zindagi_plus/core/network/result.dart';

/// Contract for Optical Character Recognition (OCR) text extraction services.
///
/// Implementations must:
/// - Validate document format and accessibility
/// - Extract raw visible characters from the document
/// - Return [Success<String>] containing the unmodified extracted text
/// - Return [Failure<String>] with safe, descriptive user-facing errors
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
  static Result<bool> validate(String filePath, {int? fileSizeBytes}) {
    if (filePath.trim().isEmpty) {
      return const Failure('File path cannot be empty.');
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      return Failure('File does not exist at path: $filePath');
    }

    final ext = filePath.split('.').last.toLowerCase();

    // Specific handling for PDF files
    if (ext == 'pdf') {
      return const Failure(
        'PDF format is not directly supported by on-device image OCR. '
        'Please upload a clear JPEG or PNG photo/scan of the report.',
      );
    }

    if (!supportedImageExtensions.contains(ext)) {
      return Failure(
        'Unsupported file type ".$ext". Please upload a JPG, JPEG, or PNG image.',
      );
    }

    final size = fileSizeBytes ?? file.lengthSync();
    if (size == 0) {
      return const Failure('The selected file is empty (0 bytes).');
    }

    if (size > maxFileSizeBytes) {
      return const Failure(
        'The selected file exceeds the 15 MB size limit for processing.',
      );
    }

    return const Success(true);
  }
}
