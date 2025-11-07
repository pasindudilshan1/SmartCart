# Azure Table Storage Configuration

## Setup Instructions

### 1. Create Azure Storage Account

1. Go to [Azure Portal](https://portal.azure.com)
2. Create a new **Storage Account**
3. Choose a unique name (e.g., `smartcartapp`)
4. Select your subscription and resource group
5. Choose location closest to your users
6. Performance: **Standard**
7. Redundancy: **LRS** (Locally Redundant Storage) for cost efficiency

### 2. Get Your Credentials

1. In your Storage Account, go to **Access Keys**
2. Copy:
   - **Storage account name**
   - **Key 1** (primary key)

### 3. Create Tables

Run this in Azure Cloud Shell or use Azure Storage Explorer:

```bash
# Create tables
az storage table create --name Users --account-name YOUR_ACCOUNT_NAME
az storage table create --name Products --account-name YOUR_ACCOUNT_NAME
az storage table create --name Nutrition --account-name YOUR_ACCOUNT_NAME
az storage table create --name ShoppingList --account-name YOUR_ACCOUNT_NAME
az storage table create --name UserSettings --account-name YOUR_ACCOUNT_NAME
```

### 4. Update Your App

Edit `lib/services/azure_table_service.dart`:

```dart
static const String _accountName = 'YOUR_STORAGE_ACCOUNT_NAME'; // Replace this
static const String _accountKey = 'YOUR_STORAGE_ACCOUNT_KEY';   // Replace this
```

### 5. Security (IMPORTANT!)

⚠️ **DO NOT commit credentials to git!**

**Option 1: Use Environment Variables**
```dart
static final String _accountName = const String.fromEnvironment('AZURE_ACCOUNT_NAME');
static final String _accountKey = const String.fromEnvironment('AZURE_ACCOUNT_KEY');
```

**Option 2: Use a config file (add to .gitignore)**
Create `lib/config/azure_config.dart`:
```dart
class AzureConfig {
  static const String accountName = 'your_account_name';
  static const String accountKey = 'your_account_key';
}
```

Add to `.gitignore`:
```
lib/config/azure_config.dart
```

## Data Structure

### Users Table
- **PartitionKey**: 'user'
- **RowKey**: Firebase UID
- Fields: Email, DisplayName, PhotoUrl, Provider, CreatedAt, LastLoginAt

### Products Table
- **PartitionKey**: User ID (Firebase UID)
- **RowKey**: Product ID
- Fields: Name, Barcode, Category, Quantity, Unit, ExpiryDate, etc.

### Nutrition Table
- **PartitionKey**: User ID
- **RowKey**: Date (YYYY-MM-DD)
- Fields: TotalCalories, TotalProtein, TotalCarbs, TotalFat, ConsumedProducts

### ShoppingList Table
- **PartitionKey**: User ID
- **RowKey**: Item ID
- Fields: ProductName, Quantity, Unit, IsPurchased, CreatedAt

### UserSettings Table
- **PartitionKey**: User ID
- **RowKey**: 'settings'
- Fields: CalorieGoal, ProteinGoal, CarbGoal, FatGoal, UpdatedAt

## Cost Estimate

### Azure Table Storage Pricing (Pay-as-you-go)

- **Storage**: ~$0.05 per GB/month
- **Transactions**: $0.00036 per 10,000 transactions

### Example for 1000 active users:
- Storage: ~500 MB = $0.025/month
- Transactions: ~100,000/day = $1.08/month
- **Total: ~$1.10/month**

### Free Tier Alternative:
Use **Azure Cosmos DB Free Tier**:
- 1000 RU/s throughput
- 25 GB storage
- **FREE forever** (limited to one account)

## Benefits of Azure Table Storage

✅ **Cheap**: Very low cost
✅ **Fast**: Low latency
✅ **Scalable**: Handles millions of records
✅ **Reliable**: 99.9% SLA
✅ **Secure**: Enterprise-grade security
✅ **Query by User**: Efficient partitioning by userId

## Next Steps

1. ✅ Azure service created
2. ✅ Firebase Auth integrated
3. ✅ Providers updated to use Azure
4. ⏳ Add your Azure credentials
5. ⏳ Run `flutter pub get`
6. ⏳ Test the app

## Testing

```bash
# Get packages
flutter pub get

# Run the app
flutter run
```

All data will now:
- Store locally in Hive (offline support)
- Sync to Azure Tables when online
- Use Firebase only for authentication
