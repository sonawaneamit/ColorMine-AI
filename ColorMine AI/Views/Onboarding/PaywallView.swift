//
//  PaywallView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var subscriptionManager = SubscriptionManager.shared

    @State private var selectedTier: SubscriptionTier = .monthly
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.pink.opacity(0.3), Color.orange.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    Spacer().frame(height: 40)

                    // App Icon/Logo
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink, .orange],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Title
                    VStack(spacing: 12) {
                        Text("ColorMine AI")
                            .font(.system(size: 42, weight: .bold))

                        Text("Discover Your Perfect Colors with AI")
                            .font(.title3)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Features
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(
                            icon: "camera.fill",
                            title: "AI Color Analysis",
                            subtitle: "Professional color season detection"
                        )
                        FeatureRow(
                            icon: "sparkles",
                            title: "Realistic AI Visualizations",
                            subtitle: "See yourself in your perfect colors"
                        )
                        FeatureRow(
                            icon: "paintbrush.fill",
                            title: "Personalized Palettes",
                            subtitle: "Makeup, hair, and wardrobe guidance"
                        )
                        FeatureRow(
                            icon: "star.fill",
                            title: "Unlimited Access",
                            subtitle: "Generate as many looks as you want"
                        )
                    }
                    .padding(.horizontal, 30)

                    // Subscription Tiers
                    VStack(spacing: 16) {
                        Text("Choose Your Plan")
                            .font(.title2)
                            .fontWeight(.bold)

                        // Monthly
                        SubscriptionTierCard(
                            tier: .monthly,
                            price: "$19.99",
                            period: "per month",
                            isSelected: selectedTier == .monthly
                        ) {
                            selectedTier = .monthly
                        }

                        // Weekly
                        SubscriptionTierCard(
                            tier: .weekly,
                            price: "$6.99",
                            period: "per week",
                            isSelected: selectedTier == .weekly
                        ) {
                            selectedTier = .weekly
                        }
                    }
                    .padding(.horizontal, 30)

                    // Subscribe Button
                    Button(action: {
                        purchase()
                    }) {
                        HStack {
                            if isPurchasing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "crown.fill")
                                Text("Start Now")
                                    .font(.headline)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .purple.opacity(0.3), radius: 10, y: 5)
                    }
                    .disabled(isPurchasing)
                    .padding(.horizontal, 30)

                    // Restore Button
                    Button("Restore Purchase") {
                        restorePurchases()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    // Terms
                    Text("Auto-renewing subscription • Cancel anytime")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 30)

                    #if DEBUG
                    // Debug bypass button - only visible in debug builds
                    Button(action: {
                        debugBypass()
                    }) {
                        HStack {
                            Image(systemName: "ant.circle.fill")
                            Text("Debug: Skip Paywall")
                        }
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.8))
                        .cornerRadius(8)
                    }
                    .padding(.top, 20)
                    #endif

                    Spacer().frame(height: 20)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Purchase
    private func purchase() {
        Task {
            isPurchasing = true

            do {
                guard let product = subscriptionManager.getProduct(for: selectedTier) else {
                    throw SubscriptionError.unknown
                }

                try await subscriptionManager.purchase(product)
                await appState.updateSubscriptionStatus()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }

            isPurchasing = false
        }
    }

    // MARK: - Restore
    private func restorePurchases() {
        Task {
            await subscriptionManager.restorePurchases()
            await appState.updateSubscriptionStatus()
        }
    }

    // MARK: - Debug Bypass (DEBUG only)
    #if DEBUG
    private func debugBypass() {
        // Mark as subscribed and persist for future sessions
        // This only works in debug builds
        appState.enableDebugBypass()
    }
    #endif
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.purple)
                .frame(width: 40)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

struct SubscriptionTierCard: View {
    let tier: SubscriptionTier
    let price: String
    let period: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tier.displayName)
                        .font(.headline)
                    Text(period)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(price)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .purple : .primary)

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .purple : .gray)
                    .font(.title2)
            }
            .padding()
            .background(isSelected ? Color.purple.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color.gray.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PaywallView()
        .environmentObject(AppState())
}
