import 'package:zindagi_plus/core/network/result.dart';
import 'package:zindagi_plus/data/repositories/interfaces/health_repository.dart';

/// Mock implementation of [HealthRepository].
///
/// Returns hard-coded data with artificial delays that mirror real network
/// latency. Swap for a real API implementation by updating
/// `lib/providers/repository_providers.dart`.
class HealthRepositoryMock implements HealthRepository {
  @override
  Future<Result<Map<String, dynamic>>> getDashboardData() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return const Success({
      'healthScore': 78,
      'userName': 'Ammar',
      'activeMeds': 2,
      'lastReport': '2 weeks ago',
      'weight': '72 kg',
      'recentInsights': [
        'Your HbA1c dropped 0.5% since last month — great progress! 🎉',
        'LDL levels are slightly elevated. Consider reducing saturated fats.',
        'Vitamin D is below the normal range. Supplementation recommended.',
        'Blood pressure is within the healthy range — keep it up! 💪',
      ],
    });
  }

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
}
