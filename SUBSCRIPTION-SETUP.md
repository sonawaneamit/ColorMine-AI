# Auto-Renewable Subscription Setup Guide

This guide will help you set up the ColorMine AI subscription plans in App Store Connect.

## Overview

ColorMine AI offers **auto-renewable subscriptions** that give users unlimited access to:
- AI color analysis
- Realistic AI visualizations
- Personalized palettes (makeup, hair, wardrobe)
- Unlimited pack generation

---

## Subscription Plans

| Plan | Duration | Price | Best For |
|------|----------|-------|----------|
| **Weekly** | 7 days | **$6.99** | Trial users, short-term needs |
| **Monthly** | 30 days | **$19.99** | Regular users (most popular) |

---

## Step 1: Create Subscription Group

Before creating individual subscriptions, you need to create a subscription group.

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click on **My Apps** > **ColorMine AI**
3. In the left sidebar, click **Subscriptions**
4. Click **+** to create a new subscription group
5. Fill in the details:

### Subscription Group Configuration

**Reference Name**: `ColorMine AI Premium`

**App Name** (shown on App Store): `ColorMine AI Premium`

---

## Step 2: Create Weekly Subscription

Click the **+** button in the subscription group to add a new subscription.

### Basic Information

- **Reference Name**: `ColorMine AI Premium - Weekly`
- **Product ID**: `com.colormineai.weekly`
- **Subscription Duration**: `7 Days (1 Week)`

### Subscription Pricing

- **Price**: `$6.99 USD` (Tier 7 or find $6.99 in pricing)
- **Territories**: All territories (or select specific regions)

### Subscription Localizations (English - U.S.)

**Display Name**: `Weekly Premium`

**Description**:
```
Get full access to ColorMine AI's professional color analysis tools:

• AI-powered color season detection
• Unlimited AI-generated style visualizations
• Personalized makeup, hair, and wardrobe palettes
• All current and future premium features

Your subscription automatically renews weekly. Cancel anytime in Settings.
```

### Review Information

**Screenshot**: Upload a screenshot showing the paywall or subscription features

**Review Notes**:
```
Weekly subscription provides unlimited access to all premium features:
- AI color analysis and season detection
- AI-generated style pack visualizations
- Personalized color palettes

To test subscription:
1. Launch app
2. Complete initial setup (or see paywall)
3. Select "Weekly" plan
4. Complete purchase flow

Sandbox tester credentials available upon request.
```

---

## Step 3: Create Monthly Subscription

Click **+** again in the subscription group to add the second subscription.

### Basic Information

- **Reference Name**: `ColorMine AI Premium - Monthly`
- **Product ID**: `com.colormineai.monthly`
- **Subscription Duration**: `1 Month (30 Days)`

### Subscription Pricing

- **Price**: `$19.99 USD` (Tier 20 or find $19.99 in pricing)
- **Territories**: All territories (or select specific regions)

### Subscription Localizations (English - U.S.)

**Display Name**: `Monthly Premium`

**Description**:
```
Get full access to ColorMine AI's professional color analysis tools:

• AI-powered color season detection
• Unlimited AI-generated style visualizations
• Personalized makeup, hair, and wardrobe palettes
• All current and future premium features

Your subscription automatically renews monthly. Cancel anytime in Settings. Save 34% compared to weekly!
```

### Review Information

**Screenshot**: Same screenshot as weekly (showing both options)

**Review Notes**:
```
Monthly subscription provides unlimited access to all premium features:
- AI color analysis and season detection
- AI-generated style pack visualizations
- Personalized color palettes

Monthly plan offers best value (20% savings vs weekly).

To test subscription:
1. Launch app
2. Complete initial setup (or see paywall)
3. Select "Monthly" plan
4. Complete purchase flow

Sandbox tester credentials available upon request.
```

---

## Step 4: Configure Subscription Group Settings

Back in the subscription group overview:

### Subscription Management

**Subscription Name**: `ColorMine AI Premium`

**Promotional Image** (1024x1024):
- Upload an image representing your subscription
- Should show color palettes, AI features, or app icon

### Free Trial (Optional)

If you want to offer a free trial:
- Click on a subscription
- Go to **Subscription Prices**
- Click **Set Introductory Price**
- Choose:
  - **Type**: Free trial
  - **Duration**: 3 days or 7 days
  - **Applies**: New subscribers only

**Recommended**: Offer 3-day free trial on monthly plan to reduce friction.

---

## Step 5: Set Subscription Ranking

Apple will ask you to rank subscriptions by value:

1. **Monthly** ($15.99) - Rank 1 (Best value)
2. **Weekly** ($4.99) - Rank 2 (Lower tier)

This ranking tells Apple which subscription provides better value and will affect how they're displayed in settings.

---

## Step 6: Submit for Review

### Before Submitting:

✅ Both subscriptions created with correct product IDs
✅ Pricing set correctly ($4.99 weekly, $15.99 monthly)
✅ Descriptions and localizations complete
✅ Screenshots uploaded
✅ Review notes added
✅ Free trial configured (if desired)

### Status:

Set both subscriptions to **"Ready to Submit"** when complete.

---

## Testing with Sandbox

### Create Sandbox Tester Accounts

1. In App Store Connect: **Users and Access** > **Sandbox Testers**
2. Create 2-3 test accounts with unique emails
3. Use these accounts to test subscriptions

### Testing Process

1. **Sign out** of production App Store on device
2. Open **Settings** > **App Store** > Scroll down to **Sandbox Account**
3. Sign in with sandbox tester account
4. Run your app from Xcode
5. Complete the purchase flow
6. Verify subscription status

### Accelerated Subscription Testing

Sandbox subscriptions renew much faster for testing:
- **7-day subscription** → Renews every **3 minutes**
- **1-month subscription** → Renews every **5 minutes**
- **Max 6 renewals** then expires (to test cancellation)

This lets you test the full subscription lifecycle quickly!

---

## Important Product ID Requirements

### Product IDs MUST Match Code

Your subscriptions **must** use these exact product IDs:

- Weekly: `com.colormineai.weekly`
- Monthly: `com.colormineai.monthly`

These IDs are hardcoded in `SubscriptionManager.swift` lines 20-21.

### Bundle ID

Your app's bundle ID must be: `com.colormineai`

---

## Subscription Features

When users subscribe, they get:

✅ **Unlimited AI Visualizations**: Generate as many style packs as they want
✅ **No Pack Generation Limits**: Remove any rate limits on pack creation
✅ **All Current Features**: Access everything in the app
✅ **Future Features**: Get new features as they're released

---

## Managing User Subscriptions

### Check Subscription Status

The app automatically checks subscription status using StoreKit:
```swift
await SubscriptionManager.shared.checkSubscriptionStatus()
```

### User Can Manage in Settings

Users can manage/cancel subscriptions:
- iOS Settings > [Their Name] > Subscriptions
- Or in-app: Call `SubscriptionManager.shared.manageSubscription()`

---

## Pricing Strategy

### Why These Prices?

**Weekly ($6.99)**:
- Low entry barrier for new users
- Good for users wanting to "try before commit"
- Allows short-term access without long commitment
- Annual value: ~$363 if user keeps it

**Monthly ($19.99)**:
- Sweet spot for pricing
- Saves 34% vs weekly ($30.26/month if paid weekly)
- Shows clear value of committing monthly
- Annual value: ~$240

### Price Comparison

| Duration | Price | Per Month | Annual Cost |
|----------|-------|-----------|-------------|
| Weekly | $6.99 | $30.26* | $363.48 |
| Monthly | $19.99 | $19.99 | $239.88 |

*If paid weekly throughout the month (4.33 weeks)

**The monthly plan saves users ~$124/year (34% savings)**

---

## Grace Period & Billing Retry

Apple automatically provides:
- **16-day grace period** if payment fails
- User keeps access during grace period
- Multiple billing retry attempts
- Emails to user about payment issue

You don't need to implement this - it's automatic!

---

## Family Sharing (Optional)

If you want to allow family sharing:
1. Select subscription in App Store Connect
2. Enable **"Available for Family Sharing"**
3. One subscriber can share with up to 5 family members

**Recommendation**: Enable this for goodwill, but monitor conversion impact.

---

## Troubleshooting

### "Products not loading"
- Verify product IDs match exactly: `com.colormineai.weekly` and `com.colormineai.monthly`
- Check subscriptions are marked "Ready to Submit" or "Approved"
- Wait 2-4 hours after creating for Apple's servers to sync
- Verify Agreements, Tax, and Banking info complete

### "Purchase fails in sandbox"
- Ensure using Sandbox Tester account (not production App Store)
- Device must be signed out of production App Store
- Check product IDs match in code and App Store Connect
- Try creating a new sandbox tester account

### "Subscription not detected"
- Check `Transaction.currentEntitlements` is being queried
- Verify transaction verification is passing
- Look for verification errors in console logs
- Try restoring purchases

---

## Next Steps After Setup

1. ✅ Create subscription group "ColorMine AI Premium"
2. ✅ Create weekly subscription ($4.99)
3. ✅ Create monthly subscription ($15.99)
4. ✅ Add descriptions and screenshots
5. ✅ Configure free trial (optional)
6. ✅ Set up sandbox testers
7. ✅ Test purchase flow thoroughly
8. ✅ Test subscription renewal (wait 3-5 mins in sandbox)
9. ✅ Test subscription cancellation
10. ✅ Submit for App Review

---

## Code References

- **Product IDs**: `SubscriptionManager.swift:20-21`
- **Subscription Check**: `SubscriptionManager.swift:44`
- **Purchase Logic**: `SubscriptionManager.swift:71`
- **Paywall UI**: `PaywallView.swift`
- **Subscription Status**: `AppState.swift`

---

## Resources

- [Apple Subscriptions Documentation](https://developer.apple.com/app-store/subscriptions/)
- [StoreKit 2 Documentation](https://developer.apple.com/documentation/storekit)
- [Subscription Best Practices](https://developer.apple.com/app-store/subscriptions/best-practices/)

---

**Need Help?** Check Apple's [In-App Purchase FAQ](https://developer.apple.com/help/app-store-connect/test-in-app-purchases/overview-of-sandbox-testing) for sandbox testing issues.
