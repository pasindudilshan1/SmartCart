// Copilot Task 4: Nutrition Provider - State Management for Nutrition Tracking
// Manages daily nutrition tracking and goals

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/nutrition.dart';

class NutritionProvider extends ChangeNotifier {
  late Box _nutritionBox;
  late Box _settingsBox;
  
  DailyNutrition? _todayNutrition;
  NutritionGoals _goals = NutritionGoals();

  DailyNutrition get todayNutrition => _todayNutrition ?? DailyNutrition(date: DateTime.now());
  NutritionGoals get goals => _goals;

  NutritionProvider() {
    _init();
  }

  Future<void> _init() async {
    _nutritionBox = Hive.box('nutrition');
    _settingsBox = Hive.box('settings');
    _loadTodayNutrition();
    _loadGoals();
  }

  void _loadTodayNutrition() {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    
    _todayNutrition = _nutritionBox.get(todayKey);
    if (_todayNutrition == null) {
      _todayNutrition = DailyNutrition(date: today);
      _nutritionBox.put(todayKey, _todayNutrition);
    }
    notifyListeners();
  }

  void _loadGoals() {
    final savedGoals = _settingsBox.get('nutrition_goals');
    if (savedGoals != null) {
      _goals = savedGoals;
    }
    notifyListeners();
  }

  // Add nutrition from consumed product
  Future<void> addNutrition({
    required double calories,
    required double protein,
    required double carbs,
    required double fat,
    required String productId,
  }) async {
    _todayNutrition?.addNutrition(calories, protein, carbs, fat, productId);
    
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    await _nutritionBox.put(todayKey, _todayNutrition);
    
    notifyListeners();
  }

  // Update nutrition goals
  Future<void> updateGoals(NutritionGoals newGoals) async {
    _goals = newGoals;
    await _settingsBox.put('nutrition_goals', newGoals);
    notifyListeners();
  }

  // Check if calorie limit exceeded
  bool get isCalorieLimitExceeded {
    return _goals.isCalorieLimitExceeded(todayNutrition.totalCalories);
  }

  // Get progress percentages
  double get calorieProgress => _goals.getCalorieProgress(todayNutrition.totalCalories);
  double get proteinProgress => _goals.getProteinProgress(todayNutrition.totalProtein);
  double get carbsProgress => _goals.getCarbsProgress(todayNutrition.totalCarbs);
  double get fatProgress => _goals.getFatProgress(todayNutrition.totalFat);

  // Get nutrition data for a specific date
  DailyNutrition? getNutritionForDate(DateTime date) {
    final dateKey = '${date.year}-${date.month}-${date.day}';
    return _nutritionBox.get(dateKey);
  }

  // Get weekly nutrition data
  List<DailyNutrition> getWeeklyNutrition() {
    final now = DateTime.now();
    final weekData = <DailyNutrition>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = '${date.year}-${date.month}-${date.day}';
      final dayNutrition = _nutritionBox.get(dateKey) ?? DailyNutrition(date: date);
      weekData.add(dayNutrition);
    }
    
    return weekData;
  }

  // Reset today's nutrition (for testing)
  Future<void> resetToday() async {
    final today = DateTime.now();
    final todayKey = '${today.year}-${today.month}-${today.day}';
    _todayNutrition = DailyNutrition(date: today);
    await _nutritionBox.put(todayKey, _todayNutrition);
    notifyListeners();
  }
}
