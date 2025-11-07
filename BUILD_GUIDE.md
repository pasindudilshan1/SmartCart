# SmartCart Build Guide

## Problem: Seeing Old App Version After Building

This happens because Flutter caches build files. Here are the solutions:

---

## Solution 1: Clean Build Script (RECOMMENDED)

**Use this when you see old versions or after major changes**

```powershell
.\clean_build_apk.ps1
```

**What it does:**
1. Runs `flutter clean`
2. Deletes all build directories (build, .dart_tool, android/build, etc.)
3. Runs `flutter pub get`
4. Generates Hive adapters with build_runner
5. Optionally increments version number
6. Builds fresh APK
7. Optionally uninstalls old version and installs new one

**Time:** 3-5 minutes (full clean build)

---

## Solution 2: Quick Build Script

**Use this for quick iterations during development**

```powershell
.\quick_build.ps1
```

**What it does:**
1. Builds APK without cleaning
2. Uninstalls old version from device
3. Installs new APK

**Time:** 1-2 minutes

**With clean flag:**
```powershell
.\quick_build.ps1 -Clean
```

---

## Solution 3: Manual Steps

If scripts don't work, run these commands manually:

### Step 1: Complete Clean
```powershell
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 2: Delete Build Folders Manually
```powershell
Remove-Item -Recurse -Force build
Remove-Item -Recurse -Force .dart_tool
Remove-Item -Recurse -Force android\.gradle
Remove-Item -Recurse -Force android\app\build
Remove-Item -Recurse -Force android\build
```

### Step 3: Build Fresh APK
```powershell
flutter build apk --release
```

### Step 4: Uninstall Old Version
```powershell
adb uninstall com.SmartCart
```

### Step 5: Install New APK
```powershell
adb install build\app\outputs\flutter-apk\app-release.apk
```

---

## Why This Happens

Flutter and Gradle cache files to speed up builds. This causes issues when:

- ✗ You change app configuration (AndroidManifest.xml, build.gradle)
- ✗ You add new dependencies
- ✗ You modify native code
- ✗ Build files become corrupted
- ✗ Version number doesn't change

**Solution:** Always uninstall the old app before installing new one!

---

## Version Management

### Current Version Location
File: `pubspec.yaml`
```yaml
version: 1.0.0+1
         ↑      ↑
    Version   Build Number
```

### Increment Version
The clean build script will ask if you want to increment the build number.

**Manual increment:**
```yaml
# Before
version: 1.0.0+1

# After
version: 1.0.0+2
```

---

## Best Practices

### During Development:
1. Use `quick_build.ps1` for fast iterations
2. Clean build once a day or after major changes

### Before Release:
1. Always use `clean_build_apk.ps1`
2. Increment version number
3. Test on real device

### After Changing:
- Dependencies → Clean build
- Native code → Clean build
- Gradle files → Clean build
- Models/Hive → Regenerate with build_runner

---

## Build Locations

### APK (Android)
```
build\app\outputs\flutter-apk\app-release.apk
```

### App Bundle (Play Store)
```
build\app\outputs\bundle\release\app-release.aab
```

---

## Common Issues

### Issue: "Installation failed"
**Solution:** Enable USB debugging on device

### Issue: "INSTALL_FAILED_UPDATE_INCOMPATIBLE"
**Solution:** Uninstall old version first
```powershell
adb uninstall com.SmartCart
```

### Issue: Old version still appears
**Solution:**
1. Uninstall app from device manually
2. Run clean build script
3. Install fresh APK

### Issue: Build errors after adding dependencies
**Solution:**
```powershell
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Quick Reference

| Command | Use Case | Time |
|---------|----------|------|
| `.\clean_build_apk.ps1` | Major changes, seeing old version | 3-5 min |
| `.\quick_build.ps1` | Quick iterations | 1-2 min |
| `.\quick_build.ps1 -Clean` | Medium changes | 2-3 min |
| `flutter build apk` | Manual build only | 1-2 min |

---

## Household Setup Feature

After sign-up, users will be prompted to enter:
- Number of family members (1-12)
- For each member:
  - Name (optional)
  - Average daily calories

Data is saved to:
- **Azure Tables** (under user ID, separate row per member)
- **Firestore** (backup/sync)

---

**Always use clean build when deploying to production!**
