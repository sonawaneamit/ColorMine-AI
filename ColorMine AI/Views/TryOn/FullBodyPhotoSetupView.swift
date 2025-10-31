//
//  FullBodyPhotoSetupView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import SwiftUI

struct FullBodyPhotoSetupView: View {
    @EnvironmentObject var appState: AppState
    @State private var showImagePicker = false
    @State private var photoSource: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    Spacer().frame(height: 20)

                    // Icon
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 70))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Title
                    VStack(spacing: 12) {
                        Text("One More Step")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("To create realistic Try-Ons, we need a full-body photo of you")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }

                    // Tips
                    VStack(alignment: .leading, spacing: 12) {
                        TipRow(text: "Use an existing photo")
                        TipRow(text: "Stand against a plain background")
                        TipRow(text: "Show your full body (head to feet)")
                        TipRow(text: "Wear fitted clothing")
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal, 30)

                    // Privacy note
                    HStack(spacing: 10) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(.purple)
                        Text("Your photo stays private and secure on your device")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 30)

                    Spacer()

                    // Buttons
                    VStack(spacing: 16) {
                        Button(action: {
                            photoSource = .photoLibrary
                            showImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "photo.fill")
                                Text("Choose from Photos")
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.horizontal, 40)

                        Button(action: {
                            photoSource = .camera
                            showImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Take New Photo")
                            }
                        }
                        .buttonStyle(SecondaryButtonStyle())
                        .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Try-On Setup")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showImagePicker) {
            FullBodyImagePicker(image: $selectedImage, sourceType: photoSource)
        }
        .onChange(of: selectedImage) { oldValue, newValue in
            if let image = newValue {
                saveFullBodyPhoto(image)
            }
        }
    }

    private func saveFullBodyPhoto(_ image: UIImage) {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

        guard var updatedProfile = appState.currentProfile else {
            print("❌ No current profile found")
            return
        }

        updatedProfile.fullBodyPhotoData = imageData
        appState.saveProfile(updatedProfile)

        print("✅ Full body photo saved")

        // Haptic feedback
        HapticManager.shared.success()

        dismiss()
    }
}

#Preview {
    NavigationStack {
        FullBodyPhotoSetupView()
            .environmentObject(AppState())
    }
}
