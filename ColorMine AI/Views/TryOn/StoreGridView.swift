//
//  StoreGridView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import SwiftUI

// MARK: - Browser Content (to fix state timing issue)
struct BrowserContent: Identifiable {
    let id = UUID()
    let store: Store?
    let customURL: String?

    init(store: Store) {
        self.store = store
        self.customURL = nil
    }

    init(customURL: String) {
        self.store = nil
        self.customURL = customURL
    }
}

struct StoreGridView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var browserContent: BrowserContent?
    @State private var showURLInput = false
    @State private var urlInputText = ""
    @State private var showImagePicker = false
    @State private var imageSourceType: UIImagePickerController.SourceType = .photoLibrary
    @State private var selectedGarmentImage: UIImage?

    private let stores = Store.predefinedStores

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Subtitle
                Text("Browse stores and try outfits virtually")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 8)

                // Quick Actions Grid (Camera & Photo Library)
                HStack(spacing: 12) {
                    // Take Photo Card
                    QuickActionCard(
                        icon: "camera.fill",
                        title: "Take Photo",
                        subtitle: "From a store",
                        gradientColors: [.orange, .red]
                    ) {
                        imageSourceType = .camera
                        showImagePicker = true
                    }

                    // Photo Library Card
                    QuickActionCard(
                        icon: "photo.fill",
                        title: "Photo Library",
                        subtitle: "Saved images",
                        gradientColors: [.blue, .purple]
                    ) {
                        imageSourceType = .photoLibrary
                        showImagePicker = true
                    }
                }
                .padding(.horizontal)

                // Enter Custom URL Card
                CustomURLCard {
                    showURLInput = true
                }
                .padding(.horizontal)

                // Divider
                VStack(spacing: 8) {
                    HStack {
                        VStack {
                            Divider()
                        }
                        Text("or browse our partners")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                        VStack {
                            Divider()
                        }
                    }
                }
                .padding(.horizontal)

                // Store Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(stores) { store in
                        StoreCard(store: store) {
                            print("🛍️ [StoreGrid] Store tapped: \(store.name), URL: \(store.url)")
                            browserContent = BrowserContent(store: store)
                            print("🛍️ [StoreGrid] browserContent set with store: \(store.name)")
                        }
                    }
                }
                .padding(.horizontal)

                Spacer().frame(height: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Shop Your Colors")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .sheet(item: $browserContent) { content in
            Group {
                if let store = content.store {
                    let _ = print("🎬 [StoreGrid] sheet presenting store: \(store.name)")
                    TryOnBrowserView(store: store)
                        .environmentObject(appState)
                } else if let url = content.customURL {
                    let _ = print("🎬 [StoreGrid] sheet presenting custom URL: \(url)")
                    TryOnBrowserView(customURL: url)
                        .environmentObject(appState)
                }
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showURLInput) {
            URLInputSheet(urlText: $urlInputText) { url in
                print("🌐 [StoreGrid] Custom URL submitted: \(url)")
                browserContent = BrowserContent(customURL: url)
                print("🌐 [StoreGrid] browserContent set with custom URL")
            }
        }
        .sheet(isPresented: $showImagePicker) {
            GarmentImagePicker(image: $selectedGarmentImage, sourceType: imageSourceType)
        }
        .onChange(of: selectedGarmentImage) { oldValue, newValue in
            if let image = newValue {
                saveGarmentFromImage(image)
            }
        }
    }

    private func saveGarmentFromImage(_ image: UIImage) {
        Task {
            guard let imageData = image.jpegData(compressionQuality: 0.8) else { return }

            // Save to cache
            guard let garmentURL = TryOnCacheManager.shared.saveGarment(image) else {
                print("❌ Failed to save garment image")
                return
            }

            // Get profile
            guard var profile = appState.currentProfile else {
                print("❌ No current profile")
                return
            }

            // Analyze garment color using OpenAI
            let season = profile.season

            print("🎨 Analyzing garment color with OpenAI...")

            do {
                let analysis = try await OpenAIService.shared.analyzeGarmentColor(
                    garmentImage: image,
                    userSeason: season
                )

                // Create garment item
                let garment = GarmentItem(
                    imageURL: garmentURL,
                    sourceStore: "Photo",
                    productURL: nil,
                    dominantColorHex: nil,
                    matchesUserSeason: analysis.matchScore >= 70,
                    colorMatchScore: analysis.matchScore
                )

                // Add to profile
                profile.savedGarments.append(garment)
                appState.saveProfile(profile)

                print("✅ Garment saved from photo: \(garment.id) with \(analysis.matchScore)% match")

                // Haptic feedback
                await MainActor.run {
                    HapticManager.shared.success()
                }

            } catch {
                print("❌ Failed to analyze garment color: \(error.localizedDescription)")
                // Still save garment but without color analysis
                let garment = GarmentItem(
                    imageURL: garmentURL,
                    sourceStore: "Photo",
                    productURL: nil,
                    dominantColorHex: nil,
                    matchesUserSeason: false,
                    colorMatchScore: nil
                )
                profile.savedGarments.append(garment)
                appState.saveProfile(profile)

                print("✅ Garment saved from photo without color analysis")
            }
        }
    }
}

// MARK: - Store Card
struct StoreCard: View {
    let store: Store
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Store Icon/Logo
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)

                    VStack(spacing: 8) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)

                        Text(store.name)
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }

                // Category Badge
                Text(store.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var gradientColors: [Color] {
        // Vary gradient based on category
        switch store.category {
        case .luxury:
            return [.purple, .pink]
        case .fashion:
            return [.blue, .cyan]
        case .streetwear:
            return [.orange, .red]
        case .athletic:
            return [.green, .mint]
        case .sustainable:
            return [.teal, .green]
        }
    }
}

// MARK: - Quick Action Card (Camera/Photo Library)
struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradientColors: [Color]
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 100)

                    Image(systemName: icon)
                        .font(.system(size: 35))
                        .foregroundColor(.white)
                }

                // Labels
                VStack(spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Custom URL Card
struct CustomURLCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: "globe")
                    .font(.system(size: 30))
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(
                        LinearGradient(
                            colors: [.indigo, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Browse Any Website")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Enter a URL to shop anywhere")
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
    }
}

// MARK: - URL Input Sheet
struct URLInputSheet: View {
    @Binding var urlText: String
    let onSubmit: (String) -> Void
    @Environment(\.dismiss) private var dismiss

    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Enter Website URL")
                        .font(.headline)

                    TextField("https://www.example.com", text: $urlText)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .focused($isFocused)
                }
                .padding()

                Button(action: submitURL) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Open Website")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(urlText.isEmpty)
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 20)
            .navigationTitle("Browse Any Site")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                isFocused = true
            }
        }
    }

    private func submitURL() {
        var finalURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)

        // Add https:// if no scheme provided
        if !finalURL.hasPrefix("http://") && !finalURL.hasPrefix("https://") {
            finalURL = "https://\(finalURL)"
        }

        onSubmit(finalURL)
        dismiss()
    }
}

// MARK: - Garment Image Picker
struct GarmentImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: GarmentImagePicker

        init(_ parent: GarmentImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    StoreGridView()
}
