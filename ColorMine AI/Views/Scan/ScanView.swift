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
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var navigateToResults = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 30) {
                if let image = capturedImage {
                    // Show captured image
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(height: 400)
                        .cornerRadius(20)
                        .shadow(radius: 10)

                    if isAnalyzing {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Analyzing your colors...")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                    } else {
                        Button("Analyze Colors") {
                            analyzeImage()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 40)
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
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $capturedImage, sourceType: .camera)
        }
        .sheet(isPresented: $showPhotoLibrary) {
            ImagePicker(image: $capturedImage, sourceType: .photoLibrary)
        }
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

                // Analyze colors
                let result = ColorAnalyzer.shared.analyzeSkinTone(from: image, faceObservation: faceObservation)

                // Save selfie data
                let imageData = image.jpegData(compressionQuality: 0.8)

                // Create profile
                let profile = UserProfile(
                    selfieImageData: imageData,
                    season: result.season,
                    undertone: result.undertone,
                    contrast: result.contrast,
                    confidence: result.confidence
                )

                appState.saveProfile(profile)

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

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
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
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.purple)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                Color(.systemBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2
                    )
            )
            .cornerRadius(16)
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
    }
}

#Preview {
    ScanView()
        .environmentObject(AppState())
}
