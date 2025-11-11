// Household Nutrition Alerts Provider
// Manages household nutrition alerts across the app

import 'package:flutter/foundation.dart';
import '../models/household_member.dart';
import '../models/nutrition.dart';
import '../services/azure_table_service.dart';
import '../services/local_storage_service.dart';
import 'nutrition_provider.dart';

class NutritionAlert {
  const NutritionAlert({
    required this.nutrient,
    required this.inventoryValue,
    required this.goalValue,
    required this.unit,
    required this.triggeredByUpcomingPurchase,
  });

  final String nutrient;
  final double inventoryValue;
  final double goalValue;
  final String unit;
  final bool triggeredByUpcomingPurchase;

  double get ratio => goalValue <= 0 ? 0 : inventoryValue / goalValue;

  bool get isCritical => ratio >= 1.0;

  String get headline => isCritical ? '$nutrient goal exceeded' : '$nutrient goal nearly met';

  String get description {
    final percent = (ratio * 100).clamp(0, 9999).toStringAsFixed(0);
    final details =
        '${inventoryValue.toStringAsFixed(0)} $unit / ${goalValue.toStringAsFixed(0)} $unit';

    if (isCritical) {
      final overflow = ((ratio - 1) * 100).abs().toStringAsFixed(0);
      if (triggeredByUpcomingPurchase) {
        return 'Adding this item will push inventory over the household $nutrient goal by $overflow% ($details).';
      }
      return 'Inventory currently exceeds the household $nutrient goal by $overflow% ($details).';
    }

    if (triggeredByUpcomingPurchase) {
      return 'Adding this item will bring inventory to about $percent% of the household $nutrient goal ($details).';
    }

    return 'Inventory currently covers about $percent% of the household $nutrient goal ($details).';
  }
}

class HouseholdNutritionAlertsProvider extends ChangeNotifier {
  final AzureTableService _azureService = AzureTableService();
  final LocalStorageService _localStorageService = LocalStorageService();

  bool _isLoading = false;
  bool _usingFallbackGoals = false;
  String? _nutritionGoalSourceNote;

  double? _monthlyCaloriesGoal;
  double? _monthlyProteinGoal;
  double? _monthlyCarbsGoal;
  double? _monthlyFatGoal;
  double? _monthlyFiberGoal;

  bool get isLoading => _isLoading;
  bool get usingFallbackGoals => _usingFallbackGoals;
  String? get nutritionGoalSourceNote => _nutritionGoalSourceNote;

  double? get monthlyCaloriesGoal => _monthlyCaloriesGoal;
  double? get monthlyProteinGoal => _monthlyProteinGoal;
  double? get monthlyCarbsGoal => _monthlyCarbsGoal;
  double? get monthlyFatGoal => _monthlyFatGoal;
  double? get monthlyFiberGoal => _monthlyFiberGoal;

  static const double _nutritionAlertThreshold = 0.9;

  Future<void> loadHouseholdNutrition(NutritionProvider nutritionProvider) async {
    _isLoading = true;
    notifyListeners();

    final fallbackGoals = nutritionProvider.goals;

    try {
      final userId = await LocalStorageService.getUserId();

      if (userId == null) {
        _applyFallbackGoals(
          fallbackGoals: fallbackGoals,
          infoNote: 'Household profile not found. Using personal nutrition goals for alerts.',
        );
        return;
      }

      List<HouseholdMember> members = await _localStorageService.getHouseholdMembers();

      if (members.isEmpty) {
        final remoteMembers = await _azureService.getHouseholdMembers(userId);
        members = remoteMembers.map((entity) => HouseholdMember.fromAzureEntity(entity)).toList();

        if (members.isNotEmpty) {
          await _localStorageService.saveHouseholdMembers(userId, members);
        }
      }

      if (members.isEmpty) {
        _applyFallbackGoals(
          fallbackGoals: fallbackGoals,
          infoNote: 'Household nutrition data unavailable. Showing alerts based on personal goals.',
        );
        return;
      }

      final monthlyCalories = members.fold<double>(0, (sum, m) => sum + m.dailyCalories) * 30;
      final monthlyProtein = members.fold<double>(0, (sum, m) => sum + m.dailyProtein) * 30;
      final monthlyCarbs = members.fold<double>(0, (sum, m) => sum + m.dailyCarbs) * 30;
      final monthlyFat = members.fold<double>(0, (sum, m) => sum + m.dailyFat) * 30;
      final monthlyFiber = members.fold<double>(0, (sum, m) => sum + m.dailyFiber) * 30;

      _monthlyCaloriesGoal = monthlyCalories;
      _monthlyProteinGoal = monthlyProtein;
      _monthlyCarbsGoal = monthlyCarbs;
      _monthlyFatGoal = monthlyFat;
      _monthlyFiberGoal = monthlyFiber;
      _nutritionGoalSourceNote = null;
      _usingFallbackGoals = false;
    } catch (e) {
      _applyFallbackGoals(
        fallbackGoals: fallbackGoals,
        infoNote: 'Unable to load household nutrition. Using personal goals for alerts.',
      );
      debugPrint('Error loading household nutrition: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFallbackGoals({
    required NutritionGoals fallbackGoals,
    required String infoNote,
  }) {
    _monthlyCaloriesGoal = fallbackGoals.dailyCalorieGoal * 30;
    _monthlyProteinGoal = fallbackGoals.dailyProteinGoal * 30;
    _monthlyCarbsGoal = fallbackGoals.dailyCarbsGoal * 30;
    _monthlyFatGoal = fallbackGoals.dailyFatGoal * 30;
    _monthlyFiberGoal = null; // Fiber not in personal goals
    _nutritionGoalSourceNote = infoNote;
    _usingFallbackGoals = true;
    _isLoading = false;
    notifyListeners();
  }

  List<NutritionAlert> calculateAlerts(Map<String, double> inventoryTotals) {
    final alerts = <NutritionAlert>[];

    void evaluate(String key, double? goal, String label, String unit) {
      if (goal == null || goal <= 0) return;
      final inventoryValue = inventoryTotals[key] ?? 0;
      final ratio = goal > 0 ? inventoryValue / goal : 0;
      if (ratio >= _nutritionAlertThreshold) {
        alerts.add(NutritionAlert(
          nutrient: label,
          inventoryValue: inventoryValue,
          goalValue: goal,
          unit: unit,
          triggeredByUpcomingPurchase: false,
        ));
      }
    }

    evaluate('calories', _monthlyCaloriesGoal, 'Calories', 'kcal');
    evaluate('protein', _monthlyProteinGoal, 'Protein', 'g');
    evaluate('carbs', _monthlyCarbsGoal, 'Carbs', 'g');
    evaluate('fat', _monthlyFatGoal, 'Fat', 'g');
    evaluate('fiber', _monthlyFiberGoal, 'Fiber', 'g');

    return alerts;
  }
}
