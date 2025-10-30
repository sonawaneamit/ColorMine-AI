# In-App Purchase Setup Guide

This guide will help you set up the Try-On credits in-app purchases in App Store Connect.

## Overview

ColorMine AI uses **consumable in-app purchases** for Try-On credits. Users purchase credits which are consumed when they generate virtual try-on images.

---

## Step 1: Access In-App Purchases

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click on **My Apps**
3. Select **ColorMine AI** (or **ColorMineAI**)
4. In the left sidebar, scroll down and click **In-App Purchases**
5. Click the **+** button to create a new in-app purchase

---

## Step 2: Create Consumable Products

Create **4 consumable products** with the following details:

### Product 1: Single Credit
- **Type**: Consumable
- **Reference Name**: `ColorMine - 1 Try-On Credit`
- **Product ID**: `com.colormineai.tryon.credits.1`
- **Price**: $6.99 USD (Tier 7)
- **Localizations (English - U.S.)**:
  - **Display Name**: `1 Try-On Credit`
  - **Description**: `One credit for a single virtual try-on. See how garments look on you before buying.`

### Product 2: Small Pack
- **Type**: Consumable
- **Reference Name**: `ColorMine - 5 Try-On Credits`
- **Product ID**: `com.colormineai.tryon.credits.5`
- **Price**: $15.00 USD (Tier 15)
- **Localizations (English - U.S.)**:
  - **Display Name**: `5 Try-On Credits`
  - **Description**: `Five credits for virtual try-ons. Save 57% per credit compared to single purchase.`

### Product 3: Popular Pack (Most Popular)
- **Type**: Consumable
- **Reference Name**: `ColorMine - 15 Try-On Credits`
- **Product ID**: `com.colormineai.tryon.credits.15`
- **Price**: $34.00 USD (Tier 34)
- **Localizations (English - U.S.)**:
  - **Display Name**: `15 Try-On Credits`
  - **Description**: `Fifteen credits for virtual try-ons. Save 68% per credit. Most popular choice!`

### Product 4: Best Value Pack
- **Type**: Consumable
- **Reference Name**: `ColorMine - 30 Try-On Credits`
- **Product ID**: `com.colormineai.tryon.credits.30`
- **Price**: $55.00 USD (Tier 55)
- **Localizations (English - U.S.)**:
  - **Display Name**: `30 Try-On Credits`
  - **Description**: `Thirty credits for virtual try-ons. Save 74% per credit. Best value!`

---

## Step 3: App Review Information

For **each product**, fill in the App Review Information section:

### Screenshot for Review
You'll need to provide a screenshot showing where the in-app purchase appears in your app. You can use:
- A screenshot of the Credits Purchase screen (`CreditsPurchaseView`)
- Screenshot should show the credit packs with prices

### Review Notes
Add this note for App Review:
```
Try-On credits are used to generate photorealistic virtual try-on images.
Each credit allows one try-on generation using our AI technology.
Credits are consumed immediately upon generating a try-on result.

To test:
1. Complete the color analysis flow
2. Navigate to "Try-On" tab
3. Browse a fashion store and save a garment
4. Tap "Try It On" - this will prompt for credits if none available
5. Purchase credits and complete the try-on

Test credentials available upon request.
```

---

## Step 4: Availability

For each product:
- **Availability**: Select "All Territories" (or specific regions)
- **Status**: Set to **Ready to Submit** once all information is filled

---

## Step 5: Tax Category

- **Category**: Digital Goods and Services

---

## Step 6: Testing with Sandbox

### Create Sandbox Testers

1. In App Store Connect, go to **Users and Access**
2. Click **Sandbox Testers**
3. Create test accounts with unique email addresses
4. Use these accounts in Settings > App Store > Sandbox Account on your device

### Testing the Purchases

1. Build and run the app on a physical device or simulator
2. Complete the color analysis flow
3. Go to the Try-On tab
4. Browse a store and save a garment
5. Try to generate a try-on (will use credits)
6. When out of credits, tap the credits banner to open purchase view
7. Test purchasing each credit pack
8. Verify credits are added to your account

**Note**: Sandbox purchases are free and can be tested unlimited times.

---

## Pricing Strategy Breakdown

| Pack | Credits | Price | Per Credit | Savings vs Single |
|------|---------|-------|------------|-------------------|
| Single | 1 | $6.99 | $6.99 | — |
| Small | 5 | $15.00 | $3.00 | 57% off |
| Popular | 15 | $34.00 | $2.27 | 68% off |
| Best Value | 30 | $55.00 | $1.83 | 74% off |

This pricing encourages users to purchase larger packs for better value.

---

## Important Notes

### Product IDs Must Match Exactly
The product IDs in App Store Connect **must exactly match** the IDs in the code:
- `com.colormineai.tryon.credits.1`
- `com.colormineai.tryon.credits.5`
- `com.colormineai.tryon.credits.15`
- `com.colormineai.tryon.credits.30`

Any typo will cause purchases to fail.

### Bundle ID Must Match
Your app's bundle ID in Xcode must match the bundle ID in App Store Connect:
- Current Bundle ID: `com.colormineai`

### Consumable vs Non-Consumable
We use **consumable** products because:
- Credits are spent/consumed when used for try-ons
- Users can purchase the same pack multiple times
- Credits don't sync across devices (stored locally)

### Initial Credit Grant
New users get **3 free credits** when they complete color analysis.
See `PacksGenerationView.swift` for the initial credit grant logic.

---

## Troubleshooting

### "No products available"
- Verify product IDs match exactly in code and App Store Connect
- Ensure products are marked "Ready to Submit"
- Wait 2-4 hours after creating products for them to propagate
- Check that Agreements, Tax, and Banking info is complete

### Purchase fails
- Ensure using a Sandbox Tester account
- Check bundle ID matches between Xcode and App Store Connect
- Verify device is signed out of production App Store
- Check Console logs for specific StoreKit errors

### Credits not awarded
- Check that product ID matches in `CreditsManager.creditsForProduct()`
- Verify transaction is marked as `.verified`
- Look for "Credits awarded" log message

---

## Next Steps After Setup

1. ✅ Create all 4 products in App Store Connect
2. ✅ Take screenshots of the purchase screen
3. ✅ Set up sandbox tester accounts
4. ✅ Test all purchase flows
5. ✅ Verify credits are awarded correctly
6. ✅ Test restore purchases functionality
7. ✅ Submit for App Review along with app

---

## Code References

- **Product IDs**: `CreditsManager.swift:20`
- **Purchase Logic**: `CreditsManager.swift:55`
- **Credits Award Logic**: `CreditsManager.swift:138`
- **Purchase UI**: `CreditsPurchaseView.swift`
- **Credit Consumption**: `TryOnProcessView.swift:128`

---

**Need Help?** Consult [Apple's In-App Purchase Documentation](https://developer.apple.com/in-app-purchase/)
