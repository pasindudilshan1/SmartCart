# Sample QR Code Data

Use these JSON samples to generate QR codes for testing the SmartCart app.

## Sample 1: Dairy Product (Milk)

```json
{
  "name": "Organic Whole Milk",
  "expiryDate": "2025-11-15",
  "quantity": 1,
  "barcode": "1234567890123",
  "category": "Dairy",
  "storageLocation": "fridge",
  "storageTips": "Keep refrigerated at 4°C. Consume within 5 days of opening.",
  "nutrition": {
    "calories": 150,
    "protein": 8,
    "carbs": 12,
    "fat": 8,
    "servingSize": "250ml"
  }
}
```

## Sample 2: Fresh Produce (Banana)

```json
{
  "name": "Organic Bananas",
  "expiryDate": "2025-11-10",
  "quantity": 6,
  "category": "Fruits",
  "storageLocation": "pantry",
  "storageTips": "Store at room temperature. Refrigerate when ripe to slow ripening.",
  "nutrition": {
    "calories": 105,
    "protein": 1.3,
    "carbs": 27,
    "fat": 0.4,
    "fiber": 3.1,
    "sugar": 14,
    "servingSize": "1 medium banana"
  }
}
```

## Sample 3: Frozen Food (Pizza)

```json
{
  "name": "Margherita Pizza",
  "expiryDate": "2026-03-01",
  "quantity": 2,
  "barcode": "9876543210987",
  "category": "Frozen Foods",
  "storageLocation": "freezer",
  "storageTips": "Keep frozen at -18°C. Do not refreeze once thawed.",
  "nutrition": {
    "calories": 280,
    "protein": 12,
    "carbs": 35,
    "fat": 10,
    "sodium": 650,
    "servingSize": "1/2 pizza"
  }
}
```

## Sample 4: Canned Goods (Tomato Soup)

```json
{
  "name": "Tomato Soup",
  "expiryDate": "2026-12-31",
  "quantity": 3,
  "barcode": "5551234567890",
  "category": "Canned Goods",
  "storageLocation": "pantry",
  "storageTips": "Store in a cool, dry place. Once opened, transfer to airtight container and refrigerate.",
  "nutrition": {
    "calories": 90,
    "protein": 2,
    "carbs": 20,
    "fat": 0,
    "sodium": 480,
    "servingSize": "1 cup"
  }
}
```

## Sample 5: Snacks (Chips)

```json
{
  "name": "Potato Chips - Sea Salt",
  "expiryDate": "2025-12-15",
  "quantity": 1,
  "category": "Snacks",
  "storageLocation": "pantry",
  "storageTips": "Store in a cool, dry place. Close bag tightly after opening to maintain freshness.",
  "nutrition": {
    "calories": 160,
    "protein": 2,
    "carbs": 15,
    "fat": 10,
    "fiber": 1,
    "sodium": 170,
    "servingSize": "28g (about 15 chips)"
  }
}
```

## Sample 6: Beverages (Orange Juice)

```json
{
  "name": "Fresh Orange Juice",
  "expiryDate": "2025-11-08",
  "quantity": 1,
  "category": "Beverages",
  "storageLocation": "fridge",
  "storageTips": "Keep refrigerated. Shake well before serving. Best consumed within 7 days of opening.",
  "nutrition": {
    "calories": 110,
    "protein": 2,
    "carbs": 26,
    "fat": 0,
    "sugar": 21,
    "servingSize": "240ml"
  }
}
```

## Sample 7: Meat (Chicken)

```json
{
  "name": "Chicken Breast",
  "expiryDate": "2025-11-07",
  "quantity": 4,
  "category": "Meat",
  "storageLocation": "fridge",
  "storageTips": "Keep refrigerated at 4°C or below. Cook within 2 days or freeze for longer storage.",
  "nutrition": {
    "calories": 165,
    "protein": 31,
    "carbs": 0,
    "fat": 3.6,
    "servingSize": "100g"
  }
}
```

## Sample 8: Low Stock Alert Test

```json
{
  "name": "Eggs (Dozen)",
  "expiryDate": "2025-11-20",
  "quantity": 1,
  "category": "Dairy",
  "storageLocation": "fridge",
  "storageTips": "Store in original carton in the coldest part of the refrigerator.",
  "nutrition": {
    "calories": 70,
    "protein": 6,
    "carbs": 0.6,
    "fat": 5,
    "servingSize": "1 large egg"
  }
}
```

---

## How to Generate QR Codes

1. **Online Generators:**
   - https://www.qr-code-generator.com/
   - https://www.the-qrcode-generator.com/
   - https://qr.io/

2. **Copy a JSON sample above**

3. **Paste into QR generator** (select "Text" or "Free Text" option)

4. **Download or print the QR code**

5. **Scan with SmartCart app!**

---

## Testing Scenarios

### Scenario 1: Normal Product
- Use Milk or Orange Juice (moderate expiry date)
- Expected: Product added successfully

### Scenario 2: Expiring Soon
- Use Chicken Breast (expires in 2 days from today - adjust date)
- Expected: Orange warning indicator

### Scenario 3: Low Stock Alert
- Scan Eggs (quantity = 1)
- Expected: Appears in Shopping List automatically

### Scenario 4: Over-Purchase Warning
- Scan the same product twice
- Expected: Alert shown on second scan

### Scenario 5: Long Shelf Life
- Use Tomato Soup (expires in 1+ year)
- Expected: Green status indicator

---

## Manual Testing Without QR Codes

If you don't have a QR code reader available:

1. Open the app
2. Navigate to Scanner tab
3. Click "Enter Manually" button
4. Fill in product details
5. Test the same features!

---

**Tip:** Save these QR codes and print them out for quick testing during development!
