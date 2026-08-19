import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:zindagi_plus/data/models/lab_report.dart';
import 'package:zindagi_plus/features/reports/screens/report_detail_screen.dart';
import 'package:zindagi_plus/features/reports/screens/report_history_screen.dart';
import 'package:zindagi_plus/features/reports/screens/report_processing_screen.dart';
import 'package:zindagi_plus/features/reports/screens/upload_screen.dart';
import 'package:zindagi_plus/providers/report_providers.dart';
import 'package:zindagi_plus/services/ocr/mock_ocr_service.dart';

void main() {
  Widget buildTestableWidget(Widget child, {List<Override> overrides = const []}) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => child,
        ),
        GoRoute(
          path: '/upload',
          builder: (_, _) => const Scaffold(body: Text('Upload Screen')),
        ),
        GoRoute(
          path: '/upload/result',
          builder: (_, _) => const Scaffold(body: Text('Result Screen')),
        ),
        GoRoute(
          path: '/upload/explanation',
          builder: (_, _) => const Scaffold(body: Text('Explanation Screen')),
        ),
      ],
    );

    return ProviderScope(
      overrides: overrides,
      child: MaterialApp.router(
        routerConfig: router,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF00674F)),
        ),
      ),
    );
  }

  group('UploadScreen Widget', () {
    testWidgets('renders upload UI, title, and on-device privacy banner', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const UploadScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Upload Lab Report'), findsAtLeast(1));
      expect(find.text('Choose File'), findsOneWidget);
      expect(find.byIcon(Icons.privacy_tip_outlined), findsOneWidget);
      expect(find.textContaining('100% Private On-Device OCR'), findsOneWidget);
    });
  });

  group('ReportProcessingScreen Widget', () {
    testWidgets('renders progress ring and processing step definitions', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const ReportProcessingScreen(
            fileName: 'CBC_Test_Report.jpg',
            scenario: MockProcessingScenario.success,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify title & initial steps
      expect(find.text('Extracting Report Text'), findsOneWidget);
      expect(find.text('CBC_Test_Report.jpg'), findsOneWidget);
      expect(find.text('Storing Original File'), findsOneWidget);
      expect(find.text('Initializing On-Device OCR'), findsOneWidget);
      expect(find.text('Extracting Raw Text'), findsOneWidget);
      expect(find.text('Finalizing Report'), findsOneWidget);

      // Settle all steps cleanly
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('renders error view on failure scenario with Retry button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const ReportProcessingScreen(
            fileName: 'corrupted_scan.jpg',
            scenario: MockProcessingScenario.invalidFile,
          ),
        ),
      );

      // Advance clock through step 0 failure
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('OCR Text Extraction Failed'), findsOneWidget);
      expect(find.text('Retry Processing'), findsOneWidget);
      expect(find.text('Pick Another File'), findsOneWidget);
    });
  });

  group('ReportDetailScreen Widget', () {
    testWidgets('renders Extracted OCR Text card with raw text and copy button', (tester) async {
      final sampleReport = LabReport(
        id: 'report_001',
        fileName: 'Blood_Report_July_2025.jpg',
        uploadedAt: DateTime(2025, 7, 5, 10, 30),
        status: ReportStatus.completed,
        extractedText: MockOcrService.defaultSampleMedicalReportText,
        biomarkerCount: 8,
        attentionCount: 3,
        aiSummary: 'HbA1c borderline, LDL elevated, Vitamin D low.',
      );

      await tester.pumpWidget(
        buildTestableWidget(
          const ReportDetailScreen(
            reportId: 'report_001',
            fileName: 'Blood_Report_July_2025.jpg',
          ),
          overrides: [
            reportDetailProvider('report_001').overrideWith((ref) => sampleReport),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Lab Report Detail'), findsOneWidget);
      expect(find.text('Extracted OCR Text'), findsOneWidget);
      expect(find.textContaining('Medical Disclaimer: This is uninterpreted raw OCR text'), findsOneWidget);
      expect(find.textContaining('CHUGHTAI LAB'), findsOneWidget);
      expect(find.textContaining('COMPLETE BLOOD COUNT'), findsOneWidget);
      expect(find.byIcon(Icons.copy_rounded), findsOneWidget);
    });
  });

  group('ReportHistoryScreen Widget', () {
    testWidgets('renders history list with status badges', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ReportHistoryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('My Reports'), findsOneWidget);
      expect(find.text('Completed'), findsAtLeast(1));
      expect(find.byIcon(Icons.document_scanner_outlined), findsAtLeast(1));
    });
  });
}
