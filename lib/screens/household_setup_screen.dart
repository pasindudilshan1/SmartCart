import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/azure_auth_service.dart';
import '../services/azure_table_service.dart';
import '../services/local_storage_service.dart';
import '../providers/inventory_provider.dart';
import '../models/household_member.dart';
import 'home_screen.dart';

class HouseholdSetupScreen extends StatefulWidget {
  const HouseholdSetupScreen({super.key});

  @override
  State<HouseholdSetupScreen> createState() => _HouseholdSetupScreenState();
}

class _HouseholdSetupScreenState extends State<HouseholdSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final AzureTableService _azureTableService = AzureTableService();
  final LocalStorageService _localStorageService = LocalStorageService();
  final List<TextEditingController> _calorieControllers = [];
  final List<TextEditingController> _proteinControllers = [];
  final List<TextEditingController> _fatControllers = [];
  final List<TextEditingController> _carbControllers = [];
  final List<TextEditingController> _fiberControllers = [];
  final List<TextEditingController> _nameControllers = [];
  final List<String> _ageGroups = [];
  late final TextEditingController _memberCountController;
  bool _isSaving = false;
  int _memberCount = 1;

  // Age group defaults
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
    _memberCountController = TextEditingController(text: _memberCount.toString());
    _syncControllers();
  }

  @override
  void dispose() {
    _memberCountController.dispose();
    for (final controller in _calorieControllers) {
      controller.dispose();
    }
    for (final controller in _proteinControllers) {
      controller.dispose();
    }
    for (final controller in _fatControllers) {
      controller.dispose();
    }
    for (final controller in _carbControllers) {
      controller.dispose();
    }
    for (final controller in _fiberControllers) {
      controller.dispose();
    }
    for (final controller in _nameControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllers() {
    while (_calorieControllers.length < _memberCount) {
      _calorieControllers.add(TextEditingController());
    }
    while (_calorieControllers.length > _memberCount) {
      _calorieControllers.removeLast().dispose();
    }

    while (_proteinControllers.length < _memberCount) {
      _proteinControllers.add(TextEditingController());
    }
    while (_proteinControllers.length > _memberCount) {
      _proteinControllers.removeLast().dispose();
    }

    while (_fatControllers.length < _memberCount) {
      _fatControllers.add(TextEditingController());
    }
    while (_fatControllers.length > _memberCount) {
      _fatControllers.removeLast().dispose();
    }

    while (_carbControllers.length < _memberCount) {
      _carbControllers.add(TextEditingController());
    }
    while (_carbControllers.length > _memberCount) {
      _carbControllers.removeLast().dispose();
    }

    while (_fiberControllers.length < _memberCount) {
      _fiberControllers.add(TextEditingController());
    }
    while (_fiberControllers.length > _memberCount) {
      _fiberControllers.removeLast().dispose();
    }

    while (_nameControllers.length < _memberCount) {
      _nameControllers.add(TextEditingController());
    }
    while (_nameControllers.length > _memberCount) {
      _nameControllers.removeLast().dispose();
    }

    while (_ageGroups.length < _memberCount) {
      _ageGroups.add('adult');
      // Set defaults for new member
      final index = _ageGroups.length - 1;
      _setDefaultsForAgeGroup(index, 'adult');
    }
    while (_ageGroups.length > _memberCount) {
      _ageGroups.removeLast();
    }
  }

  void _setDefaultsForAgeGroup(int index, String ageGroup) {
    final defaults = _ageGroupDefaults[ageGroup]!;
    _calorieControllers[index].text = defaults['calories']!.toString();
    _proteinControllers[index].text = defaults['protein']!.toString();
    _fatControllers[index].text = defaults['fat']!.toString();
    _carbControllers[index].text = defaults['carbs']!.toString();
    _fiberControllers[index].text = defaults['fiber']!.toString();
  }

  void _updateMemberCount(String value) {
    final parsed = int.tryParse(value);
    if (parsed == null) {
      return;
    }

    final clamped = parsed.clamp(1, 12);
    if (clamped != _memberCount) {
      setState(() {
        _memberCount = clamped;
        _syncControllers();
      });
    }

    if (parsed != clamped) {
      final text = clamped.toString();
      _memberCountController.text = text;
    }
  }

  Future<void> _saveHousehold() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authService = Provider.of<AzureAuthService>(context, listen: false);
    final userId = authService.currentUserId;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User not authenticated'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final calories = _calorieControllers
        .map((controller) => double.parse(controller.text.trim()))
        .toList(growable: false);

    final proteins = _proteinControllers
        .map((controller) => double.parse(controller.text.trim()))
        .toList(growable: false);

    final fats = _fatControllers
        .map((controller) => double.parse(controller.text.trim()))
        .toList(growable: false);

    final carbs = _carbControllers
        .map((controller) => double.parse(controller.text.trim()))
        .toList(growable: false);

    final fibers = _fiberControllers
        .map((controller) => double.parse(controller.text.trim()))
        .toList(growable: false);

    final names =
        _nameControllers.map((controller) => controller.text.trim()).toList(growable: false);

    setState(() {
      _isSaving = true;
    });

    try {
      debugPrint('💾 Saving household profile...');
      debugPrint('User ID: $userId');
      debugPrint('Member count: $_memberCount');
      debugPrint('Calories: $calories');
      debugPrint('Names: $names');

      // Create HouseholdMember objects
      final members = <HouseholdMember>[];

      for (int i = 0; i < _memberCount; i++) {
        final member = HouseholdMember(
          id: 'member_${i + 1}',
          memberIndex: i + 1,
          ageGroup: _ageGroups[i],
          dailyCalories: calories[i],
          dailyProtein: proteins[i],
          dailyFat: fats[i],
          dailyCarbs: carbs[i],
          dailyFiber: fibers[i],
          name: names[i].isEmpty ? null : names[i],
        );
        members.add(member);
      }

      // Save to Azure Tables
      debugPrint('☁️  Saving to Azure Tables...');
      await _azureTableService.storeHouseholdProfile(userId, _memberCount);
      debugPrint('✅ Azure profile saved');

      await _azureTableService.storeHouseholdMembers(
          userId, _ageGroups, calories, proteins, fats, carbs, fibers,
          names: names);
      debugPrint('✅ Azure members saved');

      // Mark household setup as complete (skip Hive for now - just use SharedPreferences)
      debugPrint('📱 Marking setup complete...');
      await _localStorageService.markHouseholdSetupComplete(userId);
      debugPrint('✅ Setup marked complete');

      if (!mounted) return;

      // Set user ID in inventory provider to trigger sync
      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
      inventoryProvider.setUserId(userId);

      debugPrint('🏠 Navigating to Home Screen...');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Error saving household: $e');
      debugPrint('Stack trace: $stackTrace');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save household details: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Household Details'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Tell us about your household',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'We use this information to personalize nutrition guidance for everyone at home.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _memberCountController,
                  decoration: const InputDecoration(
                    labelText: 'How many members live in your household?',
                    helperText: 'Enter a number between 1 and 12',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: _updateMemberCount,
                  validator: (value) {
                    final parsed = int.tryParse(value ?? '');
                    if (parsed == null || parsed < 1) {
                      return 'Please enter at least one household member';
                    }
                    if (parsed > 12) {
                      return 'Please enter a number up to 12';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'Member Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter details for each household member',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 16),
                ...List.generate(_memberCount, (index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Member ${index + 1}',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameControllers[index],
                            decoration: const InputDecoration(
                              labelText: 'Name (Optional)',
                              hintText: 'e.g., John, Mom, Kid 1',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: _ageGroups[index],
                            decoration: const InputDecoration(
                              labelText: 'Age Group',
                              prefixIcon: Icon(Icons.calendar_today),
                              border: OutlineInputBorder(),
                            ),
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
                              return DropdownMenuItem(
                                value: group,
                                child: Text(displayName),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _ageGroups[index] = value;
                                  _setDefaultsForAgeGroup(index, value);
                                });
                              }
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select an age group';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _calorieControllers[index],
                                  decoration: const InputDecoration(
                                    labelText: 'Calories',
                                    hintText: '2000',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(decimal: true),
                                  validator: (value) {
                                    final parsed = double.tryParse(value ?? '');
                                    if (parsed == null || parsed <= 0) {
                                      return 'Enter calories';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _proteinControllers[index],
                                  decoration: const InputDecoration(
                                    labelText: 'Protein (g)',
                                    hintText: '50',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(decimal: true),
                                  validator: (value) {
                                    final parsed = double.tryParse(value ?? '');
                                    if (parsed == null || parsed < 0) {
                                      return 'Enter protein';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _fatControllers[index],
                                  decoration: const InputDecoration(
                                    labelText: 'Fat (g)',
                                    hintText: '70',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(decimal: true),
                                  validator: (value) {
                                    final parsed = double.tryParse(value ?? '');
                                    if (parsed == null || parsed < 0) {
                                      return 'Enter fat';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: _carbControllers[index],
                                  decoration: const InputDecoration(
                                    labelText: 'Carbs (g)',
                                    hintText: '250',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(decimal: true),
                                  validator: (value) {
                                    final parsed = double.tryParse(value ?? '');
                                    if (parsed == null || parsed < 0) {
                                      return 'Enter carbs';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _fiberControllers[index],
                            decoration: const InputDecoration(
                              labelText: 'Fiber (g)',
                              hintText: '25',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              final parsed = double.tryParse(value ?? '');
                              if (parsed == null || parsed < 0) {
                                return 'Enter fiber';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveHousehold,
                  icon: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isSaving ? 'Saving...' : 'Save and Continue'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
