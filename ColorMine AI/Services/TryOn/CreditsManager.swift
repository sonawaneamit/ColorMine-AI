//
//  CreditsManager.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import Foundation
import StoreKit

/// Manages try-on credits and in-app purchases
@MainActor
class CreditsManager: ObservableObject {
    static let shared = CreditsManager()

    @Published private(set) var availableProducts: [Product] = []
    @Published private(set) var isLoading = false

    // Product IDs (must match App Store Connect)
    private let productIDs = [
        "com.colormineai.tryon.credits.1",    // 1 credit - $6.99
        "com.colormineai.tryon.credits.5",    // 5 credits - $15.00 ($3.00 ea, save 57%)
        "com.colormineai.tryon.credits.15",   // 15 credits - $34.00 ($2.27 ea, save 68%)
        "com.colormineai.tryon.credits.30"    // 30 credits - $55.00 ($1.83 ea, save 74%)
    ]

    private var updateListenerTask: Task<Void, Error>?

    private init() {
        // Start listening for transaction updates
        updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Load Products
    /// Load available credit packs from App Store
    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let products = try await Product.products(for: productIDs)
            availableProducts = products.sorted { $0.price < $1.price }
            print("✅ Loaded \(products.count) credit products")
        } catch {
            print("❌ Failed to load products: \(error)")
        }
    }

    // MARK: - Purchase Credits
    /// Purchase a credit pack
    func purchase(_ product: Product, for profile: inout UserProfile) async throws {
        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)

            // Award credits based on product
            let creditsAwarded = creditsForProduct(product)
            profile.tryOnCredits += creditsAwarded

            print("✅ Credits awarded: \(creditsAwarded)")

            // Finish transaction
            await transaction.finish()

        case .userCancelled:
            print("ℹ️ Purchase cancelled by user")
            throw CreditsError.userCancelled

        case .pending:
            print("⏳ Purchase pending approval")
            throw CreditsError.pending

        @unknown default:
            print("❌ Unknown purchase result")
            throw CreditsError.unknown
        }
    }

    // MARK: - Restore Purchases
    /// Restore previous credit purchases
    func restorePurchases(for profile: inout UserProfile) async {
        var totalRestored = 0

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)

                // Note: For consumables, this won't restore credits
                // This is mainly for debugging/verification
                print("ℹ️ Found transaction: \(transaction.productID)")

                await transaction.finish()
            } catch {
                print("❌ Failed to verify transaction: \(error)")
            }
        }

        if totalRestored > 0 {
            print("✅ Restored \(totalRestored) credits")
        } else {
            print("ℹ️ No purchases to restore")
        }
    }

    // MARK: - Listen for Transactions
    /// Listen for transaction updates in the background
    private func listenForTransactions() -> Task<Void, Error> {
        return Task {
            for await result in Transaction.updates {
                do {
                    let transaction = try self.checkVerified(result)
                    await transaction.finish()
                } catch {
                    print("❌ Transaction verification failed: \(error)")
                }
            }
        }
    }

    // MARK: - Helpers
    /// Verify transaction is legitimate
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw CreditsError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }

    /// Get credits amount for a product
    private func creditsForProduct(_ product: Product) -> Int {
        switch product.id {
        case "com.colormineai.tryon.credits.1":
            return 1
        case "com.colormineai.tryon.credits.5":
            return 5
        case "com.colormineai.tryon.credits.15":
            return 15
        case "com.colormineai.tryon.credits.30":
            return 30
        default:
            return 0
        }
    }

    /// Format credits as display string
    static func formatCredits(_ count: Int) -> String {
        if count == 1 {
            return "1 credit"
        } else {
            return "\(count) credits"
        }
    }
}

// MARK: - Credits Error
enum CreditsError: LocalizedError {
    case userCancelled
    case pending
    case verificationFailed
    case unknown
    case insufficientCredits

    var errorDescription: String? {
        switch self {
        case .userCancelled:
            return "Purchase was cancelled"
        case .pending:
            return "Purchase is pending approval"
        case .verificationFailed:
            return "Could not verify purchase"
        case .unknown:
            return "An unknown error occurred"
        case .insufficientCredits:
            return "You don't have enough credits"
        }
    }
}
