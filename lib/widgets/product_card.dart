// Product Card Widget - Reusable card for displaying products in lists

import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              _buildStatusIndicator(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: _getExpiryColor(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getExpiryText(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getExpiryColor(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.inventory_2,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Qty: ${product.quantity}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    if (product.storageLocation != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            _getLocationIcon(),
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            product.storageLocation!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (product.isLowStock)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Low Stock',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final icon = _getCategoryIcon();
    final color = _getCategoryColor();

    if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            product.imageUrl!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(icon, color: color, size: 28),
          ),
        ),
      );
    } else {
      return Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 28),
      );
    }
  }

  Color _getExpiryColor() {
    if (product.isExpired) return Colors.red;
    if (product.isExpiringSoon) return Colors.orange;
    return Colors.green;
  }

  String _getExpiryText() {
    if (product.isExpired) {
      return 'Expired ${product.daysUntilExpiry.abs()}d ago';
    } else if (product.daysUntilExpiry == 0) {
      return 'Expires today';
    } else if (product.daysUntilExpiry == 1) {
      return 'Expires tomorrow';
    } else {
      return 'Expires in ${product.daysUntilExpiry}d';
    }
  }

  IconData _getLocationIcon() {
    switch (product.storageLocation?.toLowerCase()) {
      case 'fridge':
        return Icons.kitchen;
      case 'freezer':
        return Icons.ac_unit;
      case 'pantry':
        return Icons.inventory_2;
      default:
        return Icons.place;
    }
  }

  IconData _getCategoryIcon() {
    // First, try to match specific product names for more relevant icons
    final productName = product.name.toLowerCase();

    // Fruits - diverse icons
    if (productName.contains('apple')) return Icons.apple;
    if (productName.contains('banana')) return Icons.deck;
    if (productName.contains('orange')) return Icons.circle;
    if (productName.contains('grape')) return Icons.bubble_chart;
    if (productName.contains('lemon')) return Icons.wb_sunny;
    if (productName.contains('lime')) return Icons.brightness_5;
    if (productName.contains('strawberry')) return Icons.favorite;
    if (productName.contains('blueberry')) return Icons.circle_outlined;
    if (productName.contains('peach')) return Icons.spa;
    if (productName.contains('pear')) return Icons.lightbulb;
    if (productName.contains('pineapple')) return Icons.forest;
    if (productName.contains('watermelon')) return Icons.pie_chart;
    if (productName.contains('cherry')) return Icons.favorite_border;
    if (productName.contains('kiwi')) return Icons.eco;
    if (productName.contains('mango')) return Icons.water_drop;
    if (productName.contains('papaya')) return Icons.park;
    if (productName.contains('plum')) return Icons.circle;
    if (productName.contains('avocado')) return Icons.egg_alt;
    if (productName.contains('berry')) return Icons.blur_circular;
    if (productName.contains('coconut')) return Icons.sports_basketball;
    // Other fruits
    if (productName.contains('fruit')) return Icons.yard;

    // Vegetables - diverse icons
    if (productName.contains('carrot')) return Icons.agriculture;
    if (productName.contains('potato')) return Icons.egg;
    if (productName.contains('onion')) return Icons.circle;
    if (productName.contains('tomato')) return Icons.circle;
    if (productName.contains('cucumber')) return Icons.science;
    if (productName.contains('pepper')) return Icons.whatshot;
    if (productName.contains('broccoli')) return Icons.park;
    if (productName.contains('spinach')) return Icons.grass;
    if (productName.contains('lettuce')) return Icons.eco;
    if (productName.contains('salad')) return Icons.eco;
    if (productName.contains('cabbage')) return Icons.layers;
    if (productName.contains('celery')) return Icons.segment;
    if (productName.contains('zucchini')) return Icons.straighten;
    if (productName.contains('eggplant')) return Icons.egg;
    if (productName.contains('garlic')) return Icons.grain;
    if (productName.contains('ginger')) return Icons.spa;
    if (productName.contains('corn')) return Icons.grain;
    if (productName.contains('mushroom')) return Icons.beach_access;
    if (productName.contains('bean')) return Icons.grain;
    if (productName.contains('pea')) return Icons.circle;
    if (productName.contains('vegetable')) return Icons.yard;

    // Dairy - diverse icons
    if (productName.contains('milk')) return Icons.local_drink;
    if (productName.contains('cheese')) return Icons.square;
    if (productName.contains('yogurt')) return Icons.set_meal;
    if (productName.contains('butter')) return Icons.square_rounded;
    if (productName.contains('cream')) return Icons.waves;
    if (productName.contains('ice cream')) return Icons.icecream;
    if (productName.contains('icecream')) return Icons.icecream;

    // Meat & Protein - diverse icons
    if (productName.contains('chicken')) return Icons.egg_alt;
    if (productName.contains('beef')) return Icons.restaurant_menu;
    if (productName.contains('pork')) return Icons.restaurant_menu;
    if (productName.contains('fish')) return Icons.set_meal;
    if (productName.contains('meat')) return Icons.dinner_dining;
    if (productName.contains('sausage')) return Icons.fastfood;
    if (productName.contains('bacon')) return Icons.waves;
    if (productName.contains('turkey')) return Icons.egg_alt;
    if (productName.contains('lamb')) return Icons.restaurant_menu;
    if (productName.contains('shrimp')) return Icons.water;
    if (productName.contains('salmon')) return Icons.water;
    if (productName.contains('tuna')) return Icons.water;
    if (productName.contains('crab')) return Icons.pest_control;
    if (productName.contains('lobster')) return Icons.pest_control;

    // Bakery - diverse icons
    if (productName.contains('bread')) return Icons.bakery_dining;
    if (productName.contains('bagel')) return Icons.donut_small;
    if (productName.contains('croissant')) return Icons.bakery_dining;
    if (productName.contains('cake')) return Icons.cake;
    if (productName.contains('pie')) return Icons.pie_chart;
    if (productName.contains('cookie')) return Icons.cookie;
    if (productName.contains('muffin')) return Icons.bakery_dining;
    if (productName.contains('donut')) return Icons.donut_large;
    if (productName.contains('biscuit')) return Icons.circle;
    if (productName.contains('cracker')) return Icons.crop_square;
    if (productName.contains('waffle')) return Icons.grid_on;
    if (productName.contains('pancake')) return Icons.layers;

    // Beverages - diverse icons
    if (productName.contains('water')) return Icons.water_drop;
    if (productName.contains('juice')) return Icons.local_drink;
    if (productName.contains('soda')) return Icons.local_bar;
    if (productName.contains('coffee')) return Icons.local_cafe;
    if (productName.contains('tea')) return Icons.emoji_food_beverage;
    if (productName.contains('beer')) return Icons.sports_bar;
    if (productName.contains('wine')) return Icons.wine_bar;
    if (productName.contains('whiskey')) return Icons.liquor;
    if (productName.contains('vodka')) return Icons.liquor;
    if (productName.contains('energy drink')) return Icons.flash_on;
    if (productName.contains('smoothie')) return Icons.blender;
    if (productName.contains('milkshake')) return Icons.icecream;

    // Snacks - diverse icons
    if (productName.contains('chips')) return Icons.set_meal;
    if (productName.contains('candy')) return Icons.star;
    if (productName.contains('chocolate')) return Icons.square;
    if (productName.contains('snack')) return Icons.fastfood;
    if (productName.contains('nuts')) return Icons.scatter_plot;
    if (productName.contains('popcorn')) return Icons.bubble_chart;
    if (productName.contains('pretzel')) return Icons.all_inclusive;
    if (productName.contains('granola')) return Icons.grain;

    // Grains & Pasta - diverse icons
    if (productName.contains('rice')) return Icons.rice_bowl;
    if (productName.contains('pasta')) return Icons.ramen_dining;
    if (productName.contains('noodle')) return Icons.ramen_dining;
    if (productName.contains('spaghetti')) return Icons.ramen_dining;
    if (productName.contains('grain')) return Icons.grain;
    if (productName.contains('cereal')) return Icons.breakfast_dining;
    if (productName.contains('oat')) return Icons.grain;
    if (productName.contains('quinoa')) return Icons.scatter_plot;
    if (productName.contains('barley')) return Icons.grain;
    if (productName.contains('wheat')) return Icons.grass;

    // Condiments & Sauces
    if (productName.contains('sauce')) return Icons.water_drop;
    if (productName.contains('ketchup')) return Icons.water_drop;
    if (productName.contains('mustard')) return Icons.water_drop;
    if (productName.contains('mayo')) return Icons.water_drop;
    if (productName.contains('dressing')) return Icons.local_drink;
    if (productName.contains('vinegar')) return Icons.science;
    if (productName.contains('honey')) return Icons.local_florist;
    if (productName.contains('jam')) return Icons.set_meal;
    if (productName.contains('jelly')) return Icons.set_meal;
    if (productName.contains('syrup')) return Icons.water_drop;

    // Canned & Packaged
    if (productName.contains('can') ||
        productName.contains('canned') ||
        productName.contains('tin')) {
      return Icons.inventory;
    }
    if (productName.contains('soup')) return Icons.soup_kitchen;
    if (productName.contains('beans')) return Icons.set_meal;

    // Frozen
    if (productName.contains('frozen')) return Icons.ac_unit;
    if (productName.contains('ice')) return Icons.ac_unit;

    // Eggs
    if (productName.contains('egg')) return Icons.egg;

    // Pizza & Fast Food
    if (productName.contains('pizza')) return Icons.local_pizza;
    if (productName.contains('burger')) return Icons.lunch_dining;
    if (productName.contains('hamburger')) return Icons.lunch_dining;
    if (productName.contains('hot dog')) return Icons.fastfood;
    if (productName.contains('sandwich')) return Icons.lunch_dining;
    if (productName.contains('taco')) return Icons.fastfood;
    if (productName.contains('burrito')) return Icons.fastfood;
    if (productName.contains('fries')) return Icons.fastfood;

    // Cooking Essentials
    if (productName.contains('sugar')) return Icons.square;
    if (productName.contains('salt')) return Icons.grain;
    if (productName.contains('flour')) return Icons.square_rounded;
    if (productName.contains('oil')) return Icons.opacity;
    if (productName.contains('spice')) return Icons.eco;
    if (productName.contains('herb')) return Icons.local_florist;
    if (productName.contains('baking')) return Icons.bakery_dining;

    // Fall back to category-based icons
    switch (product.category.toLowerCase()) {
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

  Color _getCategoryColor() {
    switch (product.category.toLowerCase()) {
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
      case 'frozen':
        return Colors.lightBlue;
      case 'canned':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
