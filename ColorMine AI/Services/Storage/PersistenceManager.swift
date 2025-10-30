//
//  PersistenceManager.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import Foundation

class PersistenceManager {
    static let shared = PersistenceManager()

    private let userProfileKey = "currentUserProfile"
    private let profileHistoryKey = "profileHistory"

    private init() {}

    // MARK: - Save User Profile
    func saveProfile(_ profile: UserProfile) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(profile)
            UserDefaults.standard.set(data, forKey: userProfileKey)
            print("✅ Profile saved")
        } catch {
            print("❌ Failed to save profile: \(error)")
        }
    }

    // MARK: - Load User Profile
    func loadProfile() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: userProfileKey) else {
            return nil
        }

        do {
            let decoder = JSONDecoder()
            let profile = try decoder.decode(UserProfile.self, from: data)
            return profile
        } catch {
            print("❌ Failed to load profile: \(error)")
            return nil
        }
    }

    // MARK: - Delete Profile
    func deleteProfile() {
        UserDefaults.standard.removeObject(forKey: userProfileKey)
        print("✅ Profile deleted")
    }

    // MARK: - Has Profile
    func hasProfile() -> Bool {
        return UserDefaults.standard.data(forKey: userProfileKey) != nil
    }

    // MARK: - Save Profile History
    func saveHistory(_ profiles: [HistoricalProfile]) {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(profiles)
            UserDefaults.standard.set(data, forKey: profileHistoryKey)
            print("✅ Profile history saved (\(profiles.count) profiles)")
        } catch {
            print("❌ Failed to save profile history: \(error)")
        }
    }

    // MARK: - Load Profile History
    func loadHistory() -> [HistoricalProfile] {
        guard let data = UserDefaults.standard.data(forKey: profileHistoryKey) else {
            return []
        }

        do {
            let decoder = JSONDecoder()
            let profiles = try decoder.decode([HistoricalProfile].self, from: data)
            return profiles
        } catch {
            print("❌ Failed to load profile history: \(error)")
            return []
        }
    }

    // MARK: - Clear History
    func clearHistory() {
        UserDefaults.standard.removeObject(forKey: profileHistoryKey)
        print("✅ Profile history cleared")
    }
}
