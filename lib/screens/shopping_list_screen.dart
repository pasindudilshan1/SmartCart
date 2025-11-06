// Copilot Task 6: Smart Shopping List Screen
// Auto-suggests items based on low stock and allows manual additions

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/product.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final List<String> _manualItems = [];
  final _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _exportList,
          ),
        ],
      ),
      body: Consumer<InventoryProvider>(
        builder: (context, inventoryProvider, child) {
          final lowStockProducts = inventoryProvider.getLowStockProducts();

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildInfoCard(),
              const SizedBox(height: 16),
              _buildSectionHeader('Need to Restock', lowStockProducts.length),
              if (lowStockProducts.isEmpty)
                _buildEmptySection('All items are well stocked! 🎉')
              else
                ...lowStockProducts.map((product) => _buildProductTile(product, inventoryProvider)),
              const SizedBox(height: 24),
              _buildSectionHeader('Manual Additions', _manualItems.length),
              if (_manualItems.isEmpty)
                _buildEmptySection('Add items manually using the button below')
              else
                ..._manualItems.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return _buildManualItemTile(item, index);
                }),
              const SizedBox(height: 16),
              _buildAddItemCard(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddItemDialog,
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Add Item'),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.green.shade700),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Items with low stock (≤2) are automatically added to this list',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Text(
            message,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductTile(Product product, InventoryProvider provider) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: Text(
            product.quantity.toString(),
            style: TextStyle(
              color: Colors.orange.shade900,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(product.name),
        subtitle: Text('Current stock: ${product.quantity} | ${product.storageLocation ?? 'pantry'}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
              onPressed: () async {
                await provider.updateProductQuantity(product.id, product.quantity + 1);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${product.name} stock updated')),
                  );
                }
              },
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
        onTap: () {
          _showRestockDialog(product, provider);
        },
      ),
    );
  }

  Widget _buildManualItemTile(String item, int index) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.shopping_basket),
        ),
        title: Text(item),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            setState(() {
              _manualItems.removeAt(index);
            });
          },
        ),
      ),
    );
  }

  Widget _buildAddItemCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: 'Enter item name...',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) => _addManualItem(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addManualItem,
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _addManualItem() {
    if (_textController.text.isNotEmpty) {
      setState(() {
        _manualItems.add(_textController.text);
        _textController.clear();
      });
    }
  }

  void _showAddItemDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Shopping Item'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Item name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                setState(() {
                  _manualItems.add(controller.text);
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showRestockDialog(Product product, InventoryProvider provider) {
    final quantityController = TextEditingController(text: '3');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restock ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current quantity: ${product.quantity}'),
            const SizedBox(height: 16),
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Add quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final addQuantity = int.tryParse(quantityController.text) ?? 0;
              if (addQuantity > 0) {
                await provider.updateProductQuantity(
                  product.id,
                  product.quantity + addQuantity,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${product.name} restocked')),
                  );
                }
              }
            },
            child: const Text('Restock'),
          ),
        ],
      ),
    );
  }

  void _exportList() {
    final inventoryProvider = context.read<InventoryProvider>();
    final lowStockProducts = inventoryProvider.getLowStockProducts();
    
    final allItems = [
      ...lowStockProducts.map((p) => p.name),
      ..._manualItems,
    ];

    if (allItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shopping list is empty')),
      );
      return;
    }

    // For now, just show a dialog. In production, you could export to PDF or share
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shopping List'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: allItems.map((item) => Text('• $item')).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}
