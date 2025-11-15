# App Icon Setup Instructions

To change your app icon, follow these steps:

1. **Replace the placeholder icon**: 
   - Delete this file (app_icon_README.md)
   - Add your custom icon image as `app_icon.png` in this folder
   - The icon should be at least 1024x1024 pixels for best quality
   - Use PNG format with transparent background

2. **Generate the icons**:
   - Run: `flutter pub get`
   - Run: `flutter pub run flutter_launcher_icons`

3. **Supported formats**:
   - PNG (recommended)
   - JPG
   - SVG (with flutter_svg package)

4. **Icon requirements**:
   - Square aspect ratio
   - High resolution (1024x1024 minimum)
   - Transparent background preferred

The flutter_launcher_icons package will automatically generate all the required icon sizes for Android, iOS, and other platforms.