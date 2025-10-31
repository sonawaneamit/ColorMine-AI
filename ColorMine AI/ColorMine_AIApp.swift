//
//  ColorMine_AIApp.swift
//  ColorMine AI
//
//  Created by Amit on 29/10/2025.
//

import SwiftUI
import UserNotifications

@main
struct ColorMine_AIApp: App {
    @StateObject private var appState = AppState()
    @AppStorage("appTheme") private var appTheme: String = "light"

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                RootView()
                    .environmentObject(appState)
                    .task {
                        await appState.initialize()
                    }
            }
            .id(appState.navigationResetID)  // Reset navigation when retaking selfie
            .preferredColorScheme(colorScheme)
        }
    }

    private var colorScheme: ColorScheme? {
        switch appTheme {
        case "light":
            return .light
        case "dark":
            return .dark
        default:
            return nil  // System default
        }
    }
}

// MARK: - Root View
struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isLoading {
                // Loading screen
                LoadingView()
            } else if !appState.isSubscribed {
                // Show paywall if not subscribed
                PaywallView()
            } else if let profile = appState.currentProfile {
                // Check if profile flow is complete
                if profile.favoriteColors.isEmpty {
                    // Step 1: Choose favorite colors (3-12)
                    PaletteSelectionView(profile: profile)
                } else if profile.drapesGridImageURL == nil {
                    // Step 2: Generate drapes (should auto-generate, but show selection again)
                    PaletteSelectionView(profile: profile)
                } else if profile.focusColor == nil {
                    // Step 3: Pick focus color from drapes
                    DrapesGridView(profile: profile)
                } else if !profile.hasChosenPacks {
                    // Step 4: Choose which packs to generate
                    FocusColorView(profile: profile)
                } else if !profile.packsGenerated.allGenerated(selectedPacks: profile.selectedPacks) {
                    // Step 5: Generate selected AI packs
                    PacksGenerationView(profile: profile)
                } else {
                    // Step 6: Profile complete - show dashboard
                    ProfileDashboardView()
                }
            } else {
                // Show scan view if subscribed but no profile
                ScanView()
            }
        }
        .onAppear {
            requestNotificationPermissions()
        }
    }

    private func requestNotificationPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ Notification permissions granted")
            } else if let error = error {
                print("❌ Notification permission error: \(error)")
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text("ColorMine AI")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                ProgressView()
                    .scaleEffect(1.5)
            }
        }
    }
}
