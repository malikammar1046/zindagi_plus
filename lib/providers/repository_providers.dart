import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zindagi_plus/core/config/environment.dart';
import 'package:zindagi_plus/data/repositories/implementations/auth_repository_mock.dart';
import 'package:zindagi_plus/data/repositories/implementations/auth_repository_supabase.dart';
import 'package:zindagi_plus/data/repositories/implementations/chat_repository_mock.dart';
import 'package:zindagi_plus/data/repositories/implementations/health_repository_mock.dart';
import 'package:zindagi_plus/data/repositories/implementations/lab_report_repository_mock.dart';
import 'package:zindagi_plus/data/repositories/implementations/medication_repository_mock.dart';
import 'package:zindagi_plus/data/repositories/implementations/recommendation_repository_mock.dart';
import 'package:zindagi_plus/data/repositories/interfaces/auth_repository.dart';
import 'package:zindagi_plus/data/repositories/interfaces/chat_repository.dart';
import 'package:zindagi_plus/data/repositories/interfaces/health_repository.dart';
import 'package:zindagi_plus/data/repositories/interfaces/lab_report_repository.dart';
import 'package:zindagi_plus/data/repositories/interfaces/medication_repository.dart';
import 'package:zindagi_plus/data/repositories/interfaces/recommendation_repository.dart';
import 'package:zindagi_plus/providers/supabase_provider.dart';

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

/// Provides the active [HealthRepository] implementation.
final healthRepositoryProvider = Provider<HealthRepository>(
  (ref) => HealthRepositoryMock(),
);

/// Provides the active [MedicationRepository] implementation.
final medicationRepositoryProvider = Provider<MedicationRepository>(
  (ref) => MedicationRepositoryMock(),
);

/// Provides the active [LabReportRepository] implementation.
final labReportRepositoryProvider = Provider<LabReportRepository>(
  (ref) => LabReportRepositoryMock(),
);

/// Provides the active [RecommendationRepository] implementation.
final recommendationRepositoryProvider = Provider<RecommendationRepository>(
  (ref) => RecommendationRepositoryMock(),
);

/// Provides the active [ChatRepository] implementation.
final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepositoryMock(),
);
