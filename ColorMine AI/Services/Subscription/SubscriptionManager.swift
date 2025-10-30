//
//  SubscriptionManager.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import Foundation
import StoreKit

@MainActor
class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published var isSubscribed: Bool = false
    @Published var subscriptionTier: SubscriptionTier?
    @Published var products: [Product] = []

    // Product IDs - MUST match App Store Connect
    private let weeklyProductID = "com.colormineai.weekly"
    private let monthlyProductID = "com.colormineai.monthly"

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products
    func loadProducts() async {
        do {
            products = try await Product.products(for: [weeklyProductID, monthlyProductID])
            print("✅ Loaded \(products.count) products")
        } catch {
            print("❌ Failed to load products: \(error)")
        }
    }

    // MARK: - Check Subscription Status
    func checkSubscriptionStatus() async {
        var validSubscription: Transaction? = nil

        // Check all transactions
        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Check if subscription is active
                if transaction.productID == weeklyProductID || transaction.productID == monthlyProductID {
                    validSubscription = transaction
                }
            } catch {
                print("Transaction verification failed: \(error)")
            }
        }

        isSubscribed = validSubscription != nil

        if let transaction = validSubscription {
            subscriptionTier = transaction.productID == weeklyProductID ? .weekly : .monthly
        } else {
            subscriptionTier = nil
        }
    }

    // MARK: - Purchase
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await checkSubscriptionStatus()

        case .userCancelled:
            throw SubscriptionError.userCancelled

        case .pending:
            throw SubscriptionError.pending

        @unknown default:
            throw SubscriptionError.unknown
        }
    }

    // MARK: - Restore Purchases
    func restorePurchases() async {
        try? await AppStore.sync()
        await checkSubscriptionStatus()
    }

    // MARK: - Manage Subscription
    func manageSubscription() async {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            do {
                try await AppStore.showManageSubscriptions(in: windowScene)
            } catch {
                print("Failed to show manage subscriptions: \(error)")
            }
        }
    }

    // MARK: - Listen for Transactions
    private func listenForTransactions() -> Task<Void, Error> {
        return Task.detached {
            for await result in Transaction.updates {
                do {
                    // Verify transaction
                    let transaction: Transaction
                    switch result {
                    case .unverified:
                        throw SubscriptionError.failedVerification
                    case .verified(let safe):
                        transaction = safe
                    }

                    await transaction.finish()

                    // Update subscription status on main actor
                    await Task { @MainActor in
                        await self.checkSubscriptionStatus()
                    }.value
                } catch {
                    print("Transaction update failed: \(error)")
                }
            }
        }
    }

    // MARK: - Verify Transaction
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw SubscriptionError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    // MARK: - Get Product
    func getProduct(for tier: SubscriptionTier) -> Product? {
        let productID = tier == .weekly ? weeklyProductID : monthlyProductID
        return products.first { $0.id == productID }
    }
}

// MARK: - Subscription Tier
enum SubscriptionTier {
    case weekly  // $6.99
    case monthly // $19.99

    var displayName: String {
        switch self {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        }
    }
}

// MARK: - Subscription Errors
enum SubscriptionError: LocalizedError {
    case userCancelled
    case pending
    case failedVerification
    case unknown

    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Purchase was cancelled"
        case .pending:
            return "Purchase is pending approval"
        case .failedVerification:
            return "Purchase verification failed"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}
