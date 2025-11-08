// Household Management Screen - View and Edit Household Members

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/azure_auth_service.dart';
import '../services/azure_table_service.dart';
import '../models/household_member.dart';

class HouseholdManagementScreen extends StatefulWidget {
  const HouseholdManagementScreen({super.key});

  @override
  State<HouseholdManagementScreen> createState() => _HouseholdManagementScreenState();
}

class _HouseholdManagementScreenState extends State<HouseholdManagementScreen> {
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

  Future<void> _updateMember(HouseholdMember member) async {
    final authService = Provider.of<AzureAuthService>(context, listen: false);
    final userId = authService.currentUserId;

    if (userId == null) return;

    try {
      await _azureTableService.updateHouseholdMember(
        userId,
        member.memberIndex,
        member.ageGroup,
        member.dailyCalories,
        member.dailyProtein,
        member.dailyFat,
        member.dailyCarbs,
        member.dailyFiber,
        name: member.name,
      );
      _loadMembers(); // Reload to reflect changes
    } catch (e) {
      // Handle error
    }
  }

  void _editMember(HouseholdMember member) {
    // Show dialog to edit member
    showDialog(
      context: context,
      builder: (context) => EditMemberDialog(
        member: member,
        onSave: _updateMember,
      ),
    );
  }

  void _addMember() {
    // Show dialog to add new member
    showDialog(
      context: context,
      builder: (context) => AddMemberDialog(
        existingMembers: _members,
        onSave: _saveNewMember,
      ),
    );
  }

  Future<void> _saveNewMember(HouseholdMember member) async {
    final authService = Provider.of<AzureAuthService>(context, listen: false);
    final userId = authService.currentUserId;

    if (userId == null) return;

    try {
      await _azureTableService.storeHouseholdMember(
        userId,
        member.memberIndex,
        member.ageGroup,
        member.dailyCalories,
        member.dailyProtein,
        member.dailyFat,
        member.dailyCarbs,
        member.dailyFiber,
        name: member.name,
      );
      _loadMembers(); // Reload to reflect changes
    } catch (e) {
      // Handle error
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Household Members'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _members.isEmpty
              ? const Center(child: Text('No household members found'))
              : ListView.builder(
                  itemCount: _members.length,
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    return Card(
                      margin: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(member.name ?? 'Member ${member.memberIndex}'),
                        subtitle: Text(
                          'Age Group: ${member.ageGroup}\n'
                          'Calories: ${member.dailyCalories}g\n'
                          'Protein: ${member.dailyProtein}g\n'
                          'Fat: ${member.dailyFat}g\n'
                          'Carbs: ${member.dailyCarbs}g\n'
                          'Fiber: ${member.dailyFiber}g',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () => _editMember(member),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addMember,
        tooltip: 'Add Member',
        child: const Icon(Icons.add),
      ),
    );
  }
}

class EditMemberDialog extends StatefulWidget {
  final HouseholdMember member;
  final Function(HouseholdMember) onSave;

  const EditMemberDialog({super.key, required this.member, required this.onSave});

  @override
  State<EditMemberDialog> createState() => _EditMemberDialogState();
}

class _EditMemberDialogState extends State<EditMemberDialog> {
  late String _ageGroup;
  late double _dailyCalories;
  late double _dailyProtein;
  late double _dailyFat;
  late double _dailyCarbs;
  late double _dailyFiber;
  late String? _name;

  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _fatController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fiberController;

  final Map<String, Map<String, double>> _ageGroupDefaults = {
    'infant': {'calories': 800, 'protein': 15, 'fat': 30, 'carbs': 100, 'fiber': 5},
    'child': {'calories': 1600, 'protein': 30, 'fat': 50, 'carbs': 200, 'fiber': 20},
    'teen': {'calories': 2200, 'protein': 45, 'fat': 65, 'carbs': 275, 'fiber': 25},
    'adult': {'calories': 2000, 'protein': 50, 'fat': 70, 'carbs': 250, 'fiber': 25},
    'senior': {'calories': 1800, 'protein': 45, 'fat': 60, 'carbs': 225, 'fiber': 25},
  };

  @override
  void initState() {
    super.initState();
    _ageGroup = widget.member.ageGroup;
    _dailyCalories = widget.member.dailyCalories;
    _dailyProtein = widget.member.dailyProtein;
    _dailyFat = widget.member.dailyFat;
    _dailyCarbs = widget.member.dailyCarbs;
    _dailyFiber = widget.member.dailyFiber;
    _name = widget.member.name;

    _caloriesController = TextEditingController(text: _dailyCalories.toString());
    _proteinController = TextEditingController(text: _dailyProtein.toString());
    _fatController = TextEditingController(text: _dailyFat.toString());
    _carbsController = TextEditingController(text: _dailyCarbs.toString());
    _fiberController = TextEditingController(text: _dailyFiber.toString());
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    _fiberController.dispose();
    super.dispose();
  }

  void _setDefaults() {
    final defaults = _ageGroupDefaults[_ageGroup]!;
    setState(() {
      _dailyCalories = defaults['calories']!;
      _dailyProtein = defaults['protein']!;
      _dailyFat = defaults['fat']!;
      _dailyCarbs = defaults['carbs']!;
      _dailyFiber = defaults['fiber']!;

      _caloriesController.text = _dailyCalories.toString();
      _proteinController.text = _dailyProtein.toString();
      _fatController.text = _dailyFat.toString();
      _carbsController.text = _dailyCarbs.toString();
      _fiberController.text = _dailyFiber.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Edit ${widget.member.name ?? 'Member ${widget.member.memberIndex}'}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (value) => _name = value.isEmpty ? null : value,
            ),
            DropdownButtonFormField<String>(
              initialValue: _ageGroup,
              decoration: const InputDecoration(labelText: 'Age Group'),
              items: _ageGroupDefaults.keys.map((group) {
                String displayName;
                switch (group) {
                  case 'infant':
                    displayName = 'Infant (0-1 year)';
                    break;
                  case 'child':
                    displayName = 'Child (2-10 years)';
                    break;
                  case 'teen':
                    displayName = 'Teen (11-18 years)';
                    break;
                  case 'adult':
                    displayName = 'Adult (19-50 years)';
                    break;
                  case 'senior':
                    displayName = 'Senior (51+ years)';
                    break;
                  default:
                    displayName = group;
                }
                return DropdownMenuItem(value: group, child: Text(displayName));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _ageGroup = value;
                    _setDefaults();
                  });
                }
              },
            ),
            TextFormField(
              controller: _caloriesController,
              decoration: const InputDecoration(labelText: 'Daily Calories'),
              keyboardType: TextInputType.number,
              onChanged: (value) => _dailyCalories = double.tryParse(value) ?? _dailyCalories,
            ),
            TextFormField(
              controller: _proteinController,
              decoration: const InputDecoration(labelText: 'Daily Protein (g)'),
              keyboardType: TextInputType.number,
              onChanged: (value) => _dailyProtein = double.tryParse(value) ?? _dailyProtein,
            ),
            TextFormField(
              controller: _fatController,
              decoration: const InputDecoration(labelText: 'Daily Fat (g)'),
              keyboardType: TextInputType.number,
              onChanged: (value) => _dailyFat = double.tryParse(value) ?? _dailyFat,
            ),
            TextFormField(
              controller: _carbsController,
              decoration: const InputDecoration(labelText: 'Daily Carbs (g)'),
              keyboardType: TextInputType.number,
              onChanged: (value) => _dailyCarbs = double.tryParse(value) ?? _dailyCarbs,
            ),
            TextFormField(
              controller: _fiberController,
              decoration: const InputDecoration(labelText: 'Daily Fiber (g)'),
              keyboardType: TextInputType.number,
              onChanged: (value) => _dailyFiber = double.tryParse(value) ?? _dailyFiber,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updatedMember = HouseholdMember(
              id: widget.member.id,
              memberIndex: widget.member.memberIndex,
              ageGroup: _ageGroup,
              dailyCalories: _dailyCalories,
              dailyProtein: _dailyProtein,
              dailyFat: _dailyFat,
              dailyCarbs: _dailyCarbs,
              dailyFiber: _dailyFiber,
              name: _name,
              createdAt: widget.member.createdAt,
              updatedAt: DateTime.now(),
            );
            widget.onSave(updatedMember);
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class AddMemberDialog extends StatefulWidget {
  final List<HouseholdMember> existingMembers;
  final Function(HouseholdMember) onSave;

  const AddMemberDialog({super.key, required this.existingMembers, required this.onSave});

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  late String _ageGroup;
  late double _dailyCalories;
  late double _dailyProtein;
  late double _dailyFat;
  late double _dailyCarbs;
  late double _dailyFiber;
  late String? _name;

  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _fatController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fiberController;

  final Map<String, Map<String, double>> _ageGroupDefaults = {
    'infant': {'calories': 800, 'protein': 15, 'fat': 30, 'carbs': 100, 'fiber': 5},
    'child': {'calories': 1600, 'protein': 30, 'fat': 50, 'carbs': 200, 'fiber': 20},
    'teen': {'calories': 2200, 'protein': 45, 'fat': 65, 'carbs': 275, 'fiber': 25},
    'adult': {'calories': 2000, 'protein': 50, 'fat': 70, 'carbs': 250, 'fiber': 25},
    'senior': {'calories': 1800, 'protein': 45, 'fat': 60, 'carbs': 225, 'fiber': 25},
  };

  @override
  void initState() {
    super.initState();
    _ageGroup = 'adult';
    final defaults = _ageGroupDefaults[_ageGroup]!;
    _dailyCalories = defaults['calories']!;
    _dailyProtein = defaults['protein']!;
    _dailyFat = defaults['fat']!;
    _dailyCarbs = defaults['carbs']!;
    _dailyFiber = defaults['fiber']!;
    _name = null;

    _caloriesController = TextEditingController(text: _dailyCalories.toString());
    _proteinController = TextEditingController(text: _dailyProtein.toString());
    _fatController = TextEditingController(text: _dailyFat.toString());
    _carbsController = TextEditingController(text: _dailyCarbs.toString());
    _fiberController = TextEditingController(text: _dailyFiber.toString());
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _fatController.dispose();
    _carbsController.dispose();
    _fiberController.dispose();
    super.dispose();
  }

  void _setDefaults() {
    final defaults = _ageGroupDefaults[_ageGroup]!;
    setState(() {
      _dailyCalories = defaults['calories']!;
      _dailyProtein = defaults['protein']!;
      _dailyFat = defaults['fat']!;
      _dailyCarbs = defaults['carbs']!;
      _dailyFiber = defaults['fiber']!;

      _caloriesController.text = _dailyCalories.toString();
      _proteinController.text = _dailyProtein.toString();
      _fatController.text = _dailyFat.toString();
      _carbsController.text = _dailyCarbs.toString();
      _fiberController.text = _dailyFiber.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Household Member'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Name (Optional)'),
              onChanged: (value) => _name = value.isEmpty ? null : value,
            ),
            DropdownButtonFormField<String>(
              initialValue: _ageGroup,
              decoration: const InputDecoration(labelText: 'Age Group'),
              items: _ageGroupDefaults.keys.map((group) {
                String displayName;
                switch (group) {
                  case 'infant':
                    displayName = 'Infant (0-1 year)';
                    break;
                  case 'child':
                    displayName = 'Child (2-10 years)';
                    break;
                  case 'teen':
                    displayName = 'Teen (11-18 years)';
                    break;
                  case 'adult':
                    displayName = 'Adult (19-50 years)';
                    break;
                  case 'senior':
                    displayName = 'Senior (51+ years)';
                    break;
                  default:
                    displayName = group;
                }
                return DropdownMenuItem(value: group, child: Text(displayName));
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _ageGroup = value;
                    _setDefaults();
                  });
                }
              },
            ),
            TextFormField(
              controller: _caloriesController,
              decoration: const InputDecoration(labelText: 'Daily Calories'),
              keyboardType: TextInputType.number,
              onChanged: (value) => _dailyCalories = double.tryParse(value) ?? _dailyCalories,
            ),
            TextFormField(
              controller: _proteinController,
              decoration: const InputDecoration(labelText: 'Daily Protein (g)'),
              keyboardType: TextInputType.number,
              onChanged: (value) => _dailyProtein = double.tryParse(value) ?? _dailyProtein,
            ),
            TextFormField(
              controller: _fatController,
              decoration: const InputDecoration(labelText: 'Daily Fat (g)'),
              keyboardType: TextInputType.number,
              onChanged: (value) => _dailyFat = double.tryParse(value) ?? _dailyFat,
            ),
            TextFormField(
              controller: _carbsController,
              decoration: const InputDecoration(labelText: 'Daily Carbs (g)'),
              keyboardType: TextInputType.number,
              onChanged: (value) => _dailyCarbs = double.tryParse(value) ?? _dailyCarbs,
            ),
            TextFormField(
              controller: _fiberController,
              decoration: const InputDecoration(labelText: 'Daily Fiber (g)'),
              keyboardType: TextInputType.number,
              onChanged: (value) => _dailyFiber = double.tryParse(value) ?? _dailyFiber,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Calculate next member index
            final memberIndex = (widget.existingMembers.isEmpty
                    ? 0
                    : widget.existingMembers
                        .map((m) => m.memberIndex)
                        .reduce((a, b) => a > b ? a : b)) +
                1;

            final newMember = HouseholdMember(
              id: 'member_$memberIndex',
              memberIndex: memberIndex,
              ageGroup: _ageGroup,
              dailyCalories: _dailyCalories,
              dailyProtein: _dailyProtein,
              dailyFat: _dailyFat,
              dailyCarbs: _dailyCarbs,
              dailyFiber: _dailyFiber,
              name: _name,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );
            widget.onSave(newMember);
            Navigator.of(context).pop();
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
