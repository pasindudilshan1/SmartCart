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
  String _selectedCategory = '';
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _quantityController = TextEditingController(text: widget.product.quantity.toString());
    _selectedCategory = widget.product.category;
    _selectedDate = widget.product.expiryDate ?? DateTime.now().add(const Duration(days: 7));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
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
                  if (!_isEditing) _buildQuantityControls(context),
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
                  'Pantry Staples',
                  'Snacks',
                  'Beverages',
                  'Frozen Foods',
                  'Other',
                ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedCategory = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
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
              _buildInfoRow('Quantity', widget.product.quantity.toString()),
              if (widget.product.actualWeight != null)
                _buildInfoRow('Actual Weight', '${widget.product.actualWeight}g'),
              _buildInfoRow('Expiry Date', widget.product.expiryDate.toString().split(' ')[0]),
              if (widget.product.purchaseDate != null)
                _buildInfoRow(
                    'Purchase Date', widget.product.purchaseDate.toString().split(' ')[0]),
              _buildInfoRow('Storage', widget.product.storageLocation ?? 'Pantry'),
              if (widget.product.barcode != null && widget.product.barcode!.isNotEmpty)
                _buildInfoRow('Barcode', widget.product.barcode!),
              _buildInfoRow('Added On', widget.product.dateAdded.toString().split(' ')[0]),
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
                  widget.product.quantity.toString(),
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
    final newQuantity = widget.product.quantity + change;
    if (newQuantity < 0) return;

    // Recalculate nutrition if product has nutrition info and actual weight
    NutritionInfo? updatedNutritionInfo = widget.product.nutritionInfo;
    if (widget.product.nutritionInfo != null &&
        widget.product.actualWeight != null &&
        widget.product.actualWeight! > 0) {
      final actualWeight = widget.product.actualWeight!;
      final currentQuantity = widget.product.quantity;
      final weightFactor = actualWeight / 100.0;

      // Calculate per-100g values from current total nutrition
      final per100gCalories =
          widget.product.nutritionInfo!.calories / (weightFactor * currentQuantity);
      final per100gProtein =
          widget.product.nutritionInfo!.protein / (weightFactor * currentQuantity);
      final per100gFat = widget.product.nutritionInfo!.fat / (weightFactor * currentQuantity);
      final per100gCarbs = widget.product.nutritionInfo!.carbs / (weightFactor * currentQuantity);
      final per100gFiber = widget.product.nutritionInfo!.fiber / (weightFactor * currentQuantity);

      // Calculate new total nutrition for new quantity
      final newTotalFactor = weightFactor * newQuantity;
      updatedNutritionInfo = NutritionInfo(
        calories: per100gCalories * newTotalFactor,
        protein: per100gProtein * newTotalFactor,
        fat: per100gFat * newTotalFactor,
        carbs: per100gCarbs * newTotalFactor,
        fiber: per100gFiber * newTotalFactor,
        servingSize: widget.product.nutritionInfo!.servingSize,
      );
    }

    // Create updated product with new quantity and recalculated nutrition
    final updatedProduct = Product(
      id: widget.product.id,
      name: widget.product.name,
      barcode: widget.product.barcode,
      category: widget.product.category,
      brand: widget.product.brand,
      imageUrl: widget.product.imageUrl,
      quantity: newQuantity,
      unit: widget.product.unit,
      actualWeight: widget.product.actualWeight,
      purchaseDate: widget.product.purchaseDate,
      expiryDate: widget.product.expiryDate,
      nutritionInfo: updatedNutritionInfo,
      storageLocation: widget.product.storageLocation,
      dateAdded: widget.product.dateAdded,
      storageTips: widget.product.storageTips,
    );

    await context.read<InventoryProvider>().updateProduct(updatedProduct);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity updated')),
      );
    }
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  void _saveChanges() async {
    final updatedProduct = Product(
      id: widget.product.id,
      name: _nameController.text,
      barcode: widget.product.barcode,
      category: _selectedCategory,
      brand: widget.product.brand,
      imageUrl: widget.product.imageUrl,
      quantity: double.tryParse(_quantityController.text) ?? widget.product.quantity,
      unit: widget.product.unit,
      purchaseDate: widget.product.purchaseDate,
      expiryDate: _selectedDate,
      nutritionInfo: widget.product.nutritionInfo,
      storageLocation: widget.product.storageLocation,
      dateAdded: widget.product.dateAdded,
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
