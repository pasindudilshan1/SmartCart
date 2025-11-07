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
      final userId = _generateUserId(email);
      final passwordHash = _hashPassword(password);

      // Check if user already exists
      final existingUser = await _azureService.getUserProfile(userId);
      if (existingUser != null) {
        return 'An account already exists for that email.';
      }

      // Store user profile in Azure Table
      await _azureService.storeUserProfile(
        userId: userId,
        email: email.toLowerCase().trim(),
        displayName: name.trim(),
        passwordHash: passwordHash,
        provider: 'email',
      );

      // Set current user
      _currentUserId = userId;
      _currentUserEmail = email.toLowerCase().trim();
      _currentUserName = name.trim();

      // Save to local storage
      await _localStorageService.saveCurrentUser(userId, email, name);

      notifyListeners();
      return null; // Success
    } catch (e) {
      print('❌ Sign up error: $e');
      return 'An error occurred during sign up: $e';
    }
  }

  /// Sign in with email and password
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      final userId = _generateUserId(email);
      final passwordHash = _hashPassword(password);

      // Get user profile from Azure
      final userProfile = await _azureService.getUserProfile(userId);

      if (userProfile == null) {
        return 'NO_USER_FOUND'; // Special code to show "Please sign up" message
      }

      // Verify password
      final storedPasswordHash = userProfile['PasswordHash'] as String?;
      if (storedPasswordHash != passwordHash) {
        return 'Incorrect password.';
      }

      // Update last login in Azure Table
      await _azureService.updateUserLastLogin(userId);

      // Set current user
      _currentUserId = userId;
      _currentUserEmail = userProfile['Email'] as String;
      _currentUserName = userProfile['DisplayName'] as String;

      // Fetch household data from Households table
      print('📦 Fetching household data for user...');
      final householdData = await _azureService.getCompleteHouseholdData(userId);

      // Check if household data exists and mark setup complete
      if (householdData['members'] != null && (householdData['members'] as List).isNotEmpty) {
        print('✅ Found household data from Azure');
        await _localStorageService.markHouseholdSetupComplete(userId);
      }

      // Save to local storage
      await _localStorageService.saveCurrentUser(
        userId,
        _currentUserEmail!,
        _currentUserName!,
      );

      notifyListeners();
      return null; // Success
    } catch (e) {
      print('❌ Sign in error: $e');
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
