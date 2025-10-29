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
}
