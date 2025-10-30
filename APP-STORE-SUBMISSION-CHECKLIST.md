# App Store Submission Checklist

Complete this checklist before archiving and uploading ColorMine AI to App Store Connect.

---

## ✅ 1. Xcode Project Configuration

### Bundle ID & Version
- [x] **Bundle ID**: `com.colormineai` (matches App Store Connect)
- [ ] **Version Number**: Set to `1.0` (or your desired version)
- [ ] **Build Number**: Set to `1` (increment for each upload)

**How to verify:**
1. Open project in Xcode
2. Select ColorMine AI target
3. Go to **General** tab
4. Check **Version** and **Build** fields

---

### App Icon
- [ ] **App Icon Set**: All required sizes present in Assets.xcassets
- [ ] **1024x1024 icon**: Must be present for App Store

**How to verify:**
1. Open `Assets.xcassets` in Xcode
2. Click on **AppIcon**
3. Ensure all slots are filled (especially 1024x1024)

**If missing:** Add your app icon image in all required sizes.

---

### Signing & Capabilities
- [ ] **Signing configured**: Automatic or Manual signing set up
- [ ] **Team selected**: Your Apple Developer team selected
- [ ] **Provisioning Profile**: Valid for distribution
- [ ] **In-App Purchase capability**: Added and enabled

**How to verify:**
1. Select ColorMine AI target
2. Go to **Signing & Capabilities** tab
3. Ensure no errors shown
4. Verify "In-App Purchase" capability is present

---

### Privacy Permissions (Info.plist)
- [x] **Camera Usage**: ✅ Already configured
- [x] **Photo Library Usage**: ✅ Already configured

**Current descriptions:**
- Camera: "We need camera access to take your selfie for color analysis"
- Photo Library: "Save your color analysis results to Photos"

**Note:** These look good but check if camera description has duplicate text.

---

## ✅ 2. API Keys & Secrets

### Local Configuration
- [ ] **APIKeys.swift exists**: File present in project
- [ ] **API keys filled in**: Gemini, OpenAI, fal.ai keys configured
- [ ] **Not in Git**: Verify APIKeys.swift is in .gitignore
- [ ] **Keys restricted**: API keys restricted to bundle ID in respective consoles

**How to verify:**
```bash
# Check if APIKeys.swift exists and has keys
cat "ColorMine AI/Config/APIKeys.swift"

# Verify it's not tracked by git
git status
```

**Critical:** Test on a real device to ensure API keys work!

---

## ✅ 3. Build Configuration

### Scheme Settings
- [ ] **Release scheme selected**: Not Debug
- [ ] **Run destination**: Generic iOS Device (not simulator)
- [ ] **Bitcode disabled**: Usually disabled for modern apps
- [ ] **Optimization level**: Release optimization

**How to set:**
1. In Xcode menu: **Product** > **Scheme** > **Edit Scheme**
2. Select **Archive** in left sidebar
3. Ensure **Build Configuration** is set to **Release**

---

## ✅ 4. Testing (Critical!)

### Functionality Testing
- [ ] **Test on real device**: Install and test full flow
- [ ] **Camera access works**: Selfie capture functional
- [ ] **Color analysis completes**: AI services responding
- [ ] **Pack generation works**: All packs generate successfully
- [ ] **Try-On feature works**: fal.ai integration functional
- [ ] **Navigation flows**: All screens accessible

### In-App Purchases (Sandbox)
- [ ] **Sandbox account set up**: Created in App Store Connect
- [ ] **Credit packs load**: All 4 credit products appear
- [ ] **Purchase flow works**: Can purchase credits in sandbox
- [ ] **Credits awarded**: Balance updates correctly
- [ ] **Restore works**: Restore purchases functional

### Subscriptions (Sandbox)
- [ ] **Subscriptions load**: Both weekly and monthly appear
- [ ] **Prices correct**: $6.99 weekly, $19.99 monthly
- [ ] **Purchase works**: Can subscribe in sandbox
- [ ] **Access granted**: Subscription features unlock
- [ ] **Status persists**: Subscription status saves correctly

**How to test:**
1. Device Settings > App Store > Sandbox Account
2. Sign in with sandbox tester
3. Launch app and test purchases

---

## ✅ 5. App Store Connect Metadata

### Version Information
- [ ] **App name set**: "Color Analysis - ColorMine AI"
- [ ] **Subtitle set**: "Your Season & Virtual Try-On"
- [ ] **Description written**: Compelling app description
- [ ] **Keywords entered**: Relevant search keywords
- [ ] **Promotional text**: Optional promotional text

### Screenshots
- [ ] **6.7" Display** (iPhone 14 Pro Max or later): 5-10 screenshots
- [ ] **6.5" Display** (iPhone 11 Pro Max or later): 5-10 screenshots
- [ ] **5.5" Display** (iPhone 8 Plus): 5-10 screenshots

**Required screenshot sizes:**
- 6.7": 1290 x 2796 pixels
- 6.5": 1242 x 2688 pixels
- 5.5": 1242 x 2208 pixels

**Recommended screenshots:**
1. Welcome/Onboarding
2. Selfie capture screen
3. Color analysis results (season reveal)
4. Color palette/drapes visualization
5. Generated packs (makeup, hair, etc.)
6. Try-On browser view
7. Try-On result view

### Support Information
- [ ] **Support URL**: Website or support page URL
- [ ] **Marketing URL**: Optional marketing website
- [ ] **Privacy Policy URL**: Required for apps with accounts/subscriptions

### App Category
- [ ] **Primary Category**: Lifestyle (recommended)
- [ ] **Secondary Category**: Optional (Shopping, Beauty)

### Age Rating
- [ ] **Age Rating questionnaire**: Completed
- [ ] Likely rating: **4+** (no sensitive content)

### App Review Information
- [ ] **Contact information**: Email and phone
- [ ] **Demo account**: Optional, but helpful for reviewers
- [ ] **Review notes**: Explain features, especially AI and IAP

**Recommended review notes:**
```
ColorMine AI uses AI to analyze user photos and provide personalized color recommendations.

Key Features:
1. AI Color Analysis: Uses Gemini Vision API for season detection
2. AI Pack Generation: Creates personalized style visualizations
3. Virtual Try-On: fal.ai integration for garment try-on
4. In-App Purchases: Credits for try-on features
5. Subscriptions: Weekly/monthly for unlimited access

Testing:
- Color analysis requires camera access
- Try-On credits can be tested with sandbox account
- All AI features require active internet connection

API Keys are restricted to bundle ID: com.colormineai

Please test with provided sandbox account for IAP testing.
```

---

## ✅ 6. In-App Purchases & Subscriptions

### Consumables (Credits)
- [x] **4 credit packs created**: 1, 5, 15, 30 credits
- [x] **Product IDs match code**: com.colormineai.tryon.credits.*
- [x] **Prices set**: $6.99, $15.00, $34.00, $55.00
- [x] **Ready to Submit**: All marked ready
- [x] **Added to version**: All added to app version in App Store Connect

### Subscriptions
- [x] **Subscription group created**: ColorMine AI Premium
- [x] **Weekly subscription**: $6.99, com.colormineai.weekly
- [x] **Monthly subscription**: $19.99, com.colormineai.monthly
- [x] **Descriptions complete**: Localizations filled in
- [x] **Screenshots uploaded**: Review screenshots added
- [x] **Ready to Submit**: Both marked ready
- [x] **Added to version**: Both added to app version

---

## ✅ 7. Legal & Compliance

### Required Documents
- [ ] **Privacy Policy**: Created and hosted online
- [ ] **Terms of Service**: Created and hosted online (if needed)
- [ ] **End User License Agreement**: Standard or custom EULA

**What to include in Privacy Policy:**
- Data collection (photos, color analysis)
- API usage (Gemini, OpenAI, fal.ai)
- Photo storage (local only)
- Subscription/payment information
- User rights (access, deletion)

**Free tools to create:**
- [TermsFeed Privacy Policy Generator](https://www.termsfeed.com/privacy-policy-generator/)
- [App Privacy Policy Generator](https://app-privacy-policy-generator.firebaseapp.com/)

---

## ✅ 8. Pre-Archive Steps

### Clean Build
- [ ] **Clean build folder**: Product > Clean Build Folder (Cmd+Shift+K)
- [ ] **Derived data cleared**: Optional but recommended

### Final Code Check
- [ ] **No debug code**: Remove test/debug statements
- [ ] **No hardcoded secrets**: All API keys in config file
- [ ] **No print statements**: Or remove excessive logging
- [ ] **Error handling**: All API calls handle errors gracefully

### Version Control
- [ ] **Code committed**: All changes committed to git
- [ ] **Tagged release**: Optional: create git tag for v1.0

---

## ✅ 9. Archive & Upload

### Archive Process
1. **Select Generic iOS Device**
   - In device selector, choose "Any iOS Device (arm64)"

2. **Archive the app**
   - Menu: **Product** > **Archive**
   - Wait for build to complete (5-10 minutes)

3. **Organizer opens**
   - Archives list appears
   - Select your latest archive

4. **Distribute App**
   - Click **Distribute App** button
   - Choose **App Store Connect**
   - Click **Next**

5. **Distribution Options**
   - Upload method: **Upload**
   - App Store distribution: Standard
   - Click **Next**

6. **Re-sign if needed**
   - Automatic signing: Let Xcode handle it
   - Manual signing: Select provisioning profile
   - Click **Next**

7. **Review content**
   - Review app details
   - Click **Upload**

8. **Wait for processing**
   - Upload takes 5-15 minutes
   - Processing takes 15-60 minutes
   - You'll get email when ready

### Post-Upload
- [ ] **Build appears in App Store Connect**: Check version page
- [ ] **No warnings**: Review any warnings from Apple
- [ ] **Submit for review**: Once build is processed

---

## ✅ 10. Submit for Review

### Final Checks
- [ ] **Test flight build works**: Optional but recommended
- [ ] **All metadata complete**: Name, description, screenshots
- [ ] **IAPs ready**: All in-app purchases ready to submit
- [ ] **Build selected**: Choose uploaded build
- [ ] **Age rating complete**: Questionnaire filled
- [ ] **Pricing set**: App price (Free in your case)

### Submit
1. Go to version page in App Store Connect
2. Scroll to **Build** section
3. Click **+** to select your uploaded build
4. Review all sections (green checkmarks)
5. Click **Submit for Review** button
6. Answer export compliance questions:
   - Does your app use encryption? **No** (or Yes if you use HTTPS)
   - Is app exempt? **Yes** (for standard HTTPS)

### Review Times
- **Average**: 24-48 hours
- **Can be longer**: Especially for first submission
- **Communication**: Apple may ask questions

---

## 🚨 Common Issues & Solutions

### Archive Fails
**Issue**: "Generic iOS Device" not available
**Solution**: Update Xcode, or select a physical device then archive

**Issue**: Signing errors
**Solution**: Go to Signing & Capabilities, ensure team and profile are valid

### Upload Fails
**Issue**: Invalid bundle ID
**Solution**: Must match App Store Connect exactly: `com.colormineai`

**Issue**: Missing Info.plist keys
**Solution**: Add required privacy descriptions

### Processing Fails
**Issue**: Missing required icons
**Solution**: Ensure 1024x1024 icon is in AppIcon asset

**Issue**: Invalid binary
**Solution**: Check for deprecated APIs, missing frameworks

---

## 📋 Quick Pre-Flight Checklist

**30 seconds before archiving:**

- [ ] Bundle ID: `com.colormineai` ✓
- [ ] Version: `1.0` (or higher)
- [ ] Build: `1` (or higher)
- [ ] Release scheme selected
- [ ] Generic iOS Device selected
- [ ] APIKeys.swift configured with valid keys
- [ ] App tested on real device
- [ ] IAPs tested in sandbox
- [ ] Clean build completed

**If all checked, you're ready to archive!** 🚀

---

## 📞 Need Help?

**Apple Resources:**
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [TestFlight Documentation](https://developer.apple.com/testflight/)

**Contact:**
- App Store Connect: Contact Apple Support
- Developer Forums: [developer.apple.com/forums](https://developer.apple.com/forums)

---

**Good luck with your submission!** 🎉
