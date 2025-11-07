# SmartCart - Secure Setup Instructions

## 🔒 Setting Up Secure Azure Credentials

Your Azure credentials are now stored securely and **NOT** hardcoded in the app!

### Current Setup:
- **Resource Group**: documentstoragepasindu
- **Storage Account**: documentstoragepasindu
- **Config File**: `lib/config/azure_config.dart` (in .gitignore)

---

## 🚀 First-Time Setup

### Step 1: Store Your Azure Key Securely

#### On Windows (PowerShell):
```powershell
# Create secure directory
New-Item -ItemType Directory -Force -Path $env:USERPROFILE\.smartcart

# Store your Azure key (replace with your actual key)
Set-Content -Path $env:USERPROFILE\.smartcart\azure_key.txt -Value "YOUR_ACTUAL_AZURE_ACCESS_KEY_HERE"
```

#### On macOS/Linux (Bash):
```bash
# Create secure directory
mkdir -p ~/.smartcart

# Store your Azure key (replace with your actual key)
echo "YOUR_ACTUAL_AZURE_ACCESS_KEY_HERE" > ~/.smartcart/azure_key.txt

# Secure the file (only you can read it)
chmod 600 ~/.smartcart/azure_key.txt
```

### Step 2: Add Your Key to Development Config

Edit `lib/config/azure_config.dart`:
```dart
class AzureConfig {
  static const String accountName = 'documentstoragepasindu';
  static const String accountKey = 'PASTE_YOUR_ACTUAL_KEY_HERE'; // ← Add your key
  
  // ... rest of config
}
```

**Note:** This file is in `.gitignore` and won't be committed to git!

---

## 🏗️ Building for Development

```bash
# Regular development run
flutter run
```

The app will use credentials from `lib/config/azure_config.dart`

---

## 📦 Building for Google Play Store

### Option 1: Using PowerShell (Windows)

```powershell
.\build_playstore.ps1
```

### Option 2: Using Bash (macOS/Linux)

```bash
chmod +x build_playstore.sh
./build_playstore.sh
```

### Option 3: Manual Build

```bash
flutter build appbundle --release \
  --dart-define=AZURE_ACCOUNT_NAME=documentstoragepasindu \
  --dart-define=AZURE_ACCOUNT_KEY=your_key_from_secure_file
```

---

## 📝 Where to Get Your Azure Access Key

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to your Storage Account: **documentstoragepasindu**
3. Click **"Access keys"** in the left menu
4. Copy **key1** value (the long string)
5. Paste it in:
   - `~/.smartcart/azure_key.txt` (for builds)
   - `lib/config/azure_config.dart` (for development)

---

## ✅ Security Checklist

- [x] Credentials stored in `.gitignore` file
- [x] Template file provided for team members
- [x] Build scripts use environment variables
- [x] No hardcoded keys in source code
- [x] Secure storage location (~/.smartcart)

---

## 🔄 For Team Members

If someone else needs to work on the project:

1. They clone the repository (no credentials included ✅)
2. They copy the template:
   ```bash
   cp lib/config/azure_config.dart.template lib/config/azure_config.dart
   ```
3. You share the Azure key with them **securely** (not in git!)
4. They add the key to their local `azure_config.dart`
5. They can now run the app!

---

## 🚨 If Key Is Leaked

1. **Immediately** go to Azure Portal
2. Go to Storage Account → Access keys
3. Click "Regenerate" on the compromised key
4. Update your local files with the new key:
   - `~/.smartcart/azure_key.txt`
   - `lib/config/azure_config.dart`
5. Rebuild the app

---

## 📱 Publishing to Play Store

1. Run the build script:
   ```powershell
   .\build_playstore.ps1
   ```

2. Find the AAB file:
   ```
   build\app\outputs\bundle\release\app-release.aab
   ```

3. Upload to [Google Play Console](https://play.google.com/console)

4. Your credentials are **NOT** in the published app source code! ✅

---

## 💡 Additional Security (Optional)

### Use Azure SAS Tokens

Instead of account keys, you can use Shared Access Signatures:

1. Generate SAS token in Azure Portal
2. Use time-limited tokens
3. Rotate regularly
4. Easier to revoke if needed

See `docs/SECURE_CREDENTIALS.md` for details.

---

## 🎯 Quick Reference

| Purpose | File | Committed to Git? |
|---------|------|-------------------|
| Development | `lib/config/azure_config.dart` | ❌ No (.gitignore) |
| Template | `lib/config/azure_config.dart.template` | ✅ Yes |
| Production Key | `~/.smartcart/azure_key.txt` | ❌ Never |
| Build Script | `build_playstore.ps1` | ✅ Yes |

---

Your credentials are now secure! 🔒
