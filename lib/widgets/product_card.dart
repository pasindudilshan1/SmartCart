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
    Color color;
    IconData icon;

    if (product.isExpired) {
      color = Colors.red;
      icon = Icons.dangerous;
    } else if (product.isExpiringSoon) {
      color = Colors.orange;
      icon = Icons.warning_amber;
    } else {
      color = Colors.green;
      icon = Icons.check_circle;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 28),
    );
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
}
