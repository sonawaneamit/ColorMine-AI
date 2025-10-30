# Security Setup - API Keys

## ⚠️ CRITICAL: Exposed API Key

Your Gemini API key was exposed in the Git history. Follow these steps immediately:

## Step 1: Revoke the Exposed Key

1. Go to [Google Cloud Console - API Credentials](https://console.cloud.google.com/apis/credentials)
2. Find this API key: `AIzaSyBohbtglUEIkjrvuJ_wZOMv346jjsxzafY`
3. **DELETE IT IMMEDIATELY** or restrict it to only your app's bundle ID
4. This key is in the public Git history and cannot be removed

## Step 2: Create a New API Key

1. In Google Cloud Console, click "Create Credentials" → "API Key"
2. Copy the new API key
3. Restrict it to:
   - **Application restrictions**: iOS apps
   - **Bundle ID**: `com.colormineai`
   - **API restrictions**: Generative Language API

## Step 3: Add New Key to Your Local Project

1. Open: `ColorMine AI/Config/APIKeys.swift`
2. Replace `YOUR_GEMINI_API_KEY_HERE` with your new key
3. This file is in `.gitignore` and will NEVER be committed

Example:
```swift
struct APIKeys {
    static let geminiAPIKey = "AIzaYOUR_NEW_KEY_HERE"
}
```

## Step 4: Verify Security

Run this command to confirm the key isn't tracked:
```bash
git status
```

`APIKeys.swift` should NOT appear in the list.

## For Team Members

If someone else clones this repo:

1. Copy `APIKeys-template.swift` to `APIKeys.swift`
2. Get the API key from the team securely (1Password, etc.)
3. Add it to `APIKeys.swift`
4. Never commit `APIKeys.swift`

## Future Best Practices

1. ✅ Use `.gitignore` for sensitive files
2. ✅ Keep API keys in separate config files
3. ✅ Use template files as reference
4. ✅ Restrict API keys in Google Cloud Console
5. ❌ Never hardcode keys in source files
6. ❌ Never commit credentials to Git

## Additional Security (Production)

For production apps, consider:
- **Xcconfig files** with environment variables
- **Backend proxy**: Route API calls through your server
- **Secret management**: Use services like AWS Secrets Manager
- **Budget limits**: Set spending limits on your API key

---

**Remember**: Once a key is in Git history, it's permanently exposed. Always revoke and create new keys.
