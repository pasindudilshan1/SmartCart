import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'azure_table_service.dart';
import 'local_storage_service.dart';

class AzureAuthService extends ChangeNotifier {
  final AzureTableService _azureService = AzureTableService();
  final LocalStorageService _localStorageService = LocalStorageService();

  String? _currentUserId;
  String? _currentUserEmail;
  String? _currentUserName;

  String? get currentUserId => _currentUserId;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName => _currentUserName;
  bool get isAuthenticated => _currentUserId != null;

  /// Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  /// Generate user ID from email
  String _generateUserId(String email) {
    final bytes = utf8.encode(email.toLowerCase());
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 32); // Use first 32 chars
  }

  /// Sign up with email and password
  Future<String?> signUpWithEmail(String email, String password, String name) async {
    try {
      print('📝 ========== SIGN UP ATTEMPT ==========');
      print('📧 Email: $email');
      print('👤 Name: $name');

      final userId = _generateUserId(email);
      print('🔑 Generated userId: $userId');

      final passwordHash = _hashPassword(password);
      print('🔒 Password hash: ${passwordHash.substring(0, 20)}...');

      // Check if user already exists
      print('🔍 Checking if user already exists...');
      final existingUser = await _azureService.getUserProfileByEmail(email.toLowerCase().trim());
      if (existingUser != null) {
        print('❌ User already exists');
        return 'An account already exists for that email.';
      }

      print('✅ User does not exist, creating new account...');

      // Store user profile in Azure Table
      await _azureService.storeUserProfile(
        userId: userId,
        email: email.toLowerCase().trim(),
        displayName: name.trim(),
        passwordHash: passwordHash,
        provider: 'email',
      );

      print('✅ User profile stored successfully');

      // Set current user
      _currentUserId = userId;
      _currentUserEmail = email.toLowerCase().trim();
      _currentUserName = name.trim();

      // Save to local storage
      await _localStorageService.saveCurrentUser(userId, email, name);

      print('✅ ========== SIGN UP SUCCESSFUL ==========');
      notifyListeners();
      return null; // Success
    } catch (e) {
      print('❌ Sign up error: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return 'An error occurred during sign up: $e';
    }
  }

  /// Sign in with email and password
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      print('🔐 ========== SIGN IN ATTEMPT ==========');
      print('📧 Email: $email');

      final passwordHash = _hashPassword(password);
      print('🔒 Password hash: ${passwordHash.substring(0, 20)}...');

      // Get user profile from Azure by email
      print('🔍 Querying AppUsers table by email...');
      final userProfile = await _azureService.getUserProfileByEmail(email.toLowerCase().trim());

      if (userProfile == null) {
        print('❌ User not found in AppUsers table');
        return 'NO_USER_FOUND'; // Special code to show "Please sign up" message
      }

      print('✅ User found in AppUsers table');
      print('📋 User data: Email=${userProfile['Email']}, Name=${userProfile['DisplayName']}');

      // Verify password
      final storedPasswordHash = userProfile['PasswordHash'] as String?;
      print('🔒 Stored password hash: ${storedPasswordHash?.substring(0, 20) ?? 'NULL'}...');

      if (storedPasswordHash == null || storedPasswordHash.isEmpty) {
        print('❌ No password hash stored for this user');
        return 'Account setup incomplete. Please contact support.';
      }

      if (storedPasswordHash != passwordHash) {
        print('❌ Password hash mismatch');
        print('   Expected: ${passwordHash.substring(0, 20)}...');
        print('   Got:      ${storedPasswordHash.substring(0, 20)}...');
        return 'Incorrect password.';
      }

      print('✅ Password verified successfully');

      // Get userId from the profile (it should be stored in the RowKey)
      final userId = userProfile['RowKey'] as String?;
      if (userId == null) {
        print('❌ No userId found in user profile');
        return 'Account data corrupted. Please contact support.';
      }

      // Note: Not updating LastLoginAt to avoid modifying user data during sign-in
      // Only reading data as requested
      print('ℹ️ Skipping LastLoginAt update - read-only sign-in');

      // Set current user
      _currentUserId = userId;
      _currentUserEmail = userProfile['Email'] as String;
      _currentUserName = userProfile['DisplayName'] as String;

      // Save to local storage - sign-in complete, user goes directly to home/inventory
      await _localStorageService.saveCurrentUser(userId, _currentUserEmail!, _currentUserName!);

      print('✅ ========== SIGN IN SUCCESSFUL ==========');
      notifyListeners();
      return null; // Success
    } catch (e) {
      print('❌ Sign in error: $e');
      print('❌ Stack trace: ${StackTrace.current}');
      return 'An error occurred during sign in: $e';
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _currentUserId = null;
    _currentUserEmail = null;
    _currentUserName = null;
    await _localStorageService.clearAllData();
    notifyListeners();
  }

  /// Check if household setup is complete
  Future<bool> isHouseholdSetupComplete() async {
    if (_currentUserId == null) return false;
    return await _localStorageService.isHouseholdSetupComplete(_currentUserId!);
  }

  /// Load user from local storage (for auto-login)
  Future<bool> loadUserFromStorage() async {
    try {
      final userData = await _localStorageService.getCurrentUser();
      if (userData != null) {
        _currentUserId = userData['userId'];
        _currentUserEmail = userData['email'];
        _currentUserName = userData['name'];
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error loading user from storage: $e');
      return false;
    }
  }

  /// Delete account
  Future<String?> deleteAccount() async {
    try {
      if (_currentUserId == null) {
        return 'No user is currently signed in.';
      }

      // Delete user data from Azure
      await _azureService.deleteUserData(_currentUserId!);

      // Clear local data
      await signOut();

      return null; // Success
    } catch (e) {
      return 'An error occurred while deleting account: $e';
    }
  }
}
