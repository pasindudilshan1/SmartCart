import 'package:flutter/material.dart';
import '../models/household_member.dart';

/// Widget to display household member information
class HouseholdInfoCard extends StatelessWidget {
  final List<HouseholdMember> members;

  const HouseholdInfoCard({
    super.key,
    required this.members,
  });

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const Card(
        margin: EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No household members found'),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.home, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Household Members',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${members.length} ${members.length == 1 ? 'member' : 'members'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const Divider(height: 24),
            ...members.map((member) => _buildMemberTile(context, member)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.local_fire_department, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  'Total daily calories: ${_calculateTotalCalories()}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(BuildContext context, HouseholdMember member) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              member.name?.isNotEmpty == true
                  ? member.name![0].toUpperCase()
                  : '#${member.memberIndex}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name?.isNotEmpty == true ? member.name! : 'Member ${member.memberIndex}',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.restaurant, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${member.dailyCalories.toStringAsFixed(0)} cal/day (${member.ageGroup})',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotalCalories() {
    return members.fold(0.0, (sum, member) => sum + member.dailyCalories);
  }
}
