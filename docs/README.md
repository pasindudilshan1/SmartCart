# 📚 SmartCart Documentation

Complete documentation for the SmartCart food waste reduction application.

---

## 📑 Table of Contents

- [Getting Started](#-getting-started)
- [Architecture & Design](#-architecture--design)
- [Azure Integration](#-azure-integration)
- [Development](#-development)
- [Troubleshooting](#-troubleshooting)

---

## 🚀 Getting Started

### [Quick Start Guide](QUICK_START.md)
**Start here!** Get SmartCart up and running in minutes.
- Installation steps
- First run
- Platform selection
- Basic usage

### [Setup Credentials](SETUP_CREDENTIALS.md)
Configure Azure and Firebase credentials securely.
- Azure configuration
- Firebase setup
- Security best practices
- Environment variables

### [Build Guide](BUILD_GUIDE.md)
Build SmartCart for different platforms.
- Debug builds
- Release builds
- Platform-specific builds (Android, iOS, Windows, Web)
- Build scripts usage

---

## 🏛️ Architecture & Design

### [Architecture Overview](ARCHITECTURE.md)
Complete system architecture and design patterns.
- Application layers
- State management
- Service architecture
- Design patterns used

### [Architecture Diagram](ARCHITECTURE_DIAGRAM.md)
Visual representation of system architecture.
- Component diagrams
- Data flow diagrams
- Service interactions

### [Firebase Structure](FIREBASE_STRUCTURE.md)
Database schema and Firestore organization.
- Collections structure
- Security rules
- Data models
- Indexing strategy

### [User Data Separation](USER_DATA_SEPARATION.md)
Privacy and security architecture.
- User data isolation
- Authentication flow
- Data access patterns
- Multi-tenancy approach

---

## ☁️ Azure Integration

### [Azure Setup](AZURE_SETUP.md)
Complete Azure configuration guide.
- Create Azure account
- Set up Table Storage
- Configure authentication
- Cost management

### [Azure Tables Quickstart](AZURE_TABLES_QUICKSTART.md)
Quick guide to Azure Table Storage integration.
- Table creation
- Entity structure
- CRUD operations
- Best practices

### [Azure Authentication Quickstart](AZURE_AUTH_QUICKSTART.md)
Set up Azure authentication.
- Auth service setup
- Token management
- User authentication flow

### [Azure Only Authentication](AZURE_ONLY_AUTH.md)
Use Azure as the sole authentication provider.
- Azure AD integration
- Migration from Firebase Auth
- Configuration steps

### [Azure Table Creation](AZURE_TABLE_CREATION.md)
Detailed guide for creating and managing Azure Tables.
- Table design
- Partition and row keys
- Querying strategies
- Performance optimization

---

## 💻 Development

### [Hot Reload Guide](HOT_RELOAD_GUIDE.md)
Fast development workflow with hot reload.
- Hot reload vs hot restart
- Best practices
- Limitations
- Debugging tips

### [Secure Credentials](SECURE_CREDENTIALS.md)
Best practices for credential management.
- Git ignore patterns
- Environment variables
- Secrets management
- Production deployment

### [Implementation Summary](IMPLEMENTATION_SUMMARY.md)
Feature implementation details.
- Completed features
- Implementation approach
- Code examples
- Testing strategies

### [Roadmap](ROADMAP.md)
Future features and planned improvements.
- Short-term goals
- Long-term vision
- Feature requests
- Version planning

### [Sample QR Codes](SAMPLE_QR_CODES.md)
Test barcodes for development and testing.
- Common product barcodes
- Test scenarios
- Edge cases
- Barcode formats

---

## 🔧 Troubleshooting

### [Login/Signup Fix](LOGIN_SIGNUP_FIX.md)
Common authentication issues and solutions.
- Firebase Auth errors
- Google Sign-In issues
- Network problems
- Platform-specific fixes

---

## 🆘 Common Issues

### Build Errors
1. **Hive adapter errors**: Run `flutter pub run build_runner build --delete-conflicting-outputs`
2. **Gradle errors**: Run `flutter clean` then rebuild
3. **Dependency conflicts**: Delete `pubspec.lock` and run `flutter pub get`

### Runtime Errors
1. **Camera not working**: Check [Fix QR Scanner script](../scripts/fix_qr_scanner.ps1)
2. **Firebase errors**: Verify `google-services.json` is present
3. **Azure errors**: Check credentials in `lib/config/azure_config.dart`

### Platform-Specific Issues
- **Windows**: Enable Developer Mode in Settings
- **Android**: Check SHA-1 fingerprint in Firebase
- **Web**: Camera access requires HTTPS

---

## 📖 How to Read the Documentation

### If you're new to SmartCart:
1. Start with [Quick Start Guide](QUICK_START.md)
2. Read [Setup Credentials](SETUP_CREDENTIALS.md)
3. Review [Architecture Overview](ARCHITECTURE.md)
4. Explore other docs as needed

### If you're deploying to production:
1. [Build Guide](BUILD_GUIDE.md)
2. [Secure Credentials](SECURE_CREDENTIALS.md)
3. [Firebase Structure](FIREBASE_STRUCTURE.md)
4. [Azure Setup](AZURE_SETUP.md) (if using Azure)

### If you're contributing:
1. [Architecture Overview](ARCHITECTURE.md)
2. [Implementation Summary](IMPLEMENTATION_SUMMARY.md)
3. [Hot Reload Guide](HOT_RELOAD_GUIDE.md)
4. [Roadmap](ROADMAP.md)

---

## 🔗 External Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Azure Documentation](https://docs.microsoft.com/azure/)
- [Open Food Facts API](https://world.openfoodfacts.org/data)
- [Dart Packages](https://pub.dev/)

---

## 📝 Documentation Standards

All documentation follows these standards:
- **Markdown format** for consistency
- **Clear headings** for easy navigation
- **Code examples** with syntax highlighting
- **Step-by-step instructions** for procedures
- **Visual aids** where helpful (diagrams, screenshots)

---

## 🤝 Contributing to Documentation

Help us improve the docs:
1. Found an error? Open an issue
2. Want to add content? Submit a PR
3. Need clarification? Ask in discussions
4. Have suggestions? We'd love to hear them

### Documentation Guidelines:
- Use clear, concise language
- Include code examples
- Add screenshots for UI steps
- Keep content up to date
- Cross-reference related docs

---

## 📄 License

Documentation is part of the SmartCart project and is licensed under the MIT License.

---

**Last Updated**: November 2025  
**Version**: 1.0.0

---

<div align="center">

**Need help?** Check the [Troubleshooting](#-troubleshooting) section or open an issue.

**Want to contribute?** See [Contributing to Documentation](#-contributing-to-documentation).

</div>
