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
                    Icon(hasAlerts
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_outlined),
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
                            gradient: const LinearGradient(colors: [Colors.red, Colors.redAccent]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.group_outlined),
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const HouseholdNutritionScreen(),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    const begin = Offset(1.0, 0.0);
                    const end = Offset.zero;
                    const curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    var offsetAnimation = animation.drive(tween);
                    return SlideTransition(position: offsetAnimation, child: child);
                  },
                ),
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
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: _buildHouseholdDailyCard(
                            context,
                            householdDailyCalories,
                            householdDailyProtein,
                            householdDailyCarbs,
                            householdDailyFat,
                            householdDailyFiber),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 700),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: _buildInventoryComparisonCard(
                            context, inventoryNutrition, alertsProvider),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 800),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: _buildProgressCards(inventoryNutrition, alertsProvider),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 900),
                  builder: (context, value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: _buildNutritionTips(context),
                      ),
                    );
                  },
                ),
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
      elevation: 4,
      shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.restaurant_menu_outlined,
                      color: Theme.of(context).colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Household Daily Nutrition Goals',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
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
      ),
    );
  }

  Widget _buildNutrientColumn(String label, double value, String unit) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: value),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeOut,
      builder: (context, animatedValue, child) {
        return Expanded(
          child: Column(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      animatedValue.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.7,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange, Colors.orangeAccent],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.notifications_active_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Household Nutrition Alerts',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_outlined,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (alerts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              size: 48,
                              color: Colors.green,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'All good! No alerts right now.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: alerts.length,
                        itemBuilder: (context, index) {
                          final alert = alerts[index];
                          return TweenAnimationBuilder<double>(
                            tween: Tween<double>(begin: 0.0, end: 1.0),
                            duration: Duration(milliseconds: 300 + (index * 100)),
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: _buildAlertTile(alert),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertTile(NutritionAlert alert) {
    final color = alert.isCritical ? Colors.red : Colors.orange;
    final emoji = alert.isCritical ? '🚨' : '⚠️';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.05),
              color.withOpacity(0.02),
            ],
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              shape: BoxShape.circle,
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          title: Text(
            alert.headline,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              alert.description,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
