// Azure Table Storage Service
// Handles all data storage operations with Azure Tables

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:intl/intl.dart';
import '../models/product.dart';
import '../models/nutrition.dart';
import '../config/azure_config.dart';

class AzureTableService {
  // Use configuration from azure_config.dart (not committed to git)
  static const String _accountName = AzureConfig.accountName;
  static const String _accountKey = AzureConfig.accountKey;
  static const String _tableEndpoint = 'https://${AzureConfig.accountName}.table.core.windows.net';

  final Dio _dio = Dio();

  // Table names from config
  static const String _usersTable = AzureConfig.usersTable;
  static const String _householdsTable = AzureConfig.householdsTable;
  static const String _productsTable = AzureConfig.productsTable;
  static const String _nutritionTable = AzureConfig.nutritionTable;
  static const String _shoppingListTable = AzureConfig.shoppingListTable;
  static const String _settingsTable = AzureConfig.settingsTable;

  AzureTableService() {
    _dio.options.baseUrl = _tableEndpoint;
    _dio.options.headers['Accept'] = 'application/json;odata=nometadata';
    _dio.options.headers['Content-Type'] = 'application/json';
  }

  // Generate Shared Key Signature for Azure Table Storage authentication
  String _generateSharedKeySignature(String method, String resource, String date,
      {String? contentType}) {
    final canonicalizedResource = '/$_accountName$resource';

    // For requests with content, include Content-Type in signature
    String stringToSign;
    if (contentType != null && contentType.isNotEmpty) {
      stringToSign = '$method\n\n$contentType\n$date\n$canonicalizedResource';
    } else {
      stringToSign = '$method\n\n\n$date\n$canonicalizedResource';
    }

    final key = base64.decode(_accountKey);
    final hmac = Hmac(sha256, key);
    final signature = base64.encode(hmac.convert(utf8.encode(stringToSign)).bytes);

    return 'SharedKey $_accountName:$signature';
  }

  // Get current timestamp in Azure format
  String _getAzureTimestamp() {
    final now = DateTime.now().toUtc();
    final formatter = DateFormat('EEE, dd MMM yyyy HH:mm:ss');
    return '${formatter.format(now)} GMT';
  }

  // Generic method to execute Azure Table operations
  Future<Response> _executeTableOperation(String method, String table, String resource,
      {Map<String, dynamic>? data}) async {
    final date = _getAzureTimestamp();
    final fullResource = '/$table$resource';

    // For MERGE operations, we'll use PUT instead (simpler and more reliable)
    final actualMethod = (method == 'MERGE') ? 'PUT' : method;

    // Determine content type for requests with data
    final contentType =
        (actualMethod == 'POST' || actualMethod == 'PUT') ? 'application/json' : null;

    final signature =
        _generateSharedKeySignature(actualMethod, fullResource, date, contentType: contentType);

    final headers = {
      'x-ms-date': date,
      'x-ms-version': '2019-02-02',
      'Authorization': signature,
      'Accept': 'application/json;odata=nometadata',
    };

    // Add Content-Type for requests with data
    if (contentType != null) {
      headers['Content-Type'] = contentType;
    }

    // For POST operations, add Prefer header
    if (actualMethod == 'POST') {
      headers['Prefer'] = 'return-no-content';
    }

    // For PUT/DELETE operations, add If-Match header
    if (actualMethod == 'PUT' || actualMethod == 'DELETE') {
      headers['If-Match'] = '*';
    }

    final options = Options(
      headers: headers,
    );

    try {
      if (actualMethod == 'GET') {
        return await _dio.get(fullResource, options: options);
      } else if (actualMethod == 'POST') {
        return await _dio.post(fullResource, data: data, options: options);
      } else if (actualMethod == 'PUT') {
        return await _dio.put(fullResource, data: data, options: options);
      } else if (actualMethod == 'DELETE') {
        return await _dio.delete(fullResource, options: options);
      }
      throw Exception('Unsupported HTTP method: $actualMethod');
    } catch (e) {
      rethrow;
    }
  }

  // ============ USER OPERATIONS ============

  /// Store user profile data in Azure Table
  Future<void> storeUserProfile({
    required String userId,
    required String email,
    required String displayName,
    String? passwordHash,
    String? photoUrl,
    String? provider, // 'email' or 'google'
  }) async {
    final entity = {
      'PartitionKey': 'user',
      'RowKey': userId,
      'Email': email,
      'DisplayName': displayName,
      'PasswordHash': passwordHash ?? '',
      'PhotoUrl': photoUrl ?? '',
      'Provider': provider ?? 'email',
      'CreatedAt': DateTime.now().toIso8601String(),
      'LastLoginAt': DateTime.now().toIso8601String(),
    };

    await _executeTableOperation(
      'POST',
      _usersTable,
      '',
      data: entity,
    );
  }

  /// Update user last login time
  Future<void> updateUserLastLogin(String userId) async {
    final entity = {
      'PartitionKey': 'user',
      'RowKey': userId,
      'LastLoginAt': DateTime.now().toIso8601String(),
    };

    await _executeTableOperation(
      'MERGE',
      _usersTable,
      "(PartitionKey='user',RowKey='$userId')",
      data: entity,
    );
  }

  /// Get user profile from Azure Table
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await _executeTableOperation(
        'GET',
        _usersTable,
        "(PartitionKey='user',RowKey='$userId')",
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // ============ PRODUCT OPERATIONS ============

  /// Store product in Azure Table
  Future<void> storeProduct(String userId, Product product) async {
    final entity = {
      'PartitionKey': userId, // Partition by user for efficient queries
      'RowKey': product.id,
      'Name': product.name,
      'Barcode': product.barcode ?? '',
      'Category': product.category,
      'Quantity': product.quantity,
      'Unit': product.unit,
      'ExpiryDate': product.expiryDate?.toIso8601String() ?? '',
      'PurchaseDate': product.purchaseDate?.toIso8601String() ?? '',
      'Brand': product.brand ?? '',
      'Price': product.price ?? 0.0,
      'ImageUrl': product.imageUrl ?? '',
      'StorageLocation': product.storageLocation ?? '',
      'DateAdded': product.dateAdded?.toIso8601String() ?? DateTime.now().toIso8601String(),
    };

    await _executeTableOperation(
      'POST',
      _productsTable,
      '',
      data: entity,
    );
  }

  /// Update product in Azure Table
  Future<void> updateProduct(String userId, Product product) async {
    final entity = {
      'PartitionKey': userId,
      'RowKey': product.id,
      'Name': product.name,
      'Quantity': product.quantity,
      'ExpiryDate': product.expiryDate?.toIso8601String() ?? '',
      'StorageLocation': product.storageLocation ?? '',
    };

    await _executeTableOperation(
      'MERGE',
      _productsTable,
      "(PartitionKey='$userId',RowKey='${product.id}')",
      data: entity,
    );
  }

  /// Delete product from Azure Table
  Future<void> deleteProduct(String userId, String productId) async {
    await _executeTableOperation(
      'DELETE',
      _productsTable,
      "(PartitionKey='$userId',RowKey='$productId')",
    );
  }

  /// Get all products for a user
  Future<List<Map<String, dynamic>>> getProducts(String userId) async {
    try {
      final response = await _executeTableOperation(
        'GET',
        _productsTable,
        "()?%24filter=PartitionKey%20eq%20'$userId'",
      );

      final data = response.data as Map<String, dynamic>;
      final values = data['value'] as List;
      return values.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // ============ NUTRITION OPERATIONS ============

  /// Store daily nutrition data
  Future<void> storeNutrition(String userId, DailyNutrition nutrition) async {
    final dateKey = '${nutrition.date.year}-${nutrition.date.month}-${nutrition.date.day}';

    final entity = {
      'PartitionKey': userId,
      'RowKey': dateKey,
      'Date': nutrition.date.toIso8601String(),
      'TotalCalories': nutrition.totalCalories,
      'TotalProtein': nutrition.totalProtein,
      'TotalCarbs': nutrition.totalCarbs,
      'TotalFat': nutrition.totalFat,
      'ConsumedProducts': jsonEncode(nutrition.consumedProductIds),
    };

    await _executeTableOperation(
      'POST',
      _nutritionTable,
      '',
      data: entity,
    );
  }

  /// Update nutrition data
  Future<void> updateNutrition(String userId, DailyNutrition nutrition) async {
    final dateKey = '${nutrition.date.year}-${nutrition.date.month}-${nutrition.date.day}';

    final entity = {
      'PartitionKey': userId,
      'RowKey': dateKey,
      'TotalCalories': nutrition.totalCalories,
      'TotalProtein': nutrition.totalProtein,
      'TotalCarbs': nutrition.totalCarbs,
      'TotalFat': nutrition.totalFat,
      'ConsumedProducts': jsonEncode(nutrition.consumedProductIds),
    };
    await _executeTableOperation(
      'MERGE',
      _nutritionTable,
      "(PartitionKey='$userId',RowKey='$dateKey')",
      data: entity,
    );
  }

  /// Get nutrition data for a date range
  Future<List<Map<String, dynamic>>> getNutritionHistory(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await _executeTableOperation(
        'GET',
        _nutritionTable,
        "()?%24filter=PartitionKey%20eq%20'$userId'",
      );

      final data = response.data as Map<String, dynamic>;
      final values = data['value'] as List;
      return values.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  // ============ USER SETTINGS OPERATIONS ============

  /// Store user nutrition goals and preferences
  Future<void> storeUserSettings(String userId, Map<String, dynamic> settings) async {
    final entity = {
      'PartitionKey': userId,
      'RowKey': 'settings',
      ...settings,
      'UpdatedAt': DateTime.now().toIso8601String(),
    };

    await _executeTableOperation(
      'POST',
      _settingsTable,
      '',
      data: entity,
    );
  }

  /// Update user settings
  Future<void> updateUserSettings(String userId, Map<String, dynamic> settings) async {
    final entity = {
      'PartitionKey': userId,
      'RowKey': 'settings',
      ...settings,
      'UpdatedAt': DateTime.now().toIso8601String(),
    };

    await _executeTableOperation(
      'MERGE',
      _settingsTable,
      "(PartitionKey='$userId',RowKey='settings')",
      data: entity,
    );
  }

  /// Get user settings
  Future<Map<String, dynamic>?> getUserSettings(String userId) async {
    try {
      final response = await _executeTableOperation(
        'GET',
        _settingsTable,
        "(PartitionKey='$userId',RowKey='settings')",
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // ============ SHOPPING LIST OPERATIONS ============

  /// Store shopping list item
  Future<void> storeShoppingListItem(String userId, Map<String, dynamic> item) async {
    final entity = {
      'PartitionKey': userId,
      'RowKey': item['id'],
      'ProductName': item['name'],
      'Quantity': item['quantity'],
      'Unit': item['unit'],
      'IsPurchased': item['isPurchased'] ?? false,
      'CreatedAt': DateTime.now().toIso8601String(),
    };

    await _executeTableOperation(
      'POST',
      _shoppingListTable,
      '',
      data: entity,
    );
  }

  /// Get shopping list for user
  Future<List<Map<String, dynamic>>> getShoppingList(String userId) async {
    try {
      final response = await _executeTableOperation(
        'GET',
        _shoppingListTable,
        "()?%24filter=PartitionKey%20eq%20'$userId'",
      );

      final data = response.data as Map<String, dynamic>;
      final values = data['value'] as List;
      return values.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Delete shopping list item
  Future<void> deleteShoppingListItem(String userId, String itemId) async {
    await _executeTableOperation(
      'DELETE',
      _shoppingListTable,
      "(PartitionKey='$userId',RowKey='$itemId')",
    );
  }

  // ============ HOUSEHOLD MEMBER OPERATIONS ============

  /// Store household member in Households Table
  Future<void> storeHouseholdMember(String userId, int memberIndex, double averageCalories,
      {String? name}) async {
    final memberId = 'member_$memberIndex';

    final entity = {
      'PartitionKey': userId, // Links to user
      'RowKey': memberId,
      'UserId': userId,
      'MemberIndex': memberIndex,
      'AverageDailyCalories': averageCalories,
      'Name': name ?? '',
      'CreatedAt': DateTime.now().toIso8601String(),
      'UpdatedAt': DateTime.now().toIso8601String(),
    };

    try {
      // Try to insert first
      await _executeTableOperation(
        'POST',
        _householdsTable, // Use Households table
        '',
        data: entity,
      );
      print('✅ Created household member $memberIndex for user $userId');
    } catch (e) {
      // If insert fails (entity exists), try to update
      print('⚠️  Member $memberIndex exists, updating instead');
      await _executeTableOperation(
        'MERGE',
        _householdsTable,
        "(PartitionKey='$userId',RowKey='$memberId')",
        data: entity,
      );
      print('✅ Updated household member $memberIndex for user $userId');
    }
  }

  /// Store multiple household members (batch)
  Future<void> storeHouseholdMembers(String userId, List<double> averageCalories,
      {List<String>? names}) async {
    // Note: Azure Table Storage REST API doesn't support true batch operations easily
    // We'll store them one by one
    for (int i = 0; i < averageCalories.length; i++) {
      await storeHouseholdMember(
        userId,
        i + 1,
        averageCalories[i],
        name: names != null && i < names.length ? names[i] : null,
      );
    }
  }

  /// Get all household members for a user from Households table
  Future<List<Map<String, dynamic>>> getHouseholdMembers(String userId) async {
    try {
      // Query for all entities with PartitionKey = userId and RowKey starting with 'member_'
      final response = await _executeTableOperation(
        'GET',
        _householdsTable,
        "()?%24filter=PartitionKey%20eq%20'$userId'%20and%20startswith(RowKey,'member_')",
      );

      final data = response.data as Map<String, dynamic>;
      final values = data['value'] as List;
      return values.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Update household member
  Future<void> updateHouseholdMember(String userId, int memberIndex, double averageCalories,
      {String? name}) async {
    final memberId = 'member_$memberIndex';

    final entity = {
      'PartitionKey': userId,
      'RowKey': memberId,
      'AverageDailyCalories': averageCalories,
      'Name': name ?? '',
      'UpdatedAt': DateTime.now().toIso8601String(),
    };

    await _executeTableOperation(
      'MERGE',
      _householdsTable,
      "(PartitionKey='$userId',RowKey='$memberId')",
      data: entity,
    );
  }

  /// Delete household member
  Future<void> deleteHouseholdMember(String userId, int memberIndex) async {
    final memberId = 'member_$memberIndex';
    await _executeTableOperation(
      'DELETE',
      _householdsTable,
      "(PartitionKey='$userId',RowKey='$memberId')",
    );
  }

  /// Delete all household members for a user (useful when resetting)
  Future<void> deleteAllHouseholdMembers(String userId) async {
    try {
      final members = await getHouseholdMembers(userId);
      for (final member in members) {
        final memberIndex = member['MemberIndex'] as int;
        await deleteHouseholdMember(userId, memberIndex);
      }
    } catch (e) {
      // Handle error silently or log
    }
  }

  /// Store household profile summary in Households table (separate from Users)
  Future<void> storeHouseholdProfile(String userId, int memberCount) async {
    final entity = {
      'PartitionKey': userId, // User ID links household to user
      'RowKey': 'profile',
      'UserId': userId,
      'MemberCount': memberCount,
      'CreatedAt': DateTime.now().toIso8601String(),
      'UpdatedAt': DateTime.now().toIso8601String(),
    };

    try {
      await _executeTableOperation(
        'POST',
        _householdsTable, // Use Households table
        '',
        data: entity,
      );
      print('✅ Created household profile for user $userId');
    } catch (e) {
      // If insert fails (entity exists), try to update
      print('⚠️  Household profile exists, updating instead');
      await _executeTableOperation(
        'MERGE',
        _householdsTable,
        "(PartitionKey='$userId',RowKey='profile')",
        data: entity,
      );
      print('✅ Updated household profile for user $userId');
    }
  }

  /// Update household profile summary
  Future<void> updateHouseholdProfile(String userId, int memberCount) async {
    final entity = {
      'PartitionKey': userId,
      'RowKey': 'profile',
      'MemberCount': memberCount,
      'UpdatedAt': DateTime.now().toIso8601String(),
    };

    await _executeTableOperation(
      'MERGE',
      _householdsTable,
      "(PartitionKey='$userId',RowKey='profile')",
      data: entity,
    );
  }

  /// Check if household profile exists
  Future<bool> householdProfileExists(String userId) async {
    try {
      await _executeTableOperation(
        'GET',
        _householdsTable,
        "(PartitionKey='$userId',RowKey='profile')",
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get household profile
  Future<Map<String, dynamic>?> getHouseholdProfile(String userId) async {
    try {
      final response = await _executeTableOperation(
        'GET',
        _householdsTable,
        "(PartitionKey='$userId',RowKey='profile')",
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Get complete household data (profile + members) for user sign-in
  Future<Map<String, dynamic>> getCompleteHouseholdData(String userId) async {
    try {
      // Get household profile
      final profile = await getHouseholdProfile(userId);

      // Get all household members
      final members = await getHouseholdMembers(userId);

      return {
        'profile': profile,
        'members': members,
        'hasMemberData': members.isNotEmpty,
      };
    } catch (e) {
      print('❌ Error fetching household data: $e');
      return {
        'profile': null,
        'members': <Map<String, dynamic>>[],
        'hasData': false,
      };
    }
  }

  /// Delete all user data (for account deletion)
  Future<void> deleteUserData(String userId) async {
    try {
      // Delete user profile from Users table
      await _executeTableOperation(
        'DELETE',
        _usersTable,
        "(PartitionKey='user',RowKey='$userId')",
      );

      // Delete household profile from Households table
      try {
        await _executeTableOperation(
          'DELETE',
          _householdsTable,
          "(PartitionKey='$userId',RowKey='profile')",
        );
      } catch (e) {
        // Ignore if doesn't exist
      }

      // Delete all household members from Households table
      await deleteAllHouseholdMembers(userId);

      print('✅ Deleted all data for user $userId');
    } catch (e) {
      print('❌ Error deleting user data: $e');
      rethrow;
    }
  }
}
