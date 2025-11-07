# Hot Reload Guide - Real-time Development

## 🔥 Your App is Running!

The app is now running on your virtual device in **DEBUG MODE** with hot reload enabled!

## How to Use Hot Reload

### Option 1: Save File (Automatic)
1. Make changes to any Dart file
2. Press `Ctrl + S` to save
3. Flutter automatically hot reloads! ⚡
4. See changes instantly on emulator (1-2 seconds)

### Option 2: Manual Hot Reload
In the terminal where Flutter is running, press:
- **`r`** - Hot reload (fast, preserves app state)
- **`R`** - Hot restart (slower, resets app state)
- **`q`** - Quit and stop the app

### Option 3: VS Code
- Click the ⚡ icon in VS Code's debug toolbar
- Or use the Command Palette: `Flutter: Hot Reload`

## What Can You Change with Hot Reload?

✅ **Works Great (Hot Reload)**
- UI changes (colors, text, layouts)
- Add/remove widgets
- Change widget properties
- Modify functions
- Update constants
- Change styling

⚠️ **Needs Hot Restart (R)**
- Adding new files
- Changing main() function
- Modifying StatefulWidget's state initialization
- Adding new dependencies
- Changing app structure

❌ **Needs Full Rebuild**
- Changes to `pubspec.yaml` (run `flutter pub get` first)
- Native code changes (Android/iOS)
- Asset changes (images, fonts)

## Quick Test

Try this now:

1. **Open** `lib/screens/login_screen.dart`
2. **Find** the title text "SmartCart" (around line 199)
3. **Change** it to "SmartCart v2.0"
4. **Save** the file (`Ctrl + S`)
5. **Watch** the emulator update instantly! 🎉

## Terminal Commands While Running

```
r - Hot reload (⚡ fast)
R - Hot restart (🔄 slower, resets state)
p - Show performance overlay
o - Toggle platform (Android/iOS)
v - Open DevTools
q - Quit
```

## Tips for Best Results

1. **Keep the terminal visible** - You'll see reload status and any errors
2. **Save often** - Each save triggers a hot reload
3. **Watch console output** - See print statements in real-time
4. **Use 'r' if auto-reload fails** - Sometimes manual is needed
5. **Use 'R' if state gets weird** - Hot restart clears everything

## Current App Flow

When the app launches:
1. Shows **Login Screen** first
2. Click **"Create Account"** to test signup
3. After signup → **Household Setup Screen**
4. Fill in family members and calories
5. Click **"Save"** → **Home Screen**
6. Logout and login again → Skip setup, go to Home!

## Live Debugging

While the app runs, you can:
- See all `print()` statements in terminal
- Watch for errors in real-time
- Debug Firebase authentication
- Monitor Azure API calls
- Check local storage operations

## Console Output to Watch For

Successful signup:
```
✅ Sign up successful
💾 Saving household profile...
✅ Firestore saved
✅ Azure profile saved
✅ Local storage saved
🏠 Navigating to Home Screen...
```

Successful login (returning user):
```
✅ Sign in successful
🔍 Checking if household setup is complete...
✅ Household setup complete
✅ Successfully synced household members from Azure
```

## Common Issues

**Issue**: Changes not appearing?
**Solution**: Press `r` in terminal to force hot reload

**Issue**: Error after hot reload?
**Solution**: Press `R` for hot restart

**Issue**: App crashes?
**Solution**: Check terminal for error messages, fix code, save again

**Issue**: Need to add a package?
**Solution**: Stop app (`q`), add to pubspec.yaml, run `flutter pub get`, restart app

## Performance

While developing:
- Hot reload: **~1-2 seconds** ⚡
- Hot restart: **~5-10 seconds** 🔄
- Full rebuild: **~30-60 seconds** 🐌

## Have Fun! 🎉

You can now:
- Change colors and see them instantly
- Modify text and UI
- Test login/signup flow
- Add household members
- See real-time updates!

Happy coding! 🚀
