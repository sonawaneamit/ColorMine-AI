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
    @State private var showShareSheet = false

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

                            // Share Button
                            Button(action: {
                                showShareSheet = true
                            }) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share or Save")
                                }
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
                            }
                            .padding(.horizontal)
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

                        // Reassurance message
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.caption)
                                .foregroundColor(.purple.opacity(0.7))
                            Text("Don't worry! You can change your focus color anytime later")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 8)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.top, 4)
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
        .sheet(isPresented: $showShareSheet) {
            if let imageURL = profile.drapesGridImageURL,
               let uiImage = UIImage(contentsOfFile: imageURL.path) {
                ShareSheet(items: [ImageWatermarkUtility.shared.addWatermark(to: uiImage)])
            }
        }
        .navigationDestination(isPresented: $navigateToFocus) {
            if let updatedProfile = appState.currentProfile {
                FocusColorView(profile: updatedProfile)
                    .environmentObject(appState)
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
    @State private var offset: CGSize = .zero
    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var dragOffset: CGSize = .zero
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let imageWidth = geometry.size.width
                let imageHeight = geometry.size.height

                ZStack {
                    Color.black
                        .ignoresSafeArea()

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale * magnifyBy)
                        .offset(x: offset.width + dragOffset.width, y: offset.height + dragOffset.height)
                        .gesture(makeMagnificationGesture())
                        .simultaneousGesture(makeDragGesture(imageSize: CGSize(width: imageWidth, height: imageHeight)))
                        .onTapGesture(count: 2) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if scale > 1.0 {
                                    scale = 1.0
                                    offset = .zero
                                } else {
                                    scale = 2.5
                                }
                            }
                        }
                }
            }
            .ignoresSafeArea()
            .navigationTitle("Drapes Grid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showShareSheet = true
                    }) {
                        Image(systemName: "square.and.arrow.up")
                            .foregroundColor(.white)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: [ImageWatermarkUtility.shared.addWatermark(to: image)])
            }
        }
    }

    private func makeMagnificationGesture() -> some Gesture {
        MagnificationGesture()
            .updating($magnifyBy) { value, gestureState, _ in
                gestureState = value
            }
            .onEnded { value in
                let newScale = scale * value
                scale = min(max(newScale, 1.0), 5.0)

                if scale == 1.0 {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        offset = .zero
                    }
                }
            }
    }

    private func makeDragGesture(imageSize: CGSize) -> some Gesture {
        DragGesture()
            .updating($dragOffset) { value, gestureState, _ in
                if scale > 1.0 {
                    gestureState = value.translation
                }
            }
            .onEnded { value in
                if scale > 1.0 {
                    let maxOffsetX = (imageSize.width * (scale - 1)) / 2
                    let maxOffsetY = (imageSize.height * (scale - 1)) / 2

                    let newOffsetX = offset.width + value.translation.width
                    let newOffsetY = offset.height + value.translation.height

                    offset.width = min(max(newOffsetX, -maxOffsetX), maxOffsetX)
                    offset.height = min(max(newOffsetY, -maxOffsetY), maxOffsetY)
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
