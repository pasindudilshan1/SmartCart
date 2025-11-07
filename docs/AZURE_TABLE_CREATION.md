# Azure Tables Creation Guide

## 📋 Overview

Azure Tables don't have traditional "columns" like SQL databases. Instead, they use:
- **PartitionKey** (required) - Groups related data
- **RowKey** (required) - Unique identifier within partition
- **Properties** - Your custom fields (added when inserting data)

---

## 🛠️ Method 1: Azure Portal (Easiest)

### Step 1: Go to Azure Portal
1. Open [https://portal.azure.com](https://portal.azure.com)
2. Navigate to your storage account: **documentstoragepasindu**

### Step 2: Create Tables
1. In left menu, click **"Storage Browser"**
2. Expand **"Tables"**
3. Click **"+ Add table"** button
4. Enter table name and click **"OK"**

**Create these 5 tables:**
- `Users`
- `Products`
- `Nutrition`
- `ShoppingList`
- `UserSettings`

That's it! Tables are created. Properties are added automatically when you insert data.

---

## 🖥️ Method 2: Azure CLI Commands

### Install Azure CLI (if not installed):
**Windows:**
```powershell
winget install Microsoft.AzureCLI
```

**macOS:**
```bash
brew install azure-cli
```

**Linux:**
```bash
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
```

### Login to Azure:
```bash
az login
```

### Create Tables:

```bash
# Set your storage account name
$ACCOUNT_NAME="documentstoragepasindu"

# Create Users table
az storage table create --name Users --account-name $ACCOUNT_NAME

# Create Products table
az storage table create --name Products --account-name $ACCOUNT_NAME

# Create Nutrition table
az storage table create --name Nutrition --account-name $ACCOUNT_NAME

# Create ShoppingList table
az storage table create --name ShoppingList --account-name $ACCOUNT_NAME

# Create UserSettings table
az storage table create --name UserSettings --account-name $ACCOUNT_NAME
```

### All at once (copy-paste):
```bash
# Windows PowerShell
$ACCOUNT_NAME="documentstoragepasindu"
@("Users", "Products", "Nutrition", "ShoppingList", "UserSettings") | ForEach-Object {
    az storage table create --name $_ --account-name $ACCOUNT_NAME
}
```

```bash
# Linux/Mac Bash
ACCOUNT_NAME="documentstoragepasindu"
for table in Users Products Nutrition ShoppingList UserSettings; do
    az storage table create --name $table --account-name $ACCOUNT_NAME
done
```

---

## 🔧 Method 3: Azure Storage Explorer (GUI Tool)

### Step 1: Download & Install
- Download from: [https://azure.microsoft.com/features/storage-explorer/](https://azure.microsoft.com/features/storage-explorer/)

### Step 2: Connect to Your Account
1. Open Azure Storage Explorer
2. Sign in with your Azure account
3. Navigate to **documentstoragepasindu**

### Step 3: Create Tables
1. Right-click on **"Tables"**
2. Select **"Create Table"**
3. Enter table name
4. Repeat for all 5 tables

---

## 📊 Table Schemas (Properties)

### 1. Users Table
```
PartitionKey: 'user'
RowKey: Firebase UID (e.g., "abc123xyz...")

Properties:
├─ Email: string
├─ DisplayName: string
├─ PhotoUrl: string (optional)
├─ Provider: string ('email' or 'google')
├─ CreatedAt: datetime
└─ LastLoginAt: datetime
```

**Example Entity:**
```json
{
  "PartitionKey": "user",
  "RowKey": "firebase_uid_abc123",
  "Email": "user@example.com",
  "DisplayName": "John Doe",
  "PhotoUrl": "https://...",
  "Provider": "email",
  "CreatedAt": "2025-11-06T10:00:00Z",
  "LastLoginAt": "2025-11-06T10:00:00Z"
}
```

---

### 2. Products Table
```
PartitionKey: User ID (Firebase UID)
RowKey: Product ID (UUID)

Properties:
├─ Name: string
├─ Barcode: string
├─ Category: string
├─ Quantity: double
├─ Unit: string
├─ ExpiryDate: datetime
├─ PurchaseDate: datetime
├─ Brand: string
├─ Price: double
├─ ImageUrl: string
├─ StorageLocation: string
└─ DateAdded: datetime
```

**Example Entity:**
```json
{
  "PartitionKey": "firebase_uid_abc123",
  "RowKey": "product_uuid_xyz789",
  "Name": "Milk",
  "Barcode": "123456789",
  "Category": "Dairy",
  "Quantity": 1.0,
  "Unit": "L",
  "ExpiryDate": "2025-11-15T00:00:00Z",
  "PurchaseDate": "2025-11-01T00:00:00Z",
  "Brand": "Fresh Farms",
  "Price": 3.99,
  "ImageUrl": "https://...",
  "StorageLocation": "Refrigerator",
  "DateAdded": "2025-11-01T10:00:00Z"
}
```

---

### 3. Nutrition Table
```
PartitionKey: User ID (Firebase UID)
RowKey: Date (YYYY-MM-DD)

Properties:
├─ Date: datetime
├─ TotalCalories: double
├─ TotalProtein: double
├─ TotalCarbs: double
├─ TotalFat: double
└─ ConsumedProducts: string (JSON array of product IDs)
```

**Example Entity:**
```json
{
  "PartitionKey": "firebase_uid_abc123",
  "RowKey": "2025-11-06",
  "Date": "2025-11-06T00:00:00Z",
  "TotalCalories": 1850.5,
  "TotalProtein": 75.2,
  "TotalCarbs": 220.8,
  "TotalFat": 65.3,
  "ConsumedProducts": "[\"product1\", \"product2\"]"
}
```

---

### 4. ShoppingList Table
```
PartitionKey: User ID (Firebase UID)
RowKey: Item ID (UUID)

Properties:
├─ ProductName: string
├─ Quantity: double
├─ Unit: string
├─ IsPurchased: boolean
└─ CreatedAt: datetime
```

**Example Entity:**
```json
{
  "PartitionKey": "firebase_uid_abc123",
  "RowKey": "item_uuid_123",
  "ProductName": "Eggs",
  "Quantity": 12.0,
  "Unit": "pcs",
  "IsPurchased": false,
  "CreatedAt": "2025-11-06T10:00:00Z"
}
```

---

### 5. UserSettings Table
```
PartitionKey: User ID (Firebase UID)
RowKey: 'settings'

Properties:
├─ CalorieGoal: double
├─ ProteinGoal: double
├─ CarbGoal: double
├─ FatGoal: double
└─ UpdatedAt: datetime
```

**Example Entity:**
```json
{
  "PartitionKey": "firebase_uid_abc123",
  "RowKey": "settings",
  "CalorieGoal": 2500.0,
  "ProteinGoal": 150.0,
  "CarbGoal": 300.0,
  "FatGoal": 70.0,
  "UpdatedAt": "2025-11-06T10:00:00Z"
}
```

---

## ✅ Verification

### Check tables were created:

**Azure CLI:**
```bash
az storage table list --account-name documentstoragepasindu --output table
```

**Expected output:**
```
Name            
--------------
Nutrition      
Products       
ShoppingList   
UserSettings   
Users
```

---

## 🧪 Test Insert (Optional)

After creating tables, test inserting data:

**Using Azure CLI:**
```bash
az storage entity insert \
  --table-name Users \
  --account-name documentstoragepasindu \
  --entity PartitionKey=user RowKey=test123 Email=test@example.com
```

**Delete test data:**
```bash
az storage entity delete \
  --table-name Users \
  --account-name documentstoragepasindu \
  --partition-key user \
  --row-key test123
```

---

## 📝 Important Notes

### About Azure Table Properties:

1. **No Schema Required**: Properties are added dynamically when you insert data
2. **Flexible**: Each entity can have different properties
3. **Required Keys**: Only PartitionKey and RowKey are mandatory
4. **Data Types**: string, int32, int64, double, boolean, datetime, guid, binary

### Partition Key Strategy:

- **Users**: `'user'` (all users in same partition - small table)
- **Products**: `User ID` (each user's data separate)
- **Nutrition**: `User ID` (each user's data separate)
- **ShoppingList**: `User ID` (each user's data separate)
- **UserSettings**: `User ID` (each user's data separate)

This ensures:
✅ Efficient queries per user
✅ Data isolation
✅ Scalability

---

## 🚀 Quick Start Commands

**Copy and run this (PowerShell):**
```powershell
# Login to Azure
az login

# Create all tables
$ACCOUNT_NAME = "documentstoragepasindu"
@("Users", "Products", "Nutrition", "ShoppingList", "UserSettings") | ForEach-Object {
    Write-Host "Creating table: $_" -ForegroundColor Green
    az storage table create --name $_ --account-name $ACCOUNT_NAME
}

Write-Host "`n✅ All tables created successfully!" -ForegroundColor Green

# Verify
Write-Host "`n📋 Verifying tables..." -ForegroundColor Cyan
az storage table list --account-name $ACCOUNT_NAME --output table
```

**Or (Linux/Mac):**
```bash
# Login to Azure
az login

# Create all tables
ACCOUNT_NAME="documentstoragepasindu"
for table in Users Products Nutrition ShoppingList UserSettings; do
    echo "Creating table: $table"
    az storage table create --name $table --account-name $ACCOUNT_NAME
done

echo -e "\n✅ All tables created successfully!"

# Verify
echo -e "\n📋 Verifying tables..."
az storage table list --account-name $ACCOUNT_NAME --output table
```

---

## 🎯 What Happens When Your App Runs?

1. **User signs up** → App creates entity in `Users` table
2. **User adds product** → App creates entity in `Products` table with your UserID as PartitionKey
3. **User tracks nutrition** → App creates/updates entity in `Nutrition` table
4. **All automatic!** → Your Flutter app handles the data insertion

**You just need to create the empty tables.** ✅

---

## 📞 Troubleshooting

### Error: "Storage account not found"
```bash
# List your accounts
az storage account list --output table
```

### Error: "Authentication failed"
```bash
# Re-login
az logout
az login
```

### Error: "Table already exists"
That's fine! Table is already created. ✅

---

## ✨ Summary

1. **Easiest**: Use Azure Portal (click, click, done!)
2. **Fastest**: Use Azure CLI commands (copy-paste script above)
3. **Best for teams**: Use Azure Storage Explorer (GUI tool)

**All tables ready in under 2 minutes!** 🚀
