//
//  NotificationManager.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false

    private init() {}

    // MARK: - Request Authorization
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            )
            isAuthorized = granted
            return granted
        } catch {
            print("❌ Notification authorization error: \(error)")
            isAuthorized = false
            return false
        }
    }

    // MARK: - Check Authorization Status
    func checkAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Send Pack Completion Notification
    func sendPackCompletionNotification(packType: PackType) {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "✨ Your \(packType.rawValue) is Ready!"
        content.body = "Tap to view your personalized style guide"
        content.sound = .default
        content.badge = 1

        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "pack-\(packType.rawValue)-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error)")
            }
        }
    }

    // MARK: - Send All Packs Complete Notification
    func sendAllPacksCompleteNotification() {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = "🎉 Your Style Guide is Complete!"
        content.body = "All your personalized packs are ready to explore"
        content.sound = .default
        content.badge = 1

        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)

        let request = UNNotificationRequest(
            identifier: "all-packs-complete-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to schedule notification: \(error)")
            }
        }
    }

    // MARK: - Clear Badge
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
}
