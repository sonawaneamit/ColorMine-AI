//
//  PacksGenerationView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import SwiftUI

struct PacksGenerationView: View {
    @EnvironmentObject var appState: AppState
    let profile: UserProfile

    @State private var currentStep = 0
    @State private var generatedPacks: [GeneratedPack] = []
    @State private var isGenerating = true
    @State private var errorMessage: String?
    @State private var navigateToDashboard = false

    private let steps = [
        ("Texture Pack", "square.grid.3x3.fill"),
        ("Jewelry Pack", "sparkles"),
        ("Makeup Pack", "paintbrush.fill"),
        ("Style Cards", "doc.text.fill")
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.purple.opacity(0.2), Color.pink.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Title
                VStack(spacing: 12) {
                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Creating Your Style Guide")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("This may take 2-3 minutes...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                // Progress Steps
                VStack(spacing: 20) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        PackGenerationRow(
                            icon: steps[index].1,
                            title: steps[index].0,
                            status: getStatus(for: index)
                        )
                    }
                }
                .padding(.horizontal, 30)

                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                }

                Spacer()
            }
        }
        .navigationTitle("Generating")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(isGenerating)
        .navigationDestination(isPresented: $navigateToDashboard) {
            if let updatedProfile = appState.currentProfile {
                ProfileDashboardView(profile: updatedProfile)
            }
        }
        .onAppear {
            requestNotificationPermissions()
            startGeneration()
        }
    }

    // MARK: - Request Notification Permissions
    private func requestNotificationPermissions() {
        Task {
            await NotificationManager.shared.requestAuthorization()
        }
    }

    // MARK: - Get Status
    private func getStatus(for index: Int) -> PackStatus {
        if index < currentStep {
            return .completed
        } else if index == currentStep {
            return .inProgress
        } else {
            return .pending
        }
    }

    // MARK: - Start Generation
    private func startGeneration() {
        // Check if already generated - shouldn't happen due to routing logic,
        // but adding as safety check
        if profile.packsGenerated.allGenerated {
            print("✅ All packs already generated, skipping to dashboard")
            isGenerating = false
            navigateToDashboard = true
            return
        }

        guard let selfieImage = profile.selfieImage else {
            errorMessage = "Selfie image not found"
            return
        }

        guard let focusColor = profile.focusColor else {
            errorMessage = "Focus color not selected"
            return
        }

        Task {
            var updatedProfile = profile

            // Step 1: Generate Texture Pack (skip if already generated)
            currentStep = 0
            if !profile.packsGenerated.textures {
                do {
                let textureImage = try await GeminiService.shared.generateTexturePack(
                    selfieImage: selfieImage,
                    focusColor: focusColor
                )
                let textureURL = ImageCacheManager.shared.saveAIImage(
                    textureImage,
                    for: .texturePack,
                    userID: profile.id
                )
                updatedProfile.texturePackImageURL = textureURL
                updatedProfile.packsGenerated.textures = true
                appState.saveProfile(updatedProfile)

                    // Send notification
                    NotificationManager.shared.sendPackCompletionNotification(packType: .texturePack)
                } catch {
                    errorMessage = "Texture Pack: \(error.localizedDescription)"
                }
            } else {
                print("✅ Texture Pack already generated, skipping")
            }

            // Step 2: Generate Jewelry Pack (skip if already generated)
            currentStep = 1
            if !profile.packsGenerated.jewelry {
                do {
                let jewelryImage = try await GeminiService.shared.generateJewelryPack(
                    selfieImage: selfieImage,
                    focusColor: focusColor,
                    undertone: profile.undertone
                )
                let jewelryURL = ImageCacheManager.shared.saveAIImage(
                    jewelryImage,
                    for: .jewelryPack,
                    userID: profile.id
                )
                updatedProfile.jewelryPackImageURL = jewelryURL
                updatedProfile.packsGenerated.jewelry = true
                appState.saveProfile(updatedProfile)

                    // Send notification
                    NotificationManager.shared.sendPackCompletionNotification(packType: .jewelryPack)
                } catch {
                    errorMessage = "Jewelry Pack: \(error.localizedDescription)"
                }
            } else {
                print("✅ Jewelry Pack already generated, skipping")
            }

            // Step 3: Generate Makeup Pack (skip if already generated)
            currentStep = 2
            if !profile.packsGenerated.makeup {
                do {
                let makeupImage = try await GeminiService.shared.generateMakeupPack(
                    selfieImage: selfieImage,
                    focusColor: focusColor,
                    undertone: profile.undertone,
                    contrast: profile.contrast
                )
                let makeupURL = ImageCacheManager.shared.saveAIImage(
                    makeupImage,
                    for: .makeupPack,
                    userID: profile.id
                )
                updatedProfile.makeupPackImageURL = makeupURL
                updatedProfile.packsGenerated.makeup = true
                appState.saveProfile(updatedProfile)

                    // Send notification
                    NotificationManager.shared.sendPackCompletionNotification(packType: .makeupPack)
                } catch {
                    errorMessage = "Makeup Pack: \(error.localizedDescription)"
                }
            } else {
                print("✅ Makeup Pack already generated, skipping")
            }

            // Step 4: Generate Style Cards (text-based, no AI needed, skip if already generated)
            currentStep = 3
            if !profile.packsGenerated.contrastCard || !profile.packsGenerated.neutralsMetalsCard {
                updatedProfile.contrastCard = ContrastCard.generate(for: profile.contrast)
                updatedProfile.neutralsMetalsCard = NeutralsMetalsCard.generate(for: profile.undertone, season: profile.season)
                updatedProfile.packsGenerated.contrastCard = true
                updatedProfile.packsGenerated.neutralsMetalsCard = true
                appState.saveProfile(updatedProfile)
            } else {
                print("✅ Style Cards already generated, skipping")
            }

            // Complete - send final notification
            isGenerating = false
            NotificationManager.shared.sendAllPacksCompleteNotification()

            // Navigate to dashboard
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                navigateToDashboard = true
            }
        }
    }
}

// MARK: - Pack Status
enum PackStatus {
    case pending
    case inProgress
    case completed
}

// MARK: - Pack Generation Row
struct PackGenerationRow: View {
    let icon: String
    let title: String
    let status: PackStatus

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
                .frame(width: 40)

            // Title
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            Spacer()

            // Status indicator
            Group {
                switch status {
                case .pending:
                    Image(systemName: "circle")
                        .foregroundColor(.gray)
                case .inProgress:
                    ProgressView()
                case .completed:
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
            }
            .font(.title3)
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(12)
    }

    private var iconColor: Color {
        switch status {
        case .pending:
            return .gray
        case .inProgress:
            return .purple
        case .completed:
            return .green
        }
    }
}

// MARK: - Generated Pack
struct GeneratedPack {
    let type: String
    let imageURL: URL?
}

#Preview {
    NavigationStack {
        PacksGenerationView(
            profile: UserProfile(
                selfieImageData: nil,
                season: .clearSpring,
                undertone: .warm,
                contrast: .high,
                confidence: 0.89
            )
        )
        .environmentObject(AppState())
    }
}
