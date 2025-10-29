//
//  DrapesGridView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import SwiftUI

struct DrapesGridView: View {
    @EnvironmentObject var appState: AppState
    let profile: UserProfile

    @State private var selectedColor: ColorSwatch?
    @State private var showZoomView = false
    @State private var navigateToFocus = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    // Title
                    VStack(spacing: 8) {
                        Text("Your Drapes")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("See yourself in your perfect colors")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)

                    // AI-Generated Drapes Grid Image
                    if let imageURL = profile.drapesGridImageURL,
                       let uiImage = UIImage(contentsOfFile: imageURL.path) {

                        VStack(spacing: 16) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(20)
                                .shadow(radius: 10)
                                .padding(.horizontal)
                                .onTapGesture {
                                    showZoomView = true
                                }

                            // Zoom hint
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.caption)
                                Text("Tap to zoom")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }

                    } else {
                        // Loading or error state
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading your drapes...")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .frame(height: 400)
                    }

                    // Instructions
                    VStack(spacing: 12) {
                        Text("Choose Your Focus Color")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("Select one color for a deep dive into personalized styling")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }

                    // Favorite colors selection
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 70), spacing: 12)
                    ], spacing: 12) {
                        ForEach(profile.favoriteColors) { swatch in
                            FocusColorButton(
                                swatch: swatch,
                                isSelected: selectedColor?.id == swatch.id
                            ) {
                                selectedColor = swatch
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Continue button
                    Button(action: {
                        selectFocusColor()
                    }) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Continue with \(selectedColor?.name ?? "Selected Color")")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            selectedColor != nil ?
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [.gray, .gray],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    .disabled(selectedColor == nil)
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Drapes Grid")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showZoomView) {
            if let imageURL = profile.drapesGridImageURL,
               let uiImage = UIImage(contentsOfFile: imageURL.path) {
                ZoomImageView(image: uiImage)
            }
        }
        .navigationDestination(isPresented: $navigateToFocus) {
            if let updatedProfile = appState.currentProfile {
                FocusColorView(profile: updatedProfile)
            }
        }
    }

    // MARK: - Select Focus Color
    private func selectFocusColor() {
        guard let color = selectedColor else { return }

        var updatedProfile = profile
        updatedProfile.focusColor = color

        appState.saveProfile(updatedProfile)
        navigateToFocus = true
    }
}

// MARK: - Focus Color Button
struct FocusColorButton: View {
    let swatch: ColorSwatch
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(swatch.color)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isSelected ? Color.purple : Color.gray.opacity(0.3),
                                    lineWidth: isSelected ? 4 : 2
                                )
                        )
                        .shadow(color: isSelected ? .purple.opacity(0.5) : .black.opacity(0.1), radius: isSelected ? 8 : 4)

                    if isSelected {
                        Image(systemName: "star.fill")
                            .font(.title)
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 2)
                    }
                }

                Text(swatch.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundColor(isSelected ? .purple : .primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 70)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Zoom Image View
struct ZoomImageView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black
                    .ignoresSafeArea()

                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .scaleEffect(scale)
                    .gesture(
                        MagnificationGesture()
                            .onChanged { value in
                                scale = lastScale * value
                            }
                            .onEnded { _ in
                                lastScale = scale
                            }
                    )
            }
            .navigationTitle("Drapes Grid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DrapesGridView(
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
