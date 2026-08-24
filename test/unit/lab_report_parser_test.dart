import 'package:flutter_test/flutter_test.dart';
import 'package:zindagi_plus/services/lab_report_parser.dart';

void main() {
  group('LabReportParser', () {
    test('extracts multiple standard parameters from realistic OCR text', () {
      const sampleOcr = '''
CHUGHTAI LAB
PATIENT REPORT: Complete Blood Count & Chemistry
=================================================
Hemoglobin: 13.2 g/dL       (Normal 12.0 - 16.0)
WBC: 6,500 /uL              (Normal 4000 - 11000)
RBC: 4.85 mill/uL           (Normal 4.2 - 5.4)
Platelets: 245000 /uL       (Normal 150000 - 450000)
Hematocrit: 41.5 %          (Normal 37 - 48)
Fasting Blood Glucose: 108 mg/dL (Normal 70 - 99)
HbA1c: 6.1 %                (Normal < 5.7)
Total Cholesterol: 210 mg/dL (Desirable < 200)
HDL: 42 mg/dL               (Optimal > 40)
LDL: 145 mg/dL              (Optimal < 100)
Triglycerides: 148 mg/dL    (Normal < 150)
Creatinine: 0.92 mg/dL      (Normal 0.6 - 1.2)
Blood Urea: 18 mg/dL        (Normal 7 - 20)
ALT: 32 U/L                 (Normal < 45)
AST: 28 U/L                 (Normal < 40)
TSH: 2.1 mIU/L              (Normal 0.4 - 4.0)
Vitamin D: 18.4 ng/mL       (Sufficiency > 30)
Vitamin B12: 320 pg/mL      (Normal 200 - 900)
''';

      final results = LabReportParser.parse(sampleOcr);

      expect(results.length, equals(18));

      final map = {for (final b in results) b.name: b};

      expect(map['Hemoglobin']?.value, equals(13.2));
      expect(map['Hemoglobin']?.unit, equals('g/dL'));

      expect(map['WBC']?.value, equals(6500.0));
      expect(map['WBC']?.unit, equals('/uL'));

      expect(map['RBC']?.value, equals(4.85));

      expect(map['Platelets']?.value, equals(245000.0));

      expect(map['Hematocrit']?.value, equals(41.5));
      expect(map['Hematocrit']?.unit, equals('%'));

      expect(map['Glucose']?.value, equals(108.0));
      expect(map['Glucose']?.unit, equals('mg/dL'));

      expect(map['HbA1c']?.value, equals(6.1));
      expect(map['HbA1c']?.unit, equals('%'));

      expect(map['Total Cholesterol']?.value, equals(210.0));
      expect(map['HDL']?.value, equals(42.0));
      expect(map['LDL']?.value, equals(145.0));
      expect(map['Triglycerides']?.value, equals(148.0));
      expect(map['Creatinine']?.value, equals(0.92));
      expect(map['Urea']?.value, equals(18.0));
      expect(map['ALT']?.value, equals(32.0));
      expect(map['AST']?.value, equals(28.0));
      expect(map['TSH']?.value, equals(2.1));
      expect(map['Vitamin D']?.value, equals(18.4));
      expect(map['Vitamin B12']?.value, equals(320.0));
    });

    test('tolerates common OCR spelling and punctuation variations', () {
      const variationsOcr = '''
Haemoglobin - 14.5 g/dL
HGB 12.8 g/dl
FBS: 95 mg/dL
Hb A1c 5.8 %
SGPT: 35 U/L
SGOT: 29 U/L
25-OH Vitamin D 24.5 ng/mL
Vit B-12 450 pg/mL
''';

      final results = LabReportParser.parse(variationsOcr);
      final map = {for (final b in results) b.name: b};

      expect(map['Hemoglobin']?.value, equals(14.5));
      expect(map['Glucose']?.value, equals(95.0));
      expect(map['HbA1c']?.value, equals(5.8));
      expect(map['ALT']?.value, equals(35.0));
      expect(map['AST']?.value, equals(29.0));
      expect(map['Vitamin D']?.value, equals(24.5));
      expect(map['Vitamin B12']?.value, equals(450.0));
    });

    test('returns empty list for empty or non-medical text', () {
      expect(LabReportParser.parse(''), isEmpty);
      expect(LabReportParser.parse('   '), isEmpty);
      expect(LabReportParser.parse('Grocery store receipt: Apples 5, Milk 2'), isEmpty);
    });
  });
}
