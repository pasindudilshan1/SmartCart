// Copilot Task 4: Nutrition Screen - Display Nutritional Dashboard
// Shows daily and weekly nutrition tracking with charts

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/nutrition_provider.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showGoalsDialog(context);
            },
          ),
        ],
      ),
      body: Consumer<NutritionProvider>(
        builder: (context, nutritionProvider, child) {
          final todayNutrition = nutritionProvider.todayNutrition;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTodayCard(context, todayNutrition, nutritionProvider),
                const SizedBox(height: 24),
                _buildProgressCards(nutritionProvider),
                const SizedBox(height: 24),
                _buildWeeklyChart(context, nutritionProvider),
                const SizedBox(height: 24),
                _buildNutritionTips(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodayCard(BuildContext context, dynamic todayNutrition,
      NutritionProvider provider) {
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
                _buildNutrientColumn(
                    'Calories', todayNutrition.totalCalories, 'kcal'),
                _buildNutrientColumn(
                    'Protein', todayNutrition.totalProtein, 'g'),
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
                        style: TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
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
                Text(label,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildWeeklyChart(BuildContext context, NutritionProvider provider) {
    final weeklyData = provider.getWeeklyNutrition();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly Calories',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = [
                            'Mon',
                            'Tue',
                            'Wed',
                            'Thu',
                            'Fri',
                            'Sat',
                            'Sun'
                          ];
                          if (value.toInt() >= 0 &&
                              value.toInt() < days.length) {
                            return Text(days[value.toInt()],
                                style: const TextStyle(fontSize: 10));
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles:
                          SideTitles(showTitles: true, reservedSize: 40),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: weeklyData.asMap().entries.map((entry) {
                        return FlSpot(
                            entry.key.toDouble(), entry.value.totalCalories);
                      }).toList(),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
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

    final calorieController =
        TextEditingController(text: goals.dailyCalorieGoal.toString());
    final proteinController =
        TextEditingController(text: goals.dailyProteinGoal.toString());
    final carbsController =
        TextEditingController(text: goals.dailyCarbsGoal.toString());
    final fatController =
        TextEditingController(text: goals.dailyFatGoal.toString());

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
                decoration:
                    const InputDecoration(labelText: 'Daily Calories (kcal)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: proteinController,
                decoration:
                    const InputDecoration(labelText: 'Daily Protein (g)'),
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
              // Save goals
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
