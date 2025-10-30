//
//  ReviewManager.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import Foundation
import StoreKit
import SwiftUI

// iOS 18+ uses AppStore framework
#if canImport(AppStore)
import AppStore
#endif

class ReviewManager {
    static let shared = ReviewManager()

    private let lastReviewRequestKey = "lastReviewRequestDate"
    private let reviewRequestCountKey = "reviewRequestCount"
    private let hasRequestedAfterDrapesKey = "hasRequestedAfterDrapes"
    private let hasRequestedAfterPacksKey = "hasRequestedAfterPacks"
    private let hasRequestedAfterShareKey = "hasRequestedAfterShare"
    private let sessionCountKey = "appSessionCount"

    // Minimum days between review requests
    private let minimumDaysBetweenRequests: TimeInterval = 5 * 24 * 60 * 60 // 5 days

    // Minimum sessions before asking
    private let minimumSessionsBeforeFirstRequest = 2

    private init() {}

    // MARK: - Track App Sessions
    func incrementSessionCount() {
        let currentCount = UserDefaults.standard.integer(forKey: sessionCountKey)
        UserDefaults.standard.set(currentCount + 1, forKey: sessionCountKey)
        print("📱 Session count: \(currentCount + 1)")
    }

    // MARK: - Request Review After Drapes Generation
    func requestReviewAfterDrapes() {
        let context = ReviewContext(
            moment: "after drapes generation",
            priority: .high,
            requiresMinimumSessions: true
        )

        // Check if already asked after drapes
        guard !UserDefaults.standard.bool(forKey: hasRequestedAfterDrapesKey) else {
            print("⏭️ Already requested review after drapes")
            return
        }

        requestReviewIfEligible(context: context) { success in
            if success {
                UserDefaults.standard.set(true, forKey: self.hasRequestedAfterDrapesKey)
            }
        }
    }

    // MARK: - Request Review After All Packs Complete
    func requestReviewAfterPacksComplete() {
        let context = ReviewContext(
            moment: "after packs complete",
            priority: .high,
            requiresMinimumSessions: false // They've seen enough value
        )

        // Check if already asked after packs
        guard !UserDefaults.standard.bool(forKey: hasRequestedAfterPacksKey) else {
            print("⏭️ Already requested review after packs")
            return
        }

        requestReviewIfEligible(context: context) { success in
            if success {
                UserDefaults.standard.set(true, forKey: self.hasRequestedAfterPacksKey)
            }
        }
    }

    // MARK: - Request Review After Share/Save
    func requestReviewAfterShare() {
        let context = ReviewContext(
            moment: "after sharing image",
            priority: .medium,
            requiresMinimumSessions: false
        )

        // Check if already asked after share
        guard !UserDefaults.standard.bool(forKey: hasRequestedAfterShareKey) else {
            print("⏭️ Already requested review after share")
            return
        }

        requestReviewIfEligible(context: context) { success in
            if success {
                UserDefaults.standard.set(true, forKey: self.hasRequestedAfterShareKey)
            }
        }
    }

    // MARK: - Core Review Request Logic
    private func requestReviewIfEligible(
        context: ReviewContext,
        completion: @escaping (Bool) -> Void
    ) {
        // Check session count if required
        if context.requiresMinimumSessions {
            let sessionCount = UserDefaults.standard.integer(forKey: sessionCountKey)
            guard sessionCount >= minimumSessionsBeforeFirstRequest else {
                print("⏭️ Not enough sessions yet (\(sessionCount)/\(minimumSessionsBeforeFirstRequest))")
                completion(false)
                return
            }
        }

        // Check time since last request
        if let lastRequestDate = UserDefaults.standard.object(forKey: lastReviewRequestKey) as? Date {
            let timeSinceLastRequest = Date().timeIntervalSince(lastRequestDate)
            guard timeSinceLastRequest >= minimumDaysBetweenRequests else {
                let daysRemaining = (minimumDaysBetweenRequests - timeSinceLastRequest) / (24 * 60 * 60)
                print("⏭️ Too soon to ask again (wait \(String(format: "%.1f", daysRemaining)) more days)")
                completion(false)
                return
            }
        }

        // Check request count (soft limit before Apple's hard limit)
        let requestCount = UserDefaults.standard.integer(forKey: reviewRequestCountKey)
        guard requestCount < 3 else {
            print("⏭️ Already asked 3 times (respecting Apple's limit)")
            completion(false)
            return
        }

        // All checks passed - request review!
        print("⭐ Requesting review \(context.moment) (priority: \(context.priority))")

        // Wait 2 seconds for user to appreciate the moment
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                // Use the appropriate API based on iOS version
                if #available(iOS 18.0, *) {
                    // iOS 18+ uses new API
                    AppStore.requestReview(in: windowScene)
                } else {
                    // iOS 17 and below use old API
                    SKStoreReviewController.requestReview(in: windowScene)
                }

                // Update tracking
                UserDefaults.standard.set(Date(), forKey: self.lastReviewRequestKey)
                UserDefaults.standard.set(requestCount + 1, forKey: self.reviewRequestCountKey)

                print("✅ Review prompt shown (total: \(requestCount + 1)/3)")
                completion(true)
            } else {
                print("❌ Could not show review prompt (no window scene)")
                completion(false)
            }
        }
    }

    // MARK: - Reset for Testing
    #if DEBUG
    func resetReviewTracking() {
        UserDefaults.standard.removeObject(forKey: lastReviewRequestKey)
        UserDefaults.standard.removeObject(forKey: reviewRequestCountKey)
        UserDefaults.standard.removeObject(forKey: hasRequestedAfterDrapesKey)
        UserDefaults.standard.removeObject(forKey: hasRequestedAfterPacksKey)
        UserDefaults.standard.removeObject(forKey: hasRequestedAfterShareKey)
        print("🔄 Review tracking reset")
    }
    #endif
}

// MARK: - Review Context
private struct ReviewContext {
    let moment: String
    let priority: Priority
    let requiresMinimumSessions: Bool

    enum Priority: String {
        case high = "HIGH"
        case medium = "MEDIUM"
        case low = "LOW"
    }
}
