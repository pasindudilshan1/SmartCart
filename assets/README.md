# Assets Directory

## Images
Place your app images here:
- Logo
- Onboarding graphics
- Product placeholder images

## Icons
Place custom icons here if needed.

For now, the app uses Material Icons which are built into Flutter.

## Recommended Sizes

### App Icon
- 1024x1024 PNG (for all platforms)

### Splash Screen
- 1242x2688 PNG (iPhone X/11/12 Pro Max)
- Scale down for other devices

### Product Images
- 512x512 PNG (square)
- Use transparent backgrounds where appropriate

---

To add assets to your app:

1. Place files in this directory
2. Reference them in `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/images/logo.png
    - assets/images/
```

3. Use in code:
```dart
Image.asset('assets/images/logo.png')
```
