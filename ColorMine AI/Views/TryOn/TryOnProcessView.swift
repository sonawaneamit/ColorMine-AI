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
    @State private var statusMessage = "Preparing your try-on..."
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var tryOnResult: TryOnResult?
    @State private var showResult = false

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

                    // Credits info
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple)
                        Text("This will use 3 credits")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 20)

                    // Action buttons
                    VStack(spacing: 12) {
                        Button(action: startTryOn) {
                            HStack {
                                Image(systemName: "wand.and.stars")
                                Text("Try It On")
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
        }
    }

    // MARK: - Start Try-On
    private func startTryOn() {
        guard var profile = appState.currentProfile else {
            errorMessage = "No profile found. Please set up your profile first."
            showError = true
            return
        }

        // Check credits
        guard profile.tryOnCredits >= 1 else {
            errorMessage = "Not enough credits. You need 1 credit for a try-on."
            showError = true
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
        statusMessage = "Preparing your try-on..."
        processingProgress = 0.1

        Task {
            do {
                // Simulate progress updates
                await updateProgress(0.3, message: "Uploading images...")
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5s

                await updateProgress(0.5, message: "Generating photorealistic try-on...")

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
