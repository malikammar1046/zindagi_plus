import 'package:flutter/foundation.dart';

/// A single parsed clinical measurement from OCR text.
@immutable
class ParsedBiomarker {
  const ParsedBiomarker({
    required this.name,
    required this.value,
    required this.unit,
    this.rawMatch = '',
  });

  /// Canonical parameter name (e.g. "Hemoglobin").
  final String name;

  /// Numeric measurement value (e.g. 13.2).
  final double value;

  /// Unit string as found in OCR text (e.g. "g/dL").
  final String unit;

  /// The original substring matched from the OCR text.
  final String rawMatch;

  @override
  String toString() => 'ParsedBiomarker($name=$value $unit)';
}

/// Deterministic regex-based parser that extracts common laboratory parameters
/// from raw OCR text.
///
/// Design:
/// - Case-insensitive matching.
/// - Tolerates multiple spaces, colon/dash/equals separators, and Unicode variants.
/// - Does NOT perform medical interpretation, reference-range evaluation, or
///   any diagnostic reasoning — it only extracts numeric values and units.
/// - Returns an empty list if no known parameters are found.
class LabReportParser {
  LabReportParser._();

  // ── Parameter definitions ──────────────────────────────────────────────────

  /// Each entry: (canonical name, aliases, regex alternation string).
  static final _params = <_ParamDef>[
    _ParamDef(
      name: 'Hemoglobin',
      aliases: r'(?:hemoglobin|haemoglobin|hgb?|hb)',
    ),
    _ParamDef(
      name: 'WBC',
      aliases: r'(?:wbc|white blood cells?|total leukocytes?|tlc|leukocytes?)',
    ),
    _ParamDef(
      name: 'RBC',
      aliases: r'(?:rbc|red blood cells?|erythrocytes?)',
    ),
    _ParamDef(
      name: 'Platelets',
      aliases: r'(?:platelets?|platelet count|plt)',
    ),
    _ParamDef(
      name: 'Hematocrit',
      aliases: r'(?:hematocrit|haematocrit|hct|pcv)',
    ),
    _ParamDef(
      name: 'Glucose',
      aliases: r'(?:(?:fasting\s+)?(?:blood\s+)?glucose|fbs|rbs|random\s+blood\s+sugar|blood\s+sugar)',
    ),
    _ParamDef(
      name: 'HbA1c',
      aliases: r'(?:hba1c|hb\s*a1c|glycated\s+hb|glyco?h?aemoglobin|a1c)',
    ),
    _ParamDef(
      name: 'Total Cholesterol',
      aliases: r'(?:total\s+cholesterol|cholesterol(?!\s*(?:hdl|ldl)))',
    ),
    _ParamDef(
      name: 'HDL',
      aliases: r'(?:hdl(?:\s+cholesterol)?|high[-\s]density\s+lipoprotein)',
    ),
    _ParamDef(
      name: 'LDL',
      aliases: r'(?:ldl(?:\s+cholesterol)?|low[-\s]density\s+lipoprotein)',
    ),
    _ParamDef(
      name: 'Triglycerides',
      aliases: r'(?:triglycerides?|tg(?!\w))',
    ),
    _ParamDef(
      name: 'Creatinine',
      aliases: r'(?:(?:serum\s+)?creatinine)',
    ),
    _ParamDef(
      name: 'Urea',
      aliases: r'(?:(?:blood\s+)?urea|bun)',
    ),
    _ParamDef(
      name: 'ALT',
      aliases: r'(?:alt(?!\w)|sgpt|alanine\s+(?:amino)?transferase)',
    ),
    _ParamDef(
      name: 'AST',
      aliases: r'(?:ast(?!\w)|sgot|aspartate\s+(?:amino)?transferase)',
    ),
    _ParamDef(
      name: 'TSH',
      aliases: r'(?:tsh|thyroid\s+stimulating\s+hormone|thyrotropin)',
    ),
    _ParamDef(
      name: 'Vitamin D',
      aliases: r'(?:vitamin\s+d(?:\d+)?|vit\.?\s*d|25[-\s]oh\s+vitamin\s+d|25-hydroxyvitamin\s+d)',
    ),
    _ParamDef(
      name: 'Vitamin B12',
      aliases: r'(?:vitamin\s+b[-\s]?12|vit\.?\s*b[-\s]?12|cobalamin|cyanocobalamin)',
    ),
  ];

  // ── Public API ─────────────────────────────────────────────────────────────

  /// Parses [ocrText] and returns a list of extracted [ParsedBiomarker]s.
  ///
  /// Returns an empty list if no recognizable parameters are found.
  static List<ParsedBiomarker> parse(String ocrText) {
    if (ocrText.trim().isEmpty) return [];

    final results = <ParsedBiomarker>[];
    final seen = <String>{};

    for (final param in _params) {
      final match = _tryMatch(param, ocrText);
      if (match != null && !seen.contains(param.name)) {
        results.add(match);
        seen.add(param.name);
      }
    }

    debugPrint('[BiomarkerParser] Extracted ${results.length} parameter(s) from ${ocrText.length}-char OCR text');
    return results;
  }

  // ── Internal ───────────────────────────────────────────────────────────────

  static ParsedBiomarker? _tryMatch(_ParamDef param, String text) {
    final pattern = RegExp(
      r'(?<![a-zA-Z])' +
          param.aliases +
          r'\s*[:\-=]?\s*([\d,]+\.?\d*)\s*([a-zA-Z/%µu\xb5]+(?:[/\xb7][a-zA-Z]+)?)',
      caseSensitive: false,
      multiLine: true,
    );

    final match = pattern.firstMatch(text);
    if (match == null) return null;

    final rawValueStr = match.group(1)?.replaceAll(',', '') ?? '';
    final unit = match.group(2) ?? '';
    final value = double.tryParse(rawValueStr);
    if (value == null) return null;

    return ParsedBiomarker(
      name: param.name,
      value: value,
      unit: unit,
      rawMatch: match.group(0) ?? '',
    );
  }
}

// ── Internal helper ────────────────────────────────────────────────────────────

class _ParamDef {
  const _ParamDef({required this.name, required this.aliases});
  final String name;
  final String aliases;
}
