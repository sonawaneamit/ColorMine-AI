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
                                ImagePackDetail(
                                    title: "Makeup Pack",
                                    description: "Your ideal makeup palette based on your undertone and contrast",
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
                    .scaledToFit()
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
                    .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .frame(height: 500)

            Text(scale > 1.0 ? "Pinch to zoom • Drag to pan • Double tap to reset" : "Pinch to zoom • Double tap to reset")
                .font(.caption)
                .foregroundColor(.secondary)
        }
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
