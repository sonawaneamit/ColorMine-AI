//
//  PackDetailView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import SwiftUI

struct PackDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let profile: UserProfile
    let packType: PackDetailType

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    var body: some View {
        NavigationStack {
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
                                    image: image
                                )
                            }

                        case .texturePack:
                            if let url = profile.texturePackImageURL,
                               let image = UIImage(contentsOfFile: url.path) {
                                ImagePackDetail(
                                    title: "Texture Pack",
                                    description: "Fabric patterns that enhance your natural coloring",
                                    image: image
                                )
                            }

                        case .jewelryPack:
                            if let url = profile.jewelryPackImageURL,
                               let image = UIImage(contentsOfFile: url.path) {
                                ImagePackDetail(
                                    title: "Jewelry Pack",
                                    description: "Metals and gemstones that illuminate your features",
                                    image: image
                                )
                            }

                        case .makeupPack:
                            if let url = profile.makeupPackImageURL,
                               let image = UIImage(contentsOfFile: url.path) {
                                MakeupPackDetail(
                                    profile: profile,
                                    image: image
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Image Pack Detail
struct ImagePackDetail: View {
    let title: String
    let description: String
    let image: UIImage

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        VStack(spacing: 20) {
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            GeometryReader { geometry in
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(16)
                    .shadow(radius: 10)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    // Reset to minimum scale of 1.0
                                    if scale < 1.0 {
                                        withAnimation(.spring()) {
                                            scale = 1.0
                                            lastScale = 1.0
                                            offset = .zero
                                            lastOffset = .zero
                                        }
                                    }
                                },
                            DragGesture()
                                .onChanged { value in
                                    // Only allow dragging when zoomed in
                                    if scale > 1.0 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                    )
                    .onTapGesture(count: 2) {
                        // Double tap to reset zoom
                        withAnimation(.spring()) {
                            scale = 1.0
                            lastScale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        }
                    }
            }
            .frame(height: 600) // Increased height for more viewing space

            Text(scale > 1.0 ? "Pinch to zoom • Drag to pan • Double tap to reset" : "Pinch to zoom • Double tap to reset")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Makeup Pack Detail
struct MakeupPackDetail: View {
    @EnvironmentObject var appState: AppState
    let profile: UserProfile
    let image: UIImage

    @State private var eyeshadowIntensity: Double = 50
    @State private var eyelinerIntensity: Double = 50
    @State private var blushIntensity: Double = 50
    @State private var lipstickIntensity: Double = 50
    @State private var isRegenerating = false
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        VStack(spacing: 20) {
            Text("Your ideal makeup palette based on your undertone and contrast")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // Image with zoom
            GeometryReader { geometry in
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .cornerRadius(16)
                    .shadow(radius: 10)
                    .scaleEffect(scale)
                    .offset(offset)
                    .gesture(
                        SimultaneousGesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    scale = lastScale * value
                                }
                                .onEnded { _ in
                                    lastScale = scale
                                    if scale < 1.0 {
                                        withAnimation(.spring()) {
                                            scale = 1.0
                                            lastScale = 1.0
                                            offset = .zero
                                            lastOffset = .zero
                                        }
                                    }
                                },
                            DragGesture()
                                .onChanged { value in
                                    if scale > 1.0 {
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                        )
                    )
                    .onTapGesture(count: 2) {
                        withAnimation(.spring()) {
                            scale = 1.0
                            lastScale = 1.0
                            offset = .zero
                            lastOffset = .zero
                        }
                    }
            }
            .frame(height: 500) // Increased height for better viewing

            Text(scale > 1.0 ? "Pinch to zoom • Drag to pan • Double tap to reset" : "Pinch to zoom • Double tap to reset")
                .font(.caption)
                .foregroundColor(.secondary)

            // Intensity Sliders
            VStack(spacing: 20) {
                Text("Adjust Makeup Intensity")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                MakeupSlider(
                    label: "Eyeshadow",
                    value: $eyeshadowIntensity,
                    icon: "sparkles"
                )

                MakeupSlider(
                    label: "Eyeliner",
                    value: $eyelinerIntensity,
                    icon: "eye"
                )

                MakeupSlider(
                    label: "Blush",
                    value: $blushIntensity,
                    icon: "heart.fill"
                )

                MakeupSlider(
                    label: "Lipstick",
                    value: $lipstickIntensity,
                    icon: "mouth"
                )
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .padding(.horizontal)

            // Regenerate Button
            if isRegenerating {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Regenerating with your settings...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                Button(action: {
                    regenerateMakeup()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Regenerate Makeup")
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

            Spacer().frame(height: 20)
        }
    }

    private func regenerateMakeup() {
        guard let selfieImage = profile.selfieImage,
              let focusColor = profile.focusColor else { return }

        isRegenerating = true

        Task {
            do {
                let makeupImage = try await GeminiService.shared.generateMakeupPack(
                    selfieImage: selfieImage,
                    focusColor: focusColor,
                    undertone: profile.undertone,
                    contrast: profile.contrast,
                    eyeshadowIntensity: eyeshadowIntensity,
                    eyelinerIntensity: eyelinerIntensity,
                    blushIntensity: blushIntensity,
                    lipstickIntensity: lipstickIntensity
                )

                let makeupURL = ImageCacheManager.shared.saveAIImage(
                    makeupImage,
                    for: .makeupPack,
                    userID: profile.id
                )

                var updatedProfile = profile
                updatedProfile.makeupPackImageURL = makeupURL
                appState.saveProfile(updatedProfile)

                isRegenerating = false
            } catch {
                print("❌ Error regenerating makeup: \(error)")
                isRegenerating = false
            }
        }
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
        case .contrastCard: return "Contrast Guide"
        case .neutralsMetalsCard: return "Neutrals & Metals"
        }
    }
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
