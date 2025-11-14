// Shopping List Screen with Manual and Scan tabs

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/inventory_provider.dart';
import '../providers/nutrition_provider.dart';
import '../providers/household_nutrition_alerts_provider.dart';
import '../services/azure_table_service.dart';
import '../services/local_storage_service.dart';
import 'scanner_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

const double _nutritionAlertThreshold = 0.9;

class _ShoppingListScreenState extends State<ShoppingListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AzureTableService _azureService = AzureTableService();
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _shoppingItems = [];
  List<Map<String, dynamic>> _filteredShoppingItems = [];
  bool _isLoading = false;
  bool _isSearching = false;
  bool _isLooseItemsMode = false;

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
    _tabController = TabController(length: 2, vsync: this);
    _loadShoppingItems();
    _searchController.addListener(_filterShoppingItems);
    // Load household nutrition for alerts using the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final alertsProvider = context.read<HouseholdNutritionAlertsProvider>();
      final nutritionProvider = context.read<NutritionProvider>();
      alertsProvider.loadHouseholdNutrition(nutritionProvider);
    });
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
      final items = _isLooseItemsMode
          ? (await _azureService.getAllLooseItems())
              .where((item) => item['main_category'] == 'Loose Items')
              .toList()
          : await _azureService.getAllShoppingListItems();
      setState(() {
        _shoppingItems = items;
        _filteredShoppingItems = items;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading shopping items: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showNutritionAlertsSheet(List<NutritionAlert> alerts) {
    final alertsProvider = context.read<HouseholdNutritionAlertsProvider>();
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
                if (alertsProvider.usingFallbackGoals &&
                    alertsProvider.nutritionGoalSourceNote != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    alertsProvider.nutritionGoalSourceNote!,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white70 : Colors.black54;
    final inventoryProvider = context.watch<InventoryProvider>();
    final alertsProvider = context.watch<HouseholdNutritionAlertsProvider>();
    final inventoryTotals = inventoryProvider.getTotalInventoryNutrition();
    final alerts = alertsProvider.calculateAlerts(inventoryTotals);
    final hasAlerts = alerts.isNotEmpty;

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
              _isLooseItemsMode ? 'No loose items available' : 'No items in shopping list',
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('Loose Items'),
                      const Spacer(),
                      Switch(
                        value: _isLooseItemsMode,
                        onChanged: (value) {
                          setState(() {
                            _isLooseItemsMode = value;
                          });
                          _loadShoppingItems();
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildGroupedShoppingList(),
                ),
              ],
            ),
    );
  }

  Widget _buildGroupedShoppingList() {
    // Group items by category
    final groupedItems = <String, List<Map<String, dynamic>>>{};
    for (final item in _filteredShoppingItems) {
      final category = item['Category'] ?? item['category'] ?? 'Other';
      groupedItems.putIfAbsent(category, () => []).add(item);
    }

    final categories = groupedItems.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final items = groupedItems[category]!;
        return ExpansionTile(
          title: Text(
            category,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text('${items.length} items'),
          children: items.map((item) => _buildShoppingItemCard(item)).toList(),
        );
      },
    );
  }

  Widget _buildShoppingItemCard(Map<String, dynamic> item) {
    final productName = item['ProductName'] ??
        item['product'] ??
        item['name'] ??
        item['product_name'] ??
        item['item'] ??
        'Unknown Product';
    final category = item['Category'] ?? item['category'] ?? 'Other';
    final brand = item['Brand'] ?? item['brand'] ?? '';
    final price = (item['Price'] ?? item['price'] ?? 0.0).toDouble();
    final quantity = (item['Quantity'] ?? item['quantity'] ?? 1.0).toDouble();
    final unit = item['Unit'] ?? item['unit'] ?? 'pcs';

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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$brand${brand.isNotEmpty ? ' • ' : ''}$category',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            Text(
              '$quantity $unit${price > 0 ? ' • \$${price.toStringAsFixed(2)}' : ''}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
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
    final alertsProvider = context.read<HouseholdNutritionAlertsProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ProductDetailsSheet(
        item: item,
        onPurchase: (quantity) => _purchaseProduct(item, quantity),
        householdMonthlyCalories: alertsProvider.monthlyCaloriesGoal,
        householdMonthlyProtein: alertsProvider.monthlyProteinGoal,
        householdMonthlyCarbs: alertsProvider.monthlyCarbsGoal,
        householdMonthlyFat: alertsProvider.monthlyFatGoal,
        householdMonthlyFiber: alertsProvider.monthlyFiberGoal,
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
      final baseCalories = (item['Calories'] ?? item['calories'] ?? 0.0).toDouble();
      final baseProtein = (item['Protein'] ?? item['protein'] ?? 0.0).toDouble();
      final baseCarbs = (item['Carbs'] ?? item['carbs'] ?? 0.0).toDouble();
      final baseFat = (item['Fat'] ?? item['fat'] ?? 0.0).toDouble();
      final baseFiber = (item['Fiber'] ?? item['fiber'] ?? 0.0).toDouble();
      final baseSugar = (item['Sugar'] ?? item['sugar'] ?? 0.0).toDouble();
      final baseSodium = (item['Sodium'] ?? item['sodium'] ?? 0.0).toDouble();

      // Get category to determine if it's a beverage
      final category = item['Category'] ?? item['category'] ?? 'Other';
      final isBeverage = _isLiquidCategory(category);

      // Calculate actual weight/volume purchased
      // For Beverages: ActualWeight in table is stored in ml (per unit)
      // For Others: ActualWeight in table is stored in grams (per unit)
      final isLooseItem = item['main_category'] == 'Loose Items';
      final actualWeightPerUnit =
          (item['ActualWeight'] ?? item['actualWeight'] ?? (isLooseItem ? 1.0 : 100.0))
              .toDouble(); // in grams or ml per unit
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
        name: item['ProductName'] ??
            item['product'] ??
            item['name'] ??
            item['product_name'] ??
            item['item'] ??
            'Unknown Product',
        barcode: item['Barcode'] ?? item['barcode'],
        category: category,
        brand: item['Brand'] ?? item['brand'],
        quantity: quantity,
        unit: item['Unit'] ?? item['unit'] ?? (isBeverage ? 'ml' : 'g'),
        actualWeight: totalActualWeight > 0 ? totalActualWeight : null,
        price: (item['Price'] ?? item['price'])?.toDouble(),
        imageUrl: item['ImageUrl'] ?? item['imageUrl'],
        storageLocation: item['StorageLocation'] ?? item['storageLocation'],
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

        if (mounted) {
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
      }
    } catch (e) {
      debugPrint('Error purchasing product: $e');
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
            'Scan products to add them to your shopping list or inventory.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final scannedItem = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ScannerScreen(isFromShoppingList: true)),
              );

              if (scannedItem != null && mounted) {
                _showProductDetails(scannedItem);
              }
            },
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Open Scanner'),
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
  final double? householdMonthlyCalories;
  final double? householdMonthlyProtein;
  final double? householdMonthlyCarbs;
  final double? householdMonthlyFat;
  final double? householdMonthlyFiber;

  const _ProductDetailsSheet({
    required this.item,
    required this.onPurchase,
    this.householdMonthlyCalories,
    this.householdMonthlyProtein,
    this.householdMonthlyCarbs,
    this.householdMonthlyFat,
    this.householdMonthlyFiber,
  });

  @override
  State<_ProductDetailsSheet> createState() => _ProductDetailsSheetState();
}

class _ProductDetailsSheetState extends State<_ProductDetailsSheet> {
  final TextEditingController _quantityController = TextEditingController(text: '1');
  double _purchaseQuantity = 1.0;

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
    _quantityController.addListener(_onQuantityChanged);
  }

  void _onQuantityChanged() {
    setState(() {
      _purchaseQuantity = double.tryParse(_quantityController.text) ?? 1.0;
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final productName = item['ProductName'] ??
        item['product'] ??
        item['name'] ??
        item['product_name'] ??
        item['item'] ??
        'Unknown Product';
    final category = item['Category'] ?? item['category'] ?? 'Other';
    final brand = item['Brand'] ?? item['brand'] ?? '';
    final price = (item['Price'] ?? item['price'] ?? 0.0).toDouble();
    final unit = item['Unit'] ?? item['unit'] ?? (_isLiquidCategory(category) ? 'ml' : 'g');
    final barcode = item['Barcode'] ?? item['barcode'] ?? '';
    final storageLocation = item['StorageLocation'] ?? item['storageLocation'] ?? '';
    final notes = item['Notes'] ?? item['notes'] ?? '';

    // Nutrition info (per 100g)
    final calories = (item['Calories'] ?? item['calories'] ?? 0.0).toDouble();
    final protein = (item['Protein'] ?? item['protein'] ?? 0.0).toDouble();
    final carbs = (item['Carbs'] ?? item['carbs'] ?? 0.0).toDouble();
    final fat = (item['Fat'] ?? item['fat'] ?? 0.0).toDouble();
    final fiber = (item['Fiber'] ?? item['fiber'] ?? 0.0).toDouble();
    final sugar = (item['Sugar'] ?? item['sugar'] ?? 0.0).toDouble();
    final sodium = (item['Sodium'] ?? item['sodium'] ?? 0.0).toDouble();

    // Get existing inventory products
    final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
    final existingProducts = inventoryProvider.getAllProducts().where((p) {
      return p.name.toLowerCase() == productName.toLowerCase() ||
          (p.barcode != null && p.barcode == barcode);
    }).toList();

    // Calculate current inventory totals
    double currentInventoryQuantity = 0.0;
    double currentInventoryCalories = 0.0;
    double currentInventoryProtein = 0.0;
    double currentInventoryFat = 0.0;
    double currentInventoryCarbs = 0.0;
    double currentInventoryFiber = 0.0;
    for (final product in existingProducts) {
      currentInventoryQuantity += product.quantity;
      if (product.nutritionInfo != null) {
        currentInventoryCalories += product.nutritionInfo!.calories;
        currentInventoryProtein += product.nutritionInfo!.protein;
        currentInventoryFat += product.nutritionInfo!.fat;
        currentInventoryCarbs += product.nutritionInfo!.carbs;
        currentInventoryFiber += product.nutritionInfo!.fiber;
      }
    }

    final currentInventoryTotals = inventoryProvider.getTotalInventoryNutrition();

    // Calculate new totals after purchase
    final isLooseItem = item['main_category'] == 'Loose Items';
    final actualWeightPerUnit = item['ActualWeight']?.toDouble() ?? (isLooseItem ? 1.0 : 100.0);
    final totalActualWeight = actualWeightPerUnit * _purchaseQuantity;
    final isBeverage = category.toLowerCase() == 'beverages';
    final weightMultiplier = totalActualWeight / 100.0;
    final additionalCalories = calories * weightMultiplier;
    final additionalProtein = protein * weightMultiplier;
    final additionalFat = fat * weightMultiplier;
    final additionalCarbs = carbs * weightMultiplier;
    final additionalFiber = fiber * weightMultiplier;

    final projectedInventoryTotals = {
      'calories': (currentInventoryTotals['calories'] ?? 0) + additionalCalories,
      'protein': (currentInventoryTotals['protein'] ?? 0) + additionalProtein,
      'carbs': (currentInventoryTotals['carbs'] ?? 0) + additionalCarbs,
      'fat': (currentInventoryTotals['fat'] ?? 0) + additionalFat,
      'fiber': (currentInventoryTotals['fiber'] ?? 0) + additionalFiber,
    };

    final householdAlerts = _gatherProjectedAlerts(
      currentTotals: currentInventoryTotals,
      projectedTotals: projectedInventoryTotals,
    );

    final newTotalQuantity = currentInventoryQuantity + _purchaseQuantity;
    final newTotalCalories = currentInventoryCalories + additionalCalories;
    final newTotalProtein = currentInventoryProtein + additionalProtein;
    final newTotalFat = currentInventoryFat + additionalFat;
    final newTotalCarbs = currentInventoryCarbs + additionalCarbs;
    final newTotalFiber = currentInventoryFiber + additionalFiber;

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

              if (householdAlerts.isNotEmpty) ...[
                Text(
                  'Household Nutrition Alerts',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                ...householdAlerts.map(_buildHouseholdAlertCard),
                const SizedBox(height: 16),
              ],

              // Current Inventory Info
              if (existingProducts.isNotEmpty) ...[
                _buildInfoSection('Current Inventory', [
                  _buildInfoRow('Quantity in Inventory',
                      '${currentInventoryQuantity.toStringAsFixed(1)} $unit'),
                  _buildInfoRow(
                      'Total Calories', '${currentInventoryCalories.toStringAsFixed(0)} kcal'),
                ]),
                const SizedBox(height: 16),
                _buildInfoSection('Current Inventory Nutrition', [
                  _buildInfoRow('Calories', '${currentInventoryCalories.toStringAsFixed(0)} kcal'),
                  _buildInfoRow('Protein', '${currentInventoryProtein.toStringAsFixed(1)}g'),
                  _buildInfoRow('Carbs', '${currentInventoryCarbs.toStringAsFixed(1)}g'),
                  _buildInfoRow('Fat', '${currentInventoryFat.toStringAsFixed(1)}g'),
                  if (currentInventoryFiber > 0)
                    _buildInfoRow('Fiber', '${currentInventoryFiber.toStringAsFixed(1)}g'),
                ]),
              ],

              // Basic Info
              _buildInfoSection('Basic Information', [
                _buildInfoRow('Category', category),
                if (barcode.isNotEmpty) _buildInfoRow('Barcode', barcode),
                if (price > 0) _buildInfoRow('Price', '\$${price.toStringAsFixed(2)}'),
                if (storageLocation.isNotEmpty) _buildInfoRow('Storage', storageLocation),
              ]),

              const SizedBox(height: 16),

              // Nutrition Info
              if (calories > 0)
                _buildInfoSection(
                    isBeverage
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
                  labelText: 'Quantity (${isBeverage ? 'ml' : 'g'})',
                  suffixIcon: const Icon(Icons.shopping_cart),
                ),
              ),

              const SizedBox(height: 16),

              // Purchase Nutrition
              if (calories > 0)
                _buildInfoSection('Purchase Nutrition', [
                  _buildInfoRow('Calories', '${additionalCalories.toStringAsFixed(0)} kcal'),
                  _buildInfoRow('Protein', '${additionalProtein.toStringAsFixed(1)}g'),
                  _buildInfoRow('Carbs', '${additionalCarbs.toStringAsFixed(1)}g'),
                  _buildInfoRow('Fat', '${additionalFat.toStringAsFixed(1)}g'),
                  if (additionalFiber > 0)
                    _buildInfoRow('Fiber', '${additionalFiber.toStringAsFixed(1)}g'),
                ]),

              // Projected Totals
              _buildInfoSection('After Purchase Totals', [
                _buildInfoRow('New Total Quantity', '${newTotalQuantity.toStringAsFixed(1)} $unit'),
                _buildInfoRow('New Total Calories', '${newTotalCalories.toStringAsFixed(0)} kcal'),
                _buildInfoRow('New Total Protein', '${newTotalProtein.toStringAsFixed(1)}g'),
                _buildInfoRow('New Total Carbs', '${newTotalCarbs.toStringAsFixed(1)}g'),
                _buildInfoRow('New Total Fat', '${newTotalFat.toStringAsFixed(1)}g'),
                if (newTotalFiber > 0)
                  _buildInfoRow('New Total Fiber', '${newTotalFiber.toStringAsFixed(1)}g'),
                if (currentInventoryCalories > 0)
                  _buildInfoRow(
                    'Increase',
                    '+${(newTotalCalories - currentInventoryCalories).toStringAsFixed(0)} kcal (${((newTotalCalories / currentInventoryCalories - 1) * 100).toStringAsFixed(1)}%)',
                  ),
              ]),

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

  List<NutritionAlert> _gatherProjectedAlerts({
    required Map<String, double> currentTotals,
    required Map<String, double> projectedTotals,
  }) {
    final alerts = <NutritionAlert>[];

    alerts.addAll(_evaluateNutrient(
      nutrient: 'Calories',
      unit: 'kcal',
      goal: widget.householdMonthlyCalories,
      currentValue: currentTotals['calories'] ?? 0,
      projectedValue: projectedTotals['calories'] ?? 0,
    ));

    alerts.addAll(_evaluateNutrient(
      nutrient: 'Protein',
      unit: 'g',
      goal: widget.householdMonthlyProtein,
      currentValue: currentTotals['protein'] ?? 0,
      projectedValue: projectedTotals['protein'] ?? 0,
    ));

    alerts.addAll(_evaluateNutrient(
      nutrient: 'Carbs',
      unit: 'g',
      goal: widget.householdMonthlyCarbs,
      currentValue: currentTotals['carbs'] ?? 0,
      projectedValue: projectedTotals['carbs'] ?? 0,
    ));

    alerts.addAll(_evaluateNutrient(
      nutrient: 'Fat',
      unit: 'g',
      goal: widget.householdMonthlyFat,
      currentValue: currentTotals['fat'] ?? 0,
      projectedValue: projectedTotals['fat'] ?? 0,
    ));

    alerts.addAll(_evaluateNutrient(
      nutrient: 'Fiber',
      unit: 'g',
      goal: widget.householdMonthlyFiber,
      currentValue: currentTotals['fiber'] ?? 0,
      projectedValue: projectedTotals['fiber'] ?? 0,
    ));

    return alerts;
  }

  List<NutritionAlert> _evaluateNutrient({
    required String nutrient,
    required String unit,
    required double? goal,
    required double currentValue,
    required double projectedValue,
  }) {
    if (goal == null || goal <= 0) {
      return const [];
    }

    final alerts = <NutritionAlert>[];
    final currentRatio = currentValue / goal;
    final projectedRatio = projectedValue / goal;

    if (currentRatio >= _nutritionAlertThreshold) {
      alerts.add(NutritionAlert(
        nutrient: nutrient,
        inventoryValue: currentValue,
        goalValue: goal,
        unit: unit,
        triggeredByUpcomingPurchase: false,
      ));
    }

    final bool crossesThreshold =
        currentRatio < _nutritionAlertThreshold && projectedRatio >= _nutritionAlertThreshold;
    final bool becomesCritical = currentRatio < 1.0 && projectedRatio >= 1.0;

    if (projectedRatio >= _nutritionAlertThreshold && (crossesThreshold || becomesCritical)) {
      alerts.add(NutritionAlert(
        nutrient: nutrient,
        inventoryValue: projectedValue,
        goalValue: goal,
        unit: unit,
        triggeredByUpcomingPurchase: true,
      ));
    }

    return alerts;
  }

  Widget _buildHouseholdAlertCard(NutritionAlert alert) {
    final color = alert.isCritical ? Colors.red : Colors.orange;
    final icon = alert.isCritical ? Icons.warning_amber_rounded : Icons.info_outline;
    final label = alert.triggeredByUpcomingPurchase ? 'After purchase' : 'Current';

    return Card(
      color: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alert.headline,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.16),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(alert.description),
          ],
        ),
      ),
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
}
