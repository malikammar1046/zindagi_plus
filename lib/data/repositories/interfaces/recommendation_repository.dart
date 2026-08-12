import 'package:zindagi_plus/core/network/result.dart';

/// Contract for the recommendation data layer.
///
/// Swap implementations (mock ↔ API) via the Riverpod provider in
/// `lib/providers/repository_providers.dart` without touching business logic.
abstract class RecommendationRepository {
  /// Returns AI-curated meal recommendations for the user's health profile.
  Future<Result<List<Map<String, dynamic>>>> getMealRecommendations();

  /// Returns the AI-generated activity plan.
  Future<Result<List<Map<String, dynamic>>>> getActivityPlan();

  /// Returns the prioritised list of health recommendations
  /// (medication, nutrition, activity, insights).
  Future<Result<List<Map<String, dynamic>>>> getRecommendations();

  /// Marks a recommendation with [id] as done for the current user.
  Future<Result<void>> markDone(String id);
}
