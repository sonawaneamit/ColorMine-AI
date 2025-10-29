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

    let subscriptionManager = SubscriptionManager.shared
    let persistenceManager = PersistenceManager.shared

    init() {
        // Load saved profile
        currentProfile = persistenceManager.loadProfile()
    }

    // MARK: - Check Subscription on Launch
    func initialize() async {
        await subscriptionManager.loadProducts()
        await subscriptionManager.checkSubscriptionStatus()
        isSubscribed = subscriptionManager.isSubscribed
    }

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
