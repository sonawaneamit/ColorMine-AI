//
//  CreditsPurchaseView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import SwiftUI
import StoreKit

struct CreditsPurchaseView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var creditsManager = CreditsManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    var currentCredits: Int {
        appState.currentProfile?.tryOnCredits ?? 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection

                        // Current balance
                        currentBalanceCard

                        // Credit packs
                        if creditsManager.isLoading {
                            ProgressView()
                                .padding()
                        } else if creditsManager.availableProducts.isEmpty {
                            noProductsView
                        } else {
                            creditPacksSection
                        }

                        // How it works
                        howItWorksSection

                        Spacer().frame(height: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Try-On Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Restore") {
                        restorePurchases()
                    }
                    .disabled(isPurchasing)
                }
            }
            .alert("Purchase Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .alert("Credits Added!", isPresented: $showSuccess) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Your credits have been added to your account")
            }
            .task {
                await creditsManager.loadProducts()
            }
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text("Get More Try-Ons")
                .font(.title2)
                .fontWeight(.bold)

            Text("Each try-on uses 3 credits to generate photorealistic results")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.top, 20)
    }

    // MARK: - Current Balance
    private var currentBalanceCard: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Balance")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(CreditsManager.formatCredits(currentCredits))
                    .font(.title)
                    .fontWeight(.bold)
            }

            Spacer()

            Image(systemName: "sparkles")
                .font(.title)
                .foregroundColor(.purple)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Credit Packs
    private var creditPacksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Choose Your Pack")
                .font(.headline)
                .padding(.horizontal, 4)

            ForEach(creditsManager.availableProducts) { product in
                CreditPackCard(
                    product: product,
                    isPurchasing: isPurchasing
                ) {
                    purchaseProduct(product)
                }
            }
        }
    }

    // MARK: - How It Works
    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How Credits Work")
                .font(.headline)

            VStack(alignment: .leading, spacing: 10) {
                HowItWorksRow(
                    icon: "photo.fill",
                    text: "Save garments from any store"
                )
                HowItWorksRow(
                    icon: "wand.and.stars",
                    text: "Use 3 credits per try-on"
                )
                HowItWorksRow(
                    icon: "paintpalette.fill",
                    text: "Get color analysis with every result"
                )
                HowItWorksRow(
                    icon: "leaf.fill",
                    text: "Shop smarter, reduce waste"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - No Products
    private var noProductsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Unable to load credit packs")
                .font(.headline)

            Text("Please check your internet connection and try again")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Retry") {
                Task {
                    await creditsManager.loadProducts()
                }
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }

    // MARK: - Purchase Product
    private func purchaseProduct(_ product: Product) {
        guard var profile = appState.currentProfile else {
            errorMessage = "No profile found"
            showError = true
            return
        }

        isPurchasing = true

        Task {
            do {
                try await creditsManager.purchase(product, for: &profile)

                // Save updated profile
                appState.saveProfile(profile)

                // Show success
                showSuccess = true

                // Haptic feedback
                HapticManager.shared.success()

            } catch CreditsError.userCancelled {
                // User cancelled - don't show error
                print("ℹ️ User cancelled purchase")
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }

            isPurchasing = false
        }
    }

    // MARK: - Restore Purchases
    private func restorePurchases() {
        guard var profile = appState.currentProfile else { return }

        Task {
            await creditsManager.restorePurchases(for: &profile)
            appState.saveProfile(profile)
        }
    }
}

// MARK: - Credit Pack Card
struct CreditPackCard: View {
    let product: Product
    let isPurchasing: Bool
    let action: () -> Void

    private var creditAmount: Int {
        switch product.id {
        case "com.colormine.tryon.credits.10":
            return 10
        case "com.colormine.tryon.credits.30":
            return 30
        case "com.colormine.tryon.credits.100":
            return 100
        default:
            return 0
        }
    }

    private var tryOnCount: Int {
        creditAmount / 3
    }

    private var isPopular: Bool {
        creditAmount == 30
    }

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text("\(creditAmount) Credits")
                            .font(.headline)
                            .foregroundColor(.primary)

                        if isPopular {
                            Text("POPULAR")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.purple)
                                )
                        }
                    }

                    Text("~\(tryOnCount) try-ons")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.purple)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isPopular ? Color.purple : Color.clear, lineWidth: 2)
                    )
            )
        }
        .disabled(isPurchasing)
        .buttonStyle(.plain)
    }
}

// MARK: - How It Works Row
struct HowItWorksRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    CreditsPurchaseView()
        .environmentObject(AppState())
}
