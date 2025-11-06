import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Products Collection Reference
  CollectionReference get _productsCollection =>
      _db.collection('users').doc(_userId).collection('products');

  // Shopping List Collection Reference
  CollectionReference get _shoppingListCollection =>
      _db.collection('users').doc(_userId).collection('shopping_list');

  // ============ Product Operations ============

  // Add a product to inventory
  Future<void> addProduct(Product product) async {
    if (_userId == null) throw Exception('User not authenticated');
    
    await _productsCollection.doc(product.id).set({
      'id': product.id,
      'name': product.name,
      'barcode': product.barcode,
      'category': product.category,
      'quantity': product.quantity,
      'unit': product.unit,
      'expiryDate': product.expiryDate?.toIso8601String(),
      'purchaseDate': product.purchaseDate?.toIso8601String(),
      'brand': product.brand,
      'price': product.price,
      'imageUrl': product.imageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update a product
  Future<void> updateProduct(Product product) async {
    if (_userId == null) throw Exception('User not authenticated');
    
    await _productsCollection.doc(product.id).update({
      'name': product.name,
      'barcode': product.barcode,
      'category': product.category,
      'quantity': product.quantity,
      'unit': product.unit,
      'expiryDate': product.expiryDate?.toIso8601String(),
      'purchaseDate': product.purchaseDate?.toIso8601String(),
      'brand': product.brand,
      'price': product.price,
      'imageUrl': product.imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete a product
  Future<void> deleteProduct(String productId) async {
    if (_userId == null) throw Exception('User not authenticated');
    await _productsCollection.doc(productId).delete();
  }

  // Get all products as stream
  Stream<List<Product>> getProducts() {
    if (_userId == null) return Stream.value([]);
    
    return _productsCollection
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Product(
          id: data['id'] ?? doc.id,
          name: data['name'] ?? '',
          barcode: data['barcode'],
          category: data['category'] ?? '',
          quantity: (data['quantity'] ?? 0).toDouble(),
          unit: data['unit'] ?? 'pcs',
          expiryDate: data['expiryDate'] != null 
              ? DateTime.parse(data['expiryDate']) 
              : null,
          purchaseDate: data['purchaseDate'] != null 
              ? DateTime.parse(data['purchaseDate']) 
              : null,
          brand: data['brand'],
          price: data['price']?.toDouble(),
          imageUrl: data['imageUrl'],
        );
      }).toList();
    });
  }

  // Get a single product
  Future<Product?> getProduct(String productId) async {
    if (_userId == null) return null;
    
    final doc = await _productsCollection.doc(productId).get();
    if (!doc.exists) return null;
    
    final data = doc.data() as Map<String, dynamic>;
    return Product(
      id: data['id'] ?? doc.id,
      name: data['name'] ?? '',
      barcode: data['barcode'],
      category: data['category'] ?? '',
      quantity: (data['quantity'] ?? 0).toDouble(),
      unit: data['unit'] ?? 'pcs',
      expiryDate: data['expiryDate'] != null 
          ? DateTime.parse(data['expiryDate']) 
          : null,
      purchaseDate: data['purchaseDate'] != null 
          ? DateTime.parse(data['purchaseDate']) 
          : null,
      brand: data['brand'],
      price: data['price']?.toDouble(),
      imageUrl: data['imageUrl'],
    );
  }

  // ============ Shopping List Operations ============

  // Add item to shopping list
  Future<void> addToShoppingList(Map<String, dynamic> item) async {
    if (_userId == null) throw Exception('User not authenticated');
    
    await _shoppingListCollection.add({
      ...item,
      'completed': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Update shopping list item
  Future<void> updateShoppingListItem(String itemId, Map<String, dynamic> updates) async {
    if (_userId == null) throw Exception('User not authenticated');
    
    await _shoppingListCollection.doc(itemId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete shopping list item
  Future<void> deleteShoppingListItem(String itemId) async {
    if (_userId == null) throw Exception('User not authenticated');
    await _shoppingListCollection.doc(itemId).delete();
  }

  // Get shopping list as stream
  Stream<List<Map<String, dynamic>>> getShoppingList() {
    if (_userId == null) return Stream.value([]);
    
    return _shoppingListCollection
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();
    });
  }

  // Clear completed items from shopping list
  Future<void> clearCompletedItems() async {
    if (_userId == null) throw Exception('User not authenticated');
    
    final snapshot = await _shoppingListCollection
        .where('completed', isEqualTo: true)
        .get();
    
    final batch = _db.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ============ Sync Operations ============

  // Sync local products to cloud
  Future<void> syncProducts(List<Product> localProducts) async {
    if (_userId == null) throw Exception('User not authenticated');
    
    final batch = _db.batch();
    
    for (var product in localProducts) {
      final docRef = _productsCollection.doc(product.id);
      batch.set(docRef, {
        'id': product.id,
        'name': product.name,
        'barcode': product.barcode,
        'category': product.category,
        'quantity': product.quantity,
        'unit': product.unit,
        'expiryDate': product.expiryDate?.toIso8601String(),
        'purchaseDate': product.purchaseDate?.toIso8601String(),
        'brand': product.brand,
        'price': product.price,
        'imageUrl': product.imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    
    await batch.commit();
  }
}
