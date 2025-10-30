//
//  HistoricalProfile.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import Foundation
import UIKit

/// Represents a snapshot of a user's profile at a specific point in time
struct HistoricalProfile: Identifiable, Codable {
    let id: UUID
    let timestamp: Date
    let profile: UserProfile

    init(id: UUID = UUID(), timestamp: Date = Date(), profile: UserProfile) {
        self.id = id
        self.timestamp = timestamp
        self.profile = profile
    }

    /// Display name showing date and season
    var displayName: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return "\(formatter.string(from: timestamp)) - \(profile.season.rawValue)"
    }

    /// Short date for list display
    var shortDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: timestamp)
    }

    /// Thumbnail image (uses selfie or drapes)
    var thumbnailImage: UIImage? {
        if let selfieImage = profile.selfieImage {
            return selfieImage
        }
        if let drapesURL = profile.drapesGridImageURL {
            return UIImage(contentsOfFile: drapesURL.path)
        }
        return nil
    }
}

/// Manages the collection of historical profiles
class ProfileHistory: ObservableObject {
    @Published var profiles: [HistoricalProfile] = []

    /// Add a new profile to history
    func addProfile(_ profile: UserProfile) {
        let historical = HistoricalProfile(profile: profile)
        profiles.insert(historical, at: 0) // Most recent first
        saveToStorage()
    }

    /// Delete a profile from history
    func deleteProfile(_ id: UUID) {
        profiles.removeAll { $0.id == id }
        saveToStorage()
    }

    /// Get profiles sorted chronologically (most recent first)
    func sortedProfiles() -> [HistoricalProfile] {
        return profiles.sorted { $0.timestamp > $1.timestamp }
    }

    /// Save to persistent storage
    private func saveToStorage() {
        PersistenceManager.shared.saveHistory(profiles)
    }

    /// Load from persistent storage
    func loadFromStorage() {
        profiles = PersistenceManager.shared.loadHistory()
    }
}
