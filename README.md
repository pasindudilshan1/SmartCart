# 🛒 SmartCart – Complete Guide & Documentation

<div align="center">

![SmartCart Logo](https://img.shields.io/badge/SmartCart-Food%20Waste%20Reduction-green?style=for-the-badge&logo=flutter)

**A cross-platform mobile app that helps households minimize food waste through barcode scanning, smart inventory management, and nutritional tracking**

[![Flutter](https://img.shields.io/badge/Flutter-3.0+-blue.svg)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange.svg)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Dart](https://img.shields.io/badge/Dart-3.0+-blue.svg)](https://dart.dev)

**✨ PRODUCTION-READY WITH FULL FIREBASE INTEGRATION & REAL BARCODE SCANNING! ✨**

</div>

---

## 📑 Table of Contents

- [What's New](#-whats-new)
- [Project Overview](#-project-overview)
- [Core Features](#-core-features)
- [Tech Stack](#-tech-stack)
- [Quick Start](#-quick-start)
- [Installation & Setup](#-installation--setup)
- [Running the App](#-running-the-app)
- [Firebase Console Setup](#-firebase-console-setup)
- [User Guide](#-user-guide)
- [Troubleshooting](#-troubleshooting)
- [Project Structure](#-project-structure)
- [Development Guide](#-development-guide)
- [Command Reference](#-command-reference)
- [Contributing](#-contributing)
- [License](#-license)

---

## 🔥 What's New

✅ **Firebase Authentication** - Secure user accounts with email/password and Google Sign-In  
✅ **Cloud Firestore** - Real-time sync across all your devices  
✅ **Real Barcode Scanning** - Scan actual product barcodes with your camera  
✅ **Open Food Facts API** - Automatic product info lookup from 2+ million products  
✅ **Multi-device Sync** - Access your inventory from phone, tablet, anywhere  
✅ **Offline Support** - Works without internet, syncs when back online  
✅ **Dual Database** - Hive for local storage + Firestore for cloud sync

---

## 🌱 Project Overview

**SmartCart** is a cross-platform mobile application built with **Flutter** that helps households reduce food waste by making smarter grocery purchasing decisions. The app integrates **barcode scanning**, **cloud-synced inventory tracking**, and **nutritional awareness** to promote responsible consumption.

### 🎯 Key Goals
- Reduce household food waste at the point of purchase
- Align grocery decisions with nutritional needs
- Promote sustainability through awareness and insights
- Provide real-time, cloud-synced inventory management
- Enable multi-device access to your food inventory

### 🌍 SDG Contribution
This project directly contributes to:
- **SDG 12**: Responsible Consumption and Production
- **SDG 2**: Zero Hunger
- **SDG 13**: Climate Action (reduced food waste = reduced emissions)

---

## 💡 Core Features

| Feature | Status | Description |
|---------|--------|-------------|
| **🔐 User Authentication** | ✅ **LIVE** | Email/password & Google Sign-In |
| **📷 Barcode Scanning** | ✅ **LIVE** | Scan real product barcodes using camera |
| **🌍 Product Database** | ✅ **LIVE** | Access to 2+ million products via Open Food Facts |
| **☁️ Cloud Sync** | ✅ **LIVE** | Real-time inventory sync via Firestore |
| **📦 Smart Inventory** | ✅ **LIVE** | Track products with expiry, quantities, categories |
| **🍎 Nutrition Data** | ✅ **LIVE** | Automatic nutrition info from Open Food Facts |
| **⚠️ Expiry Alerts** | ✅ **LIVE** | Get notified about expiring products |
| **🛒 Shopping List** | ✅ **LIVE** | Cloud-synced shopping list management |
| **📱 Offline Mode** | ✅ **LIVE** | Works offline, syncs when connection returns |
| **🔄 Multi-device** | ✅ **LIVE** | Access from phone, tablet, anywhere |

---

## 🧱 Tech Stack

| Layer | Tools & Frameworks |
|-------|-------------------|
| **Language** | Dart 3.0+ |
| **Framework** | Flutter 3.0+ |
| **Authentication** | Firebase Auth (Email, Google Sign-In) |
| **Cloud Database** | Cloud Firestore |
| **Local Database** | Hive (NoSQL, offline cache) |
| **State Management** | Provider |
| **Barcode API** | Open Food Facts API |
| **Scanner** | mobile_scanner package |
| **API Client** | Dio (HTTP), http |
| **Charts** | fl_chart |
| **UI** | Material Design 3 |
| **IDE** | VS Code / Android Studio |

---

## 🚀 Quick Start

### ⚡ Fastest Way to Run (30 seconds)

**Using PowerShell:**
```powershell
.\setup.ps1 run
```

**Then select:**
- **Option 1**: Windows Desktop (fastest for testing, no QR scanning)
- **Option 2**: Chrome Browser (fast, no QR scanning)
- **Android Device/Emulator** (full features including QR scanning)

### 📋 Prerequisites
- Flutter SDK 3.0+ ([Install Flutter](https://docs.flutter.dev/get-started/install))
- Dart SDK 3.0+
- VS Code or Android Studio
- Git
- For Android: Android SDK, emulator or physical device

---

## 📥 Installation & Setup

### Step 1: Clone Repository
```bash
git clone https://github.com/yourusername/smartcart-flutter.git
cd smartcart-flutter
```

### Step 2: Install Dependencies
```powershell
flutter pub get
```

Or use helper script:
```powershell
.\setup.ps1 get
```

### Step 3: Generate Hive Adapters
```powershell
flutter pub run build_runner build --delete-conflicting-outputs
```

Or use helper script:
```powershell
.\setup.ps1 build
```

**Important:** Without Hive adapters, the app will crash!

### Step 4: Enable Windows Developer Mode (for Windows testing)

1. Press **Windows + I** to open Settings
2. Go to **Privacy & Security** → **For developers**
3. Toggle **Developer Mode** to ON
4. Confirm when prompted

Or run:
```powershell
start ms-settings:developers
```

---

## 📱 Running the App

### Option A: Run on Windows Desktop (Fastest for Testing)

**No camera access, but great for UI testing:**
```powershell
flutter run -d windows
```

**Timeline:** 1-2 minutes first build, then 10-30 seconds

### Option B: Run on Chrome Browser

```powershell
flutter run -d chrome
```

**Timeline:** 30-60 seconds first build

### Option C: Run on Android Emulator (Full Features)

**Start emulator:**
```powershell
flutter emulators --launch Pixel_9_Pro_XL
```

**Wait 30-60 seconds for boot, then:**
```powershell
flutter run
```

### Option D: Run on Physical Android Device

1. Enable Developer Options (Settings → About → Tap Build Number 7 times)
2. Enable USB Debugging (Settings → Developer Options)
3. Connect phone via USB
4. Run:
```powershell
flutter run
```

### Using VS Code

1. Open project in VS Code
2. Press `F5` to run
3. Or click **Run > Start Debugging**
4. Select device from bottom-right corner

---

## 🔥 Firebase Console Setup

**⚠️ Required for full functionality!**

### 1. Enable Authentication Methods

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project
3. Navigate to **Authentication** > **Sign-in method**

**Enable Email/Password:**
- Click "Email/Password"
- Toggle "Enable"
- Click "Save"

**Enable Google Sign-In:**
- Click "Google"
- Toggle "Enable"
- Select support email
- Click "Save"

### 2. Add Android SHA-1 Key (for Google Sign-In)

**Get SHA-1:**
```bash
cd android
./gradlew signingReport
```

**Add to Firebase:**
1. Project Settings → Your apps → Android app
2. Click "Add fingerprint"
3. Paste SHA-1 key
4. Download updated `google-services.json`
5. Replace file in `android/app/google-services.json`

### 3. Create Firestore Database

1. Navigate to **Firestore Database**
2. Click "Create database"
3. Choose **Start in production mode**
4. Select location (closest to users)
5. Click "Enable"

### 4. Apply Security Rules

Go to **Firestore Database** > **Rules** tab and paste:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User-specific data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Click **Publish**

### 5. (Optional) Enable Firebase Storage

For product images:
1. Navigate to **Storage**
2. Click "Get started"
3. Use production mode rules
4. Click "Done"

---

## 📖 User Guide

### 🎯 First Launch

1. **Onboarding**: Introduction screens (first time only)
2. **Login/Register**: Create account or sign in
3. **Home Screen**: Main app with bottom navigation

### 🔐 Creating an Account

**Two options:**
- **Email/Password**: Enter details and create account
- **Google Sign-In**: One-tap sign in with Google

### 📷 Scanning Products

1. Tap **Scan** button on home screen
2. Point camera at product barcode
3. App automatically looks up product from Open Food Facts
4. Review product details (name, brand, image, nutrition)
5. Set quantity and expiry date
6. Tap **Add to Inventory**

**Supported Barcodes:**
- EAN-13 (most common)
- EAN-8
- UPC-A
- UPC-E
- Code 128

**Test Barcodes:**
- Coca-Cola: `5449000000996`
- Nutella: `3017620422003`
- Snickers: `5000159461122`

### 📦 Managing Inventory

**View Products:**
- **All Products**: Everything in inventory
- **Expiring Soon**: Products expiring in 3 days (yellow alert)
- **Expired**: Past expiry date (red alert)
- **Low Stock**: 2 or fewer items

**Update Product:**
1. Tap product card
2. View full details
3. Update quantity or expiry
4. Changes sync automatically

**Delete Product:**
- Swipe product card to delete
- Or tap product → Delete button

### 🛒 Shopping List

**Add Items:**
1. Navigate to Shopping List screen
2. Tap **+** button
3. Enter item name and quantity
4. Tap **Add**

**Check Off Items:**
- Tap checkbox when purchased
- Swipe to delete

**Auto-Suggestions:**
- Low stock items appear automatically
- Products with quantity ≤ 2

### 📊 Nutrition Tracking

**View Nutrition Data:**
- Calories per 100g
- Protein, Fat, Carbs
- Fiber, Sugar, Sodium
- Nutri-Score (A-E rating)
- Nova Group (processing level)

### 🔄 Cloud Synchronization

**Features:**
- ✅ Automatic real-time sync
- ✅ Multi-device access
- ✅ Offline-first (works without internet)
- ✅ Conflict resolution (latest change wins)

**Online/Offline Indicator:**
- **Green dot**: Connected
- **Gray dot**: Offline (saves locally)

**Manual Sync:**
- Pull down to refresh on inventory screen
- Or Settings → Sync Now

---

## 🐛 Troubleshooting

### App Won't Build

```powershell
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

Or use helper:
```powershell
.\setup.ps1 clean
.\setup.ps1 run
```

### Camera Not Working

- Grant camera permission in device settings
- Test on physical device (emulators may not support camera)
- Check AndroidManifest.xml has camera permission

### Firebase Errors

**"Firebase initialization failed":**
- Ensure `google-services.json` is in `android/app/`
- Verify Firebase project is active
- Run `flutter clean` and rebuild

**"Permission denied" on Firestore:**
- Check security rules are published
- Verify user is authenticated
- Ensure userId matches in rules

### Products Not Syncing

- Check internet connection
- Verify signed in
- Try manual sync (pull to refresh)
- Check Firebase Console for issues

### Build Errors

**Gradle errors:**
```powershell
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

**Hive errors:**
```powershell
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### No Devices Found

**Check available devices:**
```powershell
flutter devices
```

**For emulator:**
```powershell
flutter emulators
flutter emulators --launch <emulator-id>
```

**For physical device:**
- Enable USB debugging
- Trust computer when prompted
- Try different USB cable/port

### Windows Developer Mode Required

**Error:** "Building with plugins requires symlink support"

**Fix:**
```powershell
start ms-settings:developers
```
Enable Developer Mode → Toggle ON

### Visual Studio Components Missing

**For Windows desktop, need:**
- Desktop development with C++
- MSVC build tools
- C++ CMake tools
- Windows SDK

**Alternative:** Use Chrome or Android instead!

---

## 📂 Project Structure

```
smartcart_app/
├── lib/
│   ├── main.dart                     # App entry point with Firebase init
│   ├── models/                       # Data models
│   │   ├── product.dart             # Product & NutritionInfo models
│   │   ├── nutrition.dart           # Daily nutrition tracking
│   │   └── sustainability.dart      # Sustainability metrics
│   ├── services/                     # Business logic
│   │   ├── auth_service.dart        # Firebase Authentication
│   │   ├── firestore_service.dart   # Cloud Firestore sync
│   │   └── barcode_service.dart     # Open Food Facts API
│   ├── providers/                    # State management (Provider)
│   │   ├── inventory_provider.dart  # Product CRUD + sync
│   │   └── nutrition_provider.dart  # Nutrition tracking
│   ├── screens/                      # UI screens
│   │   ├── login_screen.dart        # User login
│   │   ├── register_screen.dart     # User registration
│   │   ├── onboarding_screen.dart   # First-time intro
│   │   ├── home_screen.dart         # Bottom navigation hub
│   │   ├── inventory_screen.dart    # Product list & filters
│   │   ├── scanner_screen.dart      # Barcode scanner
│   │   ├── nutrition_screen.dart    # Nutrition dashboard
│   │   ├── shopping_list_screen.dart # Shopping list
│   │   └── product_detail_screen.dart # Product details
│   └── widgets/                      # Reusable components
│       └── product_card.dart        # Product display card
├── assets/                           # Images and icons
├── android/                          # Android-specific files
│   └── app/
│       ├── build.gradle.kts         # Firebase config
│       └── google-services.json     # Firebase credentials
├── windows/                          # Windows-specific files
├── docs/                            # Documentation
│   ├── ROADMAP.md                  # Development roadmap
│   └── SAMPLE_QR_CODES.md          # Test QR data
├── pubspec.yaml                     # Dependencies
├── firestore.rules                  # Firestore security rules
└── README.md                        # This file
```

---

## 🛠️ Development Guide

### Hot Reload

While app is running:
- Press `r` - Hot reload (instant updates)
- Press `R` - Hot restart (full restart)
- Press `q` - Quit app

### Code Quality

```powershell
# Check for errors
flutter analyze

# Format code
flutter format lib/

# Run tests
flutter test
```

### Building Release

**Android APK:**
```powershell
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk`

**Android App Bundle (Google Play):**
```powershell
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab`

**iOS (requires Mac):**
```powershell
flutter build ios --release
```

### Customization

**Change Theme Color:**
`lib/main.dart` → Find `seedColor: Colors.green` → Change to any color

**Change App Name:**
- `pubspec.yaml` → Change `name: smartcart_app`
- `android/app/src/main/AndroidManifest.xml` → Change `android:label`

**Add App Icon:**
1. Create 1024x1024 PNG
2. Use [flutter_launcher_icons](https://pub.dev/packages/flutter_launcher_icons)
3. Configure in `pubspec.yaml`
4. Run: `flutter pub run flutter_launcher_icons`

---

## 📋 Command Reference

### Helper Scripts (PowerShell)

```powershell
.\setup.ps1 run        # Run the app
.\setup.ps1 doctor     # Check Flutter setup
.\setup.ps1 analyze    # Check code quality
.\setup.ps1 devices    # List connected devices
.\setup.ps1 clean      # Clean and reset project
.\setup.ps1 build      # Regenerate Hive adapters
.\setup.ps1 release    # Build release APK
.\setup.ps1 get        # Get dependencies
```

### VS Code Tasks

Available tasks (Run → Run Task):
- **Flutter: Get Packages**
- **Flutter: Generate Hive Adapters**
- **Flutter: Clean**
- **Flutter: Build APK**
- **Flutter: Build App Bundle**
- **Flutter: Analyze**

### Flutter Commands

```powershell
# Set Flutter path (if not in PATH)
$env:Path += ";C:\develop\flutter\flutter\bin"

# Device management
flutter devices
flutter emulators
flutter emulators --launch <emulator-id>

# Running
flutter run
flutter run -d <device-id>
flutter run -d windows
flutter run -d chrome

# Building
flutter build apk --release
flutter build appbundle --release
flutter build ios --release

# Maintenance
flutter clean
flutter pub get
flutter pub upgrade
flutter doctor
flutter analyze

# Code generation
flutter pub run build_runner build
flutter pub run build_runner clean
```

---

## 💡 Pro Tips

### Development Workflow

1. **Make code changes** in VS Code
2. **Save file** (Ctrl+S)
3. **Press `r`** in terminal (hot reload)
4. **See changes instantly!**

### Best Practices

- Use FIFO method: First In, First Out
- Scan products immediately when purchased
- Set realistic expiry dates
- Update quantities as you use products
- Check "Expiring Soon" section daily
- Plan meals around expiring products

### Barcode Scanning Tips

- Scan in good lighting
- Hold phone steady
- Clean barcode if needed
- Try different angles
- Use manual entry if barcode damaged

### Testing

- Use Windows/Chrome for fast UI testing
- Use Android for full features (QR scanning)
- Test offline mode (airplane mode)
- Test multi-device sync
- Test with real product barcodes

---

## 🤝 Contributing

Contributions are welcome! Here's how:

1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

### Areas Needing Help

- 🌍 Sustainability screen implementation
- 📱 iOS testing & optimization
- 🌐 Multi-language support
- 🎨 UI/UX improvements
- 📊 More chart types
- 🧪 Unit & widget tests
- 📝 Documentation improvements

---

## 📄 License

This project is licensed under the MIT License - see [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Research Team**: University of Kelaniya – Department of Accountancy
- **Inspired by**: [FreshKeeper Android App](https://github.com/FreshKeeper/AndroidApp)
- **Product Data**: [Open Food Facts](https://world.openfoodfacts.org)
- **Backend**: [Firebase](https://firebase.google.com)
- **Framework**: Flutter & Dart communities
- **Packages**: All amazing pub.dev package authors

---

## 📞 Contact & Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/smartcart-flutter/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/smartcart-flutter/discussions)
- **Email**: your.email@example.com

### Learning Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire](https://firebase.flutter.dev)
- [Open Food Facts API](https://wiki.openfoodfacts.org/API)
- [Hive Database](https://docs.hivedb.dev/)
- [Provider State Management](https://pub.dev/packages/provider)
- [Material Design 3](https://m3.material.io/)

---

## 📊 Project Statistics

- **Total Lines of Code**: ~3,500+
- **Dart Files**: 15+
- **Screens**: 7
- **Data Models**: 6
- **Providers**: 2
- **Services**: 3
- **Dependencies**: 15+
- **Supported Platforms**: Android, iOS, Windows, Web
- **Database Systems**: 2 (Firestore + Hive)

---

## 🎯 Mission Statement

> **"Empowering households to make smarter food decisions, reduce waste, and contribute to a sustainable future through intelligent inventory management and nutritional awareness."**

---

## ✅ Features Checklist

### Implemented ✅
- [x] Firebase Authentication (Email/Password, Google)
- [x] Cloud Firestore sync
- [x] Barcode scanning
- [x] Open Food Facts API integration
- [x] Inventory management
- [x] Expiry tracking
- [x] Nutrition tracking
- [x] Shopping list
- [x] Offline mode
- [x] Multi-device sync
- [x] Material Design 3 UI
- [x] Onboarding flow

### Pending 🔄
- [ ] Sustainability insights screen
- [ ] Push notifications
- [ ] Recipe suggestions
- [ ] Meal planning
- [ ] Family sharing
- [ ] Advanced analytics
- [ ] iOS testing
- [ ] Multi-language support

---

<div align="center">

## 🎉 Ready to Reduce Food Waste!

**SmartCart is production-ready and waiting for you.**

**Built with ❤️ using Flutter**

⭐ **Star this repo if you find it helpful!** ⭐

---

**Project**: SmartCart  
**Version**: 1.0.0 (Production Ready)  
**Created**: November 2025  
**License**: MIT  
**Status**: ✅ Ready for Development & Deployment

</div>
