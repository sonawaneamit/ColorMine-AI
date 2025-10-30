//
//  PackDetailView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import SwiftUI

struct PackDetailView: View {
    let profile: UserProfile
    let packType: PackDetailType

    @State private var imageToShare: UIImage?
    @State private var showSaveAlert = false
    @State private var saveAlertMessage = ""

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Show appropriate content based on pack type
                    switch packType {
                        case .drapesGrid:
                            if let url = profile.drapesGridImageURL,
                               let image = UIImage(contentsOfFile: url.path) {
                                ImagePackDetail(
                                    title: "Drapes Grid",
                                    description: "See yourself wearing your perfect colors",
                                    image: image,
                                    onShare: { shareImage(image) }
                                )
                            }

                        case .texturePack:
                            if let url = profile.texturePackImageURL,
                               let image = UIImage(contentsOfFile: url.path) {
                                ImagePackDetail(
                                    title: "Texture Pack",
                                    description: "Fabric patterns that enhance your natural coloring",
                                    image: image,
                                    onShare: { shareImage(image) }
                                )
                            }

                        case .jewelryPack:
                            if let url = profile.jewelryPackImageURL,
                               let image = UIImage(contentsOfFile: url.path) {
                                ImagePackDetail(
                                    title: "Jewelry Pack",
                                    description: "Metals and gemstones that illuminate your features",
                                    image: image,
                                    onShare: { shareImage(image) }
                                )
                            }

                        case .makeupPack:
                            if let url = profile.makeupPackImageURL,
                               let image = UIImage(contentsOfFile: url.path) {
                                MakeupPackDetail(
                                    profile: profile,
                                    image: image,
                                    onShare: { shareImage(image) }
                                )
                            }

                        case .hairColorPack:
                            if let url = profile.hairColorPackImageURL,
                               let image = UIImage(contentsOfFile: url.path) {
                                ImagePackDetail(
                                    title: "Hair Color Pack",
                                    description: "Hair colors that complement your season",
                                    image: image,
                                    onShare: { shareImage(image) }
                                )
                            }

                        case .contrastCard:
                            if let card = profile.contrastCard {
                                ContrastCardDetail(card: card)
                            }

                        case .neutralsMetalsCard:
                            if let card = profile.neutralsMetalsCard {
                                NeutralsMetalsCardDetail(card: card)
                            }
                    }
                }
                .padding()
            }
        }
        .navigationTitle(packType.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: Binding(
            get: { imageToShare.map { ShareableImage(image: $0) } },
            set: { imageToShare = $0?.image }
        )) { shareableImage in
            ShareSheet(items: [ImageWatermarkUtility.shared.addWatermark(to: shareableImage.image)])
        }
        .alert("Image Saved", isPresented: $showSaveAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveAlertMessage)
        }
    }

    private func shareImage(_ image: UIImage) {
        imageToShare = image

        // Request review after user shares (they're happy with results!)
        ReviewManager.shared.requestReviewAfterShare()
    }
}

// MARK: - Shareable Image
struct ShareableImage: Identifiable {
    let id = UUID()
    let image: UIImage
}

// MARK: - Image Pack Detail
struct ImagePackDetail: View {
    let title: String
    let description: String
    let image: UIImage
    let onShare: () -> Void

    @State private var showZoomView = false

    var body: some View {
        VStack(spacing: 20) {
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Image with tap to zoom
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(16)
                .shadow(radius: 10)
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
            Button(action: onShare) {
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
        .sheet(isPresented: $showZoomView) {
            PackZoomImageView(image: image, title: title)
        }
    }
}

// MARK: - Pack Zoom Image View
struct PackZoomImageView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage
    let title: String

    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @GestureState private var magnifyBy: CGFloat = 1.0
    @GestureState private var dragOffset: CGSize = .zero
    @State private var showShareSheet = false

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ZStack {
                    Color.black
                        .ignoresSafeArea()

                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale * magnifyBy)
                        .offset(x: offset.width + dragOffset.width, y: offset.height + dragOffset.height)
                        .gesture(makeMagnificationGesture())
                        .simultaneousGesture(makeDragGesture(imageSize: geometry.size))
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
            .navigationTitle(title)
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

// MARK: - Makeup Pack Detail
struct MakeupPackDetail: View {
    let profile: UserProfile
    let image: UIImage
    let onShare: () -> Void

    var body: some View {
        ImagePackDetail(
            title: "Makeup Pack",
            description: "Makeup looks tailored to your season and undertone",
            image: image,
            onShare: onShare
        )
    }
}

// MARK: - Makeup Slider
struct MakeupSlider: View {
    let label: String
    @Binding var value: Double
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.purple)
                    .frame(width: 20)
                Text(label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text("\(Int(value))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Slider(value: $value, in: 0...100, step: 5)
                .tint(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
        }
        .padding(.horizontal)
    }
}

// MARK: - Contrast Card Detail
struct ContrastCardDetail: View {
    let card: ContrastCard

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "circle.lefthalf.filled")
                        .font(.title)
                        .foregroundColor(.purple)
                    Text(card.contrastLevel.rawValue + " Contrast")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Text(card.description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)

            // Tips
            VStack(alignment: .leading, spacing: 12) {
                Text("Styling Tips")
                    .font(.headline)
                    .padding(.horizontal)

                ForEach(card.tips, id: \.self) { tip in
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)

                        Text(tip)
                            .font(.body)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                }
            }
        }
    }
}

// MARK: - Neutrals & Metals Card Detail
struct NeutralsMetalsCardDetail: View {
    let card: NeutralsMetalsCard

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "paintpalette.fill")
                        .font(.title)
                        .foregroundColor(.pink)
                    Text("Neutrals & Metals Guide")
                        .font(.title2)
                        .fontWeight(.bold)
                }

                Text("Based on your \(card.undertone.rawValue) undertone")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)

            // Best Neutrals
            VStack(alignment: .leading, spacing: 12) {
                Label("Best Neutrals", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding(.horizontal)

                ForEach(card.bestNeutrals) { neutral in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(neutral.color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(neutral.name)
                                .font(.body)
                                .fontWeight(.medium)
                            Text("#\(neutral.hex)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(16)

            // Best Metals
            VStack(alignment: .leading, spacing: 12) {
                Label("Best Metals", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundColor(.purple)
                    .padding(.horizontal)

                ForEach(card.bestMetals) { metal in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [metal.color, metal.color.opacity(0.7), metal.color],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: metal.color.opacity(0.3), radius: 2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(metal.name)
                                .font(.body)
                                .fontWeight(.medium)
                            Text("#\(metal.hex)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(16)

            // Avoid Neutrals
            VStack(alignment: .leading, spacing: 12) {
                Label("Avoid These Neutrals", systemImage: "xmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding(.horizontal)

                ForEach(card.avoidsNeutrals) { neutral in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(neutral.color)
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .opacity(0.6)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(neutral.name)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Text("#\(neutral.hex)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(16)

            // Avoid Metals
            VStack(alignment: .leading, spacing: 12) {
                Label("Avoid These Metals", systemImage: "xmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding(.horizontal)

                ForEach(card.avoidsMetals) { metal in
                    HStack(spacing: 12) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [metal.color, metal.color.opacity(0.7), metal.color],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 40, height: 40)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .opacity(0.6)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(metal.name)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            Text("#\(metal.hex)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(16)
        }
    }
}

// MARK: - Pack Detail Type Extension
extension PackDetailType {
    var displayTitle: String {
        switch self {
        case .drapesGrid: return "Drapes Grid"
        case .texturePack: return "Texture Pack"
        case .jewelryPack: return "Jewelry Pack"
        case .makeupPack: return "Makeup Pack"
        case .hairColorPack: return "Hair Color Pack"
        case .contrastCard: return "Contrast Guide"
        case .neutralsMetalsCard: return "Neutrals & Metals"
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    PackDetailView(
        profile: UserProfile(
            selfieImageData: nil,
            season: .clearSpring,
            undertone: .warm,
            contrast: .high,
            confidence: 0.89
        ),
        packType: .contrastCard
    )
}
