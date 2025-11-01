//
//  SettingsView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import SwiftUI
import StoreKit
import MessageUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @AppStorage("appTheme") private var appTheme: String = "light"
    @State private var showMailComposer = false
    @State private var showBugReport = false
    @State private var showRestoreAlert = false
    @State private var restoreMessage = ""
    @State private var showClearDataConfirmation = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationStack {
            List {
                // MARK: - Appearance Section
                Section {
                    Picker("Theme", selection: $appTheme) {
                        HStack {
                            Image(systemName: "sun.max.fill")
                            Text("Light")
                        }
                        .tag("light")

                        HStack {
                            Image(systemName: "moon.fill")
                            Text("Dark")
                        }
                        .tag("dark")

                        HStack {
                            Image(systemName: "circle.lefthalf.filled")
                            Text("System")
                        }
                        .tag("system")
                    }
                    .pickerStyle(.inline)
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Choose your preferred color scheme. Light mode is the default.")
                }

                // MARK: - Purchases Section
                Section {
                    Button(action: restorePurchases) {
                        HStack {
                            Image(systemName: "arrow.clockwise.circle.fill")
                                .foregroundColor(.purple)
                                .font(.title3)

                            Text("Restore Purchases")
                                .foregroundColor(.primary)
                        }
                    }
                } header: {
                    Text("Purchases")
                }

                // MARK: - Data & Privacy Section
                Section {
                    Button(action: { showClearDataConfirmation = true }) {
                        HStack {
                            Image(systemName: "trash.fill")
                                .foregroundColor(.red)
                                .font(.title3)

                            Text("Clear All History")
                                .foregroundColor(.red)
                        }
                    }
                } header: {
                    Text("Data & Privacy")
                } footer: {
                    Text("This will permanently delete all saved garments, try-on history, and color analysis history. Your purchased credits will be preserved. This action cannot be undone.")
                }

                // MARK: - Support & Feedback Section
                Section {
                    Button(action: contactUs) {
                        HStack {
                            Image(systemName: "envelope.fill")
                                .foregroundColor(.purple)
                                .font(.title3)

                            Text("Contact Us")
                                .foregroundColor(.primary)

                            Spacer()

                            Text("hello@colormineai.com")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button(action: leaveReview) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.purple)
                                .font(.title3)

                            Text("Leave a Review")
                                .foregroundColor(.primary)
                        }
                    }

                    Button(action: reportBug) {
                        HStack {
                            Image(systemName: "ladybug.fill")
                                .foregroundColor(.purple)
                                .font(.title3)

                            Text("Report a Bug")
                                .foregroundColor(.primary)
                        }
                    }
                } header: {
                    Text("Support & Feedback")
                }

                // MARK: - Legal & About Section
                Section {
                    Link(destination: URL(string: "https://colormineai.com/privacy")!) {
                        HStack {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.purple)
                                .font(.title3)

                            Text("Privacy Policy")

                            Spacer()

                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://colormineai.com/terms")!) {
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.purple)
                                .font(.title3)

                            Text("Terms of Service")

                            Spacer()

                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://colormineai.com")!) {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.purple)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("About ColorMine AI")
                                Text("Version \(appVersion) (\(buildNumber))")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "arrow.up.right.square")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Legal & About")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .alert("Restore Purchases", isPresented: $showRestoreAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(restoreMessage)
            }
            .confirmationDialog("Clear All History", isPresented: $showClearDataConfirmation, titleVisibility: .visible) {
                Button("Clear All Data", role: .destructive) {
                    clearAllData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all saved garments, try-on history, and color analysis history. Your purchased credits will be preserved.")
            }
            .sheet(isPresented: $showMailComposer) {
                MailComposeView(
                    recipient: "hello@colormineai.com",
                    subject: "ColorMine AI Support",
                    body: """


                    ---
                    App Version: \(appVersion) (\(buildNumber))
                    iOS Version: \(UIDevice.current.systemVersion)
                    Device: \(UIDevice.current.model)
                    """
                )
            }
            .sheet(isPresented: $showBugReport) {
                MailComposeView(
                    recipient: "hello@colormineai.com",
                    subject: "ColorMine AI Bug Report",
                    body: """
                    Please describe the bug:



                    Steps to reproduce:
                    1.
                    2.
                    3.

                    Expected behavior:


                    Actual behavior:


                    ---
                    App Version: \(appVersion) (\(buildNumber))
                    iOS Version: \(UIDevice.current.systemVersion)
                    Device: \(UIDevice.current.model)
                    """
                )
            }
        }
    }

    // MARK: - Actions

    private func restorePurchases() {
        print("🔄 Restoring purchases...")

        Task {
            do {
                // Request restore from StoreKit
                try await AppStore.sync()

                // Show success message
                await MainActor.run {
                    restoreMessage = "Purchases restored successfully!"
                    showRestoreAlert = true
                    HapticManager.shared.success()
                }

                print("✅ Purchases restored")
            } catch {
                print("❌ Failed to restore purchases: \(error.localizedDescription)")

                await MainActor.run {
                    restoreMessage = "Unable to restore purchases. Please try again later."
                    showRestoreAlert = true
                    HapticManager.shared.error()
                }
            }
        }
    }

    private func contactUs() {
        print("📧 Opening contact email...")

        if MFMailComposeViewController.canSendMail() {
            showMailComposer = true
            HapticManager.shared.buttonTap()
        } else {
            // Fallback to mailto URL
            if let url = URL(string: "mailto:hello@colormineai.com") {
                UIApplication.shared.open(url)
            }
        }
    }

    private func leaveReview() {
        print("⭐ Requesting review...")

        // Request review using Apple's native prompt
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
            HapticManager.shared.buttonTap()
        }
    }

    private func reportBug() {
        print("🐛 Opening bug report...")

        if MFMailComposeViewController.canSendMail() {
            showBugReport = true
            HapticManager.shared.buttonTap()
        } else {
            // Fallback to mailto URL with subject
            let subject = "ColorMine AI Bug Report".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "mailto:hello@colormineai.com?subject=\(subject)") {
                UIApplication.shared.open(url)
            }
        }
    }

    private func clearAllData() {
        print("🗑️ Clearing all data...")

        appState.clearAllData()

        HapticManager.shared.success()
        print("✅ All data cleared successfully")
    }
}

// MARK: - Mail Compose View
struct MailComposeView: UIViewControllerRepresentable {
    let recipient: String
    let subject: String
    let body: String
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients([recipient])
        composer.setSubject(subject)
        composer.setMessageBody(body, isHTML: false)
        return composer
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView

        init(_ parent: MailComposeView) {
            self.parent = parent
        }

        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            if let error = error {
                print("❌ Mail compose error: \(error.localizedDescription)")
            }

            switch result {
            case .sent:
                print("✅ Email sent")
                HapticManager.shared.success()
            case .saved:
                print("📝 Email saved as draft")
            case .cancelled:
                print("❌ Email cancelled")
            case .failed:
                print("❌ Email failed to send")
                HapticManager.shared.error()
            @unknown default:
                break
            }

            parent.dismiss()
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
