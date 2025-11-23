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
    if (_members.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Upgrade to premium to add more than 5 household members'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
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

  Future<void> _deleteMember(HouseholdMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Member'),
        content: Text(
            'Are you sure you want to delete ${member.name ?? 'Member ${member.memberIndex}'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final authService = Provider.of<AzureAuthService>(context, listen: false);
      final userId = authService.currentUserId;

      if (userId == null) return;

      try {
        await _azureTableService.deleteHouseholdMember(userId, member.memberIndex);
        _loadMembers(); // Reload to reflect changes
      } catch (e) {
        // Handle error
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Household Members'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outlined),
            onPressed: () {
              // Show info about household management
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Household Management'),
                  content: const Text(
                    'Manage your household members and their nutritional needs. '
                    'Each member\'s age group determines their daily nutrition goals.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withOpacity(0.8),
            ],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _members.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.family_restroom_outlined,
                          size: 80,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No household members yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add your first family member to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _addMember,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Member'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _members.length,
                          itemBuilder: (context, index) {
                            final member = _members[index];
                            return TweenAnimationBuilder<double>(
                              tween: Tween<double>(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 400 + (index * 100)),
                              builder: (context, itemValue, child) {
                                return Opacity(
                                  opacity: itemValue,
                                  child: Transform.translate(
                                    offset: Offset(0, 20 * (1 - itemValue)),
                                    child: _buildMemberCard(member, index),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addMember,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add Member'),
        elevation: 6,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget _buildMemberCard(HouseholdMember member, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: _getAgeGroupColors(member.ageGroup)[0].withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              _getAgeGroupColors(member.ageGroup)[0].withOpacity(0.03),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar and actions
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: _getAgeGroupColors(member.ageGroup),
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _getAgeGroupColors(member.ageGroup)[0].withOpacity(0.4),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getAgeGroupIcon(member.ageGroup),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name ?? 'Member ${member.memberIndex}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getAgeGroupColors(member.ageGroup)[0].withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            member.ageGroup,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _getAgeGroupColors(member.ageGroup)[1],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        Icons.edit_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 18,
                      ),
                      onPressed: () => _editMember(member),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      padding: const EdgeInsets.all(4),
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        Icons.delete_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                      onPressed: () => _deleteMember(member),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Nutrition information section
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 14,
                          color: Colors.grey.shade700,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Daily Nutrition Goals',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildNutrientChip(
                            '🔥', '${member.dailyCalories.toInt()} kcal', Colors.orange),
                        _buildNutrientChip('🥩', '${member.dailyProtein.toInt()}g', Colors.red),
                        _buildNutrientChip('🍞', '${member.dailyCarbs.toInt()}g', Colors.amber),
                        _buildNutrientChip(
                            '🥑', '${member.dailyFat.toInt()}g', Colors.yellow.shade700),
                        _buildNutrientChip('🥦', '${member.dailyFiber.toInt()}g', Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String emoji, String value, [Color? color]) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: chipColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: chipColor.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getAgeGroupColors(String ageGroup) {
    switch (ageGroup.toLowerCase()) {
      case 'infant':
        return [Colors.pink, Colors.pinkAccent];
      case 'child':
        return [Colors.blue, Colors.blueAccent];
      case 'teen':
        return [Colors.green, Colors.greenAccent];
      case 'adult':
        return [Colors.purple, Colors.purpleAccent];
      case 'senior':
        return [Colors.orange, Colors.orangeAccent];
      default:
        return [Colors.grey, Colors.grey.shade400];
    }
  }

  IconData _getAgeGroupIcon(String ageGroup) {
    switch (ageGroup.toLowerCase()) {
      case 'infant':
        return Icons.child_care_outlined;
      case 'child':
        return Icons.child_friendly_outlined;
      case 'teen':
        return Icons.school_outlined;
      case 'adult':
        return Icons.person_outlined;
      case 'senior':
        return Icons.elderly_outlined;
      default:
        return Icons.person_outlined;
    }
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 400,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getAgeGroupColors(_ageGroup),
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getAgeGroupIcon(_ageGroup),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Edit ${widget.member.name ?? 'Member ${widget.member.memberIndex}'}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_outlined,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: _name,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          prefixIcon: const Icon(Icons.person_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        ),
                        onChanged: (value) => _name = value.isEmpty ? null : value,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _ageGroup,
                        decoration: InputDecoration(
                          labelText: 'Age Group',
                          prefixIcon: const Icon(Icons.cake_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        ),
                        items: _ageGroupDefaults.keys.map((group) {
                          String displayName;
                          String emoji;
                          switch (group) {
                            case 'infant':
                              displayName = 'Infant (0-1 year)';
                              emoji = '👶';
                              break;
                            case 'child':
                              displayName = 'Child (2-10 years)';
                              emoji = '🧒';
                              break;
                            case 'teen':
                              displayName = 'Teen (11-18 years)';
                              emoji = '👨‍🎓';
                              break;
                            case 'adult':
                              displayName = 'Adult (19-50 years)';
                              emoji = '👨';
                              break;
                            case 'senior':
                              displayName = 'Senior (51+ years)';
                              emoji = '👴';
                              break;
                            default:
                              displayName = group;
                              emoji = '👤';
                          }
                          return DropdownMenuItem(
                            value: group,
                            child: Row(
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Text(displayName),
                              ],
                            ),
                          );
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
                      const SizedBox(height: 20),
                      const Text(
                        'Daily Nutrition Goals',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _caloriesController,
                        decoration: InputDecoration(
                          labelText: 'Daily Calories',
                          prefixIcon: const Text('🔥', style: TextStyle(fontSize: 20)),
                          suffixText: 'kcal',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) =>
                            _dailyCalories = double.tryParse(value) ?? _dailyCalories,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _proteinController,
                        decoration: InputDecoration(
                          labelText: 'Daily Protein',
                          prefixIcon: const Text('🥩', style: TextStyle(fontSize: 20)),
                          suffixText: 'g',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) =>
                            _dailyProtein = double.tryParse(value) ?? _dailyProtein,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _fatController,
                        decoration: InputDecoration(
                          labelText: 'Daily Fat',
                          prefixIcon: const Text('🥑', style: TextStyle(fontSize: 20)),
                          suffixText: 'g',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _dailyFat = double.tryParse(value) ?? _dailyFat,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _carbsController,
                        decoration: InputDecoration(
                          labelText: 'Daily Carbs',
                          prefixIcon: const Text('🍞', style: TextStyle(fontSize: 20)),
                          suffixText: 'g',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _dailyCarbs = double.tryParse(value) ?? _dailyCarbs,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _fiberController,
                        decoration: InputDecoration(
                          labelText: 'Daily Fiber',
                          prefixIcon: const Text('🥦', style: TextStyle(fontSize: 20)),
                          suffixText: 'g',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _dailyFiber = double.tryParse(value) ?? _dailyFiber,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
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
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getAgeGroupColors(String ageGroup) {
    switch (ageGroup.toLowerCase()) {
      case 'infant':
        return [Colors.pink, Colors.pinkAccent];
      case 'child':
        return [Colors.blue, Colors.blueAccent];
      case 'teen':
        return [Colors.green, Colors.greenAccent];
      case 'adult':
        return [Colors.purple, Colors.purpleAccent];
      case 'senior':
        return [Colors.orange, Colors.orangeAccent];
      default:
        return [Colors.grey, Colors.grey.shade400];
    }
  }

  IconData _getAgeGroupIcon(String ageGroup) {
    switch (ageGroup.toLowerCase()) {
      case 'infant':
        return Icons.child_care_outlined;
      case 'child':
        return Icons.child_friendly_outlined;
      case 'teen':
        return Icons.school_outlined;
      case 'adult':
        return Icons.person_outlined;
      case 'senior':
        return Icons.elderly_outlined;
      default:
        return Icons.person_outlined;
    }
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 400,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _getAgeGroupColors(_ageGroup),
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getAgeGroupIcon(_ageGroup),
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Add Household Member',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_outlined,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        initialValue: _name,
                        decoration: InputDecoration(
                          labelText: 'Name',
                          prefixIcon: const Icon(Icons.person_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        ),
                        onChanged: (value) => _name = value,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _ageGroup,
                        decoration: InputDecoration(
                          labelText: 'Age Group',
                          prefixIcon: const Icon(Icons.cake_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        ),
                        items: _ageGroupDefaults.keys.map((group) {
                          String displayName;
                          String emoji;
                          switch (group) {
                            case 'infant':
                              displayName = 'Infant (0-1 year)';
                              emoji = '👶';
                              break;
                            case 'child':
                              displayName = 'Child (2-10 years)';
                              emoji = '🧒';
                              break;
                            case 'teen':
                              displayName = 'Teen (11-18 years)';
                              emoji = '👨‍🎓';
                              break;
                            case 'adult':
                              displayName = 'Adult (19-50 years)';
                              emoji = '👨';
                              break;
                            case 'senior':
                              displayName = 'Senior (51+ years)';
                              emoji = '👴';
                              break;
                            default:
                              displayName = group;
                              emoji = '👤';
                          }
                          return DropdownMenuItem(
                            value: group,
                            child: Row(
                              children: [
                                Text(emoji, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 8),
                                Text(displayName),
                              ],
                            ),
                          );
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
                      const SizedBox(height: 20),
                      const Text(
                        'Daily Nutrition Goals',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _caloriesController,
                        decoration: InputDecoration(
                          labelText: 'Daily Calories',
                          prefixIcon: const Text('🔥', style: TextStyle(fontSize: 20)),
                          suffixText: 'kcal',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) =>
                            _dailyCalories = double.tryParse(value) ?? _dailyCalories,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _proteinController,
                        decoration: InputDecoration(
                          labelText: 'Daily Protein',
                          prefixIcon: const Text('🥩', style: TextStyle(fontSize: 20)),
                          suffixText: 'g',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) =>
                            _dailyProtein = double.tryParse(value) ?? _dailyProtein,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _fatController,
                        decoration: InputDecoration(
                          labelText: 'Daily Fat',
                          prefixIcon: const Text('🥑', style: TextStyle(fontSize: 20)),
                          suffixText: 'g',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _dailyFat = double.tryParse(value) ?? _dailyFat,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _carbsController,
                        decoration: InputDecoration(
                          labelText: 'Daily Carbs',
                          prefixIcon: const Text('🍞', style: TextStyle(fontSize: 20)),
                          suffixText: 'g',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _dailyCarbs = double.tryParse(value) ?? _dailyCarbs,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _fiberController,
                        decoration: InputDecoration(
                          labelText: 'Daily Fiber',
                          prefixIcon: const Text('🥦', style: TextStyle(fontSize: 20)),
                          suffixText: 'g',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => _dailyFiber = double.tryParse(value) ?? _dailyFiber,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      if (_name == null || _name!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Name is required')),
                        );
                        return;
                      }
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
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _getAgeGroupColors(String ageGroup) {
    switch (ageGroup.toLowerCase()) {
      case 'infant':
        return [Colors.pink, Colors.pinkAccent];
      case 'child':
        return [Colors.blue, Colors.blueAccent];
      case 'teen':
        return [Colors.green, Colors.greenAccent];
      case 'adult':
        return [Colors.purple, Colors.purpleAccent];
      case 'senior':
        return [Colors.orange, Colors.orangeAccent];
      default:
        return [Colors.grey, Colors.grey.shade400];
    }
  }

  IconData _getAgeGroupIcon(String ageGroup) {
    switch (ageGroup.toLowerCase()) {
      case 'infant':
        return Icons.child_care_outlined;
      case 'child':
        return Icons.child_friendly_outlined;
      case 'teen':
        return Icons.school_outlined;
      case 'adult':
        return Icons.person_outlined;
      case 'senior':
        return Icons.elderly_outlined;
      default:
        return Icons.person_outlined;
    }
  }
}
