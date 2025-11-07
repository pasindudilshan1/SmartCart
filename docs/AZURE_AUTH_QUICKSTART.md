# Quick Start Guide - Azure-Only Authentication

## What Changed?

Firebase has been completely removed. The app now uses **Azure Table Storage** for all authentication and data storage.

## How to Use

### 1. Sign Up (New User)
1. Open the app → You'll see the Login Screen
2. Click "Sign Up" button at the bottom
3. Enter your information:
   - **Name**: Your full name (e.g., "John Smith")
   - **Email**: Your email address
   - **Password**: At least 6 characters
   - **Confirm Password**: Same as password
4. Click "Sign Up"
5. You'll be taken to Household Setup

### 2. Household Setup (After Sign Up)
1. Enter **how many members** live in your household (1-12)
2. For each member, enter:
   - **Name** (optional): e.g., "John", "Mom", "Kid 1"
   - **Daily Average Calories**: e.g., 2000 (range: 500-10000)
     - Typical adult: 1800-2500 calories
     - Child: 1200-1800 calories
     - Teenager: 2000-2800 calories
3. Click "Save and Continue"
4. You'll be taken to the Home Screen

### 3. Sign In (Existing User)
1. Open the app → You'll see the Login Screen
2. Enter your:
   - **Email**: The email you signed up with
   - **Password**: Your password
3. Click "Sign In"
4. If you haven't completed household setup, you'll be asked to do so
5. Otherwise, you'll go to the Home Screen

### 4. What If I Forgot My Email?
Unfortunately, there's currently no way to recover your email. You'll need to sign up again with a new email.

### 5. What If I Enter Wrong Email During Login?
You'll see a message: **"No account found with this email. Please sign up."**

Click the "Sign Up" button in the message or at the bottom to create an account.

## Important Notes

### ✅ What Works:
- Email/password sign up
- Email/password sign in
- Household member setup
- Data saved to Azure Tables
- Offline mode with local storage
- Auto-login (stays signed in)

### ❌ What Doesn't Work Yet:
- Google Sign-In (removed)
- Guest mode (removed)
- Password reset
- Email verification

### 🔒 Security:
- Passwords are hashed with SHA-256 before storage
- No passwords stored in plain text
- User sessions saved locally for auto-login

## Example Data Entry

### Sign Up Example:
```
Name: John Smith
Email: john.smith@example.com
Password: MySecurePass123
Confirm Password: MySecurePass123
```

### Household Setup Example (Family of 3):
```
Number of household members: 3

Member 1:
  Name: Dad (John)
  Daily Calories: 2200

Member 2:
  Name: Mom (Sarah)
  Daily Calories: 1900

Member 3:
  Name: Kid (Emma)
  Daily Calories: 1500
```

## Troubleshooting

### "User not authenticated" error
- Try signing out and signing in again
- Make sure you completed sign up successfully

### Household setup not saving
- Check your Azure Table Storage credentials in `lib/config/azure_config.dart`
- Make sure you have internet connection
- Check console logs for specific errors

### Can't sign in
- Double-check email and password
- Email is case-insensitive but password is case-sensitive
- If "No user found", you need to sign up first

## Technical Details

### Where is data stored?

1. **Azure Tables** (Cloud):
   - User profile (email, name, password hash)
   - Household members
   - Products
   - Nutrition data
   - Shopping lists

2. **Local Storage** (Device):
   - Cached household members
   - User session (for auto-login)
   - Offline product inventory
   - Settings

### Data Privacy:
- All data is stored in YOUR Azure Table Storage account
- No third-party services have access to your data
- You control the data through your Azure account

## Developer Notes

### Required Setup:
1. Configure Azure credentials in `lib/config/azure_config.dart`
2. Make sure Azure Table Storage tables exist:
   - Users table
   - Products table
   - Nutrition table
   - Shopping list table
   - Settings table

### Testing:
- Use different email addresses for testing multiple accounts
- Clear app data to test fresh installation
- Check Azure Portal to verify data is being saved

### Next Features to Implement:
1. Password reset via email
2. Email verification
3. Profile editing
4. Account deletion UI
5. Session timeout

---

**Need Help?** Check `AZURE_ONLY_AUTH.md` for detailed technical documentation.
