//
//  PaletteSelectionView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import SwiftUI

struct PaletteSelectionView: View {
    @EnvironmentObject var appState: AppState
    let profile: UserProfile

    @State private var selectedColors: Set<ColorSwatch> = []
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var navigateToDrapes = false
    @State private var showSeasonPicker = false
    @State private var currentSeason: ColorSeason
    @State private var editingColor: ColorSwatch?
    @State private var showColorPicker = false

    init(profile: UserProfile) {
        self.profile = profile
        _currentSeason = State(initialValue: profile.season)
    }

    private let columns = [
        GridItem(.adaptive(minimum: 70), spacing: 12)
    ]

    private var canGenerate: Bool {
        selectedColors.count >= 3 && selectedColors.count <= 8
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    // Selfie preview with retake option
                    if let selfieImage = profile.selfieImage {
                        VStack(spacing: 12) {
                            Image(uiImage: selfieImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [.purple, .pink],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            lineWidth: 3
                                        )
                                )
                                .shadow(radius: 8)

                            Button(action: {
                                retakeSelfie()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "camera.rotate")
                                    Text("Retake")
                                }
                                .font(.caption)
                                .foregroundColor(.purple)
                            }
                        }
                        .padding(.top, 20)
                    }

                    // Header with analysis results
                    VStack(spacing: 16) {
                        Text("Your Season")
                            .font(.title2)
                            .fontWeight(.bold)

                        // Season badge with edit button
                        HStack(spacing: 8) {
                            Text(currentSeason.rawValue)
                                .font(.largeTitle)
                                .fontWeight(.heavy)
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )

                            Button(action: {
                                showSeasonPicker = true
                            }) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.purple, .pink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                            }
                        }

                        // Analysis details
                        HStack(spacing: 20) {
                            AnalysisDetail(
                                title: "Undertone",
                                value: profile.undertone.rawValue,
                                icon: "circle.hexagongrid"
                            )
                            AnalysisDetail(
                                title: "Contrast",
                                value: profile.contrast.rawValue,
                                icon: "circle.lefthalf.filled"
                            )
                            AnalysisDetail(
                                title: "Confidence",
                                value: "\(Int(profile.confidence * 100))%",
                                icon: "checkmark.seal"
                            )
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Instructions
                    VStack(spacing: 8) {
                        Text("Select Your Favorite Colors")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("Choose 3-8 colors that resonate with you")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Selection counter
                        HStack(spacing: 8) {
                            ForEach(1...8, id: \.self) { index in
                                Circle()
                                    .fill(index <= selectedColors.count ? Color.purple : Color.gray.opacity(0.3))
                                    .frame(width: 12, height: 12)
                            }
                        }
                        .padding(.top, 4)
                    }

                    // Color palette grid
                    let palette = SeasonPalettes.palette(for: currentSeason)
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(palette) { swatch in
                            ColorSwatchButton(
                                swatch: swatch,
                                isSelected: selectedColors.contains(swatch),
                                onTap: {
                                    toggleSelection(swatch)
                                },
                                onLongPress: {
                                    editingColor = swatch
                                    showColorPicker = true
                                }
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding()
                    }

                    // Generate button
                    Button(action: {
                        generateDrapes()
                    }) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Generating with AI...")
                            } else {
                                Image(systemName: "sparkles")
                                Text("Generate My Drapes")
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            canGenerate && !isGenerating ?
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
                    .disabled(!canGenerate || isGenerating)
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Color Analysis")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToDrapes) {
            if let updatedProfile = appState.currentProfile {
                DrapesGridView(profile: updatedProfile)
            }
        }
        .confirmationDialog("Select Your Season", isPresented: $showSeasonPicker) {
            ForEach(ColorSeason.allCases, id: \.self) { season in
                Button(season.rawValue) {
                    updateSeason(to: season)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose your color season if you already know it")
        }
        .sheet(item: $editingColor) { colorToEdit in
            ColorEditSheet(
                color: colorToEdit,
                onSave: { newColor in
                    updateColor(original: colorToEdit, new: newColor)
                }
            )
        }
    }

    // MARK: - Toggle Selection
    private func toggleSelection(_ swatch: ColorSwatch) {
        if selectedColors.contains(swatch) {
            selectedColors.remove(swatch)
        } else {
            if selectedColors.count < 8 {
                selectedColors.insert(swatch)
            }
        }
    }

    // MARK: - Generate Drapes
    private func generateDrapes() {
        guard canGenerate else { return }
        guard let selfieImage = profile.selfieImage else {
            errorMessage = "Selfie image not found"
            return
        }

        isGenerating = true
        errorMessage = nil

        Task {
            do {
                // Convert Set to Array
                let colorsArray = Array(selectedColors)

                // Generate drapes grid with Gemini AI
                let drapesImage = try await GeminiService.shared.generateDrapesGrid(
                    selfieImage: selfieImage,
                    favoriteColors: colorsArray
                )

                // Cache the image
                let cachedURL = ImageCacheManager.shared.saveAIImage(
                    drapesImage,
                    for: .drapesGrid,
                    userID: profile.id
                )

                // Update profile
                var updatedProfile = profile
                updatedProfile.favoriteColors = colorsArray
                updatedProfile.drapesGridImageURL = cachedURL

                appState.saveProfile(updatedProfile)

                isGenerating = false
                navigateToDrapes = true

            } catch {
                errorMessage = error.localizedDescription
                isGenerating = false
            }
        }
    }

    // MARK: - Retake Selfie
    private func retakeSelfie() {
        // Clear profile and restart from scan
        appState.clearProfile()
    }
}

// MARK: - Analysis Detail
struct AnalysisDetail: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.purple)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Color Swatch Button
struct ColorSwatchButton: View {
    let swatch: ColorSwatch
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(swatch.color)
                        .frame(width: 60, height: 60)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isSelected ? Color.purple : Color.clear,
                                    lineWidth: 4
                                )
                        )
                        .shadow(color: isSelected ? .purple.opacity(0.5) : .black.opacity(0.1), radius: isSelected ? 8 : 4)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.purple)
                                    .frame(width: 28, height: 28)
                            )
                            .offset(x: 22, y: -22)
                    }
                }

                Text(swatch.name)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 70)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        PaletteSelectionView(
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
