import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nutrition_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/household_nutrition_alerts_provider.dart';
import 'household_nutrition_screen.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  @override
  void initState() {
    super.initState();
    // Load household nutrition for alerts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final alertsProvider = context.read<HouseholdNutritionAlertsProvider>();
      final nutritionProvider = context.read<NutritionProvider>();
      alertsProvider.loadHouseholdNutrition(nutritionProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Tracker'),
        actions: [
          Consumer2<HouseholdNutritionAlertsProvider, InventoryProvider>(
            builder: (context, alertsProvider, inventoryProvider, child) {
              final inventoryTotals = inventoryProvider.getTotalInventoryNutrition();
              final alerts = alertsProvider.calculateAlerts(inventoryTotals);
              final hasAlerts = alerts.isNotEmpty;

              return IconButton(
                tooltip: alertsProvider.isLoading
                    ? 'Loading household nutrition...'
                    : hasAlerts
                        ? 'View nutrition alerts'
                        : 'No nutrition alerts',
                onPressed: () {
                  if (alertsProvider.isLoading) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Still loading household nutrition data...')),
                    );
                    return;
                  }

                  if (alerts.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No household nutrition alerts right now.')),
                    );
                    return;
                  }

                  _showNutritionAlertsSheet(alerts);
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(hasAlerts ? Icons.notifications : Icons.notifications_none),
                    if (alertsProvider.isLoading)
                      const Positioned(
                        right: -2,
                        top: -2,
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    if (!alertsProvider.isLoading && hasAlerts)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.group),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HouseholdNutritionScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer2<NutritionProvider, InventoryProvider>(
        builder: (context, nutritionProvider, inventoryProvider, child) {
          final inventoryNutrition = inventoryProvider.getTotalInventoryNutrition();
          final alertsProvider = context.watch<HouseholdNutritionAlertsProvider>();

          // Calculate household daily nutrition goals
          final householdDailyCalories = (alertsProvider.monthlyCaloriesGoal ?? 0) / 30;
          final householdDailyProtein = (alertsProvider.monthlyProteinGoal ?? 0) / 30;
          final householdDailyCarbs = (alertsProvider.monthlyCarbsGoal ?? 0) / 30;
          final householdDailyFat = (alertsProvider.monthlyFatGoal ?? 0) / 30;
          final householdDailyFiber = (alertsProvider.monthlyFiberGoal ?? 0) / 30;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHouseholdDailyCard(context, householdDailyCalories, householdDailyProtein,
                    householdDailyCarbs, householdDailyFat, householdDailyFiber),
                const SizedBox(height: 24),
                _buildInventoryComparisonCard(context, inventoryNutrition, alertsProvider),
                const SizedBox(height: 24),
                _buildProgressCards(inventoryNutrition, alertsProvider),
                const SizedBox(height: 24),
                _buildNutritionTips(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHouseholdDailyCard(BuildContext context, double calories, double protein,
      double carbs, double fat, double fiber) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Household Daily Nutrition Goals',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientColumn('Calories', calories, 'kcal'),
                _buildNutrientColumn('Protein', protein, 'g'),
                _buildNutrientColumn('Carbs', carbs, 'g'),
                _buildNutrientColumn('Fat', fat, 'g'),
                _buildNutrientColumn('Fiber', fiber, 'g'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientColumn(String label, double value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(0),
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressCards(
      Map<String, double> inventoryNutrition, HouseholdNutritionAlertsProvider alertsProvider) {
    return Column(
      children: [
        _buildProgressBar('Calories', inventoryNutrition['calories'] ?? 0,
            alertsProvider.monthlyCaloriesGoal ?? 0),
        const SizedBox(height: 12),
        _buildProgressBar(
            'Protein', inventoryNutrition['protein'] ?? 0, alertsProvider.monthlyProteinGoal ?? 0),
        const SizedBox(height: 12),
        _buildProgressBar(
            'Carbs', inventoryNutrition['carbs'] ?? 0, alertsProvider.monthlyCarbsGoal ?? 0),
        const SizedBox(height: 12),
        _buildProgressBar(
            'Fat', inventoryNutrition['fat'] ?? 0, alertsProvider.monthlyFatGoal ?? 0),
        const SizedBox(height: 12),
        _buildProgressBar(
            'Fiber', inventoryNutrition['fiber'] ?? 0, alertsProvider.monthlyFiberGoal ?? 0),
      ],
    );
  }

  Widget _buildProgressBar(String label, double inventory, double goal) {
    final percentage = goal > 0 ? (inventory / goal * 100).clamp(0, 999) : 0;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('${percentage.toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: goal > 0 ? (inventory / goal).clamp(0, 1) : 0,
              backgroundColor: Colors.green,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryComparisonCard(BuildContext context, Map<String, double> inventoryNutrition,
      HouseholdNutritionAlertsProvider alertsProvider) {
    final householdMonthlyCalories = alertsProvider.monthlyCaloriesGoal ?? 0;
    final householdMonthlyProtein = alertsProvider.monthlyProteinGoal ?? 0;
    final householdMonthlyCarbs = alertsProvider.monthlyCarbsGoal ?? 0;
    final householdMonthlyFat = alertsProvider.monthlyFatGoal ?? 0;
    final householdMonthlyFiber = alertsProvider.monthlyFiberGoal ?? 0;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.inventory, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Inventory vs Household Goals (Monthly)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildComparisonRow(
                'Calories', inventoryNutrition['calories'] ?? 0, householdMonthlyCalories, 'kcal'),
            const SizedBox(height: 8),
            _buildComparisonRow(
                'Protein', inventoryNutrition['protein'] ?? 0, householdMonthlyProtein, 'g'),
            const SizedBox(height: 8),
            _buildComparisonRow(
                'Carbs', inventoryNutrition['carbs'] ?? 0, householdMonthlyCarbs, 'g'),
            const SizedBox(height: 8),
            _buildComparisonRow('Fat', inventoryNutrition['fat'] ?? 0, householdMonthlyFat, 'g'),
            const SizedBox(height: 8),
            _buildComparisonRow(
                'Fiber', inventoryNutrition['fiber'] ?? 0, householdMonthlyFiber, 'g'),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow(
      String label, double inventoryValue, double householdValue, String unit) {
    final percentage = householdValue > 0 ? (inventoryValue / householdValue) * 100 : 0;
    final isOver = inventoryValue > householdValue;
    final color = isOver ? Colors.red : Colors.green;

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        ),
        Expanded(
          flex: 2,
          child: Text(
            '${inventoryValue.toStringAsFixed(0)} / ${householdValue.toStringAsFixed(0)} $unit',
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          flex: 1,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: TextStyle(color: color, fontSize: 12),
              ),
              const SizedBox(width: 4),
              Icon(
                isOver ? Icons.warning : Icons.check_circle,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionTips(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Nutrition Tips',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('• Balance your macronutrients for optimal health'),
            const Text('• Stay within your calorie goals to maintain weight'),
            const Text('• Choose products with higher nutrition scores'),
            const Text('• Track regularly to build healthy habits'),
          ],
        ),
      ),
    );
  }

  void _showNutritionAlertsSheet(List<NutritionAlert> alerts) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Household Nutrition Alerts',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...alerts.map(_buildAlertTile),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertTile(NutritionAlert alert) {
    final color = alert.isCritical ? Colors.red : Colors.orange;
    final icon = alert.isCritical ? Icons.warning_amber_rounded : Icons.info_outline;

    return Card(
      color: color.withValues(alpha: 0.08),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          alert.headline,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(alert.description),
      ),
    );
  }
}
