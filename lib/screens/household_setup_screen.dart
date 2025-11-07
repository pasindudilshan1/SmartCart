import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/azure_auth_service.dart';
import '../services/azure_table_service.dart';
import '../services/local_storage_service.dart';
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
  final List<TextEditingController> _nameControllers = [];
  late final TextEditingController _memberCountController;
  bool _isSaving = false;
  int _memberCount = 1;

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

    while (_nameControllers.length < _memberCount) {
      _nameControllers.add(TextEditingController());
    }
    while (_nameControllers.length > _memberCount) {
      _nameControllers.removeLast().dispose();
    }
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
      _memberCountController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
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

    final names =
        _nameControllers.map((controller) => controller.text.trim()).toList(growable: false);

    setState(() {
      _isSaving = true;
    });

    try {
      print('💾 Saving household profile...');
      print('User ID: $userId');
      print('Member count: $_memberCount');
      print('Calories: $calories');
      print('Names: $names');

      // Create HouseholdMember objects
      final members = <HouseholdMember>[];

      for (int i = 0; i < _memberCount; i++) {
        final member = HouseholdMember(
          id: 'member_${i + 1}',
          memberIndex: i + 1,
          averageDailyCalories: calories[i],
          name: names[i].isEmpty ? null : names[i],
        );
        members.add(member);
      }

      // Save to Azure Tables
      print('☁️  Saving to Azure Tables...');
      await _azureTableService.storeHouseholdProfile(userId, _memberCount);
      print('✅ Azure profile saved');

      await _azureTableService.storeHouseholdMembers(userId, calories, names: names);
      print('✅ Azure members saved');

      // Mark household setup as complete (skip Hive for now - just use SharedPreferences)
      print('📱 Marking setup complete...');
      await _localStorageService.markHouseholdSetupComplete(userId);
      print('✅ Setup marked complete');

      if (!mounted) return;

      print('🏠 Navigating to Home Screen...');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e, stackTrace) {
      print('❌ Error saving household: $e');
      print('Stack trace: $stackTrace');

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
                          TextFormField(
                            controller: _calorieControllers[index],
                            decoration: const InputDecoration(
                              labelText: 'Average daily calories',
                              hintText: 'e.g., 2000',
                              prefixIcon: Icon(Icons.local_fire_department),
                              border: OutlineInputBorder(),
                              helperText: 'Typical adult: 1800-2500 calories',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: (value) {
                              final parsed = double.tryParse(value ?? '');
                              if (parsed == null || parsed <= 0) {
                                return 'Enter a positive number of calories';
                              }
                              if (parsed < 500) {
                                return 'Calories seem too low (minimum 500)';
                              }
                              if (parsed > 10000) {
                                return 'Calories seem too high (maximum 10000)';
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
