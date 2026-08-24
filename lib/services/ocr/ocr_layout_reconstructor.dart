import 'dart:math' as math;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:zindagi_plus/data/models/structured_lab_report.dart';

/// Reconstructs 2D visual layout from Google ML Kit OCR bounding boxes and parses
/// rows, columns, and sections into a structured, readable format.
///
/// Principles:
/// - 100% faithful to the actual image text.
/// - Never infers or invents missing medical values or reference ranges.
/// - Never performs medical interpretation (no High/Low/Normal tags).
/// - Preserves the unmodified raw OCR text for auditability.
class OcrLayoutReconstructor {
  const OcrLayoutReconstructor._();

  // ── 1. Spatial 2D Row Reconstruction from ML Kit Bounding Boxes ───────────

  /// Reconstructs visual 2D reading order by grouping lines that share the same
  /// vertical coordinates (Y-axis) into horizontal visual rows, then sorting
  /// left-to-right (X-axis).
  static String reconstructFromMlKitLines(List<TextLine> lines) {
    if (lines.isEmpty) return '';
    if (lines.length == 1) return lines.first.text.trim();

    // 1. Calculate median line height for adaptive vertical clustering
    final heights = lines.map((l) => l.boundingBox.height).toList()..sort();
    final medianHeight = heights[heights.length ~/ 2].clamp(8.0, 100.0);

    // 2. Sort lines primarily by vertical center Y
    final sortedLines = List<TextLine>.from(lines)
      ..sort((a, b) => a.boundingBox.center.dy.compareTo(b.boundingBox.center.dy));

    // 3. Cluster lines into horizontal visual rows
    final visualRows = <List<TextLine>>[];

    for (final line in sortedLines) {
      bool addedToCluster = false;
      final lineBox = line.boundingBox;

      for (final row in visualRows) {
        final rowFirstBox = row.first.boundingBox;
        final verticalDiff = (lineBox.center.dy - rowFirstBox.center.dy).abs();
        final verticalOverlap = math.min(lineBox.bottom, rowFirstBox.bottom) -
            math.max(lineBox.top, rowFirstBox.top);

        // Check if line belongs to this row cluster
        if (verticalOverlap > 0.35 * medianHeight || verticalDiff < 0.45 * medianHeight) {
          row.add(line);
          addedToCluster = true;
          break;
        }
      }

      if (!addedToCluster) {
        visualRows.add([line]);
      }
    }

    // 4. Sort each row cluster left-to-right by X coordinate and assemble text
    final reconstructedLines = <String>[];

    for (final row in visualRows) {
      row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
      final rowText = row.map((l) => l.text.trim()).where((t) => t.isNotEmpty).join('    ');
      if (rowText.isNotEmpty) {
        reconstructedLines.add(rowText);
      }
    }

    return reconstructedLines.join('\n');
  }

  // ── 2. Structured Section & Row Parser ─────────────────────────────────────

  /// Section heading keywords commonly found in diagnostic lab reports.
  static final _sectionKeywords = RegExp(
    r'\b(?:COMPLETE\s+BLOOD\s+COUNT|CBC|HAEMATOLOGY|HEMATOLOGY|'
    r'LIPID\s+(?:PROFILE|PANEL)|LIVER\s+FUNCTION\s+TESTS?|LFT|HEPATIC\s+PANEL|'
    r'RENAL\s+FUNCTION\s+TESTS?|RFT|KIDNEY\s+FUNCTION|'
    r'GLYC[AO]EMIC\s+(?:PROFILE|CONTROL)|DIABETIC\s+PROFILE|METABOLIC\s+PANEL|'
    r'URINE\s+(?:ANALYSIS|EXAMINATION|RE)|URINALYSIS|'
    r'THYROID\s+(?:PROFILE|PANEL)|TFT|SERUM\s+ELECTROLYTES|ELECTROLYTES|'
    r'CARDIAC\s+(?:MARKERS|PROFILE)|COAGULATION\s+PROFILE|BLOOD\s+SUGAR)\b',
    caseSensitive: false,
  );

  /// Table header tokens to ignore (not data rows).
  static final _tableHeaderPattern = RegExp(
    r'^(?:[-=_*#\s]{3,}|'
    r'TEST\s+NAME.*RESULT|'
    r'PARAMETER.*VALUE|'
    r'INVESTIGATION.*RESULT|'
    r'TEST\s+DESCRIPTION.*UNIT|'
    r'NAME\s+RESULT\s+UNIT)$',
    caseSensitive: false,
  );

  /// Metadata prefixes to route to unclassified lines (not test rows).
  static final _metadataPrefixPattern = RegExp(
    r'^(?:Patient\s+Name|Name|Age|Gender|Sex|MRN|Reg(?:\s+No)?|Date|'
    r'Referred\s+By|Doctor|Specimen|Sample|Status|Lab\s+Name|Phone|Address|'
    r'Hospital|Consultant|Collected|Reported|Verified|Printed|END\s+OF\s+REPORT)[\s:]',
    caseSensitive: false,
  );

  /// Common laboratory units.
  static const _commonUnits = [
    'g/dL',
    'mg/dL',
    'ng/mL',
    'pg/mL',
    'ug/dL',
    'mcg/dL',
    '/uL',
    'cells/uL',
    'mill/uL',
    'mil/uL',
    '10^3/uL',
    '10^6/uL',
    '10*3/uL',
    '10*6/uL',
    'fL',
    'pg',
    '%',
    'mmol/L',
    'mEq/L',
    'U/L',
    'IU/L',
    'IU/mL',
    'uIU/mL',
    'mL/min',
    'mm/hr',
    'sec',
    'seconds',
    'ratio',
  ];

  /// Parses raw OCR text into structured sections and rows.
  static StructuredLabReport parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return const StructuredLabReport(sections: []);
    }

    final rawLines = rawText.split('\n');
    final sections = <LabReportSection>[];
    final unclassified = <String>[];

    String currentSectionTitle = 'Extracted Lab Results';
    List<LabResultRow> currentSectionRows = [];

    for (final rawLine in rawLines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // 1. Check for decorative lines or table header rows -> skip
      if (_tableHeaderPattern.hasMatch(line) || RegExp(r'^[-=_*#\s]{3,}$').hasMatch(line)) {
        continue;
      }

      // 2. Check for Section Heading
      if (_isSectionHeading(line)) {
        if (currentSectionRows.isNotEmpty) {
          sections.add(LabReportSection(
            title: currentSectionTitle,
            rows: List.unmodifiable(currentSectionRows),
          ));
          currentSectionRows = [];
        }
        currentSectionTitle = _cleanSectionTitle(line);
        continue;
      }

      // 3. Check for Metadata line
      if (_metadataPrefixPattern.hasMatch(line)) {
        unclassified.add(line);
        continue;
      }

      // 4. Try parsing as a LabResultRow
      final row = _parseRow(line);
      if (row != null) {
        currentSectionRows.add(row);
      } else {
        unclassified.add(line);
      }
    }

    // Flush last section
    if (currentSectionRows.isNotEmpty) {
      sections.add(LabReportSection(
        title: currentSectionTitle,
        rows: List.unmodifiable(currentSectionRows),
      ));
    }

    return StructuredLabReport(
      sections: List.unmodifiable(sections),
      unclassifiedLines: List.unmodifiable(unclassified),
      rawText: rawText,
    );
  }

  static bool _isSectionHeading(String line) {
    if (line.length > 60) return false;

    // If line has a valid measurement result value and unit or multi-space table columns, it is a data row, NOT a section heading!
    if (RegExp(r'\d+(?:\.\d+)?\s*(?:g/dL|mg/dL|%|/uL|mmol/L|mEq/L|ng/mL|pg/mL|ug/dL|cells/uL|mill/uL)', caseSensitive: false).hasMatch(line)) {
      return false;
    }

    // Must not end with a number if it's a section title
    if (RegExp(r'\d+$').hasMatch(line.trim())) {
      return false;
    }

    // Known medical section keyword
    if (_sectionKeywords.hasMatch(line)) {
      return !RegExp(r'\d+').hasMatch(line);
    }

    // Uppercase header without numbers or colons
    if (line == line.toUpperCase() &&
        line.length >= 4 &&
        !line.contains(':') &&
        !RegExp(r'\d').hasMatch(line) &&
        (line.contains('PANEL') ||
            line.contains('PROFILE') ||
            line.contains('COUNT') ||
            line.contains('TEST') ||
            line.contains('EXAMINATION'))) {
      return true;
    }
    return false;
  }

  static String _cleanSectionTitle(String raw) {
    return raw
        .replaceAll(RegExp(r'^[-=_*#\s]+|[-=_*#\s]+$'), '')
        .trim();
  }

  /// Parses a single line into a [LabResultRow] if it contains a parameter name and measured result.
  static LabResultRow? _parseRow(String line) {
    // Look for test results matching standard lab row layout:
    // [Parameter Name]   [Result Value]   [Unit (opt)]   [Reference (opt)]
    
    // Split tokens by 2+ whitespace or tab
    final parts = line.split(RegExp(r'\s{2,}|\t+')).map((p) => p.trim()).where((p) => p.isNotEmpty).toList();

    if (parts.length >= 2) {
      final name = parts[0];
      // Parameter name should not look like pure numeric or metadata
      if (!_isInvalidParameterName(name)) {
        final result = parts[1];
        if (_isValidResultValue(result)) {
          String? unit;
          String? refRange;

          if (parts.length >= 3) {
            // Check if parts[2] is a unit or a reference range
            if (_isUnit(parts[2])) {
              unit = parts[2];
              if (parts.length >= 4) {
                refRange = parts.sublist(3).join(' ');
              }
            } else if (_isReferenceRange(parts[2])) {
              refRange = parts.sublist(2).join(' ');
            } else {
              // Remaining parts
              unit = parts[2];
              if (parts.length >= 4) {
                refRange = parts.sublist(3).join(' ');
              }
            }
          }

          return LabResultRow(
            parameterName: name,
            result: result,
            unit: unit,
            referenceRange: refRange,
            originalText: line,
          );
        }
      }
    }

    // Fallback: Space-separated regex pattern for single-spaced rows:
    // e.g. "Haemoglobin 13.8 g/dL 13.0 - 17.0"
    // e.g. "Fasting Blood Glucose 108 mg/dL 70-99"
    final regex = RegExp(
      r'^([A-Za-z0-9\s\(\)\/_\-\.\+]+?)\s+([<>]?\s*\d+(?:[\.,]\d+)?|[A-Za-z]+)\s*(?:([A-Za-z%*\/^0-9]+(?:\/[A-Za-z0-9]+)?))?\s*(?:([<>]?\s*\d+(?:[\.,]\d+)?\s*(?:-|to)\s*\d+(?:[\.,]\d+)?|<[\s\d\.,]+|>[\s\d\.,]+|Up to\s+\d+))?$',
    );

    final match = regex.firstMatch(line);
    if (match != null) {
      final name = match.group(1)?.trim() ?? '';
      final val = match.group(2)?.trim() ?? '';
      final u = match.group(3)?.trim();
      final r = match.group(4)?.trim();

      if (name.isNotEmpty && val.isNotEmpty && !_isInvalidParameterName(name) && _isValidResultValue(val)) {
        return LabResultRow(
          parameterName: name,
          result: val,
          unit: (u != null && u.isNotEmpty && _isUnit(u)) ? u : null,
          referenceRange: (r != null && r.isNotEmpty) ? r : null,
          originalText: line,
        );
      }
    }

    return null;
  }

  static bool _isInvalidParameterName(String name) {
    if (name.length < 2) return true;
    if (RegExp(r'^\d+$').hasMatch(name)) return true;
    if (_metadataPrefixPattern.hasMatch(name)) return true;
    return false;
  }

  static bool _isValidResultValue(String val) {
    // Numbers e.g. 13.8, 210, 6,500, <0.01, >1000
    if (RegExp(r'^[<>]?\s*\d+(?:[\.,]\d+)?$').hasMatch(val)) return true;
    // Qualitative results e.g. Positive, Negative, Non-Reactive, Reactive, Nil, Trace
    if (RegExp(r'^(?:Positive|Negative|Reactive|Non-Reactive|Nil|Trace|Normal|Present|Absent)$', caseSensitive: false).hasMatch(val)) {
      return true;
    }
    return false;
  }

  static bool _isUnit(String token) {
    final lower = token.toLowerCase();
    for (final u in _commonUnits) {
      if (lower == u.toLowerCase() || lower.startsWith(u.toLowerCase())) {
        return true;
      }
    }
    return RegExp(r'^(?:g\/dL|mg\/dL|ng\/mL|pg\/mL|ug\/dL|\/uL|fL|pg|%|mmol\/L|mEq\/L|U\/L|IU\/L|mm\/hr)$', caseSensitive: false).hasMatch(token);
  }

  static bool _isReferenceRange(String token) {
    return RegExp(r'^(?:[<>]?\s*\d+(?:[\.,]\d+)?\s*(?:-|to)\s*\d+(?:[\.,]\d+)?|[<>]\s*\d+(?:[\.,]\d+)?|Up to\s+\d+)$', caseSensitive: false).hasMatch(token);
  }
}
