// Copilot Task 3: Inventory Screen - Display and Manage Products
// Shows all products with filtering by location and expiry status

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../providers/inventory_provider.dart';
import '../providers/household_nutrition_alerts_provider.dart';
import '../providers/nutrition_provider.dart';
import '../models/product.dart';
import '../services/azure_table_service.dart';
import 'product_detail_screen.dart';
import 'initial_inventory_setup_screen.dart';
import 'scanner_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _selectedFilter = 'All';
  String _selectedLocation = 'All';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  bool _isLiquidCategory(String category) {
    final cat = category.toLowerCase();
    return cat == 'beverages' ||
        cat.contains('milk') ||
        cat.contains('juice') ||
        cat.contains('drink') ||
        cat.contains('beverage') ||
        cat.contains('liquid');
  }

  @override
  void initState() {
    super.initState();
    // Sync with Azure when screen loads to ensure we have latest products
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().syncFromCloud();
      // Load household nutrition for alerts
      final alertsProvider = context.read<HouseholdNutritionAlertsProvider>();
      final nutritionProvider = context.read<NutritionProvider>();
      alertsProvider.loadHouseholdNutrition(nutritionProvider);
    });
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
                onChanged: (value) => setState(() {}), // Rebuild on search
              )
            : const Text('Inventory'),
        actions: [
          Consumer2<HouseholdNutritionAlertsProvider, InventoryProvider>(
            builder: (context, alertsProvider, inventoryProvider, child) {
              final inventoryTotals = inventoryProvider.getTotalInventoryNutrition();
              final alerts = alertsProvider.calculateAlerts(inventoryTotals);
              final hasAlerts = alerts.isNotEmpty;

              return IconButton(
                tooltip: alertsProvider.isLoading
                    ? 'Loading household nutrition...'
                    : hasAlerts
                        ? 'View nutrition alerts'
                        : 'No nutrition alerts',
                onPressed: () {
                  if (alertsProvider.isLoading) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Still loading household nutrition data...')),
                    );
                    return;
                  }

                  if (alerts.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No household nutrition alerts right now.')),
                    );
                    return;
                  }

                  _showNutritionAlertsSheet(alerts);
                },
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(hasAlerts ? Icons.notifications : Icons.notifications_none),
                    if (alertsProvider.isLoading)
                      const Positioned(
                        right: -2,
                        top: -2,
                        child: SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    if (!alertsProvider.isLoading && hasAlerts)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
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
                  child: _buildCategoryGroupedList(products),
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
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScannerScreen()),
              );
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
    final quantityController = TextEditingController(text: '1');
    double quantity = 1.0; // Add quantity state variable
    String selectedCategory = 'Other';
    Map<String, dynamic>? selectedProduct;
    List<Map<String, dynamic>> shoppingListItems = [];
    List<String> categories = [
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
    ]; // Default categories
    bool isLoadingProducts = false;
    bool isLooseItem = false; // Checkbox for loose items
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    final azureService = AzureTableService();

    // Function to load categories from table
    Future<void> loadCategories(bool looseItem) async {
      if (!looseItem) {
        categories = [
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
        ];
        return;
      }
      try {
        final allItems = await azureService.getAllLooseItems();
        final uniqueCategories = allItems
            .map((item) => item['category'] as String?)
            .where((cat) => cat != null && cat.isNotEmpty)
            .toSet()
            .toList();
        categories = uniqueCategories.cast<String>();
        if (categories.isEmpty) {
          categories = ['Other'];
        }
        // selectedCategory updated in caller
      } catch (e) {
        print('Error loading categories: $e');
        categories = ['Other'];
        selectedCategory = 'Other';
      }
    }

    // Function to load products for selected category
    Future<void> loadProductsForCategory(String category, bool looseItem) async {
      isLoadingProducts = true;
      try {
        final allItems = looseItem
            ? await azureService.getAllLooseItems()
            : await azureService.getAllShoppingListItems();

        if (looseItem) {
          final allLooseItems = await azureService.getAllLooseItems();
          final filteredItems =
              allLooseItems.where((item) => item['main_category'] == 'Loose Items').toList();
          shoppingListItems = filteredItems.where((item) {
            final itemCategory = item['category'] ?? '';
            return itemCategory.toLowerCase() == category.toLowerCase();
          }).toList();
        } else {
          shoppingListItems = allItems.where((item) {
            final itemCategory = item['Category'] ?? '';
            return itemCategory.toLowerCase() == category.toLowerCase();
          }).toList();
        }
      } catch (e) {
        print('Error loading ${looseItem ? 'loose' : 'shopping list'} items: $e');
        shoppingListItems = [];
      }
      isLoadingProducts = false;
    }

    // Load initial categories and products
    loadCategories(isLooseItem);
    loadProductsForCategory(selectedCategory, isLooseItem);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Product Manually'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Loose Items Checkbox
                CheckboxListTile(
                  title: const Text('Loose Items'),
                  value: isLooseItem,
                  onChanged: (value) async {
                    if (value != null) {
                      setState(() {
                        isLooseItem = value;
                        selectedProduct = null; // Reset selected product
                        isLoadingProducts = true;
                      });
                      await loadCategories(value);
                      setState(() {
                        selectedCategory = categories.contains(selectedCategory)
                            ? selectedCategory
                            : (categories.isNotEmpty ? categories.first : 'Other');
                      });
                      await loadProductsForCategory(selectedCategory, value);
                      setState(() {
                        isLoadingProducts = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                // Category Selection
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: DropdownButton<String>(
                    key: ValueKey(categories.join(',')),
                    value: selectedCategory,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items:
                        categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) async {
                      if (v != null) {
                        setState(() {
                          selectedCategory = v;
                          selectedProduct = null; // Reset selected product
                          isLoadingProducts = true;
                        });
                        await loadProductsForCategory(v, isLooseItem);
                        setState(() {
                          isLoadingProducts = false;
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(height: 12),
                // Product Name Selection
                DropdownButtonFormField<Map<String, dynamic>>(
                  initialValue: selectedProduct,
                  decoration: InputDecoration(
                    labelText: 'Product Name *',
                    border: const OutlineInputBorder(),
                    hintText: isLoadingProducts ? 'Loading products...' : 'Select a product',
                  ),
                  items: shoppingListItems.map((item) {
                    final productName = item['ProductName'] ??
                        item['product'] ??
                        item['name'] ??
                        item['product_name'] ??
                        item['item'] ??
                        'Unknown Product';
                    final brand = item['Brand'] ?? item['brand'] ?? '';
                    return DropdownMenuItem(
                      value: item,
                      child: Text(
                        brand.isNotEmpty ? '$productName ($brand)' : productName,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() => selectedProduct = v);
                  },
                ),
                const SizedBox(height: 12),
                // Quantity Input
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
                // Expiry Date
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
                // Nutrition Information Display
                if (selectedProduct != null) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Product Information',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLooseItem
                        ? (_isLiquidCategory(selectedCategory)
                            ? 'Nutrition Information (per 100ml)'
                            : 'Nutrition Information (per 100g)')
                        : 'Nutrition Information (per 100g/ml)',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  _buildBaseNutritionDisplay(selectedProduct!),
                  const SizedBox(height: 12),
                  const Text(
                    'Total Nutrition (based on quantity)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  _buildNutritionDisplay(selectedProduct!, quantity),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedProduct != null
                  ? () async {
                      // Calculate nutrition based on selected product
                      NutritionInfo? nutritionInfo;
                      if ((selectedProduct!['Calories'] ?? selectedProduct!['calories']) != null ||
                          (selectedProduct!['Protein'] ?? selectedProduct!['protein']) != null ||
                          (selectedProduct!['Fat'] ?? selectedProduct!['fat']) != null ||
                          (selectedProduct!['Carbs'] ?? selectedProduct!['carbs']) != null ||
                          (selectedProduct!['Fiber'] ?? selectedProduct!['fiber']) != null) {
                        // Get base values (per 100g/ml)
                        final baseCalories =
                            (selectedProduct!['Calories'] ?? selectedProduct!['calories'] ?? 0.0)
                                .toDouble();
                        final baseProtein =
                            (selectedProduct!['Protein'] ?? selectedProduct!['protein'] ?? 0.0)
                                .toDouble();
                        final baseFat =
                            (selectedProduct!['Fat'] ?? selectedProduct!['fat'] ?? 0.0).toDouble();
                        final baseCarbs =
                            (selectedProduct!['Carbs'] ?? selectedProduct!['carbs'] ?? 0.0)
                                .toDouble();
                        final baseFiber =
                            (selectedProduct!['Fiber'] ?? selectedProduct!['fiber'] ?? 0.0)
                                .toDouble();

                        // Get actual weight per unit
                        final actualWeightPerUnit = selectedProduct!['ActualWeight']?.toDouble() ??
                            (isLooseItem ? 1.0 : 100.0);
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
                        id: const Uuid().v4(),
                        name: selectedProduct!['ProductName'] ??
                            selectedProduct!['product'] ??
                            selectedProduct!['name'] ??
                            selectedProduct!['product_name'] ??
                            selectedProduct!['item'] ??
                            'Unknown Product',
                        expiryDate: selectedDate,
                        quantity: quantity,
                        unit: selectedProduct!['Unit'] ??
                            selectedProduct!['unit'] ??
                            (_isLiquidCategory(selectedCategory) ? 'ml' : 'g'),
                        category: selectedCategory,
                        actualWeight: selectedProduct!['ActualWeight'] ??
                            selectedProduct!['actualWeight']?.toDouble() ??
                            (isLooseItem ? 1.0 : null),
                        purchaseDate: DateTime.now(),
                        nutritionInfo: nutritionInfo,
                        brand: selectedProduct!['Brand'] ?? selectedProduct!['brand'],
                        barcode: selectedProduct!['Barcode'] ?? selectedProduct!['barcode'],
                      );

                      await context.read<InventoryProvider>().addProduct(product);
                      if (context.mounted) {
                        Navigator.pop(context); // Close dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${product.name} added to inventory')),
                        );
                      }
                    }
                  : null,
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionDisplay(Map<String, dynamic> product, double quantity) {
    // Get base values (per 100g/ml)
    final baseCalories = (product['Calories'] ?? product['calories'] ?? 0.0).toDouble();
    final baseProtein = (product['Protein'] ?? product['protein'] ?? 0.0).toDouble();
    final baseFat = (product['Fat'] ?? product['fat'] ?? 0.0).toDouble();
    final baseCarbs = (product['Carbs'] ?? product['carbs'] ?? 0.0).toDouble();
    final baseFiber = (product['Fiber'] ?? product['fiber'] ?? 0.0).toDouble();

    // Get actual weight per unit
    final actualWeightPerUnit = (product['ActualWeight'] ??
            product['actualWeight'] ??
            ((product['main_category'] == 'Loose Items') ? 1.0 : 100.0))
        .toDouble();
    final totalActualWeight = actualWeightPerUnit * quantity;
    final weightMultiplier = totalActualWeight / 100.0;

    // Calculate total nutrition
    final totalCalories = baseCalories * weightMultiplier;
    final totalProtein = baseProtein * weightMultiplier;
    final totalFat = baseFat * weightMultiplier;
    final totalCarbs = baseCarbs * weightMultiplier;
    final totalFiber = baseFiber * weightMultiplier;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total: ${totalActualWeight.toStringAsFixed(0)}${product['Category']?.toLowerCase() == 'beverages' ? 'ml' : 'g'}:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildNutritionItem('Calories', totalCalories.toStringAsFixed(0)),
              ),
              Expanded(
                child: _buildNutritionItem('Protein', '${totalProtein.toStringAsFixed(1)}g'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildNutritionItem('Fat', '${totalFat.toStringAsFixed(1)}g'),
              ),
              Expanded(
                child: _buildNutritionItem('Carbs', '${totalCarbs.toStringAsFixed(1)}g'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildNutritionItem('Fiber', '${totalFiber.toStringAsFixed(1)}g'),
        ],
      ),
    );
  }

  Widget _buildBaseNutritionDisplay(Map<String, dynamic> product) {
    // Get base values (per 100g/ml)
    final baseCalories = (product['Calories'] ?? product['calories'] ?? 0.0).toDouble();
    final baseProtein = (product['Protein'] ?? product['protein'] ?? 0.0).toDouble();
    final baseFat = (product['Fat'] ?? product['fat'] ?? 0.0).toDouble();
    final baseCarbs = (product['Carbs'] ?? product['carbs'] ?? 0.0).toDouble();
    final baseFiber = (product['Fiber'] ?? product['fiber'] ?? 0.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Per 100${_isLiquidCategory(product['Category'] ?? product['category'] ?? '') ? 'ml' : 'g'}:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildNutritionItem('Calories', baseCalories.toStringAsFixed(0)),
              ),
              Expanded(
                child: _buildNutritionItem('Protein', '${baseProtein.toStringAsFixed(1)}g'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: _buildNutritionItem('Fat', '${baseFat.toStringAsFixed(1)}g'),
              ),
              Expanded(
                child: _buildNutritionItem('Carbs', '${baseCarbs.toStringAsFixed(1)}g'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildNutritionItem('Fiber', '${baseFiber.toStringAsFixed(1)}g'),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
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

    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase().trim();
      products = products.where((p) {
        final name = p.name.toLowerCase();
        final brand = (p.brand ?? '').toLowerCase();
        final category = p.category.toLowerCase();
        final barcode = (p.barcode ?? '').toLowerCase();
        return name.contains(query) ||
            brand.contains(query) ||
            category.contains(query) ||
            barcode.contains(query);
      }).toList();
    }

    return products;
  }

  Widget _buildCategoryGroupedList(List<Product> products) {
    // Group products by category
    final Map<String, List<Product>> groupedProducts = {};
    for (final product in products) {
      final category = product.category;
      if (!groupedProducts.containsKey(category)) {
        groupedProducts[category] = [];
      }
      groupedProducts[category]!.add(product);
    }

    // Sort products within each category by expiry date (closest first), then by purchase date
    groupedProducts.forEach((category, productList) {
      productList.sort((a, b) {
        // First, sort by expiry date (items expiring soon come first)
        if (a.expiryDate != null && b.expiryDate != null) {
          final expiryCompare = a.expiryDate!.compareTo(b.expiryDate!);
          if (expiryCompare != 0) return expiryCompare;
        } else if (a.expiryDate != null) {
          return -1; // a has expiry date, b doesn't - a comes first
        } else if (b.expiryDate != null) {
          return 1; // b has expiry date, a doesn't - b comes first
        }

        // If expiry dates are equal or both null, sort by purchase date (newest first)
        if (a.purchaseDate != null && b.purchaseDate != null) {
          return b.purchaseDate!.compareTo(a.purchaseDate!);
        } else if (a.purchaseDate != null) {
          return -1;
        } else if (b.purchaseDate != null) {
          return 1;
        }

        return 0;
      });
    });

    // Sort categories alphabetically
    final sortedCategories = groupedProducts.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final category = sortedCategories[index];
        final categoryProducts = groupedProducts[category]!;

        return _buildCategorySection(category, categoryProducts);
      },
    );
  }

  Widget _buildCategorySection(String category, List<Product> products) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getCategoryColor(category),
          child: Text(
            products.length.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          category,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text('${products.length} item${products.length != 1 ? 's' : ''}'),
        children: products.map((product) {
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: product.isExpired
                  ? Colors.red
                  : product.isExpiringSoon
                      ? Colors.orange
                      : Colors.green,
              child: Icon(
                product.isExpired
                    ? Icons.warning
                    : product.isExpiringSoon
                        ? Icons.schedule
                        : Icons.check,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(product.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Qty: ${product.quantity} ${product.unit}'),
                if (product.expiryDate != null)
                  Text(
                    'Expires: ${_formatDate(product.expiryDate!)} (${product.daysUntilExpiry} days)',
                    style: TextStyle(
                      color: product.isExpired
                          ? Colors.red
                          : product.isExpiringSoon
                              ? Colors.orange
                              : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                if (product.purchaseDate != null)
                  Text(
                    'Purchased: ${_formatDate(product.purchaseDate!)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: product),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteProduct(context, product),
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: product),
                ),
              );
            },
          );
        }).toList(),
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
      case 'snacks':
        return Colors.purple;
      case 'frozen foods':
        return Colors.lightBlue;
      case 'condiments':
        return Colors.deepOrange;
      case 'nuts':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
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

  void _showNutritionAlertsSheet(List<NutritionAlert> alerts) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.notifications_active, color: Colors.orange),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Household Nutrition Alerts',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...alerts.map(_buildAlertTile),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAlertTile(NutritionAlert alert) {
    final color = alert.isCritical ? Colors.red : Colors.orange;
    final icon = alert.isCritical ? Icons.warning_amber_rounded : Icons.info_outline;

    return Card(
      color: color.withOpacity(0.08),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          alert.headline,
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(alert.description),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
