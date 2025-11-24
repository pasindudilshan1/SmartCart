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
        elevation: 6,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
      'Spreads',
      'Other',
    ]; // Default categories
    bool isLoadingProducts = false;
    bool isLooseItem = false; // Checkbox for loose items
    final now = DateTime.now();
    DateTime selectedDate = DateTime.utc(now.year, now.month, now.day + 7);
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
          'Spreads',
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
                  subtitle: Text(
                    '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (date != null) {
                      setState(() {
                        // Normalize to midnight UTC to avoid timezone issues
                        selectedDate = DateTime.utc(date.year, date.month, date.day);
                      });
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

                      // Get actual weight per unit
                      final actualWeightPerUnit = isLooseItem
                          ? (selectedProduct!['ActualWeight']?.toDouble() ?? 1.0)
                          : ((selectedProduct!['Quantity'] ?? 1.0) !=
                                  (selectedProduct!['ActualWeight'] ?? 100.0))
                              ? ((selectedProduct!['ActualWeight'] ?? 100.0) *
                                      (selectedProduct!['Quantity'] ?? 1.0))
                                  .toDouble()
                              : (selectedProduct!['ActualWeight'] ?? 100.0).toDouble();
                      final totalActualWeight = actualWeightPerUnit * quantity;

                      if ((selectedProduct!['Calories'] ?? selectedProduct!['calories']) != null ||
                          (selectedProduct!['Protein'] ?? selectedProduct!['protein']) != null ||
                          (selectedProduct!['Fat'] ?? selectedProduct!['fat']) != null ||
                          (selectedProduct!['Carbs'] ?? selectedProduct!['carbs']) != null ||
                          (selectedProduct!['Fiber'] ?? selectedProduct!['fiber']) != null) {
                        // Get actual weight per unit
                        final actualWeightPerUnit = isLooseItem
                            ? (selectedProduct!['ActualWeight']?.toDouble() ?? 1.0)
                            : ((selectedProduct!['Quantity'] ?? 1.0) !=
                                    (selectedProduct!['ActualWeight'] ?? 100.0))
                                ? ((selectedProduct!['ActualWeight'] ?? 100.0) *
                                        (selectedProduct!['Quantity'] ?? 1.0))
                                    .toDouble()
                                : (selectedProduct!['ActualWeight'] ?? 100.0).toDouble();
                        final totalActualWeight = actualWeightPerUnit * quantity;

                        if ((selectedProduct!['Calories'] ?? selectedProduct!['calories']) !=
                                null ||
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
                              (selectedProduct!['Fat'] ?? selectedProduct!['fat'] ?? 0.0)
                                  .toDouble();
                          final baseCarbs =
                              (selectedProduct!['Carbs'] ?? selectedProduct!['carbs'] ?? 0.0)
                                  .toDouble();
                          final baseFiber =
                              (selectedProduct!['Fiber'] ?? selectedProduct!['fiber'] ?? 0.0)
                                  .toDouble();

                          final weightMultiplier = totalActualWeight / 100.0;

                          nutritionInfo = NutritionInfo(
                            calories: baseCalories * weightMultiplier,
                            protein: baseProtein * weightMultiplier,
                            fat: baseFat * weightMultiplier,
                            carbs: baseCarbs * weightMultiplier,
                            fiber: baseFiber * weightMultiplier,
                          );
                        }
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
                        actualWeight: totalActualWeight,
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: isSelected ? Matrix4.identity() : Matrix4.identity().scaled(0.95),
        child: FilterChip(
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : null),
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
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedColor: Theme.of(context).colorScheme.primary,
          checkmarkColor: Colors.white,
          elevation: isSelected ? 4 : 0,
          shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.3),
        ),
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
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 4,
              shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ExpansionTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCategoryIconForHeader(category),
                    color: _getCategoryColor(category),
                    size: 26,
                  ),
                ),
                title: Text(
                  category,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                subtitle: Text('${products.length} item${products.length != 1 ? 's' : ''}'),
                children: products.asMap().entries.map((entry) {
                  final index = entry.key;
                  final product = entry.value;
                  return TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 300 + (index * 100)),
                    builder: (context, itemValue, child) {
                      return Opacity(
                        opacity: itemValue,
                        child: Transform.translate(
                          offset: Offset(20 * (1 - itemValue), 0),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _getProductIconColor(product.name, product.category)
                                    .withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _getProductIcon(product.name, product.category),
                                color: _getProductIconColor(product.name, product.category),
                                size: 26,
                              ),
                            ),
                            title: Text(product.name,
                                style: const TextStyle(fontWeight: FontWeight.w500)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                            trailing: SizedBox(
                              width: 96,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.info_outlined,
                                        color: Theme.of(context).colorScheme.primary),
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
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(product: product),
                                ),
                              );
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'dairy':
        return Colors.blue.shade600;
      case 'meat':
        return Colors.red.shade700;
      case 'fruits':
        return Colors.orange.shade700;
      case 'vegetables':
        return Colors.green.shade700;
      case 'bakery':
        return Colors.brown.shade700;
      case 'grains':
        return Colors.amber.shade700;
      case 'beverages':
        return Colors.cyan.shade700;
      case 'snacks':
        return Colors.purple.shade600;
      case 'frozen foods':
        return Colors.lightBlue.shade700;
      case 'condiments':
        return Colors.deepOrange.shade700;
      case 'nuts':
        return Colors.brown.shade600;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getCategoryIconForHeader(String category) {
    switch (category.toLowerCase()) {
      case 'dairy':
        return Icons.local_drink;
      case 'meat':
        return Icons.dinner_dining;
      case 'fruits':
        return Icons.apple;
      case 'vegetables':
        return Icons.yard;
      case 'bakery':
        return Icons.bakery_dining;
      case 'grains':
        return Icons.grain;
      case 'beverages':
        return Icons.local_bar;
      case 'snacks':
        return Icons.cookie;
      case 'frozen foods':
        return Icons.ac_unit;
      case 'condiments':
        return Icons.water_drop;
      case 'nuts':
        return Icons.scatter_plot;
      default:
        return Icons.shopping_basket;
    }
  }

  IconData _getProductIcon(String productName, String category) {
    final name = productName.toLowerCase();

    // Fruits
    if (name.contains('apple')) return Icons.apple;
    if (name.contains('banana')) return Icons.deck;
    if (name.contains('orange')) return Icons.circle;
    if (name.contains('grape')) return Icons.bubble_chart;
    if (name.contains('lemon')) return Icons.wb_sunny;
    if (name.contains('lime')) return Icons.brightness_5;
    if (name.contains('strawberry')) return Icons.favorite;
    if (name.contains('blueberry')) return Icons.circle_outlined;
    if (name.contains('peach')) return Icons.spa;
    if (name.contains('pear')) return Icons.lightbulb;
    if (name.contains('pineapple')) return Icons.forest;
    if (name.contains('watermelon')) return Icons.pie_chart;
    if (name.contains('cherry')) return Icons.favorite_border;
    if (name.contains('kiwi')) return Icons.eco;
    if (name.contains('mango')) return Icons.water_drop;
    if (name.contains('papaya')) return Icons.park;
    if (name.contains('plum')) return Icons.circle;
    if (name.contains('avocado')) return Icons.egg_alt;
    if (name.contains('berry')) return Icons.blur_circular;
    if (name.contains('coconut')) return Icons.sports_basketball;
    if (name.contains('fruit')) return Icons.yard;

    // Vegetables
    if (name.contains('carrot')) return Icons.agriculture;
    if (name.contains('potato')) return Icons.egg;
    if (name.contains('onion')) return Icons.circle;
    if (name.contains('tomato')) return Icons.circle;
    if (name.contains('cucumber')) return Icons.science;
    if (name.contains('pepper')) return Icons.whatshot;
    if (name.contains('broccoli')) return Icons.park;
    if (name.contains('spinach')) return Icons.grass;
    if (name.contains('lettuce')) return Icons.eco;
    if (name.contains('salad')) return Icons.eco;
    if (name.contains('cabbage')) return Icons.layers;
    if (name.contains('celery')) return Icons.segment;
    if (name.contains('zucchini')) return Icons.straighten;
    if (name.contains('eggplant')) return Icons.egg;
    if (name.contains('garlic')) return Icons.grain;
    if (name.contains('ginger')) return Icons.spa;
    if (name.contains('corn')) return Icons.grain;
    if (name.contains('mushroom')) return Icons.beach_access;
    if (name.contains('bean')) return Icons.grain;
    if (name.contains('pea')) return Icons.circle;
    if (name.contains('vegetable')) return Icons.yard;

    // Dairy
    if (name.contains('milk')) return Icons.local_drink;
    if (name.contains('cheese')) return Icons.square;
    if (name.contains('yogurt')) return Icons.set_meal;
    if (name.contains('butter')) return Icons.square_rounded;
    if (name.contains('cream')) return Icons.waves;
    if (name.contains('ice cream')) return Icons.icecream;
    if (name.contains('icecream')) return Icons.icecream;

    // Meat & Protein
    if (name.contains('chicken')) return Icons.egg_alt;
    if (name.contains('beef')) return Icons.restaurant_menu;
    if (name.contains('pork')) return Icons.restaurant_menu;
    if (name.contains('fish')) return Icons.set_meal;
    if (name.contains('meat')) return Icons.dinner_dining;
    if (name.contains('sausage')) return Icons.fastfood;
    if (name.contains('bacon')) return Icons.waves;
    if (name.contains('turkey')) return Icons.egg_alt;
    if (name.contains('lamb')) return Icons.restaurant_menu;
    if (name.contains('shrimp')) return Icons.water;
    if (name.contains('salmon')) return Icons.water;
    if (name.contains('tuna')) return Icons.water;
    if (name.contains('crab')) return Icons.pest_control;
    if (name.contains('lobster')) return Icons.pest_control;

    // Bakery
    if (name.contains('bread')) return Icons.bakery_dining;
    if (name.contains('bagel')) return Icons.donut_small;
    if (name.contains('croissant')) return Icons.bakery_dining;
    if (name.contains('cake')) return Icons.cake;
    if (name.contains('pie')) return Icons.pie_chart;
    if (name.contains('cookie')) return Icons.cookie;
    if (name.contains('muffin')) return Icons.bakery_dining;
    if (name.contains('donut')) return Icons.donut_large;
    if (name.contains('biscuit')) return Icons.circle;
    if (name.contains('cracker')) return Icons.crop_square;
    if (name.contains('waffle')) return Icons.grid_on;
    if (name.contains('pancake')) return Icons.layers;

    // Beverages
    if (name.contains('water')) return Icons.water_drop;
    if (name.contains('juice')) return Icons.local_drink;
    if (name.contains('soda')) return Icons.local_bar;
    if (name.contains('coffee')) return Icons.local_cafe;
    if (name.contains('tea')) return Icons.emoji_food_beverage;
    if (name.contains('beer')) return Icons.sports_bar;
    if (name.contains('wine')) return Icons.wine_bar;
    if (name.contains('whiskey')) return Icons.liquor;
    if (name.contains('vodka')) return Icons.liquor;
    if (name.contains('energy drink')) return Icons.flash_on;
    if (name.contains('smoothie')) return Icons.blender;
    if (name.contains('milkshake')) return Icons.icecream;

    // Snacks
    if (name.contains('chips')) return Icons.set_meal;
    if (name.contains('candy')) return Icons.star;
    if (name.contains('chocolate')) return Icons.square;
    if (name.contains('snack')) return Icons.fastfood;
    if (name.contains('nuts')) return Icons.scatter_plot;
    if (name.contains('popcorn')) return Icons.bubble_chart;
    if (name.contains('pretzel')) return Icons.all_inclusive;
    if (name.contains('granola')) return Icons.grain;

    // Grains & Pasta
    if (name.contains('rice')) return Icons.rice_bowl;
    if (name.contains('pasta')) return Icons.ramen_dining;
    if (name.contains('noodle')) return Icons.ramen_dining;
    if (name.contains('spaghetti')) return Icons.ramen_dining;
    if (name.contains('grain')) return Icons.grain;
    if (name.contains('cereal')) return Icons.breakfast_dining;
    if (name.contains('oat')) return Icons.grain;
    if (name.contains('quinoa')) return Icons.scatter_plot;
    if (name.contains('barley')) return Icons.grain;
    if (name.contains('wheat')) return Icons.grass;

    // Condiments & Sauces
    if (name.contains('sauce')) return Icons.water_drop;
    if (name.contains('ketchup')) return Icons.water_drop;
    if (name.contains('mustard')) return Icons.water_drop;
    if (name.contains('mayo')) return Icons.water_drop;
    if (name.contains('dressing')) return Icons.local_drink;
    if (name.contains('vinegar')) return Icons.science;
    if (name.contains('honey')) return Icons.local_florist;
    if (name.contains('jam')) return Icons.set_meal;
    if (name.contains('jelly')) return Icons.set_meal;
    if (name.contains('syrup')) return Icons.water_drop;

    // Canned & Packaged
    if (name.contains('can') || name.contains('canned') || name.contains('tin')) {
      return Icons.inventory;
    }
    if (name.contains('soup')) return Icons.soup_kitchen;
    if (name.contains('beans')) return Icons.set_meal;

    // Frozen
    if (name.contains('frozen')) return Icons.ac_unit;
    if (name.contains('ice')) return Icons.ac_unit;

    // Eggs
    if (name.contains('egg')) return Icons.egg;

    // Pizza & Fast Food
    if (name.contains('pizza')) return Icons.local_pizza;
    if (name.contains('burger')) return Icons.lunch_dining;
    if (name.contains('hamburger')) return Icons.lunch_dining;
    if (name.contains('hot dog')) return Icons.fastfood;
    if (name.contains('sandwich')) return Icons.lunch_dining;
    if (name.contains('taco')) return Icons.fastfood;
    if (name.contains('burrito')) return Icons.fastfood;
    if (name.contains('fries')) return Icons.fastfood;

    // Cooking Essentials
    if (name.contains('sugar')) return Icons.square;
    if (name.contains('salt')) return Icons.grain;
    if (name.contains('flour')) return Icons.square_rounded;
    if (name.contains('oil')) return Icons.opacity;
    if (name.contains('spice')) return Icons.eco;
    if (name.contains('herb')) return Icons.local_florist;
    if (name.contains('baking')) return Icons.bakery_dining;

    // Fall back to category-based icons
    switch (category.toLowerCase()) {
      case 'dairy':
        return Icons.local_drink;
      case 'meat':
        return Icons.dinner_dining;
      case 'fruits':
        return Icons.apple;
      case 'vegetables':
        return Icons.yard;
      case 'bakery':
        return Icons.bakery_dining;
      case 'grains':
        return Icons.grain;
      case 'beverages':
        return Icons.local_bar;
      case 'snacks':
        return Icons.cookie;
      case 'frozen':
      case 'frozen foods':
        return Icons.ac_unit;
      case 'canned':
        return Icons.inventory;
      case 'seafood':
        return Icons.set_meal;
      case 'condiments':
        return Icons.water_drop;
      case 'nuts':
        return Icons.scatter_plot;
      default:
        return Icons.shopping_basket;
    }
  }

  Color _getProductIconColor(String productName, String category) {
    final name = productName.toLowerCase();

    // Fruits
    if (name.contains('apple')) return Colors.red.shade700;
    if (name.contains('banana')) return Colors.yellow.shade700;
    if (name.contains('orange')) return Colors.orange.shade700;
    if (name.contains('grape')) return Colors.purple.shade600;
    if (name.contains('lemon')) return Colors.yellow.shade600;
    if (name.contains('lime')) return Colors.green.shade600;
    if (name.contains('strawberry')) return Colors.red.shade600;
    if (name.contains('blueberry')) return Colors.indigo.shade700;
    if (name.contains('peach')) return Colors.orange.shade400;
    if (name.contains('pear')) return Colors.green.shade400;
    if (name.contains('pineapple')) return Colors.yellow.shade700;
    if (name.contains('watermelon')) return Colors.red.shade400;
    if (name.contains('cherry')) return Colors.red.shade800;
    if (name.contains('kiwi')) return Colors.green.shade700;
    if (name.contains('mango')) return Colors.orange.shade600;
    if (name.contains('papaya')) return Colors.orange.shade400;
    if (name.contains('plum')) return Colors.purple.shade700;
    if (name.contains('avocado')) return Colors.green.shade800;
    if (name.contains('berry')) return Colors.purple.shade600;
    if (name.contains('coconut')) return Colors.brown.shade400;
    if (name.contains('fruit')) return Colors.orange.shade600;

    // Vegetables
    if (name.contains('carrot')) return Colors.orange.shade700;
    if (name.contains('potato')) return Colors.brown.shade400;
    if (name.contains('onion')) return Colors.brown.shade300;
    if (name.contains('tomato')) return Colors.red.shade600;
    if (name.contains('cucumber')) return Colors.green.shade600;
    if (name.contains('pepper')) return Colors.red.shade700;
    if (name.contains('broccoli')) return Colors.green.shade700;
    if (name.contains('spinach')) return Colors.green.shade800;
    if (name.contains('lettuce')) return Colors.green.shade600;
    if (name.contains('salad')) return Colors.green.shade600;
    if (name.contains('cabbage')) return Colors.green.shade400;
    if (name.contains('celery')) return Colors.green.shade700;
    if (name.contains('zucchini')) return Colors.green.shade600;
    if (name.contains('eggplant')) return Colors.purple.shade900;
    if (name.contains('garlic')) return Colors.grey.shade100;
    if (name.contains('ginger')) return Colors.brown.shade300;
    if (name.contains('corn')) return Colors.yellow.shade700;
    if (name.contains('mushroom')) return Colors.brown.shade400;
    if (name.contains('bean')) return Colors.green.shade700;
    if (name.contains('pea')) return Colors.green.shade600;
    if (name.contains('vegetable')) return Colors.green.shade700;

    // Dairy
    if (name.contains('milk')) return Colors.blue.shade400;
    if (name.contains('cheese')) return Colors.amber.shade700;
    if (name.contains('yogurt')) return Colors.pink.shade200;
    if (name.contains('butter')) return Colors.yellow.shade700;
    if (name.contains('cream')) return Colors.blue.shade300;
    if (name.contains('ice cream') || name.contains('icecream')) return Colors.pink.shade400;

    // Meat & Protein
    if (name.contains('chicken')) return Colors.orange.shade200;
    if (name.contains('beef')) return Colors.red.shade900;
    if (name.contains('pork')) return Colors.pink.shade300;
    if (name.contains('fish')) return Colors.blue.shade400;
    if (name.contains('meat')) return Colors.red.shade800;
    if (name.contains('sausage')) return Colors.red.shade700;
    if (name.contains('bacon')) return Colors.red.shade400;
    if (name.contains('turkey')) return Colors.brown.shade300;
    if (name.contains('lamb')) return Colors.red.shade900;
    if (name.contains('shrimp')) return Colors.pink.shade400;
    if (name.contains('salmon')) return Colors.orange.shade400;
    if (name.contains('tuna')) return Colors.blue.shade700;
    if (name.contains('crab')) return Colors.red.shade400;
    if (name.contains('lobster')) return Colors.red.shade700;

    // Bakery
    if (name.contains('bread')) return Colors.brown.shade600;
    if (name.contains('bagel')) return Colors.brown.shade500;
    if (name.contains('croissant')) return Colors.brown.shade400;
    if (name.contains('cake')) return Colors.pink.shade300;
    if (name.contains('pie')) return Colors.brown.shade500;
    if (name.contains('cookie')) return Colors.brown.shade600;
    if (name.contains('muffin')) return Colors.brown.shade400;
    if (name.contains('donut')) return Colors.pink.shade400;
    if (name.contains('biscuit')) return Colors.brown.shade500;
    if (name.contains('cracker')) return Colors.brown.shade300;
    if (name.contains('waffle')) return Colors.amber.shade700;
    if (name.contains('pancake')) return Colors.amber.shade600;

    // Beverages
    if (name.contains('water')) return Colors.blue.shade400;
    if (name.contains('juice')) return Colors.orange.shade400;
    if (name.contains('soda')) return Colors.red.shade400;
    if (name.contains('coffee')) return Colors.brown.shade700;
    if (name.contains('tea')) return Colors.brown.shade400;
    if (name.contains('beer')) return Colors.amber.shade700;
    if (name.contains('wine')) return Colors.purple.shade900;
    if (name.contains('whiskey')) return Colors.amber.shade800;
    if (name.contains('vodka')) return Colors.blue.shade200;
    if (name.contains('energy drink')) return Colors.yellow.shade700;
    if (name.contains('smoothie')) return Colors.purple.shade400;
    if (name.contains('milkshake')) return Colors.pink.shade300;

    // Snacks
    if (name.contains('chips')) return Colors.amber.shade600;
    if (name.contains('candy')) return Colors.pink.shade400;
    if (name.contains('chocolate')) return Colors.brown.shade800;
    if (name.contains('snack')) return Colors.orange.shade400;
    if (name.contains('nuts')) return Colors.brown.shade500;
    if (name.contains('popcorn')) return Colors.yellow.shade600;
    if (name.contains('pretzel')) return Colors.brown.shade400;
    if (name.contains('granola')) return Colors.brown.shade500;

    // Grains & Pasta
    if (name.contains('rice')) return Colors.brown.shade300;
    if (name.contains('pasta')) return Colors.amber.shade400;
    if (name.contains('noodle')) return Colors.amber.shade500;
    if (name.contains('spaghetti')) return Colors.amber.shade400;
    if (name.contains('grain')) return Colors.amber.shade700;
    if (name.contains('cereal')) return Colors.brown.shade400;
    if (name.contains('oat')) return Colors.brown.shade300;
    if (name.contains('quinoa')) return Colors.brown.shade400;
    if (name.contains('barley')) return Colors.amber.shade600;
    if (name.contains('wheat')) return Colors.amber.shade700;

    // Condiments & Sauces
    if (name.contains('ketchup')) return Colors.red.shade700;
    if (name.contains('mustard')) return Colors.yellow.shade700;
    if (name.contains('mayo')) return Colors.yellow.shade100;
    if (name.contains('sauce')) return Colors.red.shade600;
    if (name.contains('dressing')) return Colors.green.shade400;
    if (name.contains('vinegar')) return Colors.brown.shade300;
    if (name.contains('honey')) return Colors.amber.shade600;
    if (name.contains('jam')) return Colors.purple.shade400;
    if (name.contains('jelly')) return Colors.purple.shade300;
    if (name.contains('syrup')) return Colors.brown.shade600;

    // Special items
    if (name.contains('egg')) return Colors.amber.shade200;
    if (name.contains('pizza')) return Colors.red.shade400;
    if (name.contains('burger')) return Colors.brown.shade500;
    if (name.contains('sandwich')) return Colors.brown.shade400;
    if (name.contains('frozen')) return Colors.lightBlue.shade300;

    // Default to category color
    return _getCategoryColor(category);
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
            'Add items using the + button below',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
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
    final emoji = alert.isCritical ? '🚨' : '⚠️';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shadowColor: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withOpacity(0.05),
              color.withOpacity(0.02),
            ],
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.8)],
              ),
              shape: BoxShape.circle,
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          title: Text(
            alert.headline,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              alert.description,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
