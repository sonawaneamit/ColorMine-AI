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
        selectedColors.count >= 3 && selectedColors.count <= 12
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
                                .foregroundStyle(currentSeason.gradient)

                            Button(action: {
                                showSeasonPicker = true
                            }) {
                                Image(systemName: "pencil.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(currentSeason.gradient)
                            }
                        }

                        // Tooltip for season editing
                        HStack(spacing: 6) {
                            Image(systemName: "info.circle.fill")
                                .font(.caption)
                                .foregroundColor(.purple.opacity(0.7))
                            Text("Tap the pencil icon to change your season if you already know it")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(8)

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

                        // AI Reasoning (if available from OpenAI)
                        if let reasoning = profile.reasoning {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "brain.head.profile")
                                        .foregroundColor(.purple)
                                    Text("Why This Season?")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                }

                                Text(reasoning)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.purple.opacity(0.05))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.purple.opacity(0.2), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Instructions
                    VStack(spacing: 8) {
                        Text("Choose Colors That Speak to You")
                            .font(.title3)
                            .fontWeight(.semibold)

                        Text("Pick 3-12 colors from your season — we'll show you how they look on you")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Selection counter
                        HStack(spacing: 6) {
                            ForEach(1...12, id: \.self) { index in
                                Circle()
                                    .fill(index <= selectedColors.count ? Color.purple : Color.gray.opacity(0.3))
                                    .frame(width: 10, height: 10)
                            }
                        }
                        .padding(.top, 4)

                        // Tooltip for color editing
                        HStack(spacing: 6) {
                            Image(systemName: "hand.tap.fill")
                                .font(.caption)
                                .foregroundColor(.pink.opacity(0.7))
                            Text("Long press any color to customize its shade")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(Color.pink.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.top, 8)
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
                                Text("Creating your view...")
                            } else {
                                Image(systemName: "sparkles")
                                Text("See Myself in These Colors")
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
                    .environmentObject(appState)
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
            if selectedColors.count < 12 {
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
                updatedProfile.packsGenerated.drapes = true

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

    // MARK: - Update Season
    private func updateSeason(to newSeason: ColorSeason) {
        currentSeason = newSeason
        // Clear selected colors when season changes
        selectedColors.removeAll()

        // Update profile with new season
        var updatedProfile = profile
        updatedProfile.season = newSeason
        appState.saveProfile(updatedProfile)
    }

    // MARK: - Update Color
    private func updateColor(original: ColorSwatch, new: ColorSwatch) {
        // If the original color was selected, replace it with the new one
        if selectedColors.contains(original) {
            selectedColors.remove(original)
            selectedColors.insert(new)
        }
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
    let onTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
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
                    .onTapGesture {
                        onTap()
                    }
                    .onLongPressGesture {
                        onLongPress()
                    }

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
}

// MARK: - Color Edit Sheet
struct ColorEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    let color: ColorSwatch
    let onSave: (ColorSwatch) -> Void

    @State private var selectedColor: Color
    @State private var colorName: String

    init(color: ColorSwatch, onSave: @escaping (ColorSwatch) -> Void) {
        self.color = color
        self.onSave = onSave
        _selectedColor = State(initialValue: color.color)
        _colorName = State(initialValue: color.name)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Preview
                VStack(spacing: 16) {
                    Text("Edit Color")
                        .font(.title2)
                        .fontWeight(.bold)

                    Circle()
                        .fill(selectedColor)
                        .frame(width: 120, height: 120)
                        .overlay(
                            Circle()
                                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(radius: 8)

                    Text(colorName)
                        .font(.headline)
                }
                .padding(.top, 40)

                // Color Picker - Full Wheel
                VStack(alignment: .center, spacing: 20) {
                    VStack(spacing: 8) {
                        Image(systemName: "hand.tap.fill")
                            .font(.title2)
                            .foregroundColor(.purple.opacity(0.7))
                        Text("Tap the circle below to open color picker")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal)

                    // Make the ColorPicker more prominent
                    ZStack {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [.purple.opacity(0.3), .pink.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 80, height: 80)

                        ColorPicker("", selection: $selectedColor, supportsOpacity: false)
                            .labelsHidden()
                            .scaleEffect(2.0) // Make the circle bigger
                    }
                    .frame(height: 100)
                }
                .padding(.horizontal)

                Spacer()

                // Action Buttons
                HStack(spacing: 16) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button("Save") {
                        saveColor()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveColor()
                    }
                    .foregroundColor(.purple)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveColor() {
        // Convert Color to hex
        let uiColor = UIColor(selectedColor)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        let hexString = String(
            format: "%02X%02X%02X",
            Int(red * 255),
            Int(green * 255),
            Int(blue * 255)
        )

        let newSwatch = ColorSwatch(
            id: color.id,
            name: colorName,
            hex: hexString
        )

        onSave(newSwatch)
        dismiss()
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
