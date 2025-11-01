//
//  PackSelectionView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import SwiftUI

struct PackSelectionView: View {
    @EnvironmentObject var appState: AppState
    let profile: UserProfile

    @State private var selectedPacks: Set<String>
    @State private var navigateToGeneration = false

    init(profile: UserProfile) {
        self.profile = profile
        // Initialize with existing selections or defaults to all packs
        self._selectedPacks = State(initialValue: profile.selectedPacks.isEmpty ? ["texture", "jewelry", "makeup", "hair"] : profile.selectedPacks)
    }

    private let availablePacks = [
        PackOption(
            id: "texture",
            title: "Fabric & Texture",
            description: "Fabric patterns that bring out your natural warmth",
            icon: "square.grid.3x3.fill",
            recommended: true
        ),
        PackOption(
            id: "jewelry",
            title: "Jewelry & Metals",
            description: "Metals and gems that illuminate your features",
            icon: "sparkles",
            recommended: true
        ),
        PackOption(
            id: "makeup",
            title: "Makeup Palette",
            description: "Makeup shades that harmonize with your undertone",
            icon: "paintbrush.fill",
            recommended: true
        ),
        PackOption(
            id: "hair",
            title: "Hair Color Ideas",
            description: "Hair colors that enhance your season and energy",
            icon: "person.crop.circle.fill",
            recommended: true
        )
    ]

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "checklist")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Build Your Complete Style Guide")
                            .font(.largeTitle)
                            .fontWeight(.bold)

                        Text("Select the style areas you'd like to explore")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 20)

                    // Select All / Deselect All
                    HStack(spacing: 12) {
                        Button(action: {
                            selectedPacks = Set(availablePacks.map { $0.id })
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Select All")
                            }
                            .font(.subheadline)
                            .foregroundColor(.purple)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(20)
                        }

                        Button(action: {
                            selectedPacks.removeAll()
                        }) {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text("Deselect All")
                            }
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(20)
                        }
                    }

                    // Pack Options
                    VStack(spacing: 16) {
                        ForEach(availablePacks) { pack in
                            PackSelectionCard(
                                pack: pack,
                                isSelected: selectedPacks.contains(pack.id)
                            ) {
                                if selectedPacks.contains(pack.id) {
                                    selectedPacks.remove(pack.id)
                                } else {
                                    selectedPacks.insert(pack.id)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)

                    // Info box
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            Text("Worth the Wait")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        Text("Your style guide is being custom-created with AI. You'll get a notification when it's ready — up to 60 seconds.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)

                    // Continue Button
                    Button(action: {
                        savePacks()
                    }) {
                        HStack {
                            Image(systemName: selectedPacks.isEmpty ? "exclamationmark.triangle.fill" : "wand.and.stars")
                            Text(selectedPacks.isEmpty ? "Select at least one area" : "Create My Guide")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            selectedPacks.isEmpty ?
                            LinearGradient(
                                colors: [.gray, .gray],
                                startPoint: .leading,
                                endPoint: .trailing
                            ) :
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                    }
                    .disabled(selectedPacks.isEmpty)
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Pack Selection")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToGeneration) {
            if let updatedProfile = appState.currentProfile {
                PacksGenerationView(profile: updatedProfile)
                    .environmentObject(appState)
            }
        }
    }

    // MARK: - Save Packs
    private func savePacks() {
        var updatedProfile = profile
        updatedProfile.selectedPacks = selectedPacks
        updatedProfile.hasChosenPacks = true // Mark that user has chosen packs
        appState.saveProfile(updatedProfile)
        navigateToGeneration = true
    }
}

// MARK: - Pack Option Model
struct PackOption: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let recommended: Bool
}

// MARK: - Pack Selection Card
struct PackSelectionCard: View {
    let pack: PackOption
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.purple.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 60, height: 60)

                    Image(systemName: pack.icon)
                        .font(.title2)
                        .foregroundColor(isSelected ? .purple : .gray)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        HStack(spacing: 6) {
                            Text(pack.title)
                                .font(.headline)
                                .foregroundColor(.primary)

                            if pack.recommended {
                                HStack(spacing: 3) {
                                    Image(systemName: "star.fill")
                                        .font(.system(size: 8))
                                    Text("Top Pick")
                                }
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    LinearGradient(
                                        colors: [.purple, .pink],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(8)
                            }
                        }
                    }

                    Text(pack.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                // Checkbox
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.purple : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 28, height: 28)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.purple)
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(
                        isSelected ? Color.purple.opacity(0.5) : Color.clear,
                        lineWidth: 2
                    )
            )
            .shadow(color: isSelected ? Color.purple.opacity(0.2) : Color.clear, radius: 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        PackSelectionView(
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
