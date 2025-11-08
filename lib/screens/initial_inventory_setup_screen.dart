// Initial Inventory Setup Screen
// Allows users to scan or manually enter existing food items at home for initial inventory setup

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uuid/uuid.dart';
import '../providers/inventory_provider.dart';
import '../models/product.dart';
import '../services/barcode_service.dart';

class InitialInventorySetupScreen extends StatefulWidget {
  const InitialInventorySetupScreen({super.key});

  @override
  State<InitialInventorySetupScreen> createState() => _InitialInventorySetupScreenState();
}

class _InitialInventorySetupScreenState extends State<InitialInventorySetupScreen> {
  MobileScannerController cameraController = MobileScannerController();
  final BarcodeService _barcodeService = BarcodeService();
  bool _isProcessing = false;
  final Uuid _uuid = const Uuid();
  final List<Product> _setupProducts = [];
  bool _isScanningMode = true;

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
          const SnackBar(content: Text('Camera permission is required for scanning')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Initial Inventory Setup'),
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
      body: Column(
        children: [
          // Mode toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).colorScheme.surface,
            child: Row(
              children: [
                Expanded(
                  child: SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment<bool>(
                        value: true,
                        label: Text('Scan Items'),
                        icon: Icon(Icons.qr_code_scanner),
                      ),
                      ButtonSegment<bool>(
                        value: false,
                        label: Text('Manual Entry'),
                        icon: Icon(Icons.keyboard),
                      ),
                    ],
                    selected: {_isScanningMode},
                    onSelectionChanged: (Set<bool> selected) {
                      setState(() {
                        _isScanningMode = selected.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),

          // Main content area
          Expanded(
            child: _isScanningMode ? _buildScannerView() : _buildManualEntryView(),
          ),

          // Product list and finish button
          if (_setupProducts.isNotEmpty) _buildProductList(),

          // Bottom action bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${_setupProducts.length} items added',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _setupProducts.isEmpty ? null : _finishSetup,
                  icon: const Icon(Icons.check),
                  label: const Text('Finish Setup'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: cameraController,
          onDetect: (capture) {
            if (!_isProcessing) {
              _onQRScanned(capture);
            }
          },
        ),
        Center(
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.green, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
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
                    'Scan product QR codes',
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
    );
  }

  Widget _buildManualEntryView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Add items manually',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter details for each item in your inventory',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showManualEntryDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(8),
        itemCount: _setupProducts.length,
        itemBuilder: (context, index) {
          final product = _setupProducts[index];
          return Card(
            margin: const EdgeInsets.only(right: 8),
            child: Container(
              width: 100,
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  if (product.imageUrl != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        product.imageUrl!,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2, size: 40),
                      ),
                    )
                  else
                    const Icon(Icons.inventory_2, size: 40),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    '${product.quantity} ${product.unit}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 16),
                    onPressed: () => _removeProduct(index),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          );
        },
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

    await _processQRData(code);
    setState(() => _isProcessing = false);
  }

  Future<void> _processQRData(String qrData) async {
    try {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                SizedBox(width: 16),
                Text('Looking up product...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final productData = await _barcodeService.getProductByBarcode(qrData);

      if (productData != null && mounted) {
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
          expiryDate: DateTime.now().add(const Duration(days: 7)),
        );

        _showProductDialog(product, nutrition: nutrition);
      } else {
        _showManualEntryDialog(barcode: qrData);
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
    DateTime selectedDate = product.expiryDate ?? DateTime.now().add(const Duration(days: 7));

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

                  // Quantity
                  TextField(
                    controller: quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Current Stock Quantity',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),

                  // Expiry date
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
                        onPressed: () {
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
                            dateAdded: DateTime.now(),
                            nutritionInfo: nutritionInfo,
                          );

                          setState(() => _setupProducts.add(updatedProduct));
                          Navigator.pop(context);

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${product.name} added to setup')),
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
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      categoryController.text = value;
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Current Stock Quantity',
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
                    dateAdded: DateTime.now(),
                    nutritionInfo: nutritionInfo,
                  );

                  setState(() => _setupProducts.add(product));
                  Navigator.pop(context);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${product.name} added to setup')),
                    );
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _removeProduct(int index) {
    setState(() {
      _setupProducts.removeAt(index);
    });
  }

  Future<void> _finishSetup() async {
    if (_setupProducts.isEmpty) return;

    try {
      final inventoryProvider = context.read<InventoryProvider>();

      // Add all products to inventory
      for (final product in _setupProducts) {
        await inventoryProvider.addProduct(product);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${_setupProducts.length} items to your inventory!')),
        );

        // Navigate back to home
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving inventory: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
