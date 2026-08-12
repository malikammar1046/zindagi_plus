import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/models/lab_report.dart';
import 'package:zindagi_plus/providers/repository_providers.dart';

/// Provides dashboard data.
///
/// Uses [autoDispose] so the data is re-fetched whenever the user navigates
/// back to the Dashboard — ensuring freshness without manual invalidation.
final dashboardDataProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final repo = ref.read(healthRepositoryProvider);
  final result = await repo.getDashboardData();
  return switch (result) {
    Success(data: final d) => d,
    Failure(message: final m) => throw Exception(m),
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

/// Provides the lab report history list.
final reportHistoryProvider =
    FutureProvider.autoDispose<List<LabReport>>((ref) async {
  final repo = ref.read(labReportRepositoryProvider);
  final result = await repo.getReportHistory();
  return switch (result) {
    Success(data: final d) => d,
    Failure(message: final m) => throw Exception(m),
  };
});
