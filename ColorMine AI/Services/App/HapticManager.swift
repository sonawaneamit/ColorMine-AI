//
//  HapticManager.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import UIKit

/// Manages haptic feedback throughout the app to create satisfying milestone moments
class HapticManager {

    static let shared = HapticManager()

    private init() {}

    // MARK: - Feedback Generators

    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let notification = UINotificationFeedbackGenerator()
    private let selection = UISelectionFeedbackGenerator()

    // MARK: - Milestone Haptics

    /// Light tap feedback for color selection and UI interactions
    func colorSelected() {
        selection.selectionChanged()
    }

    /// Medium impact when season analysis completes - "You are [Season]"
    func seasonDiscovered() {
        mediumImpact.prepare()
        mediumImpact.impactOccurred()
    }

    /// Heavy impact for the drapes grid reveal - First "wow" moment
    func drapesRevealed() {
        heavyImpact.prepare()
        heavyImpact.impactOccurred()
    }

    /// Light impact when starting pack generation
    func packGenerationStarted() {
        lightImpact.prepare()
        lightImpact.impactOccurred()
    }

    /// Medium impact when each individual pack completes
    func packCompleted() {
        mediumImpact.prepare()
        mediumImpact.impactOccurred()
    }

    /// Success notification when all packs are complete - Final celebration
    func allPacksCompleted() {
        notification.prepare()
        notification.notificationOccurred(.success)
    }

    /// Light tap for general button presses and UI feedback
    func buttonTap() {
        lightImpact.prepare()
        lightImpact.impactOccurred(intensity: 0.7)
    }

    /// Success feedback for positive actions (sharing, saving)
    func success() {
        notification.prepare()
        notification.notificationOccurred(.success)
    }

    /// Warning feedback for edge cases
    func warning() {
        notification.prepare()
        notification.notificationOccurred(.warning)
    }

    /// Error feedback for failures
    func error() {
        notification.prepare()
        notification.notificationOccurred(.error)
    }
}
