// Copilot Task 2: QR Code Scanner Screen
// Scans barcodes and extracts product information from Open Food Facts

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../providers/inventory_provider.dart';
import '../models/product.dart';
import '../services/barcode_service.dart';
import '../services/azure_table_service.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  MobileScannerController cameraController = MobileScannerController();
  final BarcodeService _barcodeService = BarcodeService();
  bool _isProcessing = false;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera permission is required')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: cameraController.torchState,
              builder: (context, state, child) {
                switch (state) {
                  case TorchState.off:
                    return const Icon(Icons.flash_off);
                  case TorchState.on:
                    return const Icon(Icons.flash_on);
                }
              },
            ),
            onPressed: () => cameraController.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => cameraController.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: (capture) {
              if (!_isProcessing) {
                _onQRScanned(capture);
              }
            },
          ),
          _buildScannerOverlay(),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Scan a product QR code',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Position the QR code within the frame',
                      style: TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _showManualEntryDialog,
                      icon: const Icon(Icons.keyboard),
                      label: const Text('Enter Manually'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay() {
    return Center(
      child: Container(
        width: 250,
        height: 250,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.green, width: 3),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _onQRScanned(BarcodeCapture capture) async {
    setState(() => _isProcessing = true);

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) {
      setState(() => _isProcessing = false);
      return;
    }

    final String? code = barcodes.first.rawValue;
    if (code == null) {
      setState(() => _isProcessing = false);
      return;
    }

    // Parse QR code data (assume JSON format or simple text)
    await _processQRData(code);

    setState(() => _isProcessing = false);
  }

  Future<void> _processQRData(String qrData) async {
    try {
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Looking up product...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // First, try to find the product in the shopping list by barcode
      final azureService = AzureTableService();
      final shoppingItem = await azureService.getShoppingListItemByBarcode(qrData);

      if (shoppingItem != null && mounted) {
        // Product found in shopping list
        _showShoppingListProductDialog(shoppingItem);
      } else {
        // Not found in shopping list, try Open Food Facts API
        final productData = await _barcodeService.getProductByBarcode(qrData);

        if (productData != null && mounted) {
          // Product found in database
          final info = productData['product'] as Map<String, dynamic>;
          final nutrition = productData['nutrition'] as Map<String, dynamic>?;

          final product = Product(
            id: _uuid.v4(),
            name: info['name'] ?? 'Unknown Product',
            barcode: info['barcode'],
            category: info['category'] ?? 'Other',
            brand: info['brand'],
            imageUrl: info['imageUrl'],
            quantity: 1,
            unit: info['unit'] ?? 'pcs',
            purchaseDate: DateTime.now(),
            expiryDate: DateTime.now().add(const Duration(days: 7)), // Default 7 days
          );

          _showProductDialog(product, nutrition: nutrition);
        } else {
          // Product not found anywhere - show manual entry with barcode
          _showManualEntryDialog(barcode: qrData);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error looking up product: $e')),
        );
        _showManualEntryDialog(barcode: qrData);
      }
    }
  }

  void _showProductDialog(Product product, {Map<String, dynamic>? nutrition}) {
    final quantityController = TextEditingController(text: '1');
    final caloriesController =
        TextEditingController(text: nutrition?['calories']?.toString() ?? '');
    final proteinController = TextEditingController(text: nutrition?['protein']?.toString() ?? '');
    final fatController = TextEditingController(text: nutrition?['fat']?.toString() ?? '');
    final carbsController =
        TextEditingController(text: nutrition?['carbohydrates']?.toString() ?? '');
    final fiberController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    final categories = [
      'Fruits & Vegetables',
      'Dairy',
      'Meat & Poultry',
      'Seafood',
      'Grains & Bread',
      'Pantry Staples',
      'Snacks',
      'Beverages',
      'Frozen Foods',
      'Other'
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (product.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            product.imageUrl!,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(Icons.shopping_bag),
                            ),
                          ),
                        ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (product.brand != null)
                              Text(
                                product.brand!,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Category dropdown
                  DropdownButtonFormField<String>(
                    initialValue: product.category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => product.category = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Expiry Date'),
                    subtitle: Text(selectedDate.toString().split(' ')[0]),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Nutrition Information (per 100g) - Edit if needed',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: caloriesController,
                          decoration: const InputDecoration(
                            labelText: 'Calories',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: proteinController,
                          decoration: const InputDecoration(
                            labelText: 'Protein (g)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: fatController,
                          decoration: const InputDecoration(
                            labelText: 'Fat (g)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: carbsController,
                          decoration: const InputDecoration(
                            labelText: 'Carbs (g)',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: fiberController,
                    decoration: const InputDecoration(
                      labelText: 'Fiber (g)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  // Category selector for scanned product (editable)
                  DropdownButtonFormField<String>(
                    initialValue: product.category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      'Fruits & Vegetables',
                      'Dairy',
                      'Meat & Poultry',
                      'Seafood',
                      'Grains & Bread',
                      'Pantry Staples',
                      'Snacks',
                      'Beverages',
                      'Frozen Foods',
                      'Other',
                    ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) {
                      if (v != null) product.category = v;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          // Create nutrition info if any fields are filled
                          NutritionInfo? nutritionInfo;
                          if (caloriesController.text.isNotEmpty ||
                              proteinController.text.isNotEmpty ||
                              fatController.text.isNotEmpty ||
                              carbsController.text.isNotEmpty ||
                              fiberController.text.isNotEmpty) {
                            nutritionInfo = NutritionInfo(
                              calories: double.tryParse(caloriesController.text) ?? 0.0,
                              protein: double.tryParse(proteinController.text) ?? 0.0,
                              fat: double.tryParse(fatController.text) ?? 0.0,
                              carbs: double.tryParse(carbsController.text) ?? 0.0,
                              fiber: double.tryParse(fiberController.text) ?? 0.0,
                            );
                          }

                          final updatedProduct = Product(
                            id: product.id,
                            name: product.name,
                            barcode: product.barcode,
                            category: product.category,
                            brand: product.brand,
                            imageUrl: product.imageUrl,
                            quantity: double.tryParse(quantityController.text) ?? 1.0,
                            unit: product.unit,
                            purchaseDate: DateTime.now(),
                            expiryDate: selectedDate,
                            nutritionInfo: nutritionInfo,
                          );

                          await context.read<InventoryProvider>().addProduct(updatedProduct);
                          if (context.mounted) {
                            // Close the bottom sheet and navigate back to inventory tab
                            Navigator.pop(context);
                            // Navigate to inventory tab (tab 0)
                            DefaultTabController.of(context).animateTo(0);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${product.name} added to inventory')),
                            );
                          }
                        },
                        child: const Text('Add to Inventory'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showShoppingListProductDialog(Map<String, dynamic> shoppingItem) {
    final quantityController = TextEditingController(text: '1');
    double quantity = 1.0;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              shoppingItem['ProductName'] ?? 'Unknown Product',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            if (shoppingItem['Brand'] != null &&
                                shoppingItem['Brand'].toString().isNotEmpty)
                              Text(
                                shoppingItem['Brand'],
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            Text(
                              'Category: ${shoppingItem['Category'] ?? 'Other'}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        quantity = double.tryParse(value) ?? 1.0;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Expiry Date'),
                    subtitle: Text(selectedDate.toString().split(' ')[0]),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() => selectedDate = date);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Product Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Nutrition Information (per 100g/ml)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  _buildShoppingListNutritionDisplay(shoppingItem),
                  const SizedBox(height: 12),
                  const Text(
                    'Total Nutrition (based on quantity)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  _buildShoppingListNutritionDisplay(shoppingItem, quantity: quantity),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          // Calculate nutrition based on shopping item
                          NutritionInfo? nutritionInfo;
                          if (shoppingItem['Calories'] != null ||
                              shoppingItem['Protein'] != null ||
                              shoppingItem['Fat'] != null ||
                              shoppingItem['Carbs'] != null ||
                              shoppingItem['Fiber'] != null) {
                            // Get base values (per 100g/ml)
                            final baseCalories = shoppingItem['Calories']?.toDouble() ?? 0.0;
                            final baseProtein = shoppingItem['Protein']?.toDouble() ?? 0.0;
                            final baseFat = shoppingItem['Fat']?.toDouble() ?? 0.0;
                            final baseCarbs = shoppingItem['Carbs']?.toDouble() ?? 0.0;
                            final baseFiber = shoppingItem['Fiber']?.toDouble() ?? 0.0;

                            // Get actual weight per unit
                            final actualWeightPerUnit =
                                shoppingItem['ActualWeight']?.toDouble() ?? 100.0;
                            final totalActualWeight = actualWeightPerUnit * quantity;
                            final weightMultiplier = totalActualWeight / 100.0;

                            nutritionInfo = NutritionInfo(
                              calories: baseCalories * weightMultiplier,
                              protein: baseProtein * weightMultiplier,
                              fat: baseFat * weightMultiplier,
                              carbs: baseCarbs * weightMultiplier,
                              fiber: baseFiber * weightMultiplier,
                            );
                          }

                          final product = Product(
                            id: _uuid.v4(),
                            name: shoppingItem['ProductName'] ?? 'Unknown Product',
                            barcode: shoppingItem['Barcode'],
                            category: shoppingItem['Category'] ?? 'Other',
                            brand: shoppingItem['Brand'],
                            quantity: quantity,
                            unit: shoppingItem['Unit'] ??
                                ((shoppingItem['Category']?.toString().toLowerCase() ?? '') ==
                                        'beverages'
                                    ? 'ml'
                                    : 'g'),
                            actualWeight: shoppingItem['ActualWeight']?.toDouble(),
                            purchaseDate: DateTime.now(),
                            expiryDate: selectedDate,
                            nutritionInfo: nutritionInfo,
                          );

                          await context.read<InventoryProvider>().addProduct(product);
                          if (context.mounted) {
                            // Close the bottom sheet and navigate back to inventory tab
                            Navigator.pop(context);
                            // Navigate to inventory tab (tab 0)
                            DefaultTabController.of(context).animateTo(0);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${product.name} added to inventory')),
                            );
                          }
                        },
                        child: const Text('Add to Inventory'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShoppingListNutritionDisplay(Map<String, dynamic> item, {double quantity = 1.0}) {
    final calories = item['Calories']?.toDouble() ?? 0.0;
    final protein = item['Protein']?.toDouble() ?? 0.0;
    final fat = item['Fat']?.toDouble() ?? 0.0;
    final carbs = item['Carbs']?.toDouble() ?? 0.0;
    final fiber = item['Fiber']?.toDouble() ?? 0.0;

    // Get actual weight per unit
    final actualWeightPerUnit = item['ActualWeight']?.toDouble() ?? 100.0;
    final totalActualWeight = actualWeightPerUnit * quantity;
    final weightMultiplier = totalActualWeight / 100.0;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildNutritionItem('Calories', calories * weightMultiplier, 'kcal'),
            ),
            Expanded(
              child: _buildNutritionItem('Protein', protein * weightMultiplier, 'g'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildNutritionItem('Fat', fat * weightMultiplier, 'g'),
            ),
            Expanded(
              child: _buildNutritionItem('Carbs', carbs * weightMultiplier, 'g'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildNutritionItem('Fiber', fiber * weightMultiplier, 'g'),
            ),
            const Expanded(child: SizedBox()),
          ],
        ),
      ],
    );
  }

  Widget _buildNutritionItem(String label, double value, String unit) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog({String? barcode}) {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final categoryController = TextEditingController(text: 'Other');
    final caloriesController = TextEditingController();
    final proteinController = TextEditingController();
    final fatController = TextEditingController();
    final carbsController = TextEditingController();
    final fiberController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Product Manually'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (barcode != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Barcode: $barcode\n(Not found in database)',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: categoryController.text,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'Fruits & Vegetables',
                    'Dairy',
                    'Meat & Poultry',
                    'Seafood',
                    'Grains & Bread',
                    'Pantry Staples',
                    'Snacks',
                    'Beverages',
                    'Frozen Foods',
                    'Other',
                  ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) {
                    if (v != null) categoryController.text = v;
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Expiry Date'),
                  subtitle: Text(selectedDate.toString().split(' ')[0]),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => selectedDate = date);
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nutrition Information (per 100g)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: caloriesController,
                        decoration: const InputDecoration(
                          labelText: 'Calories',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: proteinController,
                        decoration: const InputDecoration(
                          labelText: 'Protein (g)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: fatController,
                        decoration: const InputDecoration(
                          labelText: 'Fat (g)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: carbsController,
                        decoration: const InputDecoration(
                          labelText: 'Carbs (g)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: fiberController,
                  decoration: const InputDecoration(
                    labelText: 'Fiber (g)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  // Create nutrition info if any fields are filled
                  NutritionInfo? nutritionInfo;
                  if (caloriesController.text.isNotEmpty ||
                      proteinController.text.isNotEmpty ||
                      fatController.text.isNotEmpty ||
                      carbsController.text.isNotEmpty ||
                      fiberController.text.isNotEmpty) {
                    nutritionInfo = NutritionInfo(
                      calories: double.tryParse(caloriesController.text) ?? 0.0,
                      protein: double.tryParse(proteinController.text) ?? 0.0,
                      fat: double.tryParse(fatController.text) ?? 0.0,
                      carbs: double.tryParse(carbsController.text) ?? 0.0,
                      fiber: double.tryParse(fiberController.text) ?? 0.0,
                    );
                  }

                  final product = Product(
                    id: _uuid.v4(),
                    name: nameController.text,
                    expiryDate: selectedDate,
                    quantity: double.tryParse(quantityController.text) ?? 1.0,
                    unit: 'pcs',
                    barcode: barcode,
                    category: categoryController.text,
                    purchaseDate: DateTime.now(),
                    nutritionInfo: nutritionInfo,
                  );

                  context.read<InventoryProvider>().addProduct(product);
                  Navigator.pop(context); // Close dialog
                  // Navigate to inventory tab (tab 0)
                  DefaultTabController.of(context).animateTo(0);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${product.name} added to inventory')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
