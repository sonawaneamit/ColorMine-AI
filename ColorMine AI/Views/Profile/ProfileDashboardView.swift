//
//  ProfileDashboardView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import SwiftUI

struct ProfileDashboardView: View {
    @EnvironmentObject var appState: AppState

    @State private var selectedTab = 0
    @State private var selectedPack: PackDetailType?
    @State private var showRegenerateOptions = false

    // Use computed property to always get current profile from appState
    private var profile: UserProfile {
        appState.currentProfile ?? UserProfile(
            selfieImageData: nil,
            season: .clearSpring,
            undertone: .warm,
            contrast: .high,
            confidence: 0.89
        )
    }

    var body: some View {
        Group {
            // If focus color is nil, user should be back at drapes selection
            // This handles the case when regenerateFromFocusColor() is called
            // Note: We show dashboard even if some packs failed - let user see what succeeded
            if profile.focusColor == nil {
                // Don't show dashboard - let RootView handle routing
                Color.clear
                    .onAppear {
                        // Force RootView to re-evaluate by setting a temporary state
                        // The RootView will show the correct view based on profile state
                    }
            } else {
                TabView(selection: $selectedTab) {
                    // Profile Tab
                    ProfileTab(profile: profile, selectedPack: $selectedPack)
                        .tabItem {
                            Label("Profile", systemImage: "person.circle.fill")
                        }
                        .tag(0)

                    // History Tab
                    HistoryView()
                        .environmentObject(appState)
                        .tabItem {
                            Label("History", systemImage: "clock.arrow.circlepath")
                        }
                        .tag(1)

                    // Wardrobe Tab
                    WardrobeTab()
                        .tabItem {
                            Label("Wardrobe", systemImage: "tshirt.fill")
                        }
                        .tag(2)
                }
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showRegenerateOptions = true
                        }) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.purple)
                        }
                    }
                }
                .navigationDestination(item: $selectedPack) { packType in
                    PackDetailView(profile: profile, packType: packType)
                        .environmentObject(appState)
                        .navigationBarBackButtonHidden(false)
                }
                .confirmationDialog("Update Your Guide", isPresented: $showRegenerateOptions) {
                    Button("Switch to a different color") {
                        regenerateFromFocusColor()
                    }
                    Button("Start fresh with a new photo") {
                        retakeSelfie()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("What would you like to change?")
                }
                .onAppear {
                    // Clear notification badge when viewing dashboard
                    NotificationManager.shared.clearBadge()
                }
            }
        }
    }

    // MARK: - Regenerate from Focus Color
    private func regenerateFromFocusColor() {
        var updatedProfile = profile
        // Clear focus color and all generated packs (keep drapes)
        updatedProfile.focusColor = nil
        updatedProfile.hasChosenPacks = false
        updatedProfile.texturePackImageURL = nil
        updatedProfile.jewelryPackImageURL = nil
        updatedProfile.makeupPackImageURL = nil
        updatedProfile.hairColorPackImageURL = nil
        updatedProfile.packsGenerated.textures = false
        updatedProfile.packsGenerated.jewelry = false
        updatedProfile.packsGenerated.makeup = false
        updatedProfile.packsGenerated.hairColor = false
        updatedProfile.packsGenerated.contrastCard = false
        updatedProfile.packsGenerated.neutralsMetalsCard = false
        appState.saveProfile(updatedProfile)
    }

    // MARK: - Retake Selfie
    private func retakeSelfie() {
        appState.clearProfile()
    }
}

// MARK: - Profile Tab
struct ProfileTab: View {
    let profile: UserProfile
    @Binding var selectedPack: PackDetailType?

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header with Selfie and Analysis - Consistent with PaletteSelectionView
                VStack(spacing: 16) {
                    // Selfie photo
                    if let selfieImage = profile.selfieImage {
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
                    }

                    // "Your Season" title
                    Text("Your Season")
                        .font(.title2)
                        .fontWeight(.bold)

                    // Season badge with season-specific gradient
                    Text(profile.season.rawValue)
                        .font(.largeTitle)
                        .fontWeight(.heavy)
                        .foregroundStyle(profile.season.gradient)

                    // Analysis details in grid format - matching PaletteSelectionView
                    HStack(spacing: 20) {
                        ProfileAnalysisDetail(
                            title: "Undertone",
                            value: profile.undertone.rawValue,
                            icon: "circle.hexagongrid"
                        )
                        ProfileAnalysisDetail(
                            title: "Contrast",
                            value: profile.contrast.rawValue,
                            icon: "circle.lefthalf.filled"
                        )
                        ProfileAnalysisDetail(
                            title: "Confidence",
                            value: "\(Int(profile.confidence * 100))%",
                            icon: "checkmark.seal"
                        )
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)

                    // Focus color badge
                    if let focusColor = profile.focusColor {
                        HStack(spacing: 12) {
                            Circle()
                                .fill(focusColor.color)
                                .frame(width: 30, height: 30)
                            Text("Focus Color: \(focusColor.name)")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color(.systemBackground))
                        .cornerRadius(20)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 20)

                Divider()
                    .padding(.horizontal)

                // AI Packs Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Style Guide")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    // Show message if no packs yet
                    if !profile.packsGenerated.allGenerated(selectedPacks: profile.selectedPacks) {
                        VStack(spacing: 12) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 50))
                                .foregroundColor(.purple.opacity(0.5))
                            Text("Your personalized guide is being created")
                                .font(.headline)
                            Text("This is worth the wait — usually 2-3 minutes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                        .background(Color(.systemBackground))
                        .cornerRadius(16)
                        .padding(.horizontal)
                    }

                    // Drapes Grid
                    if let drapesURL = profile.drapesGridImageURL,
                       let uiImage = UIImage(contentsOfFile: drapesURL.path) {
                        PackCard(
                            title: "Color Draping",
                            subtitle: "You, wearing your best colors",
                            image: uiImage,
                            icon: "square.grid.3x3.fill",
                            packID: "drapes_pack"
                        ) {
                            selectedPack = .drapesGrid
                        }
                        .id("drapes_pack")
                    }

                    // Texture Pack (only if selected)
                    if profile.selectedPacks.contains("texture"),
                       let textureURL = profile.texturePackImageURL,
                       let uiImage = UIImage(contentsOfFile: textureURL.path) {
                        PackCard(
                            title: "Fabric & Texture",
                            subtitle: "Fabric patterns that enhance your look",
                            image: uiImage,
                            icon: "square.grid.3x3.fill",
                            packID: "texture_pack"
                        ) {
                            selectedPack = .texturePack
                        }
                        .id("texture_pack")
                    }

                    // Jewelry Pack (only if selected)
                    if profile.selectedPacks.contains("jewelry"),
                       let jewelryURL = profile.jewelryPackImageURL,
                       let uiImage = UIImage(contentsOfFile: jewelryURL.path) {
                        PackCard(
                            title: "Jewelry & Metals",
                            subtitle: "Metals and gems that illuminate your features",
                            image: uiImage,
                            icon: "sparkles",
                            packID: "jewelry_pack"
                        ) {
                            selectedPack = .jewelryPack
                        }
                        .id("jewelry_pack")
                    }

                    // Makeup Pack (only if selected)
                    if profile.selectedPacks.contains("makeup"),
                       let makeupURL = profile.makeupPackImageURL,
                       let uiImage = UIImage(contentsOfFile: makeupURL.path) {
                        PackCard(
                            title: "Makeup Palette",
                            subtitle: "Makeup shades that harmonize with you",
                            image: uiImage,
                            icon: "paintbrush.fill",
                            packID: "makeup_pack"
                        ) {
                            selectedPack = .makeupPack
                        }
                        .id("makeup_pack")
                    }

                    // Hair Color Pack (only if selected)
                    if profile.selectedPacks.contains("hair"),
                       let hairURL = profile.hairColorPackImageURL,
                       let uiImage = UIImage(contentsOfFile: hairURL.path) {
                        PackCard(
                            title: "Hair Color Ideas",
                            subtitle: "Hair colors that enhance your season",
                            image: uiImage,
                            icon: "person.crop.circle.fill",
                            packID: "hair_pack"
                        ) {
                            selectedPack = .hairColorPack
                        }
                        .id("hair_pack")
                    }
                }

                Divider()
                    .padding(.horizontal)

                // Style Cards Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Style Cards")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    // Contrast Card
                    if let contrastCard = profile.contrastCard {
                        TextCardPreview(
                            title: "Contrast Guide",
                            subtitle: contrastCard.contrastLevel.rawValue,
                            icon: "circle.lefthalf.filled",
                            color: .purple
                        ) {
                            selectedPack = .contrastCard
                        }
                        .id("contrast_card")
                    }

                    // Neutrals & Metals Card
                    if let neutralsCard = profile.neutralsMetalsCard {
                        TextCardPreview(
                            title: "Neutrals & Metals",
                            subtitle: "\(neutralsCard.bestNeutrals.count) best neutrals • \(neutralsCard.bestMetals.count) best metals",
                            icon: "paintpalette.fill",
                            color: .pink
                        ) {
                            selectedPack = .neutralsMetalsCard
                        }
                        .id("neutrals_card")
                    }
                }

                Spacer().frame(height: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Profile Analysis Detail
private struct ProfileAnalysisDetail: View {
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

// MARK: - Pack Card
struct PackCard: View {
    let title: String
    let subtitle: String
    let image: UIImage
    let icon: String
    let packID: String  // Add unique identifier
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(height: 200)
                .clipped()
                .cornerRadius(12)

            // Title and subtitle
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.purple)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        .contentShape(Rectangle())  // Make entire card tappable
        .onTapGesture {
            action()
        }
        .padding(.horizontal)
    }
}

// MARK: - Text Card Preview
struct TextCardPreview: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(color)
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        }
        .buttonStyle(.plain)
        .padding(.horizontal)
    }
}

// MARK: - Wardrobe Tab
struct WardrobeTab: View {
    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.purple.opacity(0.3))

                Text("Wardrobe Coming Soon")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("Shop personalized clothing recommendations\nbased on your color profile")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
        }
    }
}

// MARK: - Pack Detail Type
enum PackDetailType: Identifiable {
    case drapesGrid
    case texturePack
    case jewelryPack
    case makeupPack
    case hairColorPack
    case contrastCard
    case neutralsMetalsCard

    var id: String {
        switch self {
        case .drapesGrid: return "drapes"
        case .texturePack: return "texture"
        case .jewelryPack: return "jewelry"
        case .makeupPack: return "makeup"
        case .hairColorPack: return "hair"
        case .contrastCard: return "contrast"
        case .neutralsMetalsCard: return "neutrals"
        }
    }
}

#Preview {
    ProfileDashboardView()
        .environmentObject(AppState())
}
