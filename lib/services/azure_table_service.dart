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
  String _generateSharedKeySignature(
    String date,
    String canonicalizedResource,
  ) {
    // SharedKeyLite string to sign for Table Storage:
    // stringToSign = Date + "\n" + CanonicalizedResource
    // For SharedKeyLite, query parameters are NOT included in the signature
    final stringToSign = '$date\n$canonicalizedResource';

    print('🔐 String to sign (SharedKeyLite): $stringToSign');

    final key = base64.decode(_accountKey);
    final hmac = Hmac(sha256, key);
    final signature = base64.encode(hmac.convert(utf8.encode(stringToSign)).bytes);

    // Use SharedKeyLite scheme
    return 'SharedKeyLite $_accountName:$signature';
  }

  // Get current timestamp in Azure format
  String _getAzureTimestamp() {
    final now = DateTime.now().toUtc();
    final formatter = DateFormat('EEE, dd MMM yyyy HH:mm:ss');
    return '${formatter.format(now)} GMT';
  }

  // Generic method to execute Azure Table operations
  Future<Response> _executeTableOperation(
    String method,
    String table,
    String resource, {
    Map<String, dynamic>? data,
    Map<String, String>? queryParams,
  }) async {
    final date = _getAzureTimestamp();

    // Build the full resource path
    String fullUrl = '/$table$resource';

    // For SharedKeyLite signature: canonicalized resource is /{accountName}/{table}{resource}
    // Query parameters are NOT included in SharedKeyLite signature
    String signatureResource = '/$_accountName/$table$resource';

    // Add query parameters to the URL (for the actual HTTP request only)
    if (queryParams != null && queryParams.isNotEmpty) {
      // Use Uri to properly encode the query string
      final encoded = Uri(queryParameters: queryParams).query;
      fullUrl += '?$encoded';
    }

    // For MERGE operations, we'll use PUT instead (simpler and more reliable)
    final actualMethod = (method == 'MERGE') ? 'PUT' : method;

    // Determine content type for requests with data
    final contentType =
        (actualMethod == 'POST' || actualMethod == 'PUT') ? 'application/json' : null;

    final signature = _generateSharedKeySignature(date, signatureResource);

    print('🔗 Request URL: $_tableEndpoint$fullUrl');
    print('🔐 Signing resource: $signatureResource');
    print('🔐 Authorization: $signature');

    final headers = {
      'x-ms-date': date,
      'x-ms-version': '2020-08-04',
      'Authorization': signature,
      'Accept': 'application/json;odata=nometadata',
      'DataServiceVersion': '3.0',
      'MaxDataServiceVersion': '3.0;NetFx',
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

    final options = Options(headers: headers);

    try {
      if (actualMethod == 'GET') {
        return await _dio.get(fullUrl, options: options);
      } else if (actualMethod == 'POST') {
        return await _dio.post(fullUrl, data: data, options: options);
      } else if (actualMethod == 'PUT') {
        return await _dio.put(fullUrl, data: data, options: options);
      } else if (actualMethod == 'DELETE') {
        return await _dio.delete(fullUrl, options: options);
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
    print('📝 Storing user profile in Azure...');
    print('   UserId: $userId');
    print('   Email: $email');
    print('   DisplayName: $displayName');
    print('   Provider: ${provider ?? 'email'}');
    print('   PasswordHash length: ${passwordHash?.length ?? 0}');

    final entity = {
      'PartitionKey': 'user',
      'RowKey': userId,
      'Email': email.trim().toLowerCase(),
      'DisplayName': displayName,
      'PasswordHash': passwordHash ?? '',
      'PhotoUrl': photoUrl ?? '',
      'Provider': provider ?? 'email',
      'CreatedAt': DateTime.now().toIso8601String(),
      'LastLoginAt': DateTime.now().toIso8601String(),
    };

    try {
      await _executeTableOperation('POST', _usersTable, '', data: entity);
      print('✅ User profile stored successfully in AppUsers table');
    } catch (e) {
      print('❌ Error storing user profile: $e');
      if (e is DioException) {
        print('❌ Status Code: ${e.response?.statusCode}');
        print('❌ Response: ${e.response?.data}');
      }
      rethrow;
    }
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

  /// Get user profile from Azure Table by email
  Future<Map<String, dynamic>?> getUserProfileByEmail(String email) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      print('🔍 Looking up user profile for email: $email (normalized: $normalizedEmail)');
      print('🔍 Table: $_usersTable, PartitionKey: user, Email: $normalizedEmail');

      // Query for user with matching email
      final response = await _executeTableOperation(
        'GET',
        _usersTable,
        '()', // Use () for table queries with filters
        queryParams: {
          '\$filter': "PartitionKey eq 'user' and Email eq '$normalizedEmail'",
        },
      );

      final data = response.data as Map<String, dynamic>;
      final values = data['value'] as List;

      if (values.isEmpty) {
        print('❌ No user found with email: $email');
        return null;
      }

      if (values.length > 1) {
        print('⚠️ Multiple users found with email: $email, using first one');
      }

      print('✅ User profile found: ${values[0]}');
      return values[0] as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error getting user profile by email: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e is DioException) {
        print('❌ DioException: ${e.response?.statusCode} ${e.response?.data}');
        print(
            '❌ Request options: ${e.requestOptions.method} ${e.requestOptions.baseUrl}${e.requestOptions.path}');
        if (e.requestOptions.queryParameters.isNotEmpty) {
          print('❌ Query params: ${e.requestOptions.queryParameters}');
        }
      } else {
        print('❌ Error: $e');
      }
      return null;
    }
  }

  /// Get user profile from Azure Table by userId (for backward compatibility)
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      print('🔍 Looking up user profile for userId: $userId');
      print('🔍 Table: $_usersTable, PartitionKey: user, RowKey: $userId');

      // Try direct entity path (most reliable for Azure Tables)
      final response = await _executeTableOperation(
        'GET',
        _usersTable,
        "(PartitionKey='user',RowKey='$userId')",
      );

      print('✅ User profile found: ${response.data}');
      return response.data as Map<String, dynamic>;
    } catch (e) {
      print('❌ Error getting user profile: $e');
      print('❌ Error type: ${e.runtimeType}');
      if (e is DioException) {
        print('❌ DioException: ${e.response?.statusCode} ${e.response?.data}');
        print(
            '❌ Request options: ${e.requestOptions.method} ${e.requestOptions.baseUrl}${e.requestOptions.path}');
      } else {
        print('❌ Error: $e');
      }
      return null;
    }
  }

  // ============ PRODUCT OPERATIONS ============

  /// Store product in Azure Table
  Future<void> storeProduct(String userId, Product product) async {
    print('💾 Storing product in Azure: ${product.name} for userId: $userId');
    final entity = {
      'PartitionKey': userId, // Partition by user for efficient queries
      'RowKey': product.id,
      'Name': product.name,
      'Barcode': product.barcode ?? '',
      'Category': product.category,
      'Quantity': product.quantity,
      'Unit': product.unit,
      'ActualWeight': product.actualWeight ?? 0.0,
      'ExpiryDate': product.expiryDate?.toIso8601String() ?? '',
      'PurchaseDate': product.purchaseDate?.toIso8601String() ?? '',
      'Brand': product.brand ?? '',
      'Price': product.price ?? 0.0,
      'ImageUrl': product.imageUrl ?? '',
      'StorageLocation': product.storageLocation ?? '',
      'DateAdded': product.dateAdded?.toIso8601String() ?? DateTime.now().toIso8601String(),
      // Nutrition information
      'Calories': product.nutritionInfo?.calories ?? 0.0,
      'Protein': product.nutritionInfo?.protein ?? 0.0,
      'Carbs': product.nutritionInfo?.carbs ?? 0.0,
      'Fat': product.nutritionInfo?.fat ?? 0.0,
      'Fiber': product.nutritionInfo?.fiber ?? 0.0,
      'Sugar': product.nutritionInfo?.sugar ?? 0.0,
      'Sodium': product.nutritionInfo?.sodium ?? 0.0,
      'ServingSize': product.nutritionInfo?.servingSize ?? '',
    };

    await _executeTableOperation('POST', _productsTable, '', data: entity);
    print('✅ Product stored successfully: ${product.name}');
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
      print('🔍 AzureTableService.getProducts called for userId: $userId');
      print('📋 Products table: $_productsTable');

      // First try to get all products to test table access
      try {
        final allResponse = await _executeTableOperation(
          'GET',
          _productsTable,
          '()',
        );
        final allData = allResponse.data as Map<String, dynamic>;
        final allValues = allData['value'] as List;
        print('📊 Total products in table: ${allValues.length}');
      } catch (e) {
        print('❌ Cannot access products table: $e');
        return [];
      }

      // Use queryParams so the canonicalized resource used for signing
      // does NOT include the query string (required by SharedKeyLite)
      final response = await _executeTableOperation(
        'GET',
        _productsTable,
        '()',
        queryParams: {
          '\u0024filter': "PartitionKey eq '$userId'",
        },
      );

      final data = response.data as Map<String, dynamic>;
      final values = data['value'] as List;
      print('📊 Azure getProducts returned ${values.length} products for user $userId');
      if (values.isNotEmpty) {
        print('📦 First product sample: ${values[0]}');
        print('🔑 PartitionKey in data: ${values[0]['PartitionKey']}');
        print('🔍 Query userId: $userId');
        print('✅ PartitionKey matches: ${values[0]['PartitionKey'] == userId}');
      } else {
        print('⚠️  No products found for user $userId');
        // Let's also check what partition keys exist in the table
        try {
          final allResponse = await _executeTableOperation(
            'GET',
            _productsTable,
            '()',
          );
          final allData = allResponse.data as Map<String, dynamic>;
          final allValues = allData['value'] as List;
          if (allValues.isNotEmpty) {
            final partitionKeys = allValues.map((p) => p['PartitionKey']).toSet();
            print('🔑 Available PartitionKeys in table: $partitionKeys');
          }
        } catch (e) {
          print('❌ Could not check available partition keys: $e');
        }
      }
      return values.cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      print('❌ Azure getProducts DioException: ${e.message}');
      if (e.response != null) {
        print('❌ Response status: ${e.response?.statusCode}');
        print('❌ Response data: ${e.response?.data}');
      }
      return [];
    } catch (e) {
      print('❌ Azure getProducts error: $e');
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

    await _executeTableOperation('POST', _nutritionTable, '', data: entity);
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

    await _executeTableOperation('POST', _settingsTable, '', data: entity);
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

    await _executeTableOperation('POST', _shoppingListTable, '', data: entity);
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
  Future<void> storeHouseholdMember(
    String userId,
    int memberIndex,
    String ageGroup,
    double dailyCalories,
    double dailyProtein,
    double dailyFat,
    double dailyCarbs,
    double dailyFiber, {
    String? name,
  }) async {
    final memberId = 'member_$memberIndex';

    final entity = {
      'PartitionKey': userId, // Links to user
      'RowKey': memberId,
      'UserId': userId,
      'MemberIndex': memberIndex,
      'AgeGroup': ageGroup,
      'DailyCalories': dailyCalories,
      'DailyProtein': dailyProtein,
      'DailyFat': dailyFat,
      'DailyCarbs': dailyCarbs,
      'DailyFiber': dailyFiber,
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
  Future<void> storeHouseholdMembers(
    String userId,
    List<String> ageGroups,
    List<double> dailyCalories,
    List<double> dailyProtein,
    List<double> dailyFat,
    List<double> dailyCarbs,
    List<double> dailyFiber, {
    List<String>? names,
  }) async {
    // Note: Azure Table Storage REST API doesn't support true batch operations easily
    // We'll store them one by one
    for (int i = 0; i < dailyCalories.length; i++) {
      await storeHouseholdMember(
        userId,
        i + 1,
        ageGroups[i],
        dailyCalories[i],
        dailyProtein[i],
        dailyFat[i],
        dailyCarbs[i],
        dailyFiber[i],
        name: names != null && i < names.length ? names[i] : null,
      );
    }
  }

  /// Get all household members for a user from Households table
  Future<List<Map<String, dynamic>>> getHouseholdMembers(String userId) async {
    try {
      // Query for all entities with PartitionKey = userId
      final response = await _executeTableOperation(
        'GET',
        _householdsTable,
        '()',
        queryParams: {
          '\$filter': "PartitionKey eq '$userId'",
        },
      );

      final data = response.data as Map<String, dynamic>;
      final values = data['value'] as List;
      // Filter for members (RowKey starting with 'member_')
      final members =
          values.where((entity) => (entity['RowKey'] as String).startsWith('member_')).toList();
      return members.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error getting household members: $e');
      return [];
    }
  }

  /// Update household member
  Future<void> updateHouseholdMember(
    String userId,
    int memberIndex,
    String ageGroup,
    double dailyCalories,
    double dailyProtein,
    double dailyFat,
    double dailyCarbs,
    double dailyFiber, {
    String? name,
  }) async {
    final memberId = 'member_$memberIndex';

    final entity = {
      'PartitionKey': userId,
      'RowKey': memberId,
      'AgeGroup': ageGroup,
      'DailyCalories': dailyCalories,
      'DailyProtein': dailyProtein,
      'DailyFat': dailyFat,
      'DailyCarbs': dailyCarbs,
      'DailyFiber': dailyFiber,
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

      return {'profile': profile, 'members': members, 'hasMemberData': members.isNotEmpty};
    } catch (e) {
      print('❌ Error fetching household data: $e');
      return {'profile': null, 'members': <Map<String, dynamic>>[], 'hasData': false};
    }
  }

  /// Delete all user data (for account deletion)
  Future<void> deleteUserData(String userId) async {
    try {
      // Delete user profile from Users table
      await _executeTableOperation('DELETE', _usersTable, "(PartitionKey='user',RowKey='$userId')");

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
