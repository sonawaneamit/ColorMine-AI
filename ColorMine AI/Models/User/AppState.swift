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
    @Published var navigationResetID: UUID = UUID()  // Forces navigation stack to reset
    @Published var isSavingGarment: Bool = false  // Tracks when a garment is being saved from browser

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

    // MARK: - Clear Profile (Start Over)
    /// Clear profile for "Start Over" - preserves credits, garments, and history
    func clearProfile() {
        // Preserve important data before clearing
        let creditsToPreserve = currentProfile?.tryOnCredits ?? 0
        let garmentsToPreserve = currentProfile?.savedGarments ?? []
        let historyToPreserve = currentProfile?.tryOnHistory ?? []

        // Clear current profile
        currentProfile = nil
        persistenceManager.deleteProfile()

        // Force navigation stack to reset by changing the ID
        navigationResetID = UUID()

        print("🔄 Navigation reset - returning to scan view")
        print("💾 Preserved: \(creditsToPreserve) credits, \(garmentsToPreserve.count) garments, \(historyToPreserve.count) try-on results")

        // Store preserved data temporarily
        UserDefaults.standard.set(creditsToPreserve, forKey: "preservedCredits")
        if let garmentsData = try? JSONEncoder().encode(garmentsToPreserve) {
            UserDefaults.standard.set(garmentsData, forKey: "preservedGarments")
        }
        if let historyData = try? JSONEncoder().encode(historyToPreserve) {
            UserDefaults.standard.set(historyData, forKey: "preservedHistory")
        }
    }

    // MARK: - Restore Preserved Data
    /// Restore preserved data after creating a new profile
    func restorePreservedData(to profile: inout UserProfile) {
        // Restore credits
        let preservedCredits = UserDefaults.standard.integer(forKey: "preservedCredits")
        if preservedCredits > 0 {
            profile.tryOnCredits = preservedCredits
            print("✅ Restored \(preservedCredits) credits")
        }

        // Restore garments
        if let garmentsData = UserDefaults.standard.data(forKey: "preservedGarments"),
           let garments = try? JSONDecoder().decode([GarmentItem].self, from: garmentsData) {
            profile.savedGarments = garments
            print("✅ Restored \(garments.count) saved garments")
        }

        // Restore history
        if let historyData = UserDefaults.standard.data(forKey: "preservedHistory"),
           let history = try? JSONDecoder().decode([TryOnResult].self, from: historyData) {
            profile.tryOnHistory = history
            print("✅ Restored \(history.count) try-on results")
        }

        // Clear preserved data from UserDefaults
        UserDefaults.standard.removeObject(forKey: "preservedCredits")
        UserDefaults.standard.removeObject(forKey: "preservedGarments")
        UserDefaults.standard.removeObject(forKey: "preservedHistory")
    }

    // MARK: - Clear All Data (Complete Wipe)
    /// Complete wipe of all data EXCEPT credits (purchased with real money)
    func clearAllData() {
        // Preserve credits - they are purchased with real money and should NEVER be deleted
        let creditsToPreserve = currentProfile?.tryOnCredits ?? 0

        // Clear current profile
        currentProfile = nil
        persistenceManager.deleteProfile()

        // Clear profile history
        profileHistory.clearAll()

        // Clear garments and try-on history but preserve credits
        UserDefaults.standard.removeObject(forKey: "preservedGarments")
        UserDefaults.standard.removeObject(forKey: "preservedHistory")

        // Store preserved credits
        if creditsToPreserve > 0 {
            UserDefaults.standard.set(creditsToPreserve, forKey: "preservedCredits")
            print("💾 Preserved \(creditsToPreserve) credits (purchased with real money)")
        }

        // Force navigation stack to reset
        navigationResetID = UUID()

        print("🗑️ All data cleared - credits preserved")
    }

    // MARK: - Update Subscription Status
    func updateSubscriptionStatus() async {
        await subscriptionManager.checkSubscriptionStatus()
        isSubscribed = subscriptionManager.isSubscribed
    }
}
