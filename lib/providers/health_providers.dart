import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/medication.dart';
import 'package:zindagi_plus/providers/auth_provider.dart';
import 'package:zindagi_plus/providers/repository_providers.dart';

export 'package:zindagi_plus/providers/report_providers.dart';

/// Provides dashboard summary data, merging real Supabase profile/medication
/// data with mock values for fields not yet backed by a DB (healthScore,
/// recentInsights, lastReport).
final dashboardDataProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  // Watch auth state so dashboard re-builds when profile changes.
  final user = ref.watch(authNotifierProvider);

  int activeMedsCount = 0;
  if (user != null) {
    // Load all medications and count active ones when authenticated.
    final medRepo = ref.read(medicationRepositoryProvider);
    final medResult = await medRepo.getMedications();

    if (medResult is Success<List<Medication>>) {
      activeMedsCount =
          medResult.data.where((m) => m.isActive).length;
    }
  }

  // Weight from the real profile — display as "XX kg" or "—" if not set.
  final weightStr = user?.weightKg != null
      ? '${user!.weightKg!.toStringAsFixed(0)} kg'
      : '— kg';

  // Static mock values for fields pending AI / analytics integration.
  const healthScore = 78;
  const lastReport = '—';
  const recentInsights = <String>[
    'Complete your first medication log to begin tracking adherence. 💊',
    'Your profile is set up — personalised insights will appear here soon.',
    'Tip: keep your weight and conditions up to date for better recommendations.',
  ];

  return {
    'healthScore': healthScore,
    'userName': user?.name ?? 'there',
    'activeMeds': activeMedsCount,
    'lastReport': lastReport,
    'weight': weightStr,
    'recentInsights': recentInsights,
  };
});

/// Provides AI meal recommendations.
final mealRecommendationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(healthRepositoryProvider);
  final result = await repo.getMealRecommendations();
  return switch (result) {
    Success(data: final d) => d,
    Failure(message: final m) => throw Exception(m),
  };
});
