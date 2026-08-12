import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/repositories/interfaces/recommendation_repository.dart';

/// Mock implementation of [RecommendationRepository].
///
/// Returns hard-coded data with artificial delays. Swap for a real API
/// implementation by updating `lib/providers/repository_providers.dart`.
class RecommendationRepositoryMock implements RecommendationRepository {
  @override
  Future<Result<List<Map<String, dynamic>>>> getMealRecommendations() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const Success([
      {
        'name': 'Chicken Tikka',
        'calories': 165,
        'protein': '28g',
        'carbs': '3g',
        'fat': '5g',
        'emoji': '🍗',
        'reason':
            'High protein and low carb — ideal for blood sugar control and lean muscle maintenance.',
        'tags': ['High Protein', 'Low Carb'],
      },
      {
        'name': 'Daal Moong',
        'calories': 120,
        'protein': '9g',
        'carbs': '18g',
        'fat': '1g',
        'emoji': '🫘',
        'reason':
            'Rich in fibre and plant protein. Supports heart health and provides sustained energy.',
        'tags': ['High Fibre', 'Heart Healthy'],
      },
      {
        'name': 'Saag (Mustard Greens)',
        'calories': 85,
        'protein': '5g',
        'carbs': '10g',
        'fat': '4g',
        'emoji': '🥬',
        'reason':
            'Iron-rich with strong anti-inflammatory properties — great for overall wellness.',
        'tags': ['Iron Rich', 'Anti-inflammatory'],
      },
      {
        'name': 'Grilled Fish (Rohu)',
        'calories': 140,
        'protein': '24g',
        'carbs': '0g',
        'fat': '4g',
        'emoji': '🐟',
        'reason':
            'Omega-3 rich — excellent for cholesterol management and cognitive health.',
        'tags': ['Omega-3', 'Low Calorie'],
      },
      {
        'name': 'Raita (Low-fat)',
        'calories': 60,
        'protein': '4g',
        'carbs': '6g',
        'fat': '2g',
        'emoji': '🥛',
        'reason':
            'Probiotic properties aid digestion and help restore healthy gut flora balance.',
        'tags': ['Probiotic', 'Gut Health'],
      },
    ]);
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getActivityPlan() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return const Success([
      {
        'name': 'Morning Walk',
        'duration': '30 min',
        'intensity': 'Low',
        'calories': '120 kcal',
      },
      {
        'name': 'Yoga & Stretching',
        'duration': '20 min',
        'intensity': 'Low',
        'calories': '65 kcal',
      },
    ]);
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getRecommendations() async {
    await Future.delayed(const Duration(milliseconds: 600));
    return const Success([
      {
        'id': 'rec_001',
        'type': 'medication',
        'title': 'Take Metformin with dinner',
        'description': 'You missed your evening dose yesterday.',
        'priority': 'high',
      },
      {
        'id': 'rec_002',
        'type': 'nutrition',
        'title': 'Reduce refined carbohydrates',
        'description': 'Your HbA1c is borderline — cutting white rice and bread will help.',
        'priority': 'high',
      },
      {
        'id': 'rec_003',
        'type': 'activity',
        'title': 'Add a 20-min walk today',
        'description': 'You have been sedentary for 2 days.',
        'priority': 'medium',
      },
      {
        'id': 'rec_004',
        'type': 'insight',
        'title': 'Vitamin D deficiency detected',
        'description': 'Your Vitamin D is 18 ng/mL. Supplementation and sunlight exposure recommended.',
        'priority': 'medium',
      },
    ]);
  }

  @override
  Future<Result<void>> markDone(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    return const Success(null);
  }
}
