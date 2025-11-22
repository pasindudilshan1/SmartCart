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
      color: color.withValues(alpha: 0.08),
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
                Icon(
                    hasAlerts ? Icons.notifications_active_outlined : Icons.notifications_outlined),
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
                        gradient: const LinearGradient(colors: [Colors.red, Colors.redAccent]),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.3),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close_outlined : Icons.search_outlined),
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
          onTap: _onTabTapped,
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
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 400 + (index * 100)),
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 30 * (1 - value)),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${items.length} items'),
                    children: items.asMap().entries.map((entry) {
                      final itemIndex = entry.key;
                      final item = entry.value;
                      return TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 300 + (itemIndex * 50)),
                        builder: (context, itemValue, child) {
                          return Opacity(
                            opacity: itemValue,
                            child: Transform.translate(
                              offset: Offset(20 * (1 - itemValue), 0),
                              child: _buildShoppingItemCard(item),
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
    final quantity = (item['Quantity'] ?? item['quantity'] ?? 1.0).toDouble();
    final unit = item['Unit'] ?? item['unit'] ?? 'pcs';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _getProductIconColor(productName, category).withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getProductIcon(productName, category),
            color: _getProductIconColor(productName, category),
            size: 26,
          ),
        ),
        title: Text(
          productName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$brand${brand.isNotEmpty ? ' • ' : ''}$category',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
            if (!_isLooseItemsMode)
              Text(
                '$quantity $unit',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
          ],
        ),
        trailing: Icon(Icons.chevron_right_outlined, color: Theme.of(context).colorScheme.primary),
        onTap: () => _showProductDetails(item),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'dairy':
        return Colors.blue.shade600;
      case 'meat':
      case 'meat & poultry':
        return Colors.red.shade700;
      case 'fruits':
      case 'fruits & vegetables':
        return Colors.orange.shade700;
      case 'vegetables':
        return Colors.green.shade700;
      case 'bakery':
        return Colors.brown.shade700;
      case 'grains':
      case 'grains & bread':
        return Colors.amber.shade700;
      case 'beverages':
        return Colors.cyan.shade700;
      case 'snacks':
        return Colors.purple.shade600;
      default:
        return Colors.grey.shade700;
    }
  }

  IconData _getCategoryIconForHeader(String category) {
    switch (category.toLowerCase()) {
      case 'dairy':
        return Icons.local_drink;
      case 'meat':
      case 'meat & poultry':
        return Icons.dinner_dining;
      case 'fruits':
      case 'fruits & vegetables':
        return Icons.apple;
      case 'vegetables':
        return Icons.yard;
      case 'bakery':
        return Icons.bakery_dining;
      case 'grains':
      case 'grains & bread':
        return Icons.grain;
      case 'beverages':
        return Icons.local_bar;
      case 'snacks':
        return Icons.cookie;
      case 'frozen':
        return Icons.ac_unit;
      case 'canned':
        return Icons.inventory;
      case 'seafood':
        return Icons.set_meal;
      case 'condiments':
        return Icons.water_drop;
      default:
        return Icons.shopping_basket;
    }
  }

  Color _getProductIconColor(String productName, String category) {
    final name = productName.toLowerCase();

    // Fruits - orange/yellow tones
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

    // Vegetables - green tones
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

    // Dairy - blue/white tones
    if (name.contains('milk')) return Colors.blue.shade400;
    if (name.contains('cheese')) return Colors.amber.shade700;
    if (name.contains('yogurt')) return Colors.pink.shade200;
    if (name.contains('butter')) return Colors.yellow.shade700;
    if (name.contains('cream')) return Colors.blue.shade300;
    if (name.contains('ice cream') || name.contains('icecream')) return Colors.pink.shade400;

    // Meat & Protein - red/brown tones
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

    // Bakery - brown tones
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

    // Beverages - various colors
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

    // Snacks - mixed colors
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

  IconData _getProductIcon(String productName, String category) {
    final name = productName.toLowerCase();

    // Fruits - diverse icons
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

    // Vegetables - diverse icons
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

    // Dairy - diverse icons
    if (name.contains('milk')) return Icons.local_drink;
    if (name.contains('cheese')) return Icons.square;
    if (name.contains('yogurt')) return Icons.set_meal;
    if (name.contains('butter')) return Icons.square_rounded;
    if (name.contains('cream')) return Icons.waves;
    if (name.contains('ice cream')) return Icons.icecream;
    if (name.contains('icecream')) return Icons.icecream;

    // Meat & Protein - diverse icons
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

    // Bakery - diverse icons
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

    // Beverages - diverse icons
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

    // Snacks - diverse icons
    if (name.contains('chips')) return Icons.set_meal;
    if (name.contains('candy')) return Icons.star;
    if (name.contains('chocolate')) return Icons.square;
    if (name.contains('snack')) return Icons.fastfood;
    if (name.contains('nuts')) return Icons.scatter_plot;
    if (name.contains('popcorn')) return Icons.bubble_chart;
    if (name.contains('pretzel')) return Icons.all_inclusive;
    if (name.contains('granola')) return Icons.grain;

    // Grains & Pasta - diverse icons
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
        return Icons.ac_unit;
      case 'canned':
        return Icons.inventory;
      case 'seafood':
        return Icons.set_meal;
      case 'condiments':
        return Icons.water_drop;
      default:
        return Icons.shopping_basket;
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

  void _showLooseItemShoppingDialog(Map<String, dynamic> looseItem) {
    final weightController = TextEditingController(text: '100');
    double weight = 100.0;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
                  Text(
                    'Buy ${looseItem['product'] ?? 'Loose Item'}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                looseItem['product'] ?? 'Unknown Product',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                'Loose Item - ${looseItem['category'] ?? 'Other'}',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.shopping_bag, color: Colors.green),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: weightController,
                    decoration: const InputDecoration(
                      labelText: 'Weight (grams)',
                      border: OutlineInputBorder(),
                      hintText: 'Enter weight in grams',
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        weight = double.tryParse(value) ?? 100.0;
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
                    'Nutrition Information (per 100g)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  _buildLooseItemNutritionDisplay(looseItem, isTotal: false),
                  const SizedBox(height: 12),
                  Text(
                    'Total Nutrition (${weight.toStringAsFixed(0)}g)',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  _buildLooseItemNutritionDisplay(looseItem, weight: weight, isTotal: true),
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
                        onPressed: () => _purchaseLooseItem(looseItem, weight, selectedDate),
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

      // Get category to determine if it's a beverage
      final category = item['Category'] ?? item['category'] ?? 'Other';
      final isBeverage = _isLiquidCategory(category);

      // Calculate actual weight/volume purchased
      // For Beverages: ActualWeight in table is stored in ml (per unit)
      // For Others: ActualWeight in table is stored in grams (per unit)
      final isLooseItem = item['main_category'] == 'Loose Items';
      final actualWeightPerUnit = isLooseItem
          ? (item['ActualWeight'] ?? item['actualWeight'] ?? 1.0).toDouble()
          : ((item['Quantity'] ?? 1.0) != (item['ActualWeight'] ?? 100.0))
              ? ((item['ActualWeight'] ?? 100.0) * (item['Quantity'] ?? 1.0)).toDouble()
              : (item['ActualWeight'] ?? 100.0).toDouble();
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
        quantity: isLooseItem ? quantity : 1.0,
        unit: item['Unit'] ?? item['unit'] ?? (isBeverage ? 'ml' : 'g'),
        actualWeight: isLooseItem ? totalActualWeight : actualWeightPerUnit,
        price: null,
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
                servingSize: isBeverage
                    ? '${(isLooseItem ? totalActualWeight : actualWeightPerUnit).toStringAsFixed(0)}ml'
                    : '${(isLooseItem ? totalActualWeight : actualWeightPerUnit).toStringAsFixed(0)}g',
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
    return const SizedBox.shrink();
  }

  void _onTabTapped(int index) {
    if (index == 1) {
      _navigateToScanner();
    }
  }

  Future<void> _navigateToScanner() async {
    final scannedItem = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ScannerScreen(isFromShoppingList: true)),
    );

    if (scannedItem != null && mounted) {
      final isLooseItem = scannedItem['main_category'] == 'Loose Items' ||
          scannedItem['QRCode']?.toString().startsWith('LooseItems__') == true;
      if (isLooseItem) {
        _showLooseItemShoppingDialog(scannedItem);
      } else {
        _showProductDetails(scannedItem);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildLooseItemNutritionDisplay(Map<String, dynamic> item,
      {double weight = 100.0, bool isTotal = false}) {
    final calories = item['calories']?.toDouble() ?? 0.0;
    final protein = item['protein']?.toDouble() ?? 0.0;
    final fat = item['fat']?.toDouble() ?? 0.0;
    final carbs = item['carbs']?.toDouble() ?? 0.0;
    final fiber = item['fiber']?.toDouble() ?? 0.0;

    double multiplier = 1.0;
    if (isTotal) {
      multiplier = weight / 100.0;
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildNutritionItem('Calories', calories * multiplier, 'kcal'),
            ),
            Expanded(
              child: _buildNutritionItem('Protein', protein * multiplier, 'g'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildNutritionItem('Fat', fat * multiplier, 'g'),
            ),
            Expanded(
              child: _buildNutritionItem('Carbs', carbs * multiplier, 'g'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildNutritionItem('Fiber', fiber * multiplier, 'g'),
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

  Future<void> _purchaseLooseItem(
      Map<String, dynamic> looseItem, double weight, DateTime expiryDate) async {
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

      // Calculate nutrition for the purchased weight
      final baseCalories = looseItem['calories']?.toDouble() ?? 0.0;
      final baseProtein = looseItem['protein']?.toDouble() ?? 0.0;
      final baseFat = looseItem['fat']?.toDouble() ?? 0.0;
      final baseCarbs = looseItem['carbs']?.toDouble() ?? 0.0;
      final baseFiber = looseItem['fiber']?.toDouble() ?? 0.0;

      final weightMultiplier = weight / 100.0;

      final calculatedCalories = baseCalories * weightMultiplier;
      final calculatedProtein = baseProtein * weightMultiplier;
      final calculatedFat = baseFat * weightMultiplier;
      final calculatedCarbs = baseCarbs * weightMultiplier;
      final calculatedFiber = baseFiber * weightMultiplier;

      // Create product from loose item
      final product = Product(
        id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
        name: looseItem['product'] ?? 'Unknown Product',
        barcode: looseItem['QRCode'],
        category: looseItem['category'] ?? 'Other',
        quantity: 1.0,
        unit: 'g',
        actualWeight: weight,
        price: null,
        imageUrl: null,
        storageLocation: 'pantry',
        purchaseDate: DateTime.now(),
        dateAdded: DateTime.now(),
        expiryDate: expiryDate,
        nutritionInfo: calculatedCalories > 0
            ? NutritionInfo(
                calories: calculatedCalories,
                protein: calculatedProtein,
                carbs: calculatedCarbs,
                fat: calculatedFat,
                fiber: calculatedFiber,
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
              content: Text('${product.name} (${weight.toStringAsFixed(0)}g) added to inventory'),
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
      debugPrint('Error purchasing loose item: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
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
                if (!isLooseItem)
                  _buildInfoRow(isBeverage ? 'Per Bottle' : 'Per Pack',
                      '${actualWeightPerUnit.toStringAsFixed(0)} ${isBeverage ? 'ml' : 'g'}'),
                if (barcode.isNotEmpty) _buildInfoRow('Barcode', barcode),
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
      color: color.withValues(alpha: 0.08),
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
                    color: color.withValues(alpha: 0.16),
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
