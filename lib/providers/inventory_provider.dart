// Copilot Task 3: Inventory Provider - State Management for Products
// Manages CRUD operations for the product inventory using Hive and Firestore sync

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/product.dart';
import '../services/firestore_service.dart';

class InventoryProvider extends ChangeNotifier {
  late Box _productBox;
  List<Product> _products = [];
  final FirestoreService _firestoreService = FirestoreService();
  bool _isOnline = false;

  List<Product> get products => _products;
  bool get isOnline => _isOnline;

  InventoryProvider() {
    _init();
  }

  Future<void> _init() async {
    _productBox = Hive.box('products');
    _loadProducts();
    _subscribeToFirestore();
  }

  void _loadProducts() {
    _products = _productBox.values.cast<Product>().toList();
    notifyListeners();
  }

  // Subscribe to Firestore updates
  void _subscribeToFirestore() {
    _firestoreService.getProducts().listen((cloudProducts) {
      _isOnline = true;
      // Merge cloud products with local
      for (var cloudProduct in cloudProducts) {
        _productBox.put(cloudProduct.id, cloudProduct);
      }
      _loadProducts();
    }, onError: (error) {
      _isOnline = false;
      print('Firestore sync error: $error');
    });
  }

  // Create - Add a new product
  Future<void> addProduct(Product product) async {
    await _productBox.put(product.id, product);
    
    // Sync to Firestore
    try {
      await _firestoreService.addProduct(product);
    } catch (e) {
      print('Error syncing to Firestore: $e');
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
    
    // Sync to Firestore
    try {
      await _firestoreService.updateProduct(product);
    } catch (e) {
      print('Error syncing to Firestore: $e');
    }
    
    _loadProducts();
  }

  // Delete - Remove a product
  Future<void> deleteProduct(String id) async {
    await _productBox.delete(id);
    
    // Sync to Firestore
    try {
      await _firestoreService.deleteProduct(id);
    } catch (e) {
      print('Error syncing to Firestore: $e');
    }
    
    _loadProducts();
  }

  // Check if product already exists (for over-purchase alert)
  bool checkIfProductExists(String name) {
    return _products.any((p) => 
      p.name.toLowerCase() == name.toLowerCase() && p.quantity > 0
    );
  }

  // Get existing product by name
  Product? getProductByName(String name) {
    try {
      return _products.firstWhere(
        (p) => p.name.toLowerCase() == name.toLowerCase()
      );
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
    try {
      await _firestoreService.syncProducts(_products);
      _isOnline = true;
      notifyListeners();
    } catch (e) {
      _isOnline = false;
      print('Error syncing to cloud: $e');
    }
  }
}
