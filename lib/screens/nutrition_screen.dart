import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/nutrition_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/household_nutrition_alerts_provider.dart';
import '../models/nutrition.dart';
import 'household_nutrition_screen.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  String _selectedChart = 'comparison';

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
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showGoalsDialog(context);
            },
          ),
        ],
      ),
      body: Consumer2<NutritionProvider, InventoryProvider>(
        builder: (context, nutritionProvider, inventoryProvider, child) {
          final todayNutrition = nutritionProvider.todayNutrition;
          final inventoryNutrition = inventoryProvider.getTotalInventoryNutrition();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTodayCard(context, todayNutrition, nutritionProvider),
                const SizedBox(height: 24),
                _buildInventoryComparisonCard(context, inventoryNutrition, nutritionProvider),
                const SizedBox(height: 24),
                _buildProgressCards(nutritionProvider),
                const SizedBox(height: 24),
                _buildChartSelector(context, nutritionProvider, inventoryNutrition),
                const SizedBox(height: 24),
                _buildNutritionTips(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodayCard(BuildContext context, dynamic todayNutrition, NutritionProvider provider) {
    final isOverLimit = provider.isCalorieLimitExceeded;

    return Card(
      color: isOverLimit ? Colors.red.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Nutrition',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (isOverLimit) const Icon(Icons.warning, color: Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientColumn('Calories', todayNutrition.totalCalories, 'kcal'),
                _buildNutrientColumn('Protein', todayNutrition.totalProtein, 'g'),
                _buildNutrientColumn('Carbs', todayNutrition.totalCarbs, 'g'),
                _buildNutrientColumn('Fat', todayNutrition.totalFat, 'g'),
              ],
            ),
            if (isOverLimit) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber, size: 16, color: Colors.red),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You\'ve exceeded your daily calorie goal!',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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

  Widget _buildProgressCards(NutritionProvider provider) {
    return Column(
      children: [
        _buildProgressBar('Calories', provider.calorieProgress, Colors.orange),
        const SizedBox(height: 12),
        _buildProgressBar('Protein', provider.proteinProgress, Colors.red),
        const SizedBox(height: 12),
        _buildProgressBar('Carbs', provider.carbsProgress, Colors.blue),
        const SizedBox(height: 12),
        _buildProgressBar('Fat', provider.fatProgress, Colors.yellow),
      ],
    );
  }

  Widget _buildProgressBar(String label, double progress, Color color) {
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
                Text('${progress.toStringAsFixed(0)}%'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryComparisonCard(BuildContext context, Map<String, double> inventoryNutrition,
      NutritionProvider nutritionProvider) {
    final householdMonthlyCalories = nutritionProvider.goals.dailyCalorieGoal * 30;
    final householdMonthlyProtein = nutritionProvider.goals.dailyProteinGoal * 30;
    final householdMonthlyCarbs = nutritionProvider.goals.dailyCarbsGoal * 30;
    final householdMonthlyFat = nutritionProvider.goals.dailyFatGoal * 30;

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

  Widget _buildChartSelector(BuildContext context, NutritionProvider nutritionProvider,
      Map<String, double> inventoryNutrition) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrition Charts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            DropdownButton<String>(
              value: _selectedChart,
              items: const [
                DropdownMenuItem(value: 'comparison', child: Text('Consumption vs Inventory')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly Goals')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedChart = value;
                  });
                }
              },
              isExpanded: true,
            ),
            const SizedBox(height: 16),
            _buildSelectedChart(context, nutritionProvider, inventoryNutrition),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedChart(BuildContext context, NutritionProvider nutritionProvider,
      Map<String, double> inventoryNutrition) {
    switch (_selectedChart) {
      case 'comparison':
        return _buildComparisonChart(context, nutritionProvider, inventoryNutrition);
      case 'monthly':
        return _buildMonthlyGoalsChart(context, nutritionProvider);
      default:
        return _buildComparisonChart(context, nutritionProvider, inventoryNutrition);
    }
  }

  Widget _buildComparisonChart(BuildContext context, NutritionProvider nutritionProvider,
      Map<String, double> inventoryNutrition) {
    final weeklyData = nutritionProvider.getWeeklyNutrition();
    final todayInventoryCalories = inventoryNutrition['calories'] ?? 0;

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  if (value.toInt() >= 0 && value.toInt() < days.length) {
                    return Text(days[value.toInt()], style: const TextStyle(fontSize: 10));
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: weeklyData.asMap().entries.map((entry) {
                return FlSpot(entry.key.toDouble(), entry.value.totalCalories);
              }).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots:
                  List.generate(7, (index) => FlSpot(index.toDouble(), todayInventoryCalories / 7)),
              isCurved: false,
              color: Colors.green,
              barWidth: 2,
              dotData: const FlDotData(show: false),
              dashArray: [5, 5],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyGoalsChart(BuildContext context, NutritionProvider nutritionProvider) {
    // Calculate monthly goals and current consumption
    final goals = nutritionProvider.goals;
    final monthlyCalorieGoal = goals.dailyCalorieGoal * 30;
    final monthlyProteinGoal = goals.dailyProteinGoal * 30;
    final monthlyCarbsGoal = goals.dailyCarbsGoal * 30;
    final monthlyFatGoal = goals.dailyFatGoal * 30;

    // Get current month's consumption (simplified - using weekly data * 4)
    final weeklyData = nutritionProvider.getWeeklyNutrition();
    final currentWeekTotal =
        weeklyData.isNotEmpty ? weeklyData.last : nutritionProvider.todayNutrition;
    final estimatedMonthlyCalories = currentWeekTotal.totalCalories * 4;
    final estimatedMonthlyProtein = currentWeekTotal.totalProtein * 4;
    final estimatedMonthlyCarbs = currentWeekTotal.totalCarbs * 4;
    final estimatedMonthlyFat = currentWeekTotal.totalFat * 4;

    final data = [
      {'label': 'Calories', 'actual': estimatedMonthlyCalories, 'goal': monthlyCalorieGoal},
      {'label': 'Protein', 'actual': estimatedMonthlyProtein, 'goal': monthlyProteinGoal},
      {'label': 'Carbs', 'actual': estimatedMonthlyCarbs, 'goal': monthlyCarbsGoal},
      {'label': 'Fat', 'actual': estimatedMonthlyFat, 'goal': monthlyFatGoal},
    ];

    return SizedBox(
      height: 300,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: data.map((d) => (d['goal'] as double) * 1.2).reduce((a, b) => a > b ? a : b),
          barGroups: data.asMap().entries.map((entry) {
            final item = entry.value;
            final actual = item['actual'] as double;
            final goal = item['goal'] as double;
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                  toY: actual,
                  color: actual > goal ? Colors.red : Colors.blue,
                  width: 20,
                ),
                BarChartRodData(
                  toY: goal,
                  color: Colors.green.withOpacity(0.7),
                  width: 20,
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < data.length) {
                    return Text(data[value.toInt()]['label'] as String,
                        style: const TextStyle(fontSize: 10));
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: true),
        ),
      ),
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

  void _showGoalsDialog(BuildContext context) {
    final provider = context.read<NutritionProvider>();
    final goals = provider.goals;

    final calorieController = TextEditingController(text: goals.dailyCalorieGoal.toString());
    final proteinController = TextEditingController(text: goals.dailyProteinGoal.toString());
    final carbsController = TextEditingController(text: goals.dailyCarbsGoal.toString());
    final fatController = TextEditingController(text: goals.dailyFatGoal.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Nutrition Goals'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: calorieController,
                decoration: const InputDecoration(labelText: 'Daily Calories (kcal)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: proteinController,
                decoration: const InputDecoration(labelText: 'Daily Protein (g)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: carbsController,
                decoration: const InputDecoration(labelText: 'Daily Carbs (g)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: fatController,
                decoration: const InputDecoration(labelText: 'Daily Fat (g)'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Parse values and save goals
              final calorieGoal = double.tryParse(calorieController.text) ?? goals.dailyCalorieGoal;
              final proteinGoal = double.tryParse(proteinController.text) ?? goals.dailyProteinGoal;
              final carbsGoal = double.tryParse(carbsController.text) ?? goals.dailyCarbsGoal;
              final fatGoal = double.tryParse(fatController.text) ?? goals.dailyFatGoal;

              final newGoals = NutritionGoals(
                dailyCalorieGoal: calorieGoal,
                dailyProteinGoal: proteinGoal,
                dailyCarbsGoal: carbsGoal,
                dailyFatGoal: fatGoal,
              );

              provider.updateGoals(newGoals);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
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
      color: color.withOpacity(0.08),
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
