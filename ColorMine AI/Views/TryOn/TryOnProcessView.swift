//
//  TryOnProcessView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import SwiftUI

struct TryOnProcessView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let garment: GarmentItem

    @State private var isProcessing = false
    @State private var processingProgress: Double = 0.0
    @State private var statusMessage = "Preparing your Try-On..."
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var tryOnResult: TryOnResult?
    @State private var showResult = false
    @State private var showCreditsPurchase = false

    private var currentCredits: Int {
        appState.currentProfile?.tryOnCredits ?? 0
    }

    private var hasEnoughCredits: Bool {
        currentCredits >= 1
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer()

                    // Garment preview
                    if let imageData = try? Data(contentsOf: garment.imageURL),
                       let image = UIImage(data: imageData) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                            .cornerRadius(16)
                            .shadow(color: .black.opacity(0.1), radius: 10)
                    }

                    // Status
                    VStack(spacing: 12) {
                        if isProcessing {
                            ProgressView(value: processingProgress)
                                .progressViewStyle(.linear)
                                .tint(.purple)
                                .frame(width: 200)
                        }

                        Text(statusMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    Spacer()

                    // Credit Balance Card
                    VStack(spacing: 16) {
                        // Current balance
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your Balance")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.purple)
                                    Text(CreditsManager.formatCredits(currentCredits))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }
                            }

                            Spacer()

                            // Cost indicator
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Cost")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text("1 credit")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)

                        // Warning if no credits
                        if !hasEnoughCredits {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("You need at least 1 credit to Try-On")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)

                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: startTryOn) {
                            HStack {
                                if hasEnoughCredits {
                                    Image(systemName: "wand.and.stars")
                                    Text("Try It On")
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Get Credits")
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isProcessing)
                        .padding(.horizontal, 40)

                        Button("Cancel") {
                            dismiss()
                        }
                        .disabled(isProcessing)
                        .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Virtual Try-On")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isProcessing {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
            .alert("Oops!", isPresented: $showError) {
                Button("OK", role: .cancel) {
                    isProcessing = false
                }
            } message: {
                Text(errorMessage)
            }
            .fullScreenCover(isPresented: $showResult) {
                if let result = tryOnResult {
                    TryOnResultView(result: result)
                }
            }
            .sheet(isPresented: $showCreditsPurchase) {
                CreditsPurchaseView()
            }
        }
    }

    // MARK: - Start Try-On
    private func startTryOn() {
        guard var profile = appState.currentProfile else {
            errorMessage = "No profile found. Please set up your profile first."
            showError = true
            return
        }

        // Check credits - if insufficient, show purchase sheet
        guard profile.tryOnCredits >= 1 else {
            showCreditsPurchase = true
            HapticManager.shared.buttonTap()
            return
        }

        // Check full body photo
        guard let fullBodyImage = profile.fullBodyImage else {
            errorMessage = "Please upload a full body photo first in settings."
            showError = true
            return
        }

        // Load garment image
        guard let garmentImageData = try? Data(contentsOf: garment.imageURL),
              let garmentImage = UIImage(data: garmentImageData) else {
            errorMessage = "Failed to load garment image."
            showError = true
            return
        }

        isProcessing = true
        statusMessage = "Preparing your Try-On..."
        processingProgress = 0.1

        Task {
            do {
                // Simulate progress updates
                await updateProgress(0.3, message: "Uploading images...")
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5s

                await updateProgress(0.5, message: "Generating photorealistic Try-On...")

                // Call fal.ai API
                let resultImage = try await FalAIService.shared.generateTryOn(
                    modelPhoto: fullBodyImage,
                    garmentPhoto: garmentImage
                )

                await updateProgress(0.8, message: "Analyzing colors...")
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3s

                // Save result to cache
                guard let resultURL = TryOnCacheManager.shared.saveTryOnResult(resultImage) else {
                    throw TryOnError.failedToSave
                }

                // Create result object
                let result = TryOnResult(
                    id: UUID(),
                    garmentItem: garment,
                    resultImageURL: resultURL,
                    createdAt: Date(),
                    creditsUsed: 1  // 1 credit = 1 try-on
                )

                // Deduct credits and save
                profile.tryOnCredits -= 1  // 1 credit = 1 try-on
                profile.tryOnHistory.append(result)
                appState.saveProfile(profile)

                await updateProgress(1.0, message: "Ready!")

                // Haptic feedback
                HapticManager.shared.success()

                // Show result
                await MainActor.run {
                    tryOnResult = result
                    showResult = true
                    dismiss()
                }

                print("✅ Try-on completed: \(result.id)")

            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Try-on failed: \(error.localizedDescription)"
                    showError = true
                    print("❌ Try-on error: \(error)")
                }
            }
        }
    }

    @MainActor
    private func updateProgress(_ progress: Double, message: String) async {
        processingProgress = progress
        statusMessage = message
    }
}

#Preview {
    TryOnProcessView(garment: GarmentItem(
        imageURL: URL(fileURLWithPath: "/tmp/test.jpg"),
        sourceStore: "ASOS"
    ))
    .environmentObject(AppState())
}
