// Product Detail Screen - View and edit product details

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/inventory_provider.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _deleteProduct(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusBanner(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(context),
                  const SizedBox(height: 24),
                  if (product.nutritionInfo != null) ...[
                    _buildNutritionSection(context),
                    const SizedBox(height: 24),
                  ],
                  if (product.storageTips != null) _buildStorageTipsSection(context),
                  const SizedBox(height: 24),
                  _buildQuantityControls(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    Color bannerColor;
    IconData bannerIcon;
    String bannerText;

    if (product.isExpired) {
      bannerColor = Colors.red;
      bannerIcon = Icons.dangerous;
      bannerText = 'Expired ${product.daysUntilExpiry.abs()} days ago';
    } else if (product.isExpiringSoon) {
      bannerColor = Colors.orange;
      bannerIcon = Icons.warning_amber;
      bannerText = 'Expires in ${product.daysUntilExpiry} days';
    } else {
      bannerColor = Colors.green;
      bannerIcon = Icons.check_circle;
      bannerText = '${product.daysUntilExpiry} days until expiry';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      color: bannerColor,
      child: Row(
        children: [
          Icon(bannerIcon, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            bannerText,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            _buildInfoRow('Name', product.name),
            _buildInfoRow('Category', product.category ?? 'Uncategorized'),
            _buildInfoRow('Quantity', product.quantity.toString()),
            _buildInfoRow('Expiry Date', product.expiryDate.toString().split(' ')[0]),
            _buildInfoRow('Storage', product.storageLocation ?? 'Pantry'),
            if (product.barcode != null) _buildInfoRow('Barcode', product.barcode!),
            _buildInfoRow('Added On', product.dateAdded.toString().split(' ')[0]),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildNutritionSection(BuildContext context) {
    final nutrition = product.nutritionInfo!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nutrition Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientCard('Calories', nutrition.calories, 'kcal'),
                _buildNutrientCard('Protein', nutrition.protein, 'g'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientCard('Carbs', nutrition.carbs, 'g'),
                _buildNutrientCard('Fat', nutrition.fat, 'g'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientCard(String label, double value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value.toStringAsFixed(1),
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(unit, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildStorageTipsSection(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tips_and_updates, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Storage Tips',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(product.storageTips!),
          ],
        ),
      ),
    );
  }

  Widget _buildQuantityControls(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update Quantity',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  onPressed: () => _updateQuantity(context, -1),
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: 24),
                Text(
                  product.quantity.toString(),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 24),
                IconButton.filled(
                  onPressed: () => _updateQuantity(context, 1),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _updateQuantity(BuildContext context, int change) async {
    final newQuantity = product.quantity + change;
    if (newQuantity < 0) return;

    await context.read<InventoryProvider>().updateProductQuantity(
          product.id,
          newQuantity,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity updated')),
      );
    }
  }

  void _deleteProduct(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<InventoryProvider>().deleteProduct(product.id);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted')),
        );
      }
    }
  }
}
