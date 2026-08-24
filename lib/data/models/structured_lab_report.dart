import 'package:flutter/foundation.dart';

/// A single extracted laboratory test row from OCR.
@immutable
class LabResultRow {
  const LabResultRow({
    required this.parameterName,
    required this.result,
    this.unit,
    this.referenceRange,
    required this.originalText,
  });

  /// Parameter or test name (e.g. "Haemoglobin", "Total Cholesterol", "WBC").
  final String parameterName;

  /// Measured result string (e.g. "13.8", "210", "6,500", "Negative").
  final String result;

  /// Measurement unit if present in the document (e.g. "g/dL", "mg/dL", "/uL", "%").
  final String? unit;

  /// Reference interval or normal range if present in the document (e.g. "13.5 - 17.5", "< 200").
  final String? referenceRange;

  /// The unmodified source text line from which this row was extracted.
  final String originalText;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabResultRow &&
          runtimeType == other.runtimeType &&
          parameterName == other.parameterName &&
          result == other.result &&
          unit == other.unit &&
          referenceRange == other.referenceRange &&
          originalText == other.originalText;

  @override
  int get hashCode => Object.hash(parameterName, result, unit, referenceRange, originalText);

  @override
  String toString() =>
      'LabResultRow($parameterName: $result ${unit ?? ""} [ref: ${referenceRange ?? "N/A"}])';
}

/// A logical section of lab test rows (e.g. "Complete Blood Count", "Lipid Profile").
@immutable
class LabReportSection {
  const LabReportSection({
    required this.title,
    required this.rows,
  });

  /// Section heading text.
  final String title;

  /// List of test rows under this section.
  final List<LabResultRow> rows;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabReportSection &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          listEquals(rows, other.rows);

  @override
  int get hashCode => Object.hash(title, Object.hashAll(rows));

  @override
  String toString() => 'LabReportSection($title, ${rows.length} rows)';
}

/// Complete structured layout representation of an extracted lab report.
@immutable
class StructuredLabReport {
  const StructuredLabReport({
    required this.sections,
    this.unclassifiedLines = const [],
    this.rawText = '',
  });

  /// Categorized or grouped test sections.
  final List<LabReportSection> sections;

  /// Document header lines, patient info, or other detected text.
  final List<String> unclassifiedLines;

  /// Complete original raw OCR text.
  final String rawText;

  /// Total number of structured test rows across all sections.
  int get totalRowCount =>
      sections.fold(0, (sum, section) => sum + section.rows.length);

  /// True if at least one structured test row was recognized.
  bool get hasStructuredData => totalRowCount > 0;
}
