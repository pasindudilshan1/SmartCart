# 🔒 Secure Azure Configuration for Play Store

## ⚠️ IMPORTANT: Never Hardcode Credentials!

You're right to be concerned about hardcoding credentials. Here's the secure way to handle Azure credentials for production apps.

---

## 🎯 Current Setup (Secure)

### 1. **Configuration File** (`lib/config/azure_config.dart`)
- ✅ Contains your Azure credentials
- ✅ **Added to `.gitignore`** (won't be committed to GitHub)
- ✅ Only exists on your development machine
- ✅ Template provided for team members

### 2. **What's Protected:**
```dart
// lib/config/azure_config.dart (NOT committed to git)
class AzureConfig {
  static const String accountName = 'documentstoragepasindu';
  static const String accountKey = 'YOUR_ACTUAL_KEY_HERE';
}
```

---

## 🚀 For Play Store Publishing

### **Option 1: Flutter Environment Variables (RECOMMENDED)**

#### Step 1: Remove hardcoded config
Don't use `azure_config.dart` in production. Instead:

**Create:** `lib/config/azure_config_prod.dart`
```dart
class AzureConfig {
  static const String accountName = String.fromEnvironment(
    'AZURE_ACCOUNT_NAME',
    defaultValue: 'documentstoragepasindu',
  );
  
  static const String accountKey = String.fromEnvironment(
    'AZURE_ACCOUNT_KEY',
    defaultValue: '', // Empty in code
  );
  
  static const String usersTable = 'Users';
  static const String productsTable = 'Products';
  static const String nutritionTable = 'Nutrition';
  static const String shoppingListTable = 'ShoppingList';
  static const String settingsTable = 'UserSettings';
}
```

#### Step 2: Build with environment variables
```bash
# Local development
flutter run --dart-define=AZURE_ACCOUNT_NAME=documentstoragepasindu --dart-define=AZURE_ACCOUNT_KEY=your_key_here

# Production build for Play Store
flutter build appbundle --release \
  --dart-define=AZURE_ACCOUNT_NAME=documentstoragepasindu \
  --dart-define=AZURE_ACCOUNT_KEY=your_actual_key_here
```

#### Step 3: Store in CI/CD secrets
If using GitHub Actions, GitLab CI, or similar:
```yaml
# .github/workflows/build.yml
- name: Build Release AAB
  run: |
    flutter build appbundle --release \
      --dart-define=AZURE_ACCOUNT_NAME=${{ secrets.AZURE_ACCOUNT_NAME }} \
      --dart-define=AZURE_ACCOUNT_KEY=${{ secrets.AZURE_KEY }}
```

---

### **Option 2: Backend Proxy (MOST SECURE)**

Instead of storing Azure keys in the app, use a backend server:

```
Flutter App ──► Your Backend API ──► Azure Tables
           (No Azure keys)    (Has Azure keys)
```

**Benefits:**
- ✅ No credentials in app
- ✅ Can rotate keys without updating app
- ✅ Add rate limiting & validation
- ✅ Additional security layer

**Simple Node.js Example:**
```javascript
// server.js
const express = require('express');
const azure = require('azure-storage');

const app = express();
const tableService = azure.createTableService(
  process.env.AZURE_ACCOUNT_NAME,
  process.env.AZURE_ACCOUNT_KEY
);

app.post('/api/products', async (req, res) => {
  const userId = req.user.id; // From Firebase token
  // Store in Azure Tables
  // Return response
});
```

**Flutter calls backend instead:**
```dart
// Instead of calling Azure directly
final response = await dio.post(
  'https://your-api.com/api/products',
  data: productData,
  headers: {'Authorization': 'Bearer $firebaseToken'},
);
```

---

### **Option 3: Use Azure SAS Tokens (Good for Files)**

For table storage, create **Shared Access Signature** tokens:

```dart
class AzureConfig {
  // No account key needed!
  static const String tableEndpoint = 
    'https://documentstoragepasindu.table.core.windows.net';
  
  // SAS token (time-limited, can be rotated)
  static String getSasToken() {
    // Fetch from your backend API
    return 'sv=2021-06-08&ss=t&srt=sco&sp=rwdlacu&se=...';
  }
}
```

**Advantages:**
- ✅ Token expires (time-limited)
- ✅ Can revoke anytime
- ✅ Limited permissions
- ✅ No master key in app

---

## 📝 Step-by-Step: Secure Your App NOW

### For Current Development:

**1. Update `.gitignore`** ✅ (Already done)
```
lib/config/azure_config.dart
```

**2. Keep template for team:**
```
lib/config/azure_config.dart.template
```

**3. Update README with setup instructions**

---

### For Play Store Release:

#### **Quick Setup (Environment Variables):**

**1. Create build script:**
```bash
# build_release.sh
#!/bin/bash

# Read key from secure location (not in git)
AZURE_KEY=$(cat ~/.azure/smartcart_key.txt)

flutter build appbundle --release \
  --dart-define=AZURE_ACCOUNT_NAME=documentstoragepasindu \
  --dart-define=AZURE_ACCOUNT_KEY=$AZURE_KEY
```

**2. Store key securely:**
```bash
# One-time setup
mkdir -p ~/.azure
echo "YOUR_ACTUAL_AZURE_KEY" > ~/.azure/smartcart_key.txt
chmod 600 ~/.azure/smartcart_key.txt  # Only you can read
```

**3. Build for Play Store:**
```bash
chmod +x build_release.sh
./build_release.sh
```

Your key never appears in code! ✅

---

## 🔐 Security Best Practices

### ✅ DO:
- ✅ Use environment variables for builds
- ✅ Keep credentials in `.gitignore`
- ✅ Use SAS tokens when possible
- ✅ Rotate keys periodically
- ✅ Consider backend proxy for production
- ✅ Enable Azure firewall rules
- ✅ Monitor Azure access logs

### ❌ DON'T:
- ❌ Hardcode keys in source code
- ❌ Commit credentials to git
- ❌ Share keys in team chats
- ❌ Use same keys for dev/prod
- ❌ Store keys in screenshots
- ❌ Paste keys in public issues

---

## 🚨 What If Key Is Compromised?

### Immediate Steps:
1. **Regenerate key in Azure Portal**
   - Go to Storage Account → Access Keys
   - Click "Regenerate" on key1
   
2. **Update your secure storage**
   ```bash
   echo "NEW_KEY_HERE" > ~/.azure/smartcart_key.txt
   ```

3. **Rebuild and redeploy app**
   ```bash
   ./build_release.sh
   ```

4. **Review Azure access logs**
   - Check for suspicious activity

---

## 💡 Recommended Approach for Your App

### **For Play Store Publishing:**

**Use Environment Variables + CI/CD**

**1. Update `lib/config/azure_config.dart`:**
```dart
class AzureConfig {
  static const String accountName = String.fromEnvironment(
    'AZURE_ACCOUNT_NAME',
    defaultValue: 'documentstoragepasindu',
  );
  
  static const String accountKey = String.fromEnvironment(
    'AZURE_ACCOUNT_KEY',
    defaultValue: '', // Required for build
  );
  
  // Rest of config...
}
```

**2. Create `build_playstore.sh`:**
```bash
#!/bin/bash
set -e

echo "🔨 Building SmartCart for Play Store..."

# Load Azure credentials from secure file
AZURE_KEY=$(cat ~/.smartcart/azure_key.txt)

# Build release AAB
flutter build appbundle \
  --release \
  --dart-define=AZURE_ACCOUNT_NAME=documentstoragepasindu \
  --dart-define=AZURE_ACCOUNT_KEY=$AZURE_KEY

echo "✅ Build complete: build/app/outputs/bundle/release/app-release.aab"
```

**3. First-time setup:**
```bash
# Store your Azure key securely
mkdir -p ~/.smartcart
echo "paste_your_actual_azure_key_here" > ~/.smartcart/azure_key.txt
chmod 600 ~/.smartcart/azure_key.txt

# Make build script executable
chmod +x build_playstore.sh
```

**4. Build for Play Store:**
```bash
./build_playstore.sh
```

**Key never appears in your code!** ✅

---

## 📊 Comparison

| Method | Security | Ease | Cost | Recommended |
|--------|----------|------|------|-------------|
| Hardcoded | ❌ Bad | Easy | Free | ❌ Never |
| Config File | ⚠️ Medium | Easy | Free | ⚠️ Dev only |
| Env Variables | ✅ Good | Medium | Free | ✅ Yes |
| Backend Proxy | ✅✅ Best | Hard | $5/mo | ✅✅ Production |
| SAS Tokens | ✅ Good | Medium | Free | ✅ Alternative |

---

## 🎯 Your Current Status

✅ Resource Group: `documentstoragepasindu`
✅ Account Name: `documentstoragepasindu`
✅ Config file created: `lib/config/azure_config.dart`
✅ Added to `.gitignore`
✅ Template provided: `azure_config.dart.template`

### Next Steps:
1. ✅ Add your actual Azure key to `lib/config/azure_config.dart`
2. ⏳ Set up environment variables for production builds
3. ⏳ Create `build_playstore.sh` script
4. ⏳ Test the build process

---

## 📞 Need Help?

If you want to switch to environment variables now, I can:
1. Update the code to use `String.fromEnvironment`
2. Create build scripts for you
3. Set up CI/CD configuration

Let me know! 🚀
