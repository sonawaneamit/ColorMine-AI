//
//  ProfileDashboardView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import SwiftUI

struct ProfileDashboardView: View {
    @EnvironmentObject var appState: AppState
    let profile: UserProfile

    @State private var selectedTab = 0
    @State private var selectedPack: PackDetailType?
    @State private var showRegenerateOptions = false

    var body: some View {
        TabView(selection: $selectedTab) {
            // Profile Tab
            ProfileTab(profile: profile, selectedPack: $selectedPack)
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(0)

            // Wardrobe Tab
            WardrobeTab()
                .tabItem {
                    Label("Wardrobe", systemImage: "tshirt.fill")
                }
                .tag(1)
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

            #if DEBUG
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    debugClearProfile()
                }) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
            }
            #endif
        }
        .sheet(item: $selectedPack) { packType in
            PackDetailView(profile: profile, packType: packType)
        }
        .confirmationDialog("Regenerate Content", isPresented: $showRegenerateOptions) {
            Button("Change Focus Color & Regenerate Packs") {
                regenerateFromFocusColor()
            }
            Button("Retake Selfie & Start Over") {
                retakeSelfie()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Choose what you'd like to regenerate")
        }
        .onAppear {
            // Clear notification badge when viewing dashboard
            NotificationManager.shared.clearBadge()
        }
    }

    // MARK: - Regenerate from Focus Color
    private func regenerateFromFocusColor() {
        var updatedProfile = profile
        // Clear focus color and all generated packs
        updatedProfile.focusColor = nil
        updatedProfile.texturePackImageURL = nil
        updatedProfile.jewelryPackImageURL = nil
        updatedProfile.makeupPackImageURL = nil
        updatedProfile.packsGenerated.textures = false
        updatedProfile.packsGenerated.jewelry = false
        updatedProfile.packsGenerated.makeup = false
        updatedProfile.packsGenerated.contrastCard = false
        updatedProfile.packsGenerated.neutralsMetalsCard = false
        appState.saveProfile(updatedProfile)
    }

    // MARK: - Retake Selfie
    private func retakeSelfie() {
        appState.clearProfile()
    }

    // MARK: - Debug Clear Profile
    #if DEBUG
    private func debugClearProfile() {
        appState.clearProfile()
        print("🐛 DEBUG: Profile cleared - restarting flow")
    }
    #endif
}

// MARK: - Profile Tab
struct ProfileTab: View {
    let profile: UserProfile
    @Binding var selectedPack: PackDetailType?

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    // Season badge
                    Text(profile.season.rawValue)
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    // Analysis summary
                    HStack(spacing: 16) {
                        InfoPill(icon: "circle.hexagongrid", text: profile.undertone.rawValue)
                        InfoPill(icon: "circle.lefthalf.filled", text: profile.contrast.rawValue)
                        InfoPill(icon: "calendar", text: profile.scanDate.formatted(date: .abbreviated, time: .omitted))
                    }

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
                .padding(.top, 20)

                Divider()
                    .padding(.horizontal)

                // AI Packs Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your AI Packs")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.horizontal)

                    // Drapes Grid
                    if let drapesURL = profile.drapesGridImageURL,
                       let uiImage = UIImage(contentsOfFile: drapesURL.path) {
                        PackCard(
                            title: "Drapes Grid",
                            subtitle: "See yourself in your colors",
                            image: uiImage,
                            icon: "square.grid.3x3.fill"
                        ) {
                            selectedPack = .drapesGrid
                        }
                    }

                    // Texture Pack
                    if let textureURL = profile.texturePackImageURL,
                       let uiImage = UIImage(contentsOfFile: textureURL.path) {
                        PackCard(
                            title: "Texture Pack",
                            subtitle: "Perfect fabric patterns for you",
                            image: uiImage,
                            icon: "square.grid.3x3.fill"
                        ) {
                            selectedPack = .texturePack
                        }
                    }

                    // Jewelry Pack
                    if let jewelryURL = profile.jewelryPackImageURL,
                       let uiImage = UIImage(contentsOfFile: jewelryURL.path) {
                        PackCard(
                            title: "Jewelry Pack",
                            subtitle: "Metals and gems that shine on you",
                            image: uiImage,
                            icon: "sparkles"
                        ) {
                            selectedPack = .jewelryPack
                        }
                    }

                    // Makeup Pack
                    if let makeupURL = profile.makeupPackImageURL,
                       let uiImage = UIImage(contentsOfFile: makeupURL.path) {
                        PackCard(
                            title: "Makeup Pack",
                            subtitle: "Your ideal makeup shades",
                            image: uiImage,
                            icon: "paintbrush.fill"
                        ) {
                            selectedPack = .makeupPack
                        }
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
                    }
                }

                Spacer().frame(height: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Info Pill
struct InfoPill: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Pack Card
struct PackCard: View {
    let title: String
    let subtitle: String
    let image: UIImage
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
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
        }
        .buttonStyle(.plain)
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
    case contrastCard
    case neutralsMetalsCard

    var id: String {
        switch self {
        case .drapesGrid: return "drapes"
        case .texturePack: return "texture"
        case .jewelryPack: return "jewelry"
        case .makeupPack: return "makeup"
        case .contrastCard: return "contrast"
        case .neutralsMetalsCard: return "neutrals"
        }
    }
}

#Preview {
    ProfileDashboardView(
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
