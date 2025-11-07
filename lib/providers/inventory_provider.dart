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
    notifyListeners();
  }

  // Sync with Azure Table Storage
  Future<void> _syncWithAzure() async {
    if (_currentUserId == null) return;

    try {
      final cloudProducts = await _azureService.getProducts(_currentUserId!);
      _isOnline = true;

      // Merge cloud products with local (cloud is source of truth)
      for (var cloudData in cloudProducts) {
        final product = _parseProductFromAzure(cloudData);
        if (product != null) {
          await _productBox.put(product.id, product);
        }
      }
      _loadProducts();
    } catch (e) {
      _isOnline = false;
      debugPrint('Azure sync error: $e');
    }
  }

  // Parse product from Azure Table data
  Product? _parseProductFromAzure(Map<String, dynamic> data) {
    try {
      return Product(
        id: data['RowKey'] ?? '',
        name: data['Name'] ?? '',
        barcode: data['Barcode']?.isEmpty == true ? null : data['Barcode'],
        category: data['Category'] ?? 'Other',
        quantity: (data['Quantity'] ?? 0).toDouble(),
        unit: data['Unit'] ?? 'pcs',
        expiryDate:
            data['ExpiryDate']?.isEmpty == true ? null : DateTime.tryParse(data['ExpiryDate']),
        purchaseDate:
            data['PurchaseDate']?.isEmpty == true ? null : DateTime.tryParse(data['PurchaseDate']),
        brand: data['Brand']?.isEmpty == true ? null : data['Brand'],
        price: data['Price']?.toDouble(),
        imageUrl: data['ImageUrl']?.isEmpty == true ? null : data['ImageUrl'],
        storageLocation: data['StorageLocation']?.isEmpty == true ? null : data['StorageLocation'],
        dateAdded: data['DateAdded']?.isEmpty == true ? null : DateTime.tryParse(data['DateAdded']),
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
      product.quantity = newQuantity;
      await product.save();
      _loadProducts();
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
}
