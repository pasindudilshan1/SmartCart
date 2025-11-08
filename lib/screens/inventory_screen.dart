// Copilot Task 3: Inventory Screen - Display and Manage Products
// Shows all products with filtering by location and expiry status

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/inventory_provider.dart';
import '../models/product.dart';
import 'product_detail_screen.dart';
import '../widgets/product_card.dart';
import 'initial_inventory_setup_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _selectedFilter = 'All';
  String _selectedLocation = 'All';

  @override
  void initState() {
    super.initState();
    // Sync with Azure when screen loads to ensure we have latest products
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().syncFromCloud();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            icon: const Icon(Icons.eco),
            onPressed: () {
              // Navigate to sustainability insights
              Navigator.pushNamed(context, '/sustainability');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // Navigate to settings
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: Consumer<InventoryProvider>(
              builder: (context, inventoryProvider, child) {
                final products = _getFilteredProducts(inventoryProvider);

                if (products.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  onRefresh: () async {
                    // Sync with Azure to get latest products
                    await inventoryProvider.syncFromCloud();
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8.0),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        onDelete: () => _deleteProduct(context, product),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddOptionsDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Items'),
      ),
    );
  }

  void _showAddOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Items'),
        content: const Text('How would you like to add items to your inventory?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              // Navigate to scanner tab
              DefaultTabController.of(context).animateTo(1);
            },
            child: const Text('SCAN'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _showManualEntryDialog();
            },
            child: const Text('MANUAL'),
          ),
        ],
      ),
    );
  }

  void _showManualEntryDialog() {
    final nameController = TextEditingController();
    final quantityController = TextEditingController(text: '1');
    final actualWeightController = TextEditingController();
    String selectedCategory = 'Other';
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
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedCategory,
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
                    if (v != null) {
                      setState(() => selectedCategory = v);
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
                const SizedBox(height: 12),
                TextField(
                  controller: actualWeightController,
                  decoration: const InputDecoration(
                    labelText: 'Actual Weight (g)',
                    border: OutlineInputBorder(),
                    hintText: 'Enter product weight in grams',
                  ),
                  keyboardType: TextInputType.number,
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
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  // Create nutrition info if any fields are filled
                  NutritionInfo? nutritionInfo;
                  if (caloriesController.text.isNotEmpty ||
                      proteinController.text.isNotEmpty ||
                      fatController.text.isNotEmpty ||
                      carbsController.text.isNotEmpty ||
                      fiberController.text.isNotEmpty) {
                    // Get actual weight, default to 100g if not specified
                    final actualWeight = double.tryParse(actualWeightController.text) ?? 100.0;
                    final quantity = double.tryParse(quantityController.text) ?? 1.0;
                    final weightMultiplier = actualWeight / 100.0;
                    final totalMultiplier = weightMultiplier * quantity;

                    nutritionInfo = NutritionInfo(
                      calories: (double.tryParse(caloriesController.text) ?? 0.0) * totalMultiplier,
                      protein: (double.tryParse(proteinController.text) ?? 0.0) * totalMultiplier,
                      fat: (double.tryParse(fatController.text) ?? 0.0) * totalMultiplier,
                      carbs: (double.tryParse(carbsController.text) ?? 0.0) * totalMultiplier,
                      fiber: (double.tryParse(fiberController.text) ?? 0.0) * totalMultiplier,
                    );
                  }

                  final product = Product(
                    id: const Uuid().v4(),
                    name: nameController.text,
                    expiryDate: selectedDate,
                    quantity: double.tryParse(quantityController.text) ?? 1.0,
                    unit: 'pcs',
                    category: selectedCategory,
                    actualWeight: double.tryParse(actualWeightController.text),
                    purchaseDate: DateTime.now(),
                    nutritionInfo: nutritionInfo,
                  );

                  await context.read<InventoryProvider>().addProduct(product);
                  Navigator.pop(context); // Close dialog
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${product.name} added to inventory')),
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

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', Icons.inventory_2),
                _buildFilterChip('Expiring', Icons.warning_amber),
                _buildFilterChip('Expired', Icons.dangerous),
                _buildFilterChip('Low Stock', Icons.remove_circle_outline),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Location filters
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildLocationChip('All'),
                _buildLocationChip('Fridge'),
                _buildLocationChip('Pantry'),
                _buildLocationChip('Freezer'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = label;
          });
        },
      ),
    );
  }

  Widget _buildLocationChip(String location) {
    final isSelected = _selectedLocation == location;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(location),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedLocation = location;
          });
        },
      ),
    );
  }

  List<Product> _getFilteredProducts(InventoryProvider provider) {
    List<Product> products;

    // Apply status filter
    switch (_selectedFilter) {
      case 'Expiring':
        products = provider.getExpiringProducts();
        break;
      case 'Expired':
        products = provider.getExpiredProducts();
        break;
      case 'Low Stock':
        products = provider.getLowStockProducts();
        break;
      default:
        products = provider.getAllProducts();
    }

    // Apply location filter
    if (_selectedLocation != 'All') {
      products = products
          .where((p) => p.storageLocation?.toLowerCase() == _selectedLocation.toLowerCase())
          .toList();
    }

    return products;
  }

  Widget _buildEmptyState() {
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
          Text(
            'No items in inventory',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set up your initial inventory to get started',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InitialInventorySetupScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Set Up Inventory'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteProduct(BuildContext context, Product product) async {
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await context.read<InventoryProvider>().deleteProduct(product.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name} deleted')),
        );
      }
    }
  }
}
