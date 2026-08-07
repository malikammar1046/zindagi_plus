import 'package:zindagi_plus/core/network/result.dart';

/// Contract for the health data layer.
abstract class HealthRepository {
  /// Returns dashboard summary data for the authenticated user.
  Future<Result<Map<String, dynamic>>> getDashboardData();

  /// Returns AI-curated meal recommendations for the user's health profile.
  Future<Result<List<Map<String, dynamic>>>> getMealRecommendations();
}
