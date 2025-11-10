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
            _buildNutrientCard('Calories', getMonthlyCalories(), 'kcal'),
            const SizedBox(height: 16),
            _buildNutrientCard('Protein', getMonthlyProtein(), 'g'),
            const SizedBox(height: 16),
            _buildNutrientCard('Carbohydrates', getMonthlyCarbs(), 'g'),
            const SizedBox(height: 16),
            _buildNutrientCard('Fat', getMonthlyFat(), 'g'),
            const SizedBox(height: 16),
            _buildNutrientCard('Fiber', getMonthlyFiber(), 'g'),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientCard(String label, double value, String unit) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _showMemberBreakdown(context, label),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              Text(
                '${value.toStringAsFixed(0)} $unit',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.arrow_forward_ios),
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$nutrient Breakdown by Member',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...members.map((member) => ListTile(
                title: Text(member.name ?? 'Member ${member.memberIndex}'),
                subtitle: Text(member.ageGroup),
                trailing: Text(
                  '${_getMemberValue(member).toStringAsFixed(0)} ${_getUnit()}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              )),
        ],
      ),
    );
  }
}
