//
//  TryOnResultView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import SwiftUI

struct TryOnResultView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let result: TryOnResult

    @State private var resultImage: UIImage?
    @State private var showShareSheet = false
    @State private var showColorAnalysis = true

    private var userProfile: UserProfile? {
        appState.currentProfile
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Result Image
                    if let image = resultImage {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.1), radius: 10)

                            // Color analysis toggle
                            Button(action: {
                                withAnimation {
                                    showColorAnalysis.toggle()
                                }
                            }) {
                                Image(systemName: showColorAnalysis ? "eye.fill" : "eye.slash.fill")
                                    .font(.title3)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Circle().fill(.black.opacity(0.5)))
                            }
                            .padding()
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray5))
                            .frame(height: 400)
                            .overlay {
                                ProgressView()
                            }
                    }

                    // Color Analysis Section (if enabled)
                    if showColorAnalysis, let profile = userProfile {
                        colorAnalysisSection(for: profile)
                    }

                    // Garment Color Match (if available)
                    if let matchScore = result.garmentItem.colorMatchScore {
                        colorMatchSection(score: matchScore)
                    }

                    // Success message
                    successMessageSection

                    // Action buttons
                    actionButtonsSection

                    Spacer().frame(height: 40)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Try-On Result")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let image = resultImage,
                   let watermarkedImage = addWatermark(to: image) {
                    ShareSheet(items: [watermarkedImage])
                }
            }
        }
        .onAppear {
            loadResultImage()
        }
    }

    // MARK: - Color Analysis Section
    @ViewBuilder
    private func colorAnalysisSection(for profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "paintpalette.fill")
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                Text("Your Color Profile")
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 12) {
                // Season
                ColorAnalysisRow(
                    icon: "leaf.fill",
                    label: "Season",
                    value: profile.season.rawValue
                )

                // Undertone
                ColorAnalysisRow(
                    icon: "circle.lefthalf.filled",
                    label: "Undertone",
                    value: profile.undertone.rawValue
                )

                // Best metals
                if let metals = profile.neutralsMetalsCard?.bestMetals, !metals.isEmpty {
                    ColorAnalysisRow(
                        icon: "sparkles",
                        label: "Best Metals",
                        value: metals.map { $0.name }.joined(separator: ", ")
                    )
                }
            }

            // Recommended Colors - Show all season colors
            let seasonPalette = SeasonPalettes.palette(for: profile.season)
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Best Colors")
                    .font(.subheadline)
                    .fontWeight(.medium)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(seasonPalette.prefix(12)) { swatch in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(swatch.color)
                                    .frame(width: 50, height: 50)
                                    .overlay {
                                        Circle()
                                            .stroke(Color(.systemGray4), lineWidth: 1)
                                    }

                                Text(swatch.name)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(width: 60)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Color Match Section
    @ViewBuilder
    private func colorMatchSection(score: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: score >= 70 ? "checkmark.circle.fill" : "info.circle.fill")
                    .font(.title2)
                    .foregroundColor(score >= 70 ? .green : .orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Color Match")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text(colorMatchMessage(score: score))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(score)%")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(score >= 70 ? .green : .orange)
            }

            // Reasoning
            VStack(alignment: .leading, spacing: 6) {
                Text("Why this score?")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)

                Text(colorMatchReasoning(score: score))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Success Message
    private var successMessageSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.green)
                Text("You just made a smarter choice")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            Text("Shopping with intention reduces waste and carbon footprint")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
    }

    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            Button(action: { showShareSheet = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Result")
                }
            }
            .buttonStyle(PrimaryButtonStyle())

            if let store = result.garmentItem.sourceStore {
                Button(action: openStore) {
                    HStack {
                        Image(systemName: "bag.fill")
                        Text("Shop at \(store)")
                    }
                }
                .buttonStyle(SecondaryButtonStyle())
            }
        }
    }

    // MARK: - Helpers
    private func loadResultImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: result.resultImageURL),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.resultImage = image
                }
            }
        }
    }

    private func addWatermark(to image: UIImage) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: image.size)

        return renderer.image { context in
            // Draw original image
            image.draw(at: .zero)

            // Configure watermark text
            let watermarkText = "ColorMine AI"
            let fontSize = image.size.width * 0.04 // 4% of image width
            let font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)

            // Text attributes
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .right

            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white.withAlphaComponent(0.7),
                .paragraphStyle: paragraphStyle
            ]

            // Calculate text size and position (bottom right with padding)
            let attributedString = NSAttributedString(string: watermarkText, attributes: attributes)
            let textSize = attributedString.size()

            let padding: CGFloat = image.size.width * 0.03 // 3% padding
            let textRect = CGRect(
                x: image.size.width - textSize.width - padding,
                y: image.size.height - textSize.height - padding,
                width: textSize.width,
                height: textSize.height
            )

            // Draw semi-transparent background behind text
            let backgroundRect = textRect.insetBy(dx: -padding/2, dy: -padding/3)
            UIColor.black.withAlphaComponent(0.5).setFill()
            let backgroundPath = UIBezierPath(roundedRect: backgroundRect, cornerRadius: 8)
            backgroundPath.fill()

            // Draw watermark text
            watermarkText.draw(in: textRect, withAttributes: attributes)
        }
    }

    private func colorMatchMessage(score: Int) -> String {
        switch score {
        case 80...100:
            return "Perfect match for your season!"
        case 70..<80:
            return "Great match for your colors"
        case 50..<70:
            return "Moderate match with your palette"
        default:
            return "Consider checking your best colors"
        }
    }

    private func colorMatchReasoning(score: Int) -> String {
        guard let profile = userProfile else {
            return "This score reflects how well the garment color aligns with your seasonal color palette."
        }

        let seasonName = profile.season.rawValue

        switch score {
        case 80...100:
            return "This garment's color is nearly identical to colors in your \(seasonName) palette. The hue, saturation, and brightness perfectly complement your natural coloring."
        case 70..<80:
            return "This garment's color harmonizes well with your \(seasonName) palette. While not a perfect match, it falls within the same color family and will enhance your features."
        case 50..<70:
            return "This garment's color is acceptable for your \(seasonName) palette but isn't in your ideal range. The hue or saturation may be slightly off. You might want to check if it comes in a color closer to your best shades."
        case 30..<50:
            return "This garment's color doesn't align well with your \(seasonName) palette. The hue, warmth, or intensity may clash with your natural coloring. Consider exploring the 'Your Best Colors' section for better alternatives."
        default:
            return "This garment's color is significantly different from your \(seasonName) palette. The color temperature, saturation, or brightness likely conflicts with your natural undertones. We recommend choosing colors from your seasonal palette for the most flattering look."
        }
    }

    private func openStore() {
        // Open the store website
        if let storeName = result.garmentItem.sourceStore,
           let store = Store.predefinedStores.first(where: { $0.name == storeName }),
           let url = URL(string: store.url) {
            UIApplication.shared.open(url)
            print("📱 Opening store: \(storeName) at \(store.url)")
        } else {
            print("❌ Unable to open store URL")
        }
    }
}

// MARK: - Color Analysis Row
struct ColorAnalysisRow: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.purple)
                .frame(width: 20)

            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    TryOnResultView(result: TryOnResult(
        id: UUID(),
        garmentItem: GarmentItem(
            imageURL: URL(fileURLWithPath: "/tmp/test.jpg"),
            sourceStore: "ASOS",
            colorMatchScore: 85
        ),
        resultImageURL: URL(fileURLWithPath: "/tmp/result.png"),
        createdAt: Date(),
        creditsUsed: 3
    ))
    .environmentObject(AppState())
}
