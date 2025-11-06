import 'package:dio/dio.dart';
import '../models/product.dart';
import '../models/nutrition.dart';

class BarcodeService {
  final Dio _dio = Dio();
  static const String _baseUrl = 'https://world.openfoodfacts.org/api/v2';

  // Fetch product information by barcode
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/product/$barcode.json',
        options: Options(
          headers: {
            'User-Agent': 'SmartCart - Food Waste Reduction App',
          },
        ),
      );

      if (response.statusCode == 200 && response.data['status'] == 1) {
        final product = response.data['product'];
        return _parseProductData(product, barcode);
      }
      return null;
    } catch (e) {
      print('Error fetching product: $e');
      return null;
    }
  }

  // Parse product data from Open Food Facts API
  Map<String, dynamic> _parseProductData(Map<String, dynamic> data, String barcode) {
    // Extract basic product info
    final productInfo = {
      'barcode': barcode,
      'name': data['product_name'] ?? data['product_name_en'] ?? 'Unknown Product',
      'brand': data['brands'] ?? '',
      'category': _extractCategory(data),
      'imageUrl': data['image_url'] ?? data['image_front_url'],
      'quantity': _extractQuantity(data),
      'unit': _extractUnit(data),
    };

    // Extract nutrition data
    final nutritionData = _extractNutritionData(data);

    return {
      'product': productInfo,
      'nutrition': nutritionData,
      'sustainability': _extractSustainabilityData(data),
    };
  }

  // Extract category from product data
  String _extractCategory(Map<String, dynamic> data) {
    if (data['categories'] != null && data['categories'].toString().isNotEmpty) {
      final categories = data['categories'].toString().split(',');
      if (categories.isNotEmpty) {
        return categories.first.trim();
      }
    }
    return 'Other';
  }

  // Extract quantity from product data
  double _extractQuantity(Map<String, dynamic> data) {
    if (data['product_quantity'] != null) {
      return data['product_quantity'].toDouble();
    }
    if (data['quantity'] != null) {
      // Try to parse quantity string like "500g" or "1L"
      final quantityStr = data['quantity'].toString();
      final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(quantityStr);
      if (match != null) {
        return double.tryParse(match.group(1)!) ?? 1.0;
      }
    }
    return 1.0;
  }

  // Extract unit from product data
  String _extractUnit(Map<String, dynamic> data) {
    if (data['quantity'] != null) {
      final quantityStr = data['quantity'].toString().toLowerCase();
      if (quantityStr.contains('kg')) return 'kg';
      if (quantityStr.contains('g')) return 'g';
      if (quantityStr.contains('l')) return 'L';
      if (quantityStr.contains('ml')) return 'ml';
    }
    return 'pcs';
  }

  // Extract nutrition data
  Map<String, dynamic>? _extractNutritionData(Map<String, dynamic> data) {
    final nutriments = data['nutriments'];
    if (nutriments == null) return null;

    return {
      'calories': _getDoubleValue(nutriments, 'energy-kcal_100g'),
      'protein': _getDoubleValue(nutriments, 'proteins_100g'),
      'carbohydrates': _getDoubleValue(nutriments, 'carbohydrates_100g'),
      'fat': _getDoubleValue(nutriments, 'fat_100g'),
      'fiber': _getDoubleValue(nutriments, 'fiber_100g'),
      'sugar': _getDoubleValue(nutriments, 'sugars_100g'),
      'sodium': _getDoubleValue(nutriments, 'sodium_100g'),
      'servingSize': data['serving_size'] ?? '100g',
      'nutriScore': data['nutriscore_grade']?.toString().toUpperCase(),
      'novaGroup': _getIntValue(data, 'nova_group'),
    };
  }

  // Extract sustainability/eco data
  Map<String, dynamic>? _extractSustainabilityData(Map<String, dynamic> data) {
    return {
      'ecoScore': data['ecoscore_grade']?.toString().toUpperCase(),
      'ecoScoreValue': _getIntValue(data, 'ecoscore_score'),
      'packagingInfo': data['packaging'] ?? '',
      'origins': data['origins'] ?? '',
      'labels': data['labels'] ?? '',
      'carbonFootprint': _getDoubleValue(data['ecoscore_data'] ?? {}, 'adjustments.production_system.value'),
    };
  }

  // Helper to safely get double value
  double? _getDoubleValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  // Helper to safely get int value
  int? _getIntValue(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Search products by name
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    try {
      final response = await _dio.get(
        '$_baseUrl/search',
        queryParameters: {
          'search_terms': query,
          'page_size': 20,
          'json': 1,
        },
        options: Options(
          headers: {
            'User-Agent': 'SmartCart - Food Waste Reduction App',
          },
        ),
      );

      if (response.statusCode == 200) {
        final products = response.data['products'] as List;
        return products.map((product) {
          return {
            'barcode': product['code'] ?? '',
            'name': product['product_name'] ?? 'Unknown',
            'brand': product['brands'] ?? '',
            'imageUrl': product['image_url'],
          };
        }).toList();
      }
      return [];
    } catch (e) {
      print('Error searching products: $e');
      return [];
    }
  }
}
