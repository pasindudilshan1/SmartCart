# Azure-Only Authentication Implementation

## Overview
This document describes the complete removal of Firebase and implementation of Azure Table Storage-only authentication and data storage.

## Changes Made

### 1. **New Azure Authentication Service** (`lib/services/azure_auth_service.dart`)
- Created a new authentication service that uses Azure Table Storage instead of Firebase
- Password hashing using SHA-256
- User ID generation from email hash
- Session management with local storage
- Features:
  - `signUpWithEmail()` - Create new user account
  - `signInWithEmail()` - Sign in existing user
  - `signOut()` - Sign out and clear local data
  - `loadUserFromStorage()` - Auto-login from saved session
  - `deleteAccount()` - Delete user account and all data

### 2. **Updated Azure Table Service** (`lib/services/azure_table_service.dart`)
- Added `passwordHash` field to user profile storage
- Added `deleteUserData()` method to delete all user data
- Stores user credentials securely in Azure Tables

### 3. **Updated Local Storage Service** (`lib/services/local_storage_service.dart`)
- Added methods to save/retrieve current user info:
  - `saveCurrentUser()` - Save userId, email, name
  - `getCurrentUser()` - Retrieve saved user data
- Stores user session for offline access and auto-login

### 4. **Updated Authentication Flow**

#### **Login Screen** (`lib/screens/login_screen.dart`)
- Uses `AzureAuthService` instead of Firebase Auth
- Shows "Please sign up" message when user doesn't exist
- Removed Google Sign-In button
- Removed Guest mode button
- Password reset disabled (requires custom implementation)

#### **Register Screen** (`lib/screens/register_screen.dart`)
- Collects: Name, Email, Password
- Creates account in Azure Tables
- Automatically navigates to household setup after signup
- Removed Google Sign-In button
- Removed Guest mode button

#### **Household Setup Screen** (`lib/screens/household_setup_screen.dart`)
- Uses `AzureAuthService` to get current user ID
- Removed Firebase/Firestore dependencies
- Asks for:
  1. Number of household members
  2. Each member's name (optional)
  3. Each member's daily average calories
- Saves to Azure Tables and local storage

### 5. **Updated Providers**

#### **Inventory Provider** (`lib/providers/inventory_provider.dart`)
- Removed Firebase Auth dependency
- Added `setUserId()` method to set current user after login
- Uses `_currentUserId` instead of Firebase UID

#### **Nutrition Provider** (`lib/providers/nutrition_provider.dart`)
- Removed Firebase Auth dependency
- Added `setUserId()` method to set current user after login
- Uses `_currentUserId` instead of Firebase UID

### 6. **Main App** (`lib/main.dart`)
- Removed Firebase initialization
- Uses `AzureAuthService` in provider
- Removed all Firebase dependencies

### 7. **Dependencies** (`pubspec.yaml`)
Removed:
- ✗ firebase_core
- ✗ firebase_auth
- ✗ cloud_firestore
- ✗ firebase_storage
- ✗ google_sign_in

Kept:
- ✓ hive & hive_flutter (local storage)
- ✓ dio & http (Azure API calls)
- ✓ crypto (password hashing)
- ✓ shared_preferences (session storage)
- ✓ provider (state management)

## User Authentication Flow

### Sign Up Flow:
1. User enters: Name, Email, Password
2. System generates User ID from email hash
3. Password is hashed with SHA-256
4. User profile stored in Azure Tables with:
   - PartitionKey: 'user'
   - RowKey: userId
   - Email, DisplayName, PasswordHash, Provider, CreatedAt, LastLoginAt
5. User session saved to local storage
6. Navigate to Household Setup Screen

### Sign In Flow:
1. User enters: Email, Password
2. System generates User ID from email
3. Fetches user profile from Azure Tables
4. If user doesn't exist → Show "Please sign up" message with button
5. If user exists → Verify password hash
6. If password correct → Update LastLoginAt, save session, navigate
7. Check if household setup complete:
   - If complete → Navigate to Home Screen
   - If not complete → Navigate to Household Setup Screen

### Household Setup Flow:
1. User enters: Number of household members (1-12)
2. For each member, user enters:
   - Name (optional, e.g., "John", "Mom", "Kid 1")
   - Daily average calories (500-10000)
3. Data saved to:
   - Azure Tables (household profile + individual members)
   - Local storage (for offline access)
4. Navigate to Home Screen

## Data Storage Structure

### Azure Tables - Users Table

#### User Profile:
```
PartitionKey: 'user'
RowKey: {userId}
Fields:
  - Email: string
  - DisplayName: string
  - PasswordHash: string (SHA-256)
  - Provider: string ('email')
  - CreatedAt: ISO8601 string
  - LastLoginAt: ISO8601 string
```

#### Household Profile:
```
PartitionKey: {userId}
RowKey: 'household_profile'
Fields:
  - MemberCount: number
  - CreatedAt: ISO8601 string
  - UpdatedAt: ISO8601 string
```

#### Household Members:
```
PartitionKey: {userId}
RowKey: 'member_{index}' (e.g., 'member_1', 'member_2')
Fields:
  - MemberIndex: number
  - Name: string (optional)
  - AverageDailyCalories: number
  - CreatedAt: ISO8601 string
  - UpdatedAt: ISO8601 string
```

## Security Considerations

1. **Password Storage**: Passwords are hashed using SHA-256 before storage
2. **User ID Generation**: User IDs are generated from email hash to ensure uniqueness
3. **No Plaintext Passwords**: Passwords are never stored in plaintext
4. **Session Storage**: User sessions stored locally using SharedPreferences
5. **Azure Security**: All data stored in Azure Tables with account key authentication

## Migration Notes

### Old Services (Not Used Anymore):
- `lib/services/auth_service.dart` - Old Firebase auth service
- `lib/services/firestore_service.dart` - Old Firestore service

These files can be deleted if no other code references them.

### Files to Delete (Optional):
- `android/app/google-services.json` - Firebase config
- `firestore.rules` - Firestore security rules

## Testing Checklist

- [x] Sign up new user with email/password
- [x] Sign in shows "Please sign up" for non-existent users
- [x] Sign in works with correct password
- [x] Sign in fails with incorrect password
- [x] Household setup saves to Azure Tables
- [x] Household setup saves to local storage
- [x] Navigation flow works correctly
- [x] No Firebase dependencies remain
- [ ] Password hashing is secure
- [ ] User data persists across app restarts
- [ ] Offline mode works with local storage

## Next Steps

1. **Implement Password Reset**: 
   - Add password reset functionality
   - Send reset codes via email (requires email service)

2. **Enhance Security**:
   - Consider using bcrypt instead of SHA-256 for passwords
   - Add salt to password hashing
   - Implement session timeout

3. **Add Email Verification**:
   - Verify email addresses during signup
   - Send verification codes

4. **Delete Old Files**:
   - Remove `auth_service.dart`
   - Remove `firestore_service.dart`
   - Remove `google-services.json`

## Summary

The app now uses **Azure Tables exclusively** for:
- User authentication (email/password)
- User profile storage
- Household member data
- Product inventory
- Nutrition tracking
- Shopping lists

All Firebase dependencies have been removed, and the app works entirely with Azure Table Storage and local Hive storage.
