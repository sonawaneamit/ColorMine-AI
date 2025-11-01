//
//  ScanView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import SwiftUI

struct ScanView: View {
    @EnvironmentObject var appState: AppState

    @State private var showCamera = false
    @State private var showPhotoLibrary = false
    @State private var capturedImage: UIImage?
    @State private var displayedImage: UIImage?  // The image to display (may be flipped)
    @State private var isFlipped = false  // Track if user manually flipped the image
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var navigateToResults = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                if let image = displayedImage {
                    VStack(spacing: 12) {
                        // Show captured image
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 400)
                            .cornerRadius(20)
                            .shadow(radius: 10)

                        // Flip button
                        Button(action: flipImage) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                                    .font(.caption)
                                Text("Flip Image")
                                    .font(.caption)
                            }
                            .foregroundColor(.purple)
                        }
                    }

                    if isAnalyzing {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Reading your unique color story...")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Button("Discover My Season") {
                                analyzeImage()
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.horizontal, 40)

                            Button(action: {
                                retakePhoto()
                            }) {
                                HStack {
                                    Image(systemName: "arrow.counterclockwise")
                                    Text("Retake Photo")
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .padding(.horizontal, 40)
                        }
                    }
                } else {
                    // Show instructions
                    VStack(spacing: 24) {
                        Image(systemName: "camera.viewfinder")
                            .font(.system(size: 80))
                            .foregroundColor(.purple)

                        VStack(spacing: 12) {
                            Text("Take Your Selfie")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("For best results:")
                                .font(.headline)
                                .foregroundColor(.secondary)

                            VStack(alignment: .leading, spacing: 8) {
                                TipRow(text: "Use natural lighting")
                                TipRow(text: "Face the camera directly")
                                TipRow(text: "Remove makeup if possible")
                                TipRow(text: "Use a plain background")
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)

                        // Accuracy Warning
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                                .font(.title3)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Best Results with Camera")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)

                                Text("Selfies are more accurate than uploaded photos")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.15))
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                        )
                        .padding(.horizontal, 30)

                        Spacer()

                        VStack(spacing: 16) {
                            Button(action: {
                                showCamera = true
                            }) {
                                HStack {
                                    Image(systemName: "camera.fill")
                                    Text("Take Photo")
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .padding(.horizontal, 40)

                            Button(action: {
                                showPhotoLibrary = true
                            }) {
                                HStack {
                                    Image(systemName: "photo.fill")
                                    Text("Choose from Library")
                                }
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            .padding(.horizontal, 40)
                        }
                    }
                    .padding(.top, 40)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                }

                Spacer()
            }
        }
        .navigationTitle("Color Scan")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: capturedImage) { oldValue, newValue in
            // When a new image is captured, set it as the displayed image
            displayedImage = newValue
            isFlipped = false  // Reset flip state
        }
        .fullScreenCover(isPresented: $showCamera) {
            CustomCameraView(capturedImage: $capturedImage)
        }
        .sheet(isPresented: $showPhotoLibrary) {
            ImagePicker(image: $capturedImage, sourceType: .photoLibrary)
        }
    }

    // MARK: - Flip Image
    private func flipImage() {
        guard let current = displayedImage else { return }

        // Toggle flip state
        isFlipped.toggle()

        // Flip the image
        if let flipped = current.flipped() {
            displayedImage = flipped
        }
    }

    // MARK: - Retake Photo
    private func retakePhoto() {
        capturedImage = nil
        displayedImage = nil
        errorMessage = nil
        isFlipped = false
    }

    // MARK: - Analyze Image
    private func analyzeImage() {
        guard let image = capturedImage else { return }

        isAnalyzing = true
        errorMessage = nil

        Task {
            do {
                // Detect face
                let faceObservation = try await VisionService.shared.detectFaceLandmarks(in: image)

                // Analyze colors (supports both OpenAI and on-device ML)
                let result = try await ColorAnalyzer.shared.analyzeSkinTone(from: image, faceObservation: faceObservation)

                // Save selfie data
                let imageData = image.jpegData(compressionQuality: 0.8)

                // Create profile
                var profile = UserProfile(
                    selfieImageData: imageData,
                    season: result.season,
                    undertone: result.undertone,
                    contrast: result.contrast,
                    confidence: result.confidence
                )
                profile.reasoning = result.reasoning  // Save AI reasoning if available

                // Restore preserved data (credits, garments, history) from "Start Over"
                appState.restorePreservedData(to: &profile)

                appState.saveProfile(profile)

                // Haptic feedback for season discovery milestone
                HapticManager.shared.seasonDiscovered()

                isAnalyzing = false
                navigateToResults = true

            } catch {
                errorMessage = error.localizedDescription
                isAnalyzing = false
            }
        }
    }
}

struct TipRow: View {
    let text: String

    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

#Preview {
    ScanView()
        .environmentObject(AppState())
}
