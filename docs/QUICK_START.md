# Quick Start Guide - Login & Household Setup

## What's Fixed ✅

Your SmartCart app now has a complete login/signup flow with household member management!

## How It Works

### For New Users (First Time)
1. **Sign Up** → Enter email, password, name
2. **Household Setup** → Enter:
   - Number of family members (1-12)
   - Each member's name (optional)
   - Each member's daily calorie target
3. **Data Saved** to:
   - 🔥 Firebase (cloud backup)
   - ☁️ Azure Tables (under your user ID)
   - 📱 Local storage (works offline)
4. **Home Screen** → Start using the app!

### For Returning Users
1. **Login** → Enter email and password
2. **Automatic** → Loads your household data instantly from local storage
3. **Background Sync** → Updates from Azure if needed (every 24 hours)
4. **Home Screen** → All your data is ready!

## Key Features

✅ **Offline First** - Works without internet using local storage
✅ **Cloud Sync** - Data backed up to Azure Tables
✅ **Multi-device** - Login from any device and see your data
✅ **Smart Navigation** - First-time users set up household, returning users skip to home
✅ **Secure** - All data saved under your Firebase Auth user ID

## New Files

1. **`lib/services/local_storage_service.dart`** - Handles local data and sync
2. **`lib/widgets/household_info_card.dart`** - Shows household members (can add to settings)
3. **`docs/LOGIN_SIGNUP_FIX.md`** - Complete technical documentation

## Testing

### Test New User Flow
```
1. Open app
2. Click "Create Account"
3. Fill in name, email, password
4. Click "Sign Up"
5. You'll see Household Setup screen
6. Enter family members and calories
7. Click "Save"
8. You're in!
```

### Test Returning User
```
1. Logout
2. Login with same credentials
3. You'll skip setup and go straight to Home
```

## Where's Your Data?

Your household information is saved in **three places**:

1. **Firebase Firestore** (`households` collection)
2. **Azure Tables** (`users` table, partition by your user ID)
3. **Local Storage** (Hive database on your phone)

## Console Messages

When everything works, you'll see:
```
✅ Firebase initialized successfully
✅ Hive initialized successfully
✅ Sign up successful
✅ Firestore saved
✅ Azure profile saved
✅ Azure members saved
✅ Saved 3 household members to local storage
🏠 Navigating to Home Screen...
```

## Next Steps

You can now:
- Add products to inventory
- Track nutrition per household member
- See total daily calorie targets
- All data syncs across devices!

## Need Help?

See the full documentation in `docs/LOGIN_SIGNUP_FIX.md`

---

**Note**: Make sure your `lib/config/azure_config.dart` has valid Azure credentials for cloud storage to work!
