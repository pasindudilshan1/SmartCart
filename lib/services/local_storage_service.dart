import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/household_member.dart';

/// Service for managing local storage of user data
/// Provides offline access and caching of household information
class LocalStorageService {
  static const String _householdBoxName = 'household_members';

  // SharedPreferences keys
  static const String _householdSetupCompleteKey = 'household_setup_complete';
  static const String _currentUserIdKey = 'current_user_id';
  static const String _currentUserEmailKey = 'current_user_email';
  static const String _currentUserNameKey = 'current_user_name';
  static const String _memberCountKey = 'member_count';
  static const String _lastSyncKey = 'last_sync_time';

  /// Save current user to local storage
  Future<void> saveCurrentUser(String userId, String email, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserIdKey, userId);
    await prefs.setString(_currentUserEmailKey, email);
    await prefs.setString(_currentUserNameKey, name);
  }

  /// Get current user from local storage
  Future<Map<String, String>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_currentUserIdKey);
    final email = prefs.getString(_currentUserEmailKey);
    final name = prefs.getString(_currentUserNameKey);

    if (userId != null && email != null && name != null) {
      return {
        'userId': userId,
        'email': email,
        'name': name,
      };
    }
    return null;
  }

  /// Check if household setup is complete for current user
  Future<bool> isHouseholdSetupComplete(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserId = prefs.getString(_currentUserIdKey);

    // Check if same user and setup is complete
    if (savedUserId == userId) {
      return prefs.getBool(_householdSetupCompleteKey) ?? false;
    }

    // Different user, need to setup
    return false;
  }

  /// Mark household setup as complete
  Future<void> markHouseholdSetupComplete(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentUserIdKey, userId);
    await prefs.setBool(_householdSetupCompleteKey, true);
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Clear household setup status (for logout)
  Future<void> clearHouseholdSetup() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_householdSetupCompleteKey);
    await prefs.remove(_currentUserIdKey);
    await prefs.remove(_currentUserEmailKey);
    await prefs.remove(_currentUserNameKey);
    await prefs.remove(_memberCountKey);
    await prefs.remove(_lastSyncKey);
  }

  /// Save household members to local storage
  Future<void> saveHouseholdMembers(String userId, List<HouseholdMember> members) async {
    try {
      // Check if box is already open, if not, open it
      late Box<HouseholdMember> box;
      if (Hive.isBoxOpen(_householdBoxName)) {
        box = Hive.box<HouseholdMember>(_householdBoxName);
      } else {
        box = await Hive.openBox<HouseholdMember>(_householdBoxName);
      }

      // Clear existing members for this user
      await box.clear();

      // Save all members
      for (final member in members) {
        await box.put(member.id, member);
      }

      // Update member count in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_memberCountKey, members.length);
      await prefs.setString(_currentUserIdKey, userId);

      print('✅ Saved ${members.length} household members to local storage');
    } catch (e) {
      print('❌ Error saving household members locally: $e');
      rethrow;
    }
  }

  /// Get household members from local storage
  Future<List<HouseholdMember>> getHouseholdMembers() async {
    try {
      // Check if box is already open, if not, open it
      late Box<HouseholdMember> box;
      if (Hive.isBoxOpen(_householdBoxName)) {
        box = Hive.box<HouseholdMember>(_householdBoxName);
      } else {
        box = await Hive.openBox<HouseholdMember>(_householdBoxName);
      }
      return box.values.toList();
    } catch (e) {
      print('❌ Error getting household members from local storage: $e');
      return [];
    }
  }

  /// Get member count from local storage
  Future<int> getMemberCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_memberCountKey) ?? 0;
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final syncTimeStr = prefs.getString(_lastSyncKey);
    if (syncTimeStr != null) {
      return DateTime.parse(syncTimeStr);
    }
    return null;
  }

  /// Update last sync time
  Future<void> updateLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
  }

  /// Check if data needs sync (older than 24 hours)
  Future<bool> needsSync() async {
    final lastSync = await getLastSyncTime();
    if (lastSync == null) return true;

    final hoursSinceSync = DateTime.now().difference(lastSync).inHours;
    return hoursSinceSync >= 24;
  }

  /// Clear all local data (for logout)
  Future<void> clearAllData() async {
    try {
      // Check if box is already open, if not, open it
      late Box<HouseholdMember> householdBox;
      if (Hive.isBoxOpen(_householdBoxName)) {
        householdBox = Hive.box<HouseholdMember>(_householdBoxName);
      } else {
        householdBox = await Hive.openBox<HouseholdMember>(_householdBoxName);
      }
      await householdBox.clear();

      await clearHouseholdSetup();

      print('✅ Cleared all local data');
    } catch (e) {
      print('❌ Error clearing local data: $e');
    }
  }
}
