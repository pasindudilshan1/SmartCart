# Shopping List Feature - Implementation Guide

## Overview
The Shopping List screen now has **two tabs**: **Manual** and **Scan**.

## Manual Tab Features

### 1. View All Products
- Displays all products from the Azure `ShoppingList` table
- Shows product details: name, brand, category, price, quantity
- Color-coded by category for easy identification
- **Search Bar**: Click the search icon to search products by name, brand, category, or barcode
  - Adaptive text color (works in light and dark themes)
  - Real-time filtering as you type
  - Clear hint text: "Search by name, brand, category..."
- Pull-to-refresh to reload products

### 2. Product Details
Click on any product to see:
- **Basic Information**: Category, Barcode, Actual Weight (kg), Price, Storage Location
- **Nutrition Information**: Calories, Protein, Carbs, Fat, Fiber, Sugar, Sodium (per 100g)
- **Notes**: Additional product information

### Nutrition Calculation
- Nutrition values in the ShoppingList table are stored **per 100g**
- When purchasing, the app automatically calculates total nutrition based on actual weight
- Formula: `Total Nutrition = (Per 100g Value) × (Actual Weight in kg) × 10`
- Example: 2L milk (2kg) with 64 kcal/100g = 64 × 2 × 10 = 1280 kcal total

### 3. Purchase & Add to Inventory
When viewing product details:
1. Enter the quantity you purchased
2. Click "Add to Inventory"
3. Product is automatically:
   - Saved to the Products table with your user ID
   - Added to your local inventory
   - Visible in the Inventory screen

## Data Flow

```
ShoppingList Table (No User ID)
         ↓
  User selects product
         ↓
  Enters purchase quantity
         ↓
Products Table (With User ID) → Inventory Screen
```

## Running the Mock Data Script

To populate the ShoppingList table with 15 sample products:

```powershell
# Navigate to project directory
cd "e:\new project"

# Run the populate script
.\scripts\populate_shopping_list.ps1 -AccountKey "YOUR_AZURE_STORAGE_KEY"
```

The script includes:
- 15 diverse products across multiple categories
- Complete nutrition information
- Realistic prices and quantities
- Storage locations and notes

## Product Categories

The app includes color-coding for:
- 🔵 **Dairy** - Milk, Yogurt, Cheese, Eggs
- 🔴 **Meat** - Chicken, Beef, Fish
- 🟠 **Fruits** - Bananas, Apples, Oranges
- 🟢 **Vegetables** - Spinach, Tomatoes, Potatoes
- 🟤 **Bakery** - Bread, Pastries
- 🟡 **Grains** - Rice, Oats, Pasta
- 🔵 **Beverages** - Juice, Coffee, Tea
- ⚪ **Other** - Everything else

## Features Implemented

### Shopping List Features
✅ Manual shopping tab with product listing
✅ Fetch all products from ShoppingList table
✅ Product detail view with complete information
✅ Purchase quantity input
✅ Add purchased products to inventory
✅ Link products to user account
✅ Nutrition information display (per 100g)
✅ Category-based color coding
✅ Refresh functionality
✅ **Search functionality** - Search by product name, brand, category, or barcode
✅ Real-time search filtering with visible text (light/dark theme support)
✅ Trim whitespace in search queries for better results

### Inventory Features
✅ **Category-based grouping** - Products organized by category
✅ **Expandable category sections** - Click to expand/collapse
✅ **Smart sorting within categories**:
  - Primary: By expiry date (closest expiry first)
  - Secondary: By purchase date (newest first)
✅ **Visual indicators**:
  - Red: Expired products
  - Orange: Expiring soon (within 3 days)
  - Green: Fresh products
✅ **Category item count** - Shows number of products per category
✅ **Quick actions** - Info and delete buttons for each product
✅ Click product to view detailed information
✅ Search functionality across all products

## Coming Soon

🔜 Scan tab for barcode scanning
🔜 Search and filter products
🔜 Mark items as purchased
🔜 Remove items from shopping list
🔜 Add custom items to shopping list

## Testing

1. Run the populate script to add sample data
2. Open the app and navigate to Shopping List
3. Click on Manual tab
4. Select any product to view details
5. Enter quantity and click "Add to Inventory"
6. Navigate to Inventory screen to see the added product

## Nutrition Calculation Examples

### Example 1: Milk (Liquid - Liters)
- Product: Fresh Milk 2L
- Actual Weight: 2.0 kg
- Nutrition (per 100g): 64 kcal
- **Purchased**: 2 liters (user enters quantity: 2)
- **Calculation**: 
  - Actual weight per unit: 2.0 kg / 2 L = 1.0 kg per L
  - Total weight: 1.0 kg × 2 = 2.0 kg
  - Total calories: 64 × 2.0 × 10 = **1280 kcal**

### Example 2: Cheese (Grams)
- Product: Cheddar Cheese 500g
- Actual Weight: 0.5 kg
- Nutrition (per 100g): 403 kcal
- **Purchased**: 1 pack (user enters quantity: 1)
- **Calculation**:
  - Total weight: 0.5 kg × 1 = 0.5 kg
  - Total calories: 403 × 0.5 × 10 = **2015 kcal**

### Example 3: Bananas (Pieces)
- Product: Bananas (6 pcs suggested)
- Actual Weight: 0.9 kg (for 6 bananas)
- Nutrition (per 100g): 89 kcal
- **Purchased**: 12 bananas (user enters quantity: 12)
- **Calculation**:
  - Weight per banana: 0.9 kg / 6 = 0.15 kg
  - Total weight: 0.15 kg × 12 = 1.8 kg
  - Total calories: 89 × 1.8 × 10 = **1602 kcal**

## Notes

- The ShoppingList table is shared across all users
- Each user's purchased products are stored separately in the Products table
- Products maintain all nutrition and detail information when added to inventory
- The app automatically generates unique product IDs with timestamps
- **Nutrition values are always stored per 100g in the database**
- Actual weight is calculated proportionally based on quantity purchased
- Serving size in inventory shows total weight of purchased product
