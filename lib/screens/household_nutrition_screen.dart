// Household Nutrition Screen - Monthly Household Nutrition Overview
// Shows total household nutrition for the month and breakdowns by member

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/azure_auth_service.dart';
import '../services/azure_table_service.dart';
import '../models/household_member.dart';

class HouseholdNutritionScreen extends StatefulWidget {
  const HouseholdNutritionScreen({super.key});

  @override
  State<HouseholdNutritionScreen> createState() => _HouseholdNutritionScreenState();
}

class _HouseholdNutritionScreenState extends State<HouseholdNutritionScreen> {
  final AzureTableService _azureTableService = AzureTableService();
  List<HouseholdMember> _members = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    final authService = Provider.of<AzureAuthService>(context, listen: false);
    final userId = authService.currentUserId;

    if (userId == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final membersData = await _azureTableService.getHouseholdMembers(userId);
      _members = membersData
          .map((data) {
            try {
              final member = HouseholdMember.fromAzureEntity(data);
              return member;
            } catch (e) {
              return null;
            }
          })
          .where((member) => member != null)
          .cast<HouseholdMember>()
          .toList();
    } catch (e) {
      // Handle error
    }

    setState(() {
      _isLoading = false;
    });
  }

  // Calculate monthly totals (daily * 30)
  double getMonthlyCalories() {
    return _members.fold(0.0, (sum, member) => sum + member.dailyCalories) * 30;
  }

  double getMonthlyProtein() {
    return _members.fold(0.0, (sum, member) => sum + member.dailyProtein) * 30;
  }

  double getMonthlyCarbs() {
    return _members.fold(0.0, (sum, member) => sum + member.dailyCarbs) * 30;
  }

  double getMonthlyFat() {
    return _members.fold(0.0, (sum, member) => sum + member.dailyFat) * 30;
  }

  double getMonthlyFiber() {
    return _members.fold(0.0, (sum, member) => sum + member.dailyFiber) * 30;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Household Nutrition'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Household Nutrition Goals',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildNutrientCard('Calories', getMonthlyCalories(), 'kcal',
                Icons.local_fire_department, Colors.orange),
            const SizedBox(height: 12),
            _buildNutrientCard(
                'Protein', getMonthlyProtein(), 'g', Icons.fitness_center, Colors.red),
            const SizedBox(height: 12),
            _buildNutrientCard(
                'Carbohydrates', getMonthlyCarbs(), 'g', Icons.bakery_dining, Colors.amber),
            const SizedBox(height: 12),
            _buildNutrientCard('Fat', getMonthlyFat(), 'g', Icons.opacity, const Color(0xFFFFA726)),
            const SizedBox(height: 12),
            _buildNutrientCard('Fiber', getMonthlyFiber(), 'g', Icons.grass, Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientCard(String label, double value, String unit, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      elevation: 3,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () => _showMemberBreakdown(context, label),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                color.withOpacity(0.05),
              ],
            ),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color,
                      color.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${value.toStringAsFixed(0)} $unit',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: color,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMemberBreakdown(BuildContext context, String nutrient) {
    showModalBottomSheet(
      context: context,
      builder: (context) => MemberNutritionBreakdown(
        nutrient: nutrient,
        members: _members,
      ),
    );
  }
}

class MemberNutritionBreakdown extends StatelessWidget {
  final String nutrient;
  final List<HouseholdMember> members;

  const MemberNutritionBreakdown({
    super.key,
    required this.nutrient,
    required this.members,
  });

  double _getMemberValue(HouseholdMember member) {
    switch (nutrient) {
      case 'Calories':
        return member.dailyCalories * 30;
      case 'Protein':
        return member.dailyProtein * 30;
      case 'Carbohydrates':
        return member.dailyCarbs * 30;
      case 'Fat':
        return member.dailyFat * 30;
      case 'Fiber':
        return member.dailyFiber * 30;
      default:
        return 0.0;
    }
  }

  String _getUnit() {
    switch (nutrient) {
      case 'Calories':
        return 'kcal';
      default:
        return 'g';
    }
  }

  Color _getNutrientColor() {
    switch (nutrient) {
      case 'Calories':
        return Colors.orange;
      case 'Protein':
        return Colors.red;
      case 'Carbohydrates':
        return Colors.amber;
      case 'Fat':
        return const Color(0xFFFFA726);
      case 'Fiber':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getNutrientIcon() {
    switch (nutrient) {
      case 'Calories':
        return Icons.local_fire_department;
      case 'Protein':
        return Icons.fitness_center;
      case 'Carbohydrates':
        return Icons.bakery_dining;
      case 'Fat':
        return Icons.opacity;
      case 'Fiber':
        return Icons.grass;
      default:
        return Icons.restaurant;
    }
  }

  List<Color> _getAgeGroupColors(String ageGroup) {
    switch (ageGroup.toLowerCase()) {
      case 'infant':
        return [Colors.pink, Colors.pinkAccent];
      case 'child':
        return [Colors.blue, Colors.blueAccent];
      case 'teen':
        return [Colors.purple, Colors.purpleAccent];
      case 'adult':
        return [Colors.teal, Colors.tealAccent];
      case 'senior':
        return [Colors.orange, Colors.orangeAccent];
      default:
        return [Colors.grey, Colors.grey.shade400];
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getNutrientColor();
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  _getNutrientIcon(),
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$nutrient Breakdown by Member',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...members.map((member) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white,
                      _getAgeGroupColors(member.ageGroup)[0].withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _getAgeGroupColors(member.ageGroup)[0].withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _getAgeGroupColors(member.ageGroup),
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (member.name != null && member.name!.isNotEmpty)
                              ? member.name!.substring(0, 1).toUpperCase()
                              : 'M',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name ?? 'Member ${member.memberIndex}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            member.ageGroup,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: color.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        '${_getMemberValue(member).toStringAsFixed(0)} ${_getUnit()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
