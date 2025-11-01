//
//  StoreGridView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import SwiftUI
import AVFoundation

// MARK: - Browser Content (to fix state timing issue)
struct BrowserContent: Identifiable, Hashable {
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

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: BrowserContent, rhs: BrowserContent) -> Bool {
        lhs.id == rhs.id
    }
}

struct StoreGridView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var browserContent: BrowserContent?
    @State private var imagePickerSource: UIImagePickerController.SourceType?
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
                        checkCameraPermissionAndOpen()
                    }

                    // Photo Library Card
                    QuickActionCard(
                        icon: "photo.fill",
                        title: "Photo Library",
                        subtitle: "Saved images",
                        gradientColors: [.blue, .purple]
                    ) {
                        imagePickerSource = .photoLibrary
                    }
                }
                .padding(.horizontal)

                // Enter Custom URL Card
                CustomURLCard {
                    // Open browser with Google (blank slate for browsing)
                    browserContent = BrowserContent(customURL: "https://www.google.com")
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
                            browserContent = BrowserContent(store: store)
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
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark")
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
        }
        .navigationDestination(item: $browserContent) { content in
            Group {
                if let store = content.store {
                    TryOnBrowserView(store: store)
                        .environmentObject(appState)
                } else if let url = content.customURL {
                    TryOnBrowserView(customURL: url)
                        .environmentObject(appState)
                }
            }
        }
        .fullScreenCover(item: $imagePickerSource) { sourceType in
            GarmentImagePicker(image: $selectedGarmentImage, sourceType: sourceType)
                .ignoresSafeArea()
        }
        .onChange(of: selectedGarmentImage) { oldValue, newValue in
            if let image = newValue {
                saveGarmentFromImage(image)
            }
        }
    }

    private func saveGarmentFromImage(_ image: UIImage) {
        Task {
            // Save to cache
            guard let garmentURL = TryOnCacheManager.shared.saveGarment(image) else {
                return
            }

            // Get profile
            guard var profile = appState.currentProfile else {
                return
            }

            // Create garment item WITHOUT color analysis (will analyze on try-on)
            let garment = GarmentItem(
                imageURL: garmentURL,
                sourceStore: "Photo",
                productURL: nil,
                dominantColorHex: nil,
                matchesUserSeason: false,  // Will be analyzed during try-on
                colorMatchScore: nil  // Will be analyzed during try-on
            )

            // Add to profile and save immediately
            profile.savedGarments.append(garment)
            appState.saveProfile(profile)

            // Haptic feedback
            await MainActor.run {
                HapticManager.shared.success()
            }
        }
    }

    private func checkCameraPermissionAndOpen() {
        // Check if camera is available (fails on Simulator)
        #if targetEnvironment(simulator)
        imagePickerSource = .photoLibrary
        return
        #endif

        // Check if camera source is available
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            imagePickerSource = .photoLibrary
            return
        }

        let cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)

        switch cameraAuthorizationStatus {
        case .authorized:
            // Permission already granted, open camera
            imagePickerSource = .camera

        case .notDetermined:
            // Request permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        self.imagePickerSource = .camera
                    }
                }
            }

        case .denied, .restricted:
            // Permission previously denied
            break

        @unknown default:
            break
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
                // Store Logo Card
                ZStack {
                    // Use custom logo if available, otherwise fallback to tag icon with name
                    if let logoName = store.logoImageName {
                        Image(logoName)
                            .resizable()
                            .scaledToFit()
                            .padding(20)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)

                            Text(store.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 120)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 2)

                // Category Badge
                Text(store.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
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

        // Check if the requested source type is available
        if UIImagePickerController.isSourceTypeAvailable(sourceType) {
            picker.sourceType = sourceType
        } else {
            picker.sourceType = .photoLibrary
        }

        picker.delegate = context.coordinator

        // No editing - user will crop after selection in TryOnProcessView
        picker.allowsEditing = false

        // Set camera settings for better compatibility
        if sourceType == .camera {
            picker.cameraCaptureMode = .photo
            picker.cameraDevice = .rear
        }

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
            // Always use original image (no editing enabled)
            if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - UIImagePickerController.SourceType + Identifiable
extension UIImagePickerController.SourceType: Identifiable {
    public var id: Int {
        return self.rawValue
    }
}

#Preview {
    StoreGridView()
}
