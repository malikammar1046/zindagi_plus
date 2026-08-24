import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zindagi_plus/core/config/environment.dart';
import 'package:zindagi_plus/data/repositories/implementations/auth_repository_mock.dart';
import 'package:zindagi_plus/data/repositories/implementations/auth_repository_supabase.dart';
import 'package:zindagi_plus/data/repositories/implementations/chat_repository_mock.dart';
import 'package:zindagi_plus/data/repositories/implementations/health_repository_mock.dart';
import 'package:zindagi_plus/data/repositories/implementations/lab_report_repository_mock.dart';
import 'package:zindagi_plus/data/repositories/implementations/lab_report_repository_supabase.dart';
import 'package:zindagi_plus/data/repositories/implementations/medication_repository_mock.dart';
import 'package:zindagi_plus/data/repositories/implementations/medication_repository_supabase.dart';
import 'package:zindagi_plus/data/repositories/implementations/recommendation_repository_mock.dart';
import 'package:zindagi_plus/data/repositories/interfaces/auth_repository.dart';
import 'package:zindagi_plus/data/repositories/interfaces/chat_repository.dart';
import 'package:zindagi_plus/data/repositories/interfaces/health_repository.dart';
import 'package:zindagi_plus/data/repositories/interfaces/lab_report_repository.dart';
import 'package:zindagi_plus/data/repositories/interfaces/medication_repository.dart';
import 'package:zindagi_plus/data/repositories/interfaces/recommendation_repository.dart';
import 'package:zindagi_plus/providers/supabase_provider.dart';
import 'package:zindagi_plus/services/ocr/mlkit_ocr_service.dart';
import 'package:zindagi_plus/services/ocr/mock_ocr_service.dart';
import 'package:zindagi_plus/services/ocr/ocr_service.dart';

/// Provides the active [OcrService] implementation.
///
/// Uses [MlKitOcrService] for on-device native OCR on mobile devices (Android / iOS).
/// Falls back to [MockOcrService] only on non-mobile host environments (desktop, web, unit tests).
final ocrServiceProvider = Provider<OcrService>((ref) {
  final isMobile = !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  debugPrint(
    '[OCR-DIAG] ocrServiceProvider resolving -> isMobile=$isMobile, platform=$defaultTargetPlatform, flavor=${Environment.currentFlavor}',
  );

  if (isMobile) {
    debugPrint('[OCR-DIAG] ocrServiceProvider -> Instantiating MlKitOcrService');
    return MlKitOcrService();
  }

  debugPrint('[OCR-DIAG] ocrServiceProvider -> Instantiating MockOcrService (non-mobile host)');
  return MockOcrService();
});

/// Provides the active [AuthRepository] implementation.
///
/// Uses [AuthRepositorySupabase] when Supabase is initialized and configured,
/// with graceful fallback to [AuthRepositoryMock].
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (Environment.isSupabaseConfigured && isSupabaseInitialized) {
    final client = ref.watch(supabaseClientProvider);
    return AuthRepositorySupabase(client);
  }
  return AuthRepositoryMock();
});

/// Provides the active [MedicationRepository] implementation.
///
/// Uses [MedicationRepositorySupabase] when Supabase is configured.
/// Falls back to [MedicationRepositoryMock] for local/test environments.
final medicationRepositoryProvider = Provider<MedicationRepository>((ref) {
  if (Environment.isSupabaseConfigured && isSupabaseInitialized) {
    final client = ref.watch(supabaseClientProvider);
    return MedicationRepositorySupabase(client);
  }
  return MedicationRepositoryMock();
});

/// Provides the active [HealthRepository] implementation.
final healthRepositoryProvider = Provider<HealthRepository>(
  (ref) => HealthRepositoryMock(),
);

/// Provides the active [LabReportRepository] implementation.
///
/// Uses [LabReportRepositorySupabase] when Supabase is configured and initialized,
/// with [LabReportRepositoryMock] fallback for local/test environments.
final labReportRepositoryProvider = Provider<LabReportRepository>((ref) {
  final ocr = ref.watch(ocrServiceProvider);
  if (Environment.isSupabaseConfigured && isSupabaseInitialized) {
    final client = ref.watch(supabaseClientProvider);
    return LabReportRepositorySupabase(client, ocr);
  }
  return LabReportRepositoryMock(ocrService: ocr);
});

/// Provides the active [RecommendationRepository] implementation.
final recommendationRepositoryProvider = Provider<RecommendationRepository>(
  (ref) => RecommendationRepositoryMock(),
);

/// Provides the active [ChatRepository] implementation.
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepositoryMock(),
);
