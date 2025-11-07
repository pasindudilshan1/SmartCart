# 🚀 QUICK START: Create Azure Tables

## ⚡ Fastest Method (1 Minute)

### Windows (PowerShell):
```powershell
.\create_azure_tables.ps1
```

### Windows (Command Prompt):
```cmd
create_azure_tables.bat
```

### Linux/Mac:
```bash
chmod +x create_azure_tables.sh
./create_azure_tables.sh
```

**That's it!** All 5 tables created automatically! ✅

---

## 📋 Tables Created

1. ✅ **Users** - User profiles
2. ✅ **Products** - Inventory items
3. ✅ **Nutrition** - Daily nutrition tracking
4. ✅ **ShoppingList** - Shopping items
5. ✅ **UserSettings** - User preferences

---

## 🔧 Manual Commands (if needed)

### One-by-one:
```bash
az login

az storage table create --name Users --account-name documentstoragepasindu
az storage table create --name Products --account-name documentstoragepasindu
az storage table create --name Nutrition --account-name documentstoragepasindu
az storage table create --name ShoppingList --account-name documentstoragepasindu
az storage table create --name UserSettings --account-name documentstoragepasindu
```

### All at once (PowerShell):
```powershell
az login
$ACCOUNT_NAME="documentstoragepasindu"
@("Users","Products","Nutrition","ShoppingList","UserSettings") | ForEach-Object {
    az storage table create --name $_ --account-name $ACCOUNT_NAME
}
```

### All at once (Bash):
```bash
az login
ACCOUNT_NAME="documentstoragepasindu"
for table in Users Products Nutrition ShoppingList UserSettings; do
    az storage table create --name $table --account-name $ACCOUNT_NAME
done
```

---

## ✅ Verify Tables

```bash
az storage table list --account-name documentstoragepasindu --output table
```

Expected output:
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

## 📖 Full Documentation

For detailed information about table schemas and properties:
- See `docs/AZURE_TABLE_CREATION.md`

---

**Now you can run your app!** 🎉
```bash
flutter run
```
