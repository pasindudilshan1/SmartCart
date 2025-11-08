// Shopping List Screen with Manual and Scan tabs

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/product.dart';
import '../services/azure_table_service.dart';
import '../services/local_storage_service.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AzureTableService _azureService = AzureTableService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _shoppingItems = [];
  List<Map<String, dynamic>> _filteredShoppingItems = [];
  bool _isLoading = false;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadShoppingItems();
    _searchController.addListener(_filterShoppingItems);
  }

  void _filterShoppingItems() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredShoppingItems = _shoppingItems;
      } else {
        _filteredShoppingItems = _shoppingItems.where((item) {
          final productName = (item['ProductName'] ?? '').toString().toLowerCase();
          final brand = (item['Brand'] ?? '').toString().toLowerCase();
          final category = (item['Category'] ?? '').toString().toLowerCase();
          final barcode = (item['Barcode'] ?? '').toString().toLowerCase();
          return productName.contains(query) ||
              brand.contains(query) ||
              category.contains(query) ||
              barcode.contains(query);
        }).toList();
      }
    });
  }

  Future<void> _loadShoppingItems() async {
    setState(() => _isLoading = true);
    try {
      final items = await _azureService.getAllShoppingListItems();
      setState(() {
        _shoppingItems = items;
        _filteredShoppingItems = items;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading shopping items: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Search by name, brand, category...',
                  hintStyle: TextStyle(color: hintColor),
                  border: InputBorder.none,
                ),
              )
            : const Text('Shopping List'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                }
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.list), text: 'Manual'),
            Tab(icon: Icon(Icons.qr_code_scanner), text: 'Scan'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManualTab(),
          _buildScanTab(),
        ],
      ),
    );
  }

  Widget _buildManualTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_shoppingItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No items in shopping list',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loadShoppingItems,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadShoppingItems,
      child: _filteredShoppingItems.isEmpty && _searchController.text.isNotEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No products found',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Try a different search term',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filteredShoppingItems.length,
              itemBuilder: (context, index) {
                final item = _filteredShoppingItems[index];
                return _buildShoppingItemCard(item);
              },
            ),
    );
  }

  Widget _buildShoppingItemCard(Map<String, dynamic> item) {
    final productName = item['ProductName'] ?? 'Unknown Product';
    final category = item['Category'] ?? 'Other';
    final brand = item['Brand'] ?? '';
    final price = item['Price']?.toDouble() ?? 0.0;
    final quantity = item['Quantity']?.toDouble() ?? 1.0;
    final unit = item['Unit'] ?? 'pcs';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(category),
          child: Text(
            productName[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          productName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$brand${brand.isNotEmpty ? ' • ' : ''}$category\n$quantity $unit${price > 0 ? ' • \$${price.toStringAsFixed(2)}' : ''}',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _showProductDetails(item),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'dairy':
        return Colors.blue;
      case 'meat':
        return Colors.red;
      case 'fruits':
        return Colors.orange;
      case 'vegetables':
        return Colors.green;
      case 'bakery':
        return Colors.brown;
      case 'grains':
        return Colors.amber;
      case 'beverages':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  void _showProductDetails(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ProductDetailsSheet(
        item: item,
        onPurchase: (quantity) => _purchaseProduct(item, quantity),
      ),
    );
  }

  Future<void> _purchaseProduct(Map<String, dynamic> item, double quantity) async {
    try {
      final userId = await LocalStorageService.getUserId();
      if (userId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: User not logged in')),
          );
        }
        return;
      }

      // Get base nutrition values (per 100g or 100ml from table)
      final baseCalories = item['Calories']?.toDouble() ?? 0.0;
      final baseProtein = item['Protein']?.toDouble() ?? 0.0;
      final baseCarbs = item['Carbs']?.toDouble() ?? 0.0;
      final baseFat = item['Fat']?.toDouble() ?? 0.0;
      final baseFiber = item['Fiber']?.toDouble() ?? 0.0;
      final baseSugar = item['Sugar']?.toDouble() ?? 0.0;
      final baseSodium = item['Sodium']?.toDouble() ?? 0.0;

      // Get category to determine if it's a beverage
      final category = item['Category'] ?? 'Other';
      final isBeverage = category.toLowerCase() == 'beverages';

      // Calculate actual weight/volume purchased
      // For Beverages: ActualWeight in table is stored in ml (per unit)
      // For Others: ActualWeight in table is stored in grams (per unit)
      final actualWeightPerUnit =
          item['ActualWeight']?.toDouble() ?? 0.0; // in grams or ml per unit
      final totalActualWeight =
          actualWeightPerUnit * quantity; // total = weight per unit × user quantity

      // Calculate nutrition for the actual weight purchased
      // Beverages: Nutrition in table is per 100ml, so divide total ml by 100
      // Others: Nutrition in table is per 100g, so divide total grams by 100
      final weightMultiplier = totalActualWeight / 100.0;

      final calculatedCalories = baseCalories * weightMultiplier;
      final calculatedProtein = baseProtein * weightMultiplier;
      final calculatedCarbs = baseCarbs * weightMultiplier;
      final calculatedFat = baseFat * weightMultiplier;
      final calculatedFiber = baseFiber * weightMultiplier;
      final calculatedSugar = baseSugar * weightMultiplier;
      final calculatedSodium = baseSodium * weightMultiplier;

      // Create product from shopping item
      final product = Product(
        id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
        name: item['ProductName'] ?? 'Unknown Product',
        barcode: item['Barcode'],
        category: item['Category'] ?? 'Other',
        brand: item['Brand'],
        quantity: quantity,
        unit: item['Unit'] ?? 'pcs',
        actualWeight: totalActualWeight > 0 ? totalActualWeight : null,
        price: item['Price']?.toDouble(),
        imageUrl: item['ImageUrl'],
        storageLocation: item['StorageLocation'],
        purchaseDate: DateTime.now(),
        dateAdded: DateTime.now(),
        nutritionInfo: baseCalories > 0
            ? NutritionInfo(
                calories: calculatedCalories,
                protein: calculatedProtein,
                carbs: calculatedCarbs,
                fat: calculatedFat,
                fiber: calculatedFiber,
                sugar: calculatedSugar,
                sodium: calculatedSodium,
                servingSize: isBeverage
                    ? '${totalActualWeight.toStringAsFixed(0)}ml (total)'
                    : '${totalActualWeight.toStringAsFixed(0)}g (total)',
              )
            : null,
      );

      // Store in Azure and local database
      await _azureService.storeProduct(userId, product);

      // Add to inventory provider
      if (mounted) {
        final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
        await inventoryProvider.addProduct(product);

        Navigator.pop(context); // Close the bottom sheet

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to inventory'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () {
                Navigator.pushNamed(context, '/inventory');
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error purchasing product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Widget _buildScanTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.qr_code_scanner, size: 100, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Scan Mode',
            style: TextStyle(fontSize: 24, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon...',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }
}

// Product Details Bottom Sheet
class _ProductDetailsSheet extends StatefulWidget {
  final Map<String, dynamic> item;
  final Function(double) onPurchase;

  const _ProductDetailsSheet({
    required this.item,
    required this.onPurchase,
  });

  @override
  State<_ProductDetailsSheet> createState() => _ProductDetailsSheetState();
}

class _ProductDetailsSheetState extends State<_ProductDetailsSheet> {
  final TextEditingController _quantityController = TextEditingController(text: '1');

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final productName = item['ProductName'] ?? 'Unknown Product';
    final category = item['Category'] ?? 'Other';
    final brand = item['Brand'] ?? '';
    final price = item['Price']?.toDouble() ?? 0.0;
    final unit = item['Unit'] ?? 'pcs';
    final barcode = item['Barcode'] ?? '';
    final storageLocation = item['StorageLocation'] ?? '';
    final notes = item['Notes'] ?? '';
    final actualWeight = item['ActualWeight']?.toDouble() ?? 0.0;

    // Nutrition info (per 100g)
    final calories = item['Calories']?.toDouble() ?? 0.0;
    final protein = item['Protein']?.toDouble() ?? 0.0;
    final carbs = item['Carbs']?.toDouble() ?? 0.0;
    final fat = item['Fat']?.toDouble() ?? 0.0;
    final fiber = item['Fiber']?.toDouble() ?? 0.0;
    final sugar = item['Sugar']?.toDouble() ?? 0.0;
    final sodium = item['Sodium']?.toDouble() ?? 0.0;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: scrollController,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: _getCategoryColor(category),
                    child: Text(
                      productName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          productName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (brand.isNotEmpty)
                          Text(
                            brand,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Basic Info
              _buildInfoSection('Basic Information', [
                _buildInfoRow('Category', category),
                if (barcode.isNotEmpty) _buildInfoRow('Barcode', barcode),
                if (actualWeight > 0)
                  _buildInfoRow(
                    category.toLowerCase() == 'beverages' ? 'Volume' : 'Actual Weight',
                    category.toLowerCase() == 'beverages'
                        ? '${actualWeight.toStringAsFixed(0)} ml'
                        : '${actualWeight.toStringAsFixed(0)} g',
                  ),
                if (price > 0) _buildInfoRow('Price', '\$${price.toStringAsFixed(2)}'),
                if (storageLocation.isNotEmpty) _buildInfoRow('Storage', storageLocation),
              ]),

              const SizedBox(height: 16),

              // Nutrition Info
              if (calories > 0)
                _buildInfoSection(
                    category.toLowerCase() == 'beverages'
                        ? 'Nutrition Information (per 100ml)'
                        : 'Nutrition Information (per 100g)',
                    [
                      _buildInfoRow('Calories', '${calories.toStringAsFixed(0)} kcal'),
                      _buildInfoRow('Protein', '${protein.toStringAsFixed(1)}g'),
                      _buildInfoRow('Carbs', '${carbs.toStringAsFixed(1)}g'),
                      _buildInfoRow('Fat', '${fat.toStringAsFixed(1)}g'),
                      if (fiber > 0) _buildInfoRow('Fiber', '${fiber.toStringAsFixed(1)}g'),
                      if (sugar > 0) _buildInfoRow('Sugar', '${sugar.toStringAsFixed(1)}g'),
                      if (sodium > 0) _buildInfoRow('Sodium', '${sodium.toStringAsFixed(1)}mg'),
                    ]),

              if (notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildInfoSection('Notes', [
                  Text(notes, style: TextStyle(color: Colors.grey.shade700)),
                ]),
              ],

              const SizedBox(height: 24),

              // Quantity Input
              const Text(
                'Purchase Quantity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'Quantity ($unit)',
                  suffixIcon: const Icon(Icons.shopping_cart),
                ),
              ),
              const SizedBox(height: 24),

              // Purchase Button
              ElevatedButton.icon(
                onPressed: _purchaseItem,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Add to Inventory'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'dairy':
        return Colors.blue;
      case 'meat':
        return Colors.red;
      case 'fruits':
        return Colors.orange;
      case 'vegetables':
        return Colors.green;
      case 'bakery':
        return Colors.brown;
      case 'grains':
        return Colors.amber;
      case 'beverages':
        return Colors.cyan;
      default:
        return Colors.grey;
    }
  }

  void _purchaseItem() {
    final quantity = double.tryParse(_quantityController.text);
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid quantity')),
      );
      return;
    }
    widget.onPurchase(quantity);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }
}
