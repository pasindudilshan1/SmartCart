// Product Detail Screen - View and edit product details

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../providers/inventory_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isEditing = false;
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _weightController;
  String _selectedCategory = '';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _quantityController = TextEditingController(text: widget.product.quantity.toString());
    _weightController = TextEditingController(text: (widget.product.actualWeight ?? 0).toString());
    _selectedCategory = widget.product.category;
    _selectedDate = widget.product.expiryDate ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product.name),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: _isEditing ? _saveChanges : _toggleEditMode,
          ),
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
                  if (widget.product.nutritionInfo != null) ...[
                    _buildNutritionSection(context),
                    const SizedBox(height: 24),
                  ],
                  if (widget.product.storageTips != null) _buildStorageTipsSection(context),
                  const SizedBox(height: 24),
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

    if (widget.product.isExpired) {
      bannerColor = Colors.red;
      bannerIcon = Icons.dangerous;
      bannerText = 'Expired ${widget.product.daysUntilExpiry.abs()} days ago';
    } else if (widget.product.isExpiringSoon) {
      bannerColor = Colors.orange;
      bannerIcon = Icons.warning_amber;
      bannerText = 'Expires in ${widget.product.daysUntilExpiry} days';
    } else {
      bannerColor = Colors.green;
      bannerIcon = Icons.check_circle;
      bannerText = '${widget.product.daysUntilExpiry} days until expiry';
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
            if (_isEditing) ...[
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  'Fruits & Vegetables',
                  'Dairy',
                  'Meat & Poultry',
                  'Seafood',
                  'Grains & Bread',
                  'Bakery',
                  'Pantry Staples',
                  'Snacks',
                  'Beverages',
                  'Frozen Foods',
                  'Spreads',
                  'Other',
                ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              // Show Purchase Quantity field for loose items, Actual Weight for others
              if (_isLooseItem())
                TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(labelText: 'Purchase Quantity'),
                  keyboardType: TextInputType.number,
                )
              else
                TextField(
                  controller: _weightController,
                  decoration: const InputDecoration(
                    labelText: 'Actual Weight (g)',
                    suffixText: 'g',
                  ),
                  keyboardType: TextInputType.number,
                ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Expiry Date'),
                subtitle: Text(_selectedDate.toString().split(' ')[0]),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
            ] else ...[
              _buildInfoRow('Name', widget.product.name),
              _buildInfoRow('Category', widget.product.category),
              // Show Purchase Quantity for loose items, regular Quantity for others
              if (_isLooseItem())
                _buildInfoRow('Purchase Quantity', widget.product.quantity.toString())
              else
                _buildInfoRow('Quantity', widget.product.quantity.toString()),
              if (widget.product.actualWeight != null)
                _buildInfoRow('Actual Weight', '${widget.product.actualWeight}g'),
              _buildInfoRow('Expiry Date', widget.product.expiryDate.toString().split(' ')[0]),
              if (widget.product.purchaseDate != null)
                _buildInfoRow(
                    'Purchase Date', widget.product.purchaseDate.toString().split(' ')[0]),
              _buildInfoRow('Storage', widget.product.storageLocation ?? 'Pantry'),
            ],
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
    final nutrition = widget.product.nutritionInfo!;

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
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildNutrientCard('Calories', nutrition.calories, 'kcal',
                    Icons.local_fire_department, Colors.orange),
                _buildNutrientCard(
                    'Protein', nutrition.protein, 'g', Icons.fitness_center, Colors.red),
                _buildNutrientCard(
                    'Carbs', nutrition.carbs, 'g', Icons.bakery_dining, Colors.amber),
                _buildNutrientCard(
                    'Fat', nutrition.fat, 'g', Icons.opacity, Colors.yellow.shade700),
                _buildNutrientCard('Fiber', nutrition.fiber, 'g', Icons.grass, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientCard(String label, double value, String unit, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.1),
            color.withOpacity(0.05),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              unit,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
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
            Text(widget.product.storageTips!),
          ],
        ),
      ),
    );
  }

  // Helper method to determine if a product is a loose item
  // Loose items are identified by weight-based units (g, kg) or having actualWeight set
  bool _isLooseItem() {
    return widget.product.unit == 'g' ||
        widget.product.unit == 'kg' ||
        (widget.product.actualWeight != null && widget.product.actualWeight! > 0);
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() async {
    // Parse new quantity and weight values
    final newQuantity = double.tryParse(_quantityController.text) ?? widget.product.quantity;
    final newWeight = double.tryParse(_weightController.text) ?? widget.product.actualWeight;

    // Recalculate nutrition if values changed and nutrition info exists
    NutritionInfo? updatedNutrition = widget.product.nutritionInfo;
    if (updatedNutrition != null) {
      if (_isLooseItem() && newQuantity != widget.product.quantity) {
        // For loose items, adjust nutrition based on quantity change
        final ratio = newQuantity / widget.product.quantity;
        updatedNutrition = NutritionInfo(
          calories: widget.product.nutritionInfo!.calories * ratio,
          protein: widget.product.nutritionInfo!.protein * ratio,
          carbs: widget.product.nutritionInfo!.carbs * ratio,
          fat: widget.product.nutritionInfo!.fat * ratio,
          fiber: widget.product.nutritionInfo!.fiber * ratio,
          servingSize: widget.product.nutritionInfo!.servingSize,
        );
      } else if (!_isLooseItem() &&
          newWeight != null &&
          widget.product.actualWeight != null &&
          widget.product.actualWeight! > 0) {
        // For non-loose items, adjust nutrition based on weight change
        final ratio = newWeight / widget.product.actualWeight!;
        updatedNutrition = NutritionInfo(
          calories: widget.product.nutritionInfo!.calories * ratio,
          protein: widget.product.nutritionInfo!.protein * ratio,
          carbs: widget.product.nutritionInfo!.carbs * ratio,
          fat: widget.product.nutritionInfo!.fat * ratio,
          fiber: widget.product.nutritionInfo!.fiber * ratio,
          servingSize: widget.product.nutritionInfo!.servingSize,
        );
      }
    }

    final updatedProduct = Product(
      id: widget.product.id,
      name: _nameController.text,
      barcode: widget.product.barcode,
      category: _selectedCategory,
      brand: widget.product.brand,
      imageUrl: widget.product.imageUrl,
      quantity: newQuantity,
      unit: widget.product.unit,
      purchaseDate: widget.product.purchaseDate,
      expiryDate: _selectedDate,
      nutritionInfo: updatedNutrition,
      storageLocation: widget.product.storageLocation,
      dateAdded: widget.product.dateAdded,
      actualWeight: newWeight,
    );

    await context.read<InventoryProvider>().updateProduct(updatedProduct);

    setState(() {
      _isEditing = false;
    });

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated')),
      );
    }
  }

  void _deleteProduct(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${widget.product.name}?'),
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
      await context.read<InventoryProvider>().deleteProduct(widget.product.id);
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product deleted')),
        );
      }
    }
  }
}
