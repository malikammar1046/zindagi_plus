import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/data/models/structured_lab_report.dart';
import 'package:zindagi_plus/services/ocr/ocr_layout_reconstructor.dart';

void main() {
  group('OCR Layout Reconstructor & Structured Lab Report Parser Tests', () {
    test('1. Parses standard multi-column CBC report with units and reference ranges', () {
      const ocrText = '''
CHUGHTAI LAB - DIAGNOSTIC REPORT
Patient Name: Ammar Malik
Date: 20-Aug-2026

COMPLETE BLOOD COUNT
Haemoglobin    13.8    g/dL    13.0 - 17.0
WBC    7200    /uL    4000 - 11000
Platelets    280000    /uL    150000 - 450000
Hematocrit    42.1    %    40.0 - 52.0
''';

      final structured = OcrLayoutReconstructor.parse(ocrText);

      expect(structured.sections.length, 1);
      final cbcSection = structured.sections.first;
      expect(cbcSection.title, contains('COMPLETE BLOOD COUNT'));
      expect(cbcSection.rows.length, 4);

      // Haemoglobin
      expect(cbcSection.rows[0].parameterName, 'Haemoglobin');
      expect(cbcSection.rows[0].result, '13.8');
      expect(cbcSection.rows[0].unit, 'g/dL');
      expect(cbcSection.rows[0].referenceRange, '13.0 - 17.0');

      // WBC
      expect(cbcSection.rows[1].parameterName, 'WBC');
      expect(cbcSection.rows[1].result, '7200');
      expect(cbcSection.rows[1].unit, '/uL');
      expect(cbcSection.rows[1].referenceRange, '4000 - 11000');

      // Platelets
      expect(cbcSection.rows[2].parameterName, 'Platelets');
      expect(cbcSection.rows[2].result, '280000');
      expect(cbcSection.rows[2].unit, '/uL');
      expect(cbcSection.rows[2].referenceRange, '150000 - 450000');

      // Unclassified lines contain patient metadata
      expect(structured.unclassifiedLines.any((l) => l.contains('Patient Name: Ammar Malik')), isTrue);
      expect(structured.unclassifiedLines.any((l) => l.contains('Date: 20-Aug-2026')), isTrue);
    });

    test('2. Multiple sections are grouped independently without cross-contamination', () {
      const ocrText = '''
COMPLETE BLOOD COUNT
Haemoglobin    14.2    g/dL    13.5 - 17.5
WBC    6500    /uL    4000 - 11000

LIPID PROFILE
Total Cholesterol    198    mg/dL    < 200
HDL Cholesterol    46    mg/dL    > 40
LDL Cholesterol    121    mg/dL    < 100
Triglycerides    155    mg/dL    < 150
''';

      final structured = OcrLayoutReconstructor.parse(ocrText);

      expect(structured.sections.length, 2);
      expect(structured.sections[0].title, contains('COMPLETE BLOOD COUNT'));
      expect(structured.sections[0].rows.length, 2);

      expect(structured.sections[1].title, contains('LIPID PROFILE'));
      expect(structured.sections[1].rows.length, 4);

      expect(structured.sections[1].rows[0].parameterName, 'Total Cholesterol');
      expect(structured.sections[1].rows[0].result, '198');
      expect(structured.sections[1].rows[0].unit, 'mg/dL');
      expect(structured.sections[1].rows[0].referenceRange, '< 200');
    });

    test('3. Missing reference range or unit remains null/empty and is NEVER invented', () {
      const ocrText = '''
Fasting Blood Sugar    104    mg/dL
Hemoglobin    13.4
ABC_PARAMETER_99    99
''';

      final structured = OcrLayoutReconstructor.parse(ocrText);

      expect(structured.sections.length, 1);
      final rows = structured.sections.first.rows;
      expect(rows.length, 3);

      // Row with unit, but NO reference range
      expect(rows[0].parameterName, 'Fasting Blood Sugar');
      expect(rows[0].result, '104');
      expect(rows[0].unit, 'mg/dL');
      expect(rows[0].referenceRange, isNull); // Never fabricated

      // Row with no unit and no reference range
      expect(rows[1].parameterName, 'Hemoglobin');
      expect(rows[1].result, '13.4');
      expect(rows[1].unit, isNull); // Never fabricated
      expect(rows[1].referenceRange, isNull); // Never fabricated

      // Minimal 2-column parameter
      expect(rows[2].parameterName, 'ABC_PARAMETER_99');
      expect(rows[2].result, '99');
      expect(rows[2].unit, isNull);
      expect(rows[2].referenceRange, isNull);
    });

    test('4. Qualitative results (Positive / Negative / Non-Reactive) are parsed accurately', () {
      const ocrText = '''
HEPATITIS PROFILE
HBsAg    Negative
Anti-HCV    Non-Reactive
Blood Group    Positive
''';

      final structured = OcrLayoutReconstructor.parse(ocrText);

      expect(structured.sections.length, 1);
      final rows = structured.sections.first.rows;
      expect(rows.length, 3);

      expect(rows[0].parameterName, 'HBsAg');
      expect(rows[0].result, 'Negative');

      expect(rows[1].parameterName, 'Anti-HCV');
      expect(rows[1].result, 'Non-Reactive');
    });

    test('5. Non-tabular, uncertain or header text is kept in unclassifiedLines without fake rows', () {
      const ocrText = '''
Hospital: Shaukat Khanum Memorial
Consultant: Dr. Shahid
Specimen: Whole Blood EDTA
Verified By: Laboratory Director
Random notes here with no numbers
''';

      final structured = OcrLayoutReconstructor.parse(ocrText);

      // No fake test rows should be created
      expect(structured.totalRowCount, 0);
      expect(structured.unclassifiedLines.length, greaterThanOrEqualTo(4));
    });

    test('6. Completely empty or whitespace text produces empty structured report', () {
      final structured = OcrLayoutReconstructor.parse('    \n\n   ');
      expect(structured.sections, isEmpty);
      expect(structured.totalRowCount, 0);
      expect(structured.hasStructuredData, isFalse);
    });

    test('7. Table header separator lines (---, ===) are ignored and not treated as data', () {
      const ocrText = '''
==================================================
TEST NAME          RESULT       UNIT       NORMAL
--------------------------------------------------
Serum Creatinine   0.92         mg/dL      0.70 - 1.20
Serum Urea         24           mg/dL      10 - 50
==================================================
''';

      final structured = OcrLayoutReconstructor.parse(ocrText);

      expect(structured.sections.length, 1);
      final rows = structured.sections.first.rows;
      expect(rows.length, 2);
      expect(rows[0].parameterName, 'Serum Creatinine');
      expect(rows[0].result, '0.92');
      expect(rows[0].unit, 'mg/dL');
      expect(rows[0].referenceRange, '0.70 - 1.20');

      expect(rows[1].parameterName, 'Serum Urea');
      expect(rows[1].result, '24');
    });

    test('8. LabResultRow model immutability and equality tests', () {
      const row1 = LabResultRow(
        parameterName: 'Hb',
        result: '14.0',
        unit: 'g/dL',
        referenceRange: '13-17',
        originalText: 'Hb 14.0 g/dL 13-17',
      );
      const row2 = LabResultRow(
        parameterName: 'Hb',
        result: '14.0',
        unit: 'g/dL',
        referenceRange: '13-17',
        originalText: 'Hb 14.0 g/dL 13-17',
      );
      const row3 = LabResultRow(
        parameterName: 'Hb',
        result: '15.0',
        unit: 'g/dL',
        referenceRange: '13-17',
        originalText: 'Hb 15.0 g/dL 13-17',
      );

      expect(row1, equals(row2));
      expect(row1.hashCode, equals(row2.hashCode));
      expect(row1 == row3, isFalse);
      expect(row1.toString(), contains('Hb: 14.0'));
    });
  });
}
