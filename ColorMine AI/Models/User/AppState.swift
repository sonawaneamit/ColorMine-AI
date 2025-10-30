//
//  AppState.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import Foundation
import SwiftUI

@MainActor
class AppState: ObservableObject {
    @Published var currentProfile: UserProfile?
    @Published var isSubscribed: Bool = false
    @Published var isLoading: Bool = false
    @Published var profileHistory = ProfileHistory()

    let subscriptionManager = SubscriptionManager.shared
    let persistenceManager = PersistenceManager.shared

    // UserDefaults key for debug bypass
    private let debugBypassKey = "debugBypassEnabled"

    init() {
        // Load saved profile
        currentProfile = persistenceManager.loadProfile()

        // Load profile history
        profileHistory.loadFromStorage()

        // Track app session for review prompts
        ReviewManager.shared.incrementSessionCount()

        // Check if debug bypass was previously enabled
        #if DEBUG
        if UserDefaults.standard.bool(forKey: debugBypassKey) {
            isSubscribed = true
            print("🐛 DEBUG: Restored debug bypass from previous session")
        }
        #endif
    }

    // MARK: - Check Subscription on Launch
    func initialize() async {
        // Skip subscription check if debug bypass is active
        #if DEBUG
        if UserDefaults.standard.bool(forKey: debugBypassKey) {
            isSubscribed = true
            return
        }
        #endif

        await subscriptionManager.loadProducts()
        await subscriptionManager.checkSubscriptionStatus()
        isSubscribed = subscriptionManager.isSubscribed
    }

    // MARK: - Debug Bypass (DEBUG only)
    #if DEBUG
    func enableDebugBypass() {
        isSubscribed = true
        UserDefaults.standard.set(true, forKey: debugBypassKey)
        print("🐛 DEBUG: Paywall bypassed and saved for future sessions")
    }

    func disableDebugBypass() {
        isSubscribed = false
        UserDefaults.standard.set(false, forKey: debugBypassKey)
        print("🐛 DEBUG: Debug bypass disabled")
    }
    #endif

    // MARK: - Save Profile
    func saveProfile(_ profile: UserProfile) {
        currentProfile = profile
        persistenceManager.saveProfile(profile)
    }

    // MARK: - Clear Profile
    func clearProfile() {
        currentProfile = nil
        persistenceManager.deleteProfile()
    }

    // MARK: - Update Subscription Status
    func updateSubscriptionStatus() async {
        await subscriptionManager.checkSubscriptionStatus()
        isSubscribed = subscriptionManager.isSubscribed
    }
}
