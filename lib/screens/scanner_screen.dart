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

      // Try to fetch product from Open Food Facts API
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
          expiryDate:
              DateTime.now().add(const Duration(days: 7)), // Default 7 days
        );

        _showProductDialog(product, nutrition: nutrition);
      } else {
        // Product not found - show manual entry with barcode
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
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
                  if (nutrition != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Nutrition Info (per 100g)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        if (nutrition['calories'] != null)
                          Chip(label: Text('${nutrition['calories']} kcal')),
                        if (nutrition['protein'] != null)
                          Chip(
                              label: Text('Protein: ${nutrition['protein']}g')),
                        if (nutrition['fat'] != null)
                          Chip(label: Text('Fat: ${nutrition['fat']}g')),
                        if (nutrition['carbohydrates'] != null)
                          Chip(
                              label: Text(
                                  'Carbs: ${nutrition['carbohydrates']}g')),
                      ],
                    ),
                  ],
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
                          final updatedProduct = Product(
                            id: product.id,
                            name: product.name,
                            barcode: product.barcode,
                            category: product.category,
                            brand: product.brand,
                            imageUrl: product.imageUrl,
                            quantity:
                                double.tryParse(quantityController.text) ?? 1.0,
                            unit: product.unit,
                            purchaseDate: DateTime.now(),
                            expiryDate: selectedDate,
                          );

                          await context
                              .read<InventoryProvider>()
                              .addProduct(updatedProduct);
                          if (context.mounted) {
                            Navigator.pop(context);
                            Navigator.pop(
                                context); // Go back to previous screen
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      '${product.name} added to inventory')),
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
                  final product = Product(
                    id: _uuid.v4(),
                    name: nameController.text,
                    expiryDate: selectedDate,
                    quantity: double.tryParse(quantityController.text) ?? 1.0,
                    unit: 'pcs',
                    barcode: barcode,
                    category: 'Other',
                    purchaseDate: DateTime.now(),
                  );

                  context.read<InventoryProvider>().addProduct(product);
                  Navigator.pop(context);
                  Navigator.pop(context); // Go back to previous screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('${product.name} added to inventory')),
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
