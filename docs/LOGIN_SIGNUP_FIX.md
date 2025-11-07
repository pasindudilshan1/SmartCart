# Login and Signup Flow - Complete Fix Documentation

## Overview
This document describes the complete fix for the login and signup flow, including household member setup, data storage across multiple platforms (Firebase Auth, Azure Tables, and local storage), and proper navigation logic.

## What Was Fixed

### 1. **Authentication Flow**
- ✅ Users can sign up with email/password
- ✅ Users can login with existing accounts
- ✅ First-time users are directed to household setup after signup
- ✅ Returning users skip setup and go directly to home screen
- ✅ Session management properly maintained between app restarts

### 2. **Household Setup Screen**
- ✅ Asks for number of household members (1-12)
- ✅ For each member, collects:
  - Name (optional)
  - Average daily calorie needs
- ✅ Validates all inputs before saving
- ✅ Data is saved to **three locations**:
  1. **Firebase Firestore** - for cloud backup
  2. **Azure Tables** - under user's ID from Firebase Auth
  3. **Local Storage (Hive)** - for offline access

### 3. **Data Storage Architecture**

#### Firebase Authentication
- Provides user ID (`uid`) used across all storage systems
- Handles authentication state
- Supports email/password, Google Sign-In, and anonymous auth

#### Azure Tables Storage
Each user has entries in the `users` table:
- **User Profile**: `PartitionKey=user, RowKey={userId}`
- **Household Profile**: `PartitionKey={userId}, RowKey=household_profile`
- **Household Members**: `PartitionKey={userId}, RowKey=member_1, member_2, etc.`

Example household member entity in Azure:
```json
{
  "PartitionKey": "user123",
  "RowKey": "member_1",
  "MemberIndex": 1,
  "AverageDailyCalories": 2000.0,
  "Name": "John",
  "CreatedAt": "2025-11-06T10:30:00Z",
  "UpdatedAt": "2025-11-06T10:30:00Z"
}
```

#### Local Storage (Hive)
- Stores household member data locally for offline access
- Uses SharedPreferences to track:
  - `household_setup_complete` - boolean flag
  - `current_user_id` - to verify correct user
  - `member_count` - number of household members
  - `last_sync_time` - when data was last synced from cloud

### 4. **Navigation Logic**

#### After Signup
```
Sign Up → Firebase Auth → Household Setup → Save Data → Home Screen
```

#### After Login (First Time)
```
Login → Firebase Auth → Check Local Storage → Household Setup → Save Data → Home Screen
```

#### After Login (Returning User)
```
Login → Firebase Auth → Check Local Storage → Fetch Azure Data (background) → Home Screen
```

The system checks if household setup is complete by:
1. Verifying the user ID matches stored user
2. Checking the `household_setup_complete` flag in SharedPreferences
3. If complete, loads data from local storage (instant)
4. Syncs with Azure in background if data is older than 24 hours

## New Files Created

### 1. `lib/services/local_storage_service.dart`
Manages local data storage and sync status.

**Key Methods:**
- `isHouseholdSetupComplete(userId)` - Checks if setup is done
- `markHouseholdSetupComplete(userId)` - Marks setup as complete
- `saveHouseholdMembers(userId, members)` - Saves members locally
- `getHouseholdMembers()` - Retrieves members from local storage
- `needsSync()` - Checks if data needs refresh from cloud
- `clearAllData()` - Clears data on logout

### 2. `lib/widgets/household_info_card.dart`
Reusable widget to display household member information.

**Features:**
- Shows all household members with names and calorie targets
- Displays total daily calories for the household
- Can be used in settings or profile screens

## Modified Files

### 1. `lib/services/auth_service.dart`
**Changes:**
- Added `LocalStorageService` integration
- Enhanced `signOut()` to clear local data
- Added `isHouseholdSetupComplete()` method

### 2. `lib/screens/login_screen.dart`
**Changes:**
- Added smart navigation after login
- Checks if household setup is complete
- Fetches fresh data from Azure in background
- Falls back to local storage for instant app startup

### 3. `lib/screens/register_screen.dart`
**Changes:**
- Always navigates to household setup after signup
- Removed complex logic for Google Sign-In (simplified)

### 4. `lib/screens/household_setup_screen.dart`
**Changes:**
- Creates proper `HouseholdMember` objects
- Saves to all three storage locations (Firestore, Azure, Local)
- Marks setup as complete in SharedPreferences
- Better error handling and user feedback

### 5. `lib/main.dart`
**Changes:**
- Removed forced logout (was for testing)
- Properly initializes Hive boxes for household members
- Cleaner imports

## Data Flow Diagram

```
┌─────────────────┐
│   User Login    │
└────────┬────────┘
         │
         ▼
┌─────────────────────────┐
│  Firebase Auth Check    │
│  (Get User ID)          │
└────────┬────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Check Local Storage    │
│  (SharedPreferences)    │
└────────┬────────────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
[Setup     [Setup
 Done?]    Not Done]
    │         │
    │         └──────────────┐
    │                        │
    ▼                        ▼
┌─────────────────┐   ┌──────────────────┐
│ Load from Hive  │   │ Household Setup  │
│ (Instant)       │   │ Screen           │
└────────┬────────┘   └────────┬─────────┘
         │                     │
         ▼                     ▼
┌─────────────────┐   ┌──────────────────┐
│ Sync with Azure │   │ Save to:         │
│ (Background)    │   │ 1. Firestore     │
└────────┬────────┘   │ 2. Azure Tables  │
         │            │ 3. Hive (Local)  │
         │            └────────┬─────────┘
         │                     │
         └──────┬──────────────┘
                │
                ▼
        ┌───────────────┐
        │  Home Screen  │
        └───────────────┘
```

## Testing Steps

### Test 1: New User Signup
1. Open the app
2. Click "Sign Up"
3. Enter name, email, password
4. Click "Sign Up"
5. **Expected**: Navigates to Household Setup Screen

### Test 2: Household Setup
1. After signup, on Household Setup screen
2. Enter number of members (e.g., 3)
3. Fill in names (optional) and calories for each member
4. Click "Save"
5. **Expected**: 
   - Data saves to all three locations
   - Navigates to Home Screen
   - Console shows success messages

### Test 3: Logout and Login
1. Logout from the app
2. Login with same credentials
3. **Expected**:
   - Skips Household Setup
   - Goes directly to Home Screen
   - Household data is loaded from local storage
   - Background sync fetches latest from Azure

### Test 4: App Restart
1. Close and restart the app
2. Login
3. **Expected**:
   - User bypasses setup screen
   - Data loads instantly from local storage
   - App feels responsive

### Test 5: Data Sync
1. Login on one device, change household data
2. Login on another device (or after 24 hours)
3. **Expected**:
   - Latest data syncs from Azure Tables
   - Local storage updates with fresh data

## Offline Support

The app works offline because:
1. **First Priority**: Local storage (Hive) - always available
2. **Second Priority**: Azure sync happens in background
3. **Fallback**: If Azure fails, uses local data

This means:
- ✅ App opens instantly even without internet
- ✅ Household data is always available offline
- ✅ Background sync keeps data fresh when online

## Console Output Example

When a user logs in (household setup complete):
```
🔐 Starting sign in...
Email: user@example.com
Sign in result - Error: null
✅ Sign in successful, navigating...
🔍 Checking if household setup is complete...
✅ Household setup complete, loading data...
🔄 Fetching household data from Azure...
✅ Successfully synced 3 household members from Azure
```

When a new user completes setup:
```
💾 Saving household profile...
User ID: abc123
Member count: 3
Calories: [2000.0, 1800.0, 2200.0]
Names: [John, Mary, Tom]
📝 Saving to Firestore...
✅ Firestore saved
☁️  Saving to Azure Tables...
✅ Azure profile saved
✅ Azure members saved
📱 Saving to local storage...
✅ Saved 3 household members to local storage
✅ Local storage saved
🏠 Navigating to Home Screen...
```

## Future Enhancements

Potential improvements:
1. **Edit Household Members** - Allow users to update member info
2. **Delete Members** - Remove household members
3. **Profile Pictures** - Add avatars for each member
4. **Calorie Tracking** - Track actual vs. target calories per member
5. **Member-specific Inventory** - Assign products to specific members
6. **Dietary Preferences** - Add allergies, restrictions per member
7. **Export Data** - Download household data as CSV/PDF

## Troubleshooting

### Issue: User stuck in setup loop
**Solution**: Clear app data or call `LocalStorageService.clearAllData()`

### Issue: Data not syncing from Azure
**Solution**: Check Azure credentials in `lib/config/azure_config.dart`

### Issue: "User not authenticated" error
**Solution**: Firebase auth session expired - user needs to login again

### Issue: Hive adapter errors
**Solution**: Run `flutter pub run build_runner build --delete-conflicting-outputs`

## Security Notes

- User passwords are handled by Firebase Auth (industry-standard security)
- Azure Tables use Shared Key authentication
- Local data is stored in encrypted Hive boxes (on-device encryption)
- User IDs from Firebase Auth are used as partition keys in Azure
- No sensitive data is logged to console in production

## Summary

The login/signup flow now properly:
✅ Handles new user registration
✅ Collects household member information
✅ Saves data to Firebase, Azure, and local storage
✅ Intelligently navigates based on setup status
✅ Provides offline support with background sync
✅ Maintains user session across app restarts
✅ Clears data on logout

All data is stored under the user's Firebase Auth ID, ensuring proper data separation between users.
