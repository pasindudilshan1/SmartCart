# 🛒 SmartCart – Food Waste Reduction App

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
- [Project Structure](#-project-structure)
- [Scripts](#-scripts)
- [Documentation](#-documentation)
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

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.0+ ([Install Flutter](https://docs.flutter.dev/get-started/install))
- Dart SDK 3.0+
- VS Code or Android Studio
- Git
- For Android: Android SDK, emulator or physical device

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/smartcart.git
   cd smartcart
   ```

2. **Install dependencies**
   ```powershell
   flutter pub get
   ```
   Or use the setup script:
   ```powershell
   .\scripts\setup.ps1 get
   ```

3. **Configure credentials** (Important!)
   ```powershell
   Copy-Item lib\config\azure_config.dart.template lib\config\azure_config.dart
   ```
   Edit `lib/config/azure_config.dart` with your actual credentials.
   
   📚 See [docs/SETUP_CREDENTIALS.md](docs/SETUP_CREDENTIALS.md) for details.

4. **Generate Hive adapters**
   ```powershell
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Run the app**
   ```powershell
   flutter run
   ```

For detailed setup instructions, see [docs/QUICK_START.md](docs/QUICK_START.md).

---

## 📂 Project Structure

```
smartcart/
├── lib/                          # Main application code
│   ├── main.dart                 # App entry point
│   ├── config/                   # Configuration files
│   │   ├── azure_config.dart     # Azure credentials (gitignored)
│   │   └── azure_config.dart.template
│   ├── models/                   # Data models (Hive)
│   │   ├── product.dart
│   │   ├── household_member.dart
│   │   ├── nutrition.dart
│   │   └── sustainability.dart
│   ├── screens/                  # UI screens
│   │   ├── home_screen.dart
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── scanner_screen.dart
│   │   ├── inventory_screen.dart
│   │   ├── shopping_list_screen.dart
│   │   ├── nutrition_screen.dart
│   │   └── product_detail_screen.dart
│   ├── services/                 # Business logic & APIs
│   │   ├── azure_auth_service.dart
│   │   ├── azure_table_service.dart
│   │   ├── barcode_service.dart
│   │   └── local_storage_service.dart
│   ├── providers/                # State management
│   │   ├── inventory_provider.dart
│   │   └── nutrition_provider.dart
│   └── widgets/                  # Reusable widgets
│       ├── product_card.dart
│       └── household_info_card.dart
├── assets/                       # Images, icons
│   ├── icons/
│   └── images/
├── android/                      # Android platform code
├── windows/                      # Windows platform code
├── test/                         # Unit & widget tests
├── docs/                         # Documentation
│   ├── QUICK_START.md
│   ├── BUILD_GUIDE.md
│   ├── HOT_RELOAD_GUIDE.md
│   ├── SETUP_CREDENTIALS.md
│   ├── ARCHITECTURE.md
│   ├── FIREBASE_STRUCTURE.md
│   └── ...
├── scripts/                      # Build & setup scripts
│   ├── setup.ps1
│   ├── build_playstore.ps1
│   ├── clean_build_apk.ps1
│   ├── quick_build.ps1
│   └── fix_qr_scanner.ps1
├── pubspec.yaml                  # Dependencies
├── analysis_options.yaml         # Linting rules
└── README.md                     # This file
```

For detailed architecture, see [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## 🔧 Scripts

All scripts are located in the `scripts/` folder:

| Script | Description |
|--------|-------------|
| `setup.ps1` | Interactive setup and run helper |
| `build_playstore.ps1` | Build release APK/AAB for Play Store |
| `clean_build_apk.ps1` | Clean build directory and rebuild APK |
| `quick_build.ps1` | Quick debug APK build |
| `fix_qr_scanner.ps1` | Fix QR scanner permissions |
| `setup.bat` | Windows batch setup script |

### Usage Examples

```powershell
# Interactive setup
.\scripts\setup.ps1

# Get packages
.\scripts\setup.ps1 get

# Build for production
.\scripts\build_playstore.ps1

# Clean and rebuild
.\scripts\clean_build_apk.ps1
```

For more details, see [docs/BUILD_GUIDE.md](docs/BUILD_GUIDE.md).

---

## 📚 Documentation

All documentation is organized in the `docs/` folder:

### Getting Started
- [📖 Quick Start Guide](docs/QUICK_START.md) - Get up and running in minutes
- [🔧 Setup Credentials](docs/SETUP_CREDENTIALS.md) - Configure Azure & Firebase
- [🏗️ Build Guide](docs/BUILD_GUIDE.md) - Building for different platforms

### Architecture & Design
- [🏛️ Architecture Overview](docs/ARCHITECTURE.md) - System design and patterns
- [📊 Architecture Diagram](docs/ARCHITECTURE_DIAGRAM.md) - Visual system overview
- [🔥 Firebase Structure](docs/FIREBASE_STRUCTURE.md) - Database schema
- [👥 User Data Separation](docs/USER_DATA_SEPARATION.md) - Privacy & security

### Azure Integration
- [☁️ Azure Setup](docs/AZURE_SETUP.md) - Complete Azure configuration
- [📝 Azure Tables Quickstart](docs/AZURE_TABLES_QUICKSTART.md) - Table storage guide
- [🔐 Azure Authentication](docs/AZURE_AUTH_QUICKSTART.md) - Auth setup
- [🔒 Azure Only Auth](docs/AZURE_ONLY_AUTH.md) - Azure-only authentication
- [📦 Azure Table Creation](docs/AZURE_TABLE_CREATION.md) - Creating tables

### Development
- [🔥 Hot Reload Guide](docs/HOT_RELOAD_GUIDE.md) - Fast development workflow
- [🔒 Secure Credentials](docs/SECURE_CREDENTIALS.md) - Credential management
- [🛠️ Implementation Summary](docs/IMPLEMENTATION_SUMMARY.md) - Feature implementation
- [🗺️ Roadmap](docs/ROADMAP.md) - Future features & plans
- [📱 QR Code Samples](docs/SAMPLE_QR_CODES.md) - Test barcodes

### Troubleshooting
- [🔧 Login/Signup Fix](docs/LOGIN_SIGNUP_FIX.md) - Auth troubleshooting

---

## 🤝 Contributing

We welcome contributions! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

Please ensure:
- Code follows Dart/Flutter style guidelines
- All tests pass
- Documentation is updated
- No credentials are committed

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- **Open Food Facts** - Product database API
- **Firebase** - Authentication & cloud database
- **Flutter Team** - Amazing framework
- **Contributors** - Thank you for your support!

---

## 📞 Contact & Support

- **Issues**: [GitHub Issues](https://github.com/yourusername/smartcart/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/smartcart/discussions)
- **Email**: your.email@example.com

---

<div align="center">

**Made with ❤️ for a sustainable future**

**Reducing food waste, one scan at a time**

</div>
