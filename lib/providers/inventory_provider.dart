// Copilot Task 3: Inventory Provider - State Management for Products
// Manages CRUD operations for the product inventory using Hive and Azure Table sync

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/product.dart';
import '../services/azure_table_service.dart';

class InventoryProvider extends ChangeNotifier {
  late Box _productBox;
  List<Product> _products = [];
  final AzureTableService _azureService = AzureTableService();
  bool _isOnline = false;
  String? _currentUserId;

  List<Product> get products => _products;
  bool get isOnline => _isOnline;

  InventoryProvider() {
    _init();
  }

  /// Set the current user ID (call this after login)
  void setUserId(String? userId) {
    _currentUserId = userId;
    debugPrint('🔑 InventoryProvider: setUserId called with userId: $userId');
    if (userId != null) {
      _syncWithAzure();
    }
  }

  Future<void> _init() async {
    _productBox = Hive.box('products');
    _loadProducts();
  }

  void _loadProducts() {
    _products = _productBox.values.cast<Product>().toList();
    debugPrint('📱 Loaded ${_products.length} products from local storage');
    if (_products.isNotEmpty) {
      debugPrint('📦 Sample product: ${_products[0].name}');
    }
    notifyListeners();
  }

  // Sync with Azure Table Storage
  Future<void> _syncWithAzure() async {
    debugPrint('🔄 _syncWithAzure called with userId: $_currentUserId');
    if (_currentUserId == null) {
      debugPrint('❌ _syncWithAzure: userId is null, returning');
      return;
    }

    try {
      // First check if we have any products locally
      final localProducts = _productBox.values.cast<Product>().toList();
      debugPrint('📦 Local products count: ${localProducts.length}');

      if (localProducts.isEmpty) {
        debugPrint('☁️  Local storage is empty, fetching from Azure...');
        // Local storage is empty, fetch from Azure and store locally
        final cloudProducts = await _azureService.getProducts(_currentUserId!);
        debugPrint('☁️  Fetched ${cloudProducts.length} products from Azure');

        _isOnline = true;

        // Store cloud products locally
        for (var cloudData in cloudProducts) {
          final product = _parseProductFromAzure(cloudData);
          if (product != null) {
            await _productBox.put(product.id, product);
            debugPrint('💾 Stored product locally: ${product.name}');
          }
        }
        _loadProducts();
        debugPrint('✅ Synced ${cloudProducts.length} products from Azure to local storage');
      } else {
        // Local storage has products, mark as online but don't overwrite
        _isOnline = true;
        debugPrint('ℹ️  Local storage has ${localProducts.length} products, skipping Azure sync');
      }
    } catch (e) {
      _isOnline = false;
      debugPrint('❌ Azure sync error: $e');
    }
  }

  // Public method to sync from Azure Table Storage
  Future<void> syncFromCloud() async {
    debugPrint('🔄 syncFromCloud called with userId: $_currentUserId');
    if (_currentUserId == null) {
      debugPrint('❌ syncFromCloud: userId is null, returning');
      return;
    }

    try {
      debugPrint('☁️  Fetching products from Azure...');
      final cloudProducts = await _azureService.getProducts(_currentUserId!);
      debugPrint('☁️  Fetched ${cloudProducts.length} products from Azure');

      _isOnline = true;

      // Clear local storage and replace with cloud data
      await _productBox.clear();

      // Store cloud products locally
      for (var cloudData in cloudProducts) {
        final product = _parseProductFromAzure(cloudData);
        if (product != null) {
          await _productBox.put(product.id, product);
          debugPrint('💾 Stored product locally: ${product.name}');
        }
      }
      _loadProducts();
      debugPrint('✅ Synced ${cloudProducts.length} products from Azure to local storage');
    } catch (e) {
      _isOnline = false;
      debugPrint('❌ Azure sync error: $e');
    }
  }

  // Parse product from Azure Table data
  Product? _parseProductFromAzure(Map<String, dynamic> data) {
    try {
      // Parse nutrition info if available
      NutritionInfo? nutritionInfo;
      if ((data['Calories'] ?? 0.0) > 0 ||
          (data['Protein'] ?? 0.0) > 0 ||
          (data['Carbs'] ?? 0.0) > 0 ||
          (data['Fat'] ?? 0.0) > 0) {
        nutritionInfo = NutritionInfo(
          calories: (data['Calories'] ?? 0.0).toDouble(),
          protein: (data['Protein'] ?? 0.0).toDouble(),
          carbs: (data['Carbs'] ?? 0.0).toDouble(),
          fat: (data['Fat'] ?? 0.0).toDouble(),
          fiber: (data['Fiber'] ?? 0.0).toDouble(),
          servingSize: data['ServingSize']?.isEmpty == true ? null : data['ServingSize'],
        );
      }

      return Product(
        id: data['RowKey'] ?? '',
        name: data['Name'] ?? '',
        barcode: data['Barcode']?.isEmpty == true ? null : data['Barcode'],
        category: data['Category'] ?? 'Other',
        quantity: (data['Quantity'] ?? 0).toDouble(),
        unit: data['Unit'] ?? 'pcs',
        actualWeight: data['ActualWeight']?.toDouble(),
        expiryDate:
            data['ExpiryDate']?.isEmpty == true ? null : DateTime.tryParse(data['ExpiryDate']),
        purchaseDate:
            data['PurchaseDate']?.isEmpty == true ? null : DateTime.tryParse(data['PurchaseDate']),
        brand: data['Brand']?.isEmpty == true ? null : data['Brand'],
        price: data['Price']?.toDouble(),
        imageUrl: data['ImageUrl']?.isEmpty == true ? null : data['ImageUrl'],
        storageLocation: data['StorageLocation']?.isEmpty == true ? null : data['StorageLocation'],
        dateAdded: data['DateAdded']?.isEmpty == true ? null : DateTime.tryParse(data['DateAdded']),
        nutritionInfo: nutritionInfo,
      );
    } catch (e) {
      debugPrint('Error parsing product: $e');
      return null;
    }
  }

  // Create - Add a new product
  Future<void> addProduct(Product product) async {
    await _productBox.put(product.id, product);

    // Sync to Azure Table Storage
    if (_currentUserId != null) {
      try {
        await _azureService.storeProduct(_currentUserId!, product);
        _isOnline = true;
      } catch (e) {
        _isOnline = false;
        debugPrint('Error syncing to Azure: $e');
      }
    }

    _loadProducts();
  }

  // Read - Get all products
  List<Product> getAllProducts() {
    return _products;
  }

  // Read - Get product by ID
  Product? getProductById(String id) {
    return _productBox.get(id);
  }

  // Read - Get products by category
  List<Product> getProductsByCategory(String category) {
    return _products.where((p) => p.category == category).toList();
  }

  // Read - Get expiring products
  List<Product> getExpiringProducts() {
    return _products.where((p) => p.isExpiringSoon && !p.isExpired).toList();
  }

  // Read - Get expired products
  List<Product> getExpiredProducts() {
    return _products.where((p) => p.isExpired).toList();
  }

  // Read - Get low stock products
  List<Product> getLowStockProducts() {
    return _products.where((p) => p.isLowStock).toList();
  }

  // Read - Get products by storage location
  List<Product> getProductsByLocation(String location) {
    return _products.where((p) => p.storageLocation == location).toList();
  }

  // Update - Update product quantity
  Future<void> updateProductQuantity(String id, double newQuantity) async {
    final product = getProductById(id);
    if (product != null) {
      // Recalculate nutrition if product has nutrition info and actual weight
      NutritionInfo? updatedNutritionInfo = product.nutritionInfo;
      if (product.nutritionInfo != null &&
          product.actualWeight != null &&
          product.actualWeight! > 0) {
        final actualWeight = product.actualWeight!;
        final currentQuantity = product.quantity;
        final weightFactor = actualWeight / 100.0;

        // Calculate per-100g values from current total nutrition
        final per100gCalories = product.nutritionInfo!.calories / (weightFactor * currentQuantity);
        final per100gProtein = product.nutritionInfo!.protein / (weightFactor * currentQuantity);
        final per100gFat = product.nutritionInfo!.fat / (weightFactor * currentQuantity);
        final per100gCarbs = product.nutritionInfo!.carbs / (weightFactor * currentQuantity);
        final per100gFiber = product.nutritionInfo!.fiber / (weightFactor * currentQuantity);

        // Calculate new total nutrition for new quantity
        final newTotalFactor = weightFactor * newQuantity;
        updatedNutritionInfo = NutritionInfo(
          calories: per100gCalories * newTotalFactor,
          protein: per100gProtein * newTotalFactor,
          fat: per100gFat * newTotalFactor,
          carbs: per100gCarbs * newTotalFactor,
          fiber: per100gFiber * newTotalFactor,
          servingSize: product.nutritionInfo!.servingSize,
        );
      }

      // Create updated product with new quantity and recalculated nutrition
      final updatedProduct = Product(
        id: product.id,
        name: product.name,
        barcode: product.barcode,
        category: product.category,
        brand: product.brand,
        imageUrl: product.imageUrl,
        quantity: newQuantity,
        unit: product.unit,
        actualWeight: product.actualWeight,
        purchaseDate: product.purchaseDate,
        expiryDate: product.expiryDate,
        nutritionInfo: updatedNutritionInfo,
        storageLocation: product.storageLocation,
        dateAdded: product.dateAdded,
        storageTips: product.storageTips,
      );

      await updateProduct(updatedProduct);
    }
  }

  // Update - Modify product
  Future<void> updateProduct(Product product) async {
    await _productBox.put(product.id, product);

    // Sync to Azure Table Storage
    if (_currentUserId != null) {
      try {
        await _azureService.updateProduct(_currentUserId!, product);
        _isOnline = true;
      } catch (e) {
        _isOnline = false;
        debugPrint('Error syncing to Azure: $e');
      }
    }

    _loadProducts();
  }

  // Delete - Remove a product
  Future<void> deleteProduct(String id) async {
    await _productBox.delete(id);

    // Sync to Azure Table Storage
    if (_currentUserId != null) {
      try {
        await _azureService.deleteProduct(_currentUserId!, id);
        _isOnline = true;
      } catch (e) {
        _isOnline = false;
        debugPrint('Error syncing to Azure: $e');
      }
    }

    _loadProducts();
  }

  // Check if product already exists (for over-purchase alert)
  bool checkIfProductExists(String name) {
    return _products.any((p) => p.name.toLowerCase() == name.toLowerCase() && p.quantity > 0);
  }

  // Get existing product by name
  Product? getProductByName(String name) {
    try {
      return _products.firstWhere((p) => p.name.toLowerCase() == name.toLowerCase());
    } catch (e) {
      return null;
    }
  }

  // Get total number of items in inventory
  int get totalItems {
    return _products.fold(0, (sum, product) => sum + product.quantity.toInt());
  }

  // Get inventory value (estimated)
  double get estimatedValue {
    return _products.fold(
      0.0,
      (sum, product) => sum + (product.price ?? 5.0) * product.quantity,
    );
  }

  // Clean up expired products
  Future<void> removeExpiredProducts() async {
    final expiredProducts = getExpiredProducts();
    for (var product in expiredProducts) {
      await deleteProduct(product.id);
    }
  }

  // Sync all local products to cloud
  Future<void> syncToCloud() async {
    if (_currentUserId == null) return;

    try {
      // Sync all products to Azure
      for (var product in _products) {
        await _azureService.storeProduct(_currentUserId!, product);
      }
      _isOnline = true;
      notifyListeners();
      debugPrint('Synced ${_products.length} products to Azure');
    } catch (e) {
      _isOnline = false;
      debugPrint('Error syncing to Azure: $e');
    }
  }

  // Clear all local products (for testing)
  Future<void> clearLocalStorage() async {
    await _productBox.clear();
    _loadProducts();
    debugPrint('🗑️ Cleared all local products');
  }

  // Calculate total nutrition from all inventory products
  Map<String, double> getTotalInventoryNutrition() {
    double totalCalories = 0.0;
    double totalProtein = 0.0;
    double totalCarbs = 0.0;
    double totalFat = 0.0;
    double totalFiber = 0.0;

    for (var product in _products) {
      if (product.nutritionInfo != null) {
        // Calculate nutrition based on quantity and unit
        double multiplier = 1.0;

        // If we have actual weight, use it for calculation
        if (product.actualWeight != null && product.actualWeight! > 0) {
          // Nutrition info is per 100g, so divide by 100 and multiply by actual weight
          multiplier = product.actualWeight! / 100.0;
        } else {
          // Fallback to quantity if no actual weight
          multiplier = product.quantity;
        }

        totalCalories += product.nutritionInfo!.calories * multiplier;
        totalProtein += product.nutritionInfo!.protein * multiplier;
        totalCarbs += product.nutritionInfo!.carbs * multiplier;
        totalFat += product.nutritionInfo!.fat * multiplier;
        totalFiber += product.nutritionInfo!.fiber * multiplier;
      }
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
      'fiber': totalFiber,
    };
  }
}
