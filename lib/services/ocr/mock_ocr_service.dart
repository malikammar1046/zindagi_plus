import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/services/ocr/ocr_service.dart';

/// Configurable mock OCR behavior for unit testing and offline development.
enum MockOcrBehavior {
  success,
  emptyResult,
  unsupportedFormat,
  invalidFile,
  ocrEngineFailure,
}

/// Deterministic mock implementation of [OcrService].
///
/// Returns authentic medical laboratory diagnostic report text extracted
/// from blood tests, lipid panels, and metabolic panels.
class MockOcrService implements OcrService {
  MockOcrService({
    this.behavior = MockOcrBehavior.success,
    this.delayMs = 400,
    this.customText,
  });

  MockOcrBehavior behavior;
  final int delayMs;
  final String? customText;

  static const String defaultSampleMedicalReportText = '''
============================================================
              CHUGHTAI LAB - DIAGNOSTIC REPORT
============================================================
Patient Name: AMMAR MALIK            Age / Gender: 28 Y / M
Patient MRN:  MRN-849201             Date Collected: 15-Aug-2026
Referred By:  Dr. Tariq Mahmood      Specimen: Whole Blood (EDTA)
Lab Reg No:   CL-2026-081944         Status: Final

------------------------------------------------------------
TEST NAME                  RESULT     UNIT       REFERENCE
------------------------------------------------------------
COMPLETE BLOOD COUNT (CBC)
Haemoglobin (Hb)           14.2       g/dL       13.5 - 17.5
Total Leukocyte Count      6,500      /uL        4,000 - 11,000
Platelet Count             245,000    /uL        150,000 - 450,000
Red Blood Cell (RBC)       4.85       mill/uL    4.50 - 5.90
Hematocrit (PCV)           42.5       %          40.0 - 50.0
Mean Corpuscular Volume    87.6       fL         80.0 - 96.0

LIPID PANEL
Total Cholesterol          210        mg/dL      < 200 (Desirable)
Triglycerides              148        mg/dL      < 150 (Normal)
HDL Cholesterol            42         mg/dL      > 40 (Healthy)
LDL Cholesterol            138        mg/dL      < 100 (Optimal)

GLYCEMIC CONTROL & METABOLIC
HbA1c (Glycated Hb)        6.8        %          < 5.7 (Normal)
Fasting Blood Glucose      108        mg/dL      70 - 99
Serum Creatinine           0.92       mg/dL      0.70 - 1.20
Vitamin D (25-OH)          18.4       ng/mL      20.0 - 50.0

============================================================
                   END OF REPORT
============================================================''';

  @override
  Result<bool> validateFile(String filePath, {int? fileSizeBytes}) {
    if (behavior == MockOcrBehavior.unsupportedFormat || filePath.toLowerCase().endsWith('.pdf')) {
      return const Failure(
        'PDF format is not directly supported by on-device image OCR. '
        'Please upload a clear JPEG or PNG photo/scan of the report.',
      );
    }

    if (behavior == MockOcrBehavior.invalidFile) {
      return const Failure('The document could not be read or the file is corrupted.');
    }

    return const Success(true);
  }

  @override
  Future<Result<String>> extractText(String filePath) async {
    if (delayMs > 0) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }

    final validation = validateFile(filePath);
    if (validation is Failure<bool>) {
      return Failure(validation.message);
    }

    return switch (behavior) {
      MockOcrBehavior.success => Success(customText ?? defaultSampleMedicalReportText),
      MockOcrBehavior.emptyResult => const Failure(
          'No legible text could be recognized in the image. Please ensure the document is clear, well-lit, and in focus.',
        ),
      MockOcrBehavior.unsupportedFormat => const Failure(
          'Unsupported file format. Please upload a JPG, JPEG, or PNG image of your report.',
        ),
      MockOcrBehavior.invalidFile => const Failure(
          'The document could not be read. Please upload a clear image of a medical lab report.',
        ),
      MockOcrBehavior.ocrEngineFailure => const Failure(
          'OCR text recognition encountered an unexpected error. Please try again.',
        ),
    };
  }
}
