// Copilot Task 7: Sustainability Insights - Metrics Model
// Track food waste reduction and environmental impact

import 'package:hive/hive.dart';

part 'sustainability.g.dart';

@HiveType(typeId: 4)
class SustainabilityMetrics extends HiveObject {
  @HiveField(0)
  DateTime weekStart;

  @HiveField(1)
  DateTime weekEnd;

  @HiveField(2)
  int itemsSaved; // Number of items not wasted

  @HiveField(3)
  double foodWeightSaved; // in kg

  @HiveField(4)
  double co2Reduced; // in kg CO2

  @HiveField(5)
  double moneySaved; // in currency

  @HiveField(6)
  int itemsConsumed;

  @HiveField(7)
  int itemsWasted;

  SustainabilityMetrics({
    required this.weekStart,
    required this.weekEnd,
    this.itemsSaved = 0,
    this.foodWeightSaved = 0.0,
    this.co2Reduced = 0.0,
    this.moneySaved = 0.0,
    this.itemsConsumed = 0,
    this.itemsWasted = 0,
  });

  // Estimate CO2 reduction (average: 1kg food waste = 2.5kg CO2)
  void calculateCO2Reduction() {
    co2Reduced = foodWeightSaved * 2.5;
  }

  // Calculate waste reduction percentage
  double get wasteReductionPercentage {
    final totalItems = itemsConsumed + itemsWasted;
    if (totalItems == 0) return 0.0;
    return ((itemsConsumed / totalItems) * 100).clamp(0.0, 100.0);
  }

  // Get impact message
  String get impactMessage {
    if (itemsSaved >= 10) {
      return '🌟 Amazing! You saved $itemsSaved items this week!';
    } else if (itemsSaved >= 5) {
      return '👏 Great job! $itemsSaved items saved from waste!';
    } else if (itemsSaved > 0) {
      return '✅ Good start! Keep tracking to save more!';
    }
    return '🌱 Start tracking to see your impact!';
  }
}
