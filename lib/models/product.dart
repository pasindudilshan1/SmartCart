// Copilot Task 3: Local Inventory System - Product Model
// This file defines the Product model with Hive annotations for local storage

import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 0)
class Product extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  DateTime? expiryDate;

  @HiveField(3)
  double quantity;

  @HiveField(4)
  String unit; // pcs, kg, g, L, ml, etc.

  @HiveField(5)
  String? barcode;

  @HiveField(6)
  String category;

  @HiveField(7)
  String? imageUrl;

  @HiveField(8)
  DateTime? purchaseDate;

  @HiveField(9)
  String? brand;

  @HiveField(10)
  double? price;

  @HiveField(11)
  String? storageLocation;

  @HiveField(12)
  DateTime? dateAdded;

  @HiveField(13)
  NutritionInfo? nutritionInfo;

  @HiveField(14)
  String? storageTips;

  @HiveField(15)
  double? actualWeight; // in grams

  Product({
    required this.id,
    required this.name,
    this.expiryDate,
    this.quantity = 1.0,
    this.unit = 'pcs',
    this.barcode,
    this.category = 'Other',
    this.imageUrl,
    this.purchaseDate,
    this.brand,
    this.price,
    this.storageLocation,
    this.dateAdded,
    this.nutritionInfo,
    this.storageTips,
    this.actualWeight,
  });

  // Calculate days until expiry
  int get daysUntilExpiry {
    if (expiryDate == null) return 999;
    // Normalize both dates to midnight for accurate day comparison
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate!.year, expiryDate!.month, expiryDate!.day);
    return expiry.difference(today).inDays;
  }

  // Check if product is expired
  bool get isExpired => expiryDate != null && daysUntilExpiry < 0;

  // Check if expiring soon (within 3 days)
  bool get isExpiringSoon => expiryDate != null && daysUntilExpiry >= 0 && daysUntilExpiry <= 3;

  // Check if low stock (quantity <= 2)
  bool get isLowStock => quantity <= 2;

  @override
  String toString() {
    return 'Product{name: $name, quantity: $quantity, expiryDate: $expiryDate}';
  }
}

@HiveType(typeId: 5)
class NutritionInfo {
  @HiveField(0)
  double calories;

  @HiveField(1)
  double protein; // in grams

  @HiveField(2)
  double carbs; // in grams

  @HiveField(3)
  double fat; // in grams

  @HiveField(4)
  double fiber; // in grams

  @HiveField(5)
  String? servingSize;

  NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0.0,
    this.servingSize,
  });

  @override
  String toString() {
    return 'NutritionInfo{calories: $calories, protein: $protein, carbs: $carbs, fat: $fat}';
  }
}
