// Copilot Task 4: Nutrition Tracker - Nutrition Model
// This file defines daily nutrition tracking and goals

import 'package:hive/hive.dart';

part 'nutrition.g.dart';

@HiveType(typeId: 2)
class DailyNutrition extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  double totalCalories;

  @HiveField(2)
  double totalProtein;

  @HiveField(3)
  double totalCarbs;

  @HiveField(4)
  double totalFat;

  @HiveField(5)
  List<String> consumedProductIds;

  DailyNutrition({
    required this.date,
    this.totalCalories = 0.0,
    this.totalProtein = 0.0,
    this.totalCarbs = 0.0,
    this.totalFat = 0.0,
    List<String>? consumedProductIds,
  }) : consumedProductIds = consumedProductIds ?? [];

  // Add nutrition from a product
  void addNutrition(double calories, double protein, double carbs, double fat, String productId) {
    totalCalories += calories;
    totalProtein += protein;
    totalCarbs += carbs;
    totalFat += fat;
    if (!consumedProductIds.contains(productId)) {
      consumedProductIds.add(productId);
    }
  }
}

@HiveType(typeId: 3)
class NutritionGoals extends HiveObject {
  @HiveField(0)
  double dailyCalorieGoal;

  @HiveField(1)
  double dailyProteinGoal;

  @HiveField(2)
  double dailyCarbsGoal;

  @HiveField(3)
  double dailyFatGoal;

  @HiveField(4)
  String userProfile; // active, sedentary, athlete

  NutritionGoals({
    this.dailyCalorieGoal = 2500.0,
    this.dailyProteinGoal = 50.0,
    this.dailyCarbsGoal = 300.0,
    this.dailyFatGoal = 70.0,
    this.userProfile = 'active',
  });

  // Check if calorie limit exceeded
  bool isCalorieLimitExceeded(double currentCalories) {
    return currentCalories > dailyCalorieGoal;
  }

  // Calculate percentage of goal achieved
  double getCalorieProgress(double currentCalories) {
    return (currentCalories / dailyCalorieGoal * 100).clamp(0.0, 100.0);
  }

  double getProteinProgress(double currentProtein) {
    return (currentProtein / dailyProteinGoal * 100).clamp(0.0, 100.0);
  }

  double getCarbsProgress(double currentCarbs) {
    return (currentCarbs / dailyCarbsGoal * 100).clamp(0.0, 100.0);
  }

  double getFatProgress(double currentFat) {
    return (currentFat / dailyFatGoal * 100).clamp(0.0, 100.0);
  }
}
