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
    @State private var showStartOverOptions = false

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
                    // Home Tab
                    ProfileTab(profile: profile, selectedPack: $selectedPack)
                        .tabItem {
                            Label("Home", systemImage: "house.fill")
                        }
                        .tag(0)

                    // History Tab
                    HistoryView()
                        .environmentObject(appState)
                        .tabItem {
                            Label("History", systemImage: "clock.arrow.circlepath")
                        }
                        .tag(1)

                    // Try-On Tab
                    TryOnTab()
                        .environmentObject(appState)
                        .tabItem {
                            Label("Try-On", systemImage: "tshirt.fill")
                        }
                        .tag(2)

                    // Settings Tab
                    SettingsView()
                        .environmentObject(appState)
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                        .tag(3)
                }
                .navigationBarBackButtonHidden(true)
                .toolbar {
                    // Show "Start Over" button only on Home and Try-On tabs
                    if selectedTab == 0 || selectedTab == 2 {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                showStartOverOptions = true
                            }) {
                                Text("Start Over")
                                    .font(.body)
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                }
                .navigationDestination(item: $selectedPack) { packType in
                    PackDetailView(profile: profile, packType: packType)
                        .environmentObject(appState)
                        .navigationBarBackButtonHidden(false)
                }
                .confirmationDialog("Start Over", isPresented: $showStartOverOptions) {
                    Button("Choose a new focus color") {
                        regenerateFromFocusColor()
                    }
                    Button("Retake selfie and start fresh") {
                        retakeSelfie()
                    }
                    Button("Cancel", role: .cancel) {}
                } message: {
                    Text("What would you like to do?")
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
        // Clear focus color and all generated packs (keep selfie and draping results)
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
                            Text("This is worth the wait — up to 60 seconds")
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

// MARK: - Try-On Tab
struct TryOnTab: View {
    @EnvironmentObject var appState: AppState
    @State private var showSetup = false
    @State private var showStoreGrid = false
    @State private var showSavedGarments = false
    @State private var showCreditsPurchase = false
    @State private var selectedGarment: GarmentItem?
    @State private var selectedResult: TryOnResult?
    @State private var showRetakeSelfie = false
    @State private var showRetakeFullBody = false
    @State private var newSelfieImage: UIImage?
    @State private var newFullBodyImage: UIImage?

    private var profile: UserProfile? {
        appState.currentProfile
    }

    private var isSetupComplete: Bool {
        profile?.hasTryOnSetup ?? false
    }

    private var credits: Int {
        profile?.tryOnCredits ?? 0
    }

    private var savedGarments: [GarmentItem] {
        // Reverse order so newest garments appear first (left side of carousel)
        (profile?.savedGarments ?? []).reversed()
    }

    private var recentTryOns: [TryOnResult] {
        (profile?.tryOnHistory ?? [])
            .filter { $0.isRecent }
            .sorted { $0.createdAt > $1.createdAt }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                if !isSetupComplete {
                    // Setup required
                    setupRequiredView
                } else {
                    // Main try-on interface
                    mainTryOnView
                }
            }
            .navigationTitle("Try-On")
            .navigationBarTitleDisplayMode(.large)
            .fullScreenCover(isPresented: $showSetup) {
                NavigationStack {
                    FullBodyPhotoSetupView()
                        .environmentObject(appState)
                }
            }
            .fullScreenCover(isPresented: $showStoreGrid) {
                NavigationStack {
                    StoreGridView()
                        .environmentObject(appState)
                }
            }
            .fullScreenCover(isPresented: $showSavedGarments) {
                NavigationStack {
                    SavedGarmentsView()
                        .environmentObject(appState)
                }
            }
            .fullScreenCover(isPresented: $showCreditsPurchase) {
                NavigationStack {
                    CreditsPurchaseView()
                        .environmentObject(appState)
                }
            }
            .fullScreenCover(item: $selectedGarment) { garment in
                NavigationStack {
                    TryOnProcessView(garment: garment)
                        .environmentObject(appState)
                }
            }
            .fullScreenCover(item: $selectedResult) { result in
                TryOnResultView(result: result)
                    .environmentObject(appState)
            }
            .fullScreenCover(isPresented: $showRetakeSelfie) {
                ImagePicker(image: $newSelfieImage, sourceType: .photoLibrary)
                    .ignoresSafeArea()
            }
            .fullScreenCover(isPresented: $showRetakeFullBody) {
                FullBodyImagePicker(image: $newFullBodyImage, sourceType: .photoLibrary)
                    .ignoresSafeArea()
            }
            .onChange(of: newSelfieImage) { _, newImage in
                if let image = newImage, var currentProfile = profile {
                    currentProfile.selfieImageData = image.jpegData(compressionQuality: 0.8)
                    appState.saveProfile(currentProfile)
                    print("✅ Updated selfie photo")
                    newSelfieImage = nil
                    HapticManager.shared.success()
                }
            }
            .onChange(of: newFullBodyImage) { _, newImage in
                if let image = newImage, var currentProfile = profile {
                    currentProfile.fullBodyPhotoData = image.jpegData(compressionQuality: 0.8)
                    appState.saveProfile(currentProfile)
                    print("✅ Updated full body photo")
                    newFullBodyImage = nil
                    HapticManager.shared.success()
                }
            }
        }
    }

    // MARK: - Setup Required View
    private var setupRequiredView: some View {
        VStack(spacing: 30) {
            Spacer()

            Image(systemName: "wand.and.stars")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 12) {
                Text("Virtual Try-On")
                    .font(.title)
                    .fontWeight(.bold)

                Text("See how clothes look on you before buying")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 30)
            }

            VStack(spacing: 12) {
                SimpleFeatureRow(icon: "photo.fill", text: "Upload one full-body photo")
                SimpleFeatureRow(icon: "bag.fill", text: "Browse 25+ fashion stores")
                SimpleFeatureRow(icon: "paintpalette.fill", text: "Get instant color analysis")
                SimpleFeatureRow(icon: "leaf.fill", text: "Shop smarter, waste less")
            }

            Spacer()

            Button(action: { showSetup = true }) {
                HStack {
                    Image(systemName: "arrow.right.circle.fill")
                    Text("Get Started")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 40)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Main Try-On View
    private var mainTryOnView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Credits balance
                creditsBalanceCard

                // User photos
                if let currentProfile = profile {
                    userPhotosSection(profile: currentProfile)
                }

                // Quick actions
                quickActionsSection

                // Saved garments preview
                if !savedGarments.isEmpty {
                    savedGarmentsSection
                }

                // Recent try-ons
                if !recentTryOns.isEmpty {
                    recentTryOnsSection
                }

                Spacer().frame(height: 40)
            }
            .padding()
        }
    }

    // MARK: - Credits Balance Card
    private var creditsBalanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Your Credits")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(CreditsManager.formatCredits(credits))
                    .font(.title)
                    .fontWeight(.bold)

                Text("1 credit per Try-On")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Button(action: { showCreditsPurchase = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                    Text("Buy Credits")
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(20)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }

    // MARK: - User Photos Section
    @ViewBuilder
    private func userPhotosSection(profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your Photos")
                .font(.headline)
                .padding(.horizontal, 4)

            HStack(spacing: 16) {
                // Selfie Photo
                VStack(spacing: 8) {
                    if let selfieImage = profile.selfieImage {
                        Image(uiImage: selfieImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [.purple, .pink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    } else {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 100, height: 100)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                            }
                    }

                    Text("Selfie")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button(action: { showRetakeSelfie = true }) {
                        Text("Change")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                    }
                }
                .frame(maxWidth: .infinity)

                // Full Body Photo
                VStack(spacing: 8) {
                    if let fullBodyImage = profile.fullBodyImage {
                        Image(uiImage: fullBodyImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 100, height: 140)
                            .clipped()
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        LinearGradient(
                                            colors: [.purple, .pink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        ),
                                        lineWidth: 2
                                    )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemGray5))
                            .frame(width: 100, height: 140)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundColor(.secondary)
                            }
                    }

                    Text("Full Body")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button(action: { showRetakeFullBody = true }) {
                        Text("Change")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.purple)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
        }
    }

    // MARK: - Quick Actions
    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
                .padding(.horizontal, 4)

            HStack(spacing: 12) {
                DashboardQuickActionCard(
                    icon: "bag.fill",
                    title: "Browse Stores",
                    color: .purple
                ) {
                    showStoreGrid = true
                }

                DashboardQuickActionCard(
                    icon: "photo.fill",
                    title: "My Garments",
                    color: .pink
                ) {
                    showSavedGarments = true
                }
            }
        }
    }

    // MARK: - Saved Garments Section
    private var savedGarmentsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Saved Garments")
                    .font(.headline)

                Spacer()

                Button("See All") {
                    showSavedGarments = true
                }
                .font(.subheadline)
                .foregroundColor(.purple)
            }
            .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(savedGarments.prefix(5)) { garment in
                        SavedGarmentThumbnail(garment: garment) {
                            print("🖼️ [TryOnTab] Garment thumbnail tapped: \(garment.id)")
                            selectedGarment = garment
                        }
                    }
                }
            }
        }
    }

    // MARK: - Recent Try-Ons Section
    private var recentTryOnsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Recent Try-Ons")
                    .font(.headline)

                Text("Permanent history of credits used")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.8))
            }
            .padding(.horizontal, 4)

            ForEach(recentTryOns.prefix(3)) { result in
                RecentTryOnCard(result: result) {
                    print("🖼️ [TryOnTab] Try-on result tapped: \(result.id)")
                    selectedResult = result
                }
            }
        }
    }
}

// MARK: - Simple Feature Row (for Try-On)
private struct SimpleFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Dashboard Quick Action Card
private struct DashboardQuickActionCard: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title)
                    .foregroundColor(.white)

                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(
                LinearGradient(
                    colors: [color, color.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Saved Garment Thumbnail
private struct SavedGarmentThumbnail: View {
    let garment: GarmentItem
    let action: () -> Void
    @State private var garmentImage: UIImage?

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if let image = garmentImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 120)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(width: 100, height: 120)
                }

                if let store = garment.sourceStore {
                    Text(store)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .frame(width: 100)
                }
            }
        }
        .buttonStyle(.plain)
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: garment.imageURL),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.garmentImage = image
                }
            }
        }
    }
}

// MARK: - Recent Try-On Card
private struct RecentTryOnCard: View {
    let result: TryOnResult
    let action: () -> Void
    @State private var resultImage: UIImage?

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Result thumbnail with video badge
                ZStack(alignment: .topTrailing) {
                    if let image = resultImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 80, height: 100)
                            .clipped()
                            .cornerRadius(8)
                    } else {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemGray5))
                            .frame(width: 80, height: 100)
                    }

                    // Video badge if video exists
                    if result.videoURL != nil {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .background(
                                Circle()
                                    .fill(Color.green.opacity(0.9))
                                    .frame(width: 24, height: 24)
                            )
                            .padding(6)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    if let store = result.garmentItem.sourceStore {
                        Text(store)
                            .font(.headline)
                    }

                    Text(result.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.caption2)
                        Text("\(result.creditsUsed) credits")
                            .font(.caption2)
                    }
                    .foregroundColor(.purple)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: result.resultImageURL),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.resultImage = image
                }
            }
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
