//
//  TryOnResultView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import SwiftUI
import UserNotifications

struct TryOnResultView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let result: TryOnResult

    @State private var resultImage: UIImage?
    @State private var showShareSheet = false
    @State private var showColorAnalysis = true
    @State private var isGeneratingVideo = false
    @State private var showVideoPlayer = false
    @State private var showCreditsPurchase = false
    @State private var showFullScreenImage = false
    @State private var generatedVideoURL: URL? // Track generated video URL

    private var userProfile: UserProfile? {
        appState.currentProfile
    }

    private var hasVideo: Bool {
        generatedVideoURL != nil || result.videoURL != nil
    }

    private var videoURL: URL? {
        generatedVideoURL ?? result.videoURL
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
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
                                    .onTapGesture {
                                        showFullScreenImage = true
                                    }

                                // Top-right buttons
                                HStack(spacing: 12) {
                                    // Video generation button with cost indicator
                                    Button(action: generateVideo) {
                                        VStack(spacing: 4) {
                                            if isGeneratingVideo {
                                                ProgressView()
                                                    .tint(.white)
                                            } else if hasVideo {
                                                Image(systemName: "play.circle.fill")
                                                    .font(.title2)
                                            } else {
                                                Image(systemName: "video.badge.plus")
                                                    .font(.title2)
                                            }

                                            if !hasVideo && !isGeneratingVideo {
                                                Text("3 credits")
                                                    .font(.caption2)
                                                    .fontWeight(.semibold)
                                            } else if hasVideo && !isGeneratingVideo {
                                                Text("Play")
                                                    .font(.caption2)
                                                    .fontWeight(.semibold)
                                            }
                                        }
                                        .foregroundColor(.white)
                                        .padding(10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(hasVideo ? Color.green.opacity(0.9) : Color.purple.opacity(0.9))
                                        )
                                    }
                                    .disabled(isGeneratingVideo)

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

            // Floating video generation notification banner
            if isGeneratingVideo {
                VStack {
                    HStack(spacing: 12) {
                        Image(systemName: "bell.badge.fill")
                            .foregroundColor(.white)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Video Generating...")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)

                            Text("Feel free to leave. We'll notify you when your video is ready!")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.9))
                        }

                        Spacer()
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.purple.opacity(0.95))
                            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isGeneratingVideo)
                .zIndex(1) // Ensure it appears above ScrollView content
            }
        }
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
            .fullScreenCover(isPresented: $showVideoPlayer) {
                if let url = videoURL {
                    VideoPlayerView(videoURL: url)
                }
            }
            .fullScreenCover(isPresented: $showFullScreenImage) {
                if let image = resultImage {
                    ZoomableImageView(image: image)
                }
            }
            .sheet(isPresented: $showCreditsPurchase) {
                CreditsPurchaseView()
            }
        }
        .onAppear {
            loadResultImage()
            // Initialize video URL if already exists
            if let existingVideoURL = result.videoURL {
                generatedVideoURL = existingVideoURL
            }
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

    private func generateVideo() {
        // If video already exists, play it
        if hasVideo {
            showVideoPlayer = true
            return
        }

        // Check if user has enough credits (3 credits for video)
        guard var profile = appState.currentProfile else { return }

        guard profile.tryOnCredits >= 3 else {
            // Show purchase sheet to get more credits
            showCreditsPurchase = true
            return
        }

        // Start video generation
        guard let image = resultImage else { return }

        isGeneratingVideo = true
        HapticManager.shared.buttonTap()

        Task {
            do {
                // Generate video using fal.ai Veo 3.1
                let videoData = try await FalAIService.shared.generateTryOnVideo(
                    tryOnImage: image
                )

                // Save video to cache
                guard let videoURL = TryOnCacheManager.shared.saveTryOnVideo(videoData) else {
                    throw TryOnError.failedToSave
                }

                // Update result with video URL
                var updatedResult = result
                updatedResult.videoURL = videoURL
                updatedResult.videoCreditsUsed = 3

                // Deduct credits
                profile.tryOnCredits -= 3

                // Update the try-on history with video URL
                if let index = profile.tryOnHistory.firstIndex(where: { $0.id == result.id }) {
                    profile.tryOnHistory[index] = updatedResult
                }

                appState.saveProfile(profile)

                print("✅ Video generated and saved! Credits remaining: \(profile.tryOnCredits)")

                // Send notification
                sendVideoReadyNotification()

                await MainActor.run {
                    generatedVideoURL = videoURL // Set the generated video URL
                    isGeneratingVideo = false
                    HapticManager.shared.success()
                    showVideoPlayer = true // Autoplay
                }

            } catch {
                print("❌ Video generation failed: \(error.localizedDescription)")
                await MainActor.run {
                    isGeneratingVideo = false
                    HapticManager.shared.error()
                }
            }
        }
    }

    private func sendVideoReadyNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Try-On Video Ready!"
        content.body = "Your 8-second Try-On video is ready to watch"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Failed to send notification: \(error)")
            } else {
                print("✅ Video ready notification sent")
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
        // First priority: Open saved product URL if available
        if let productURLString = result.garmentItem.productURL,
           let url = URL(string: productURLString) {
            UIApplication.shared.open(url)
            print("📱 Opening product URL: \(productURLString)")
            return
        }

        // Fallback: Open general store homepage
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

// MARK: - Video Player View
import AVKit
import Photos

struct VideoPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    let videoURL: URL
    @State private var player: AVPlayer?
    @State private var showSaveSuccess = false
    @State private var showSaveError = false

    var body: some View {
        ZStack(alignment: .topLeading) {
            if let player = player {
                VideoPlayer(player: player)
                    .edgesIgnoringSafeArea(.all)
            }

            // Top buttons
            HStack {
                // Close button
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .background(Circle().fill(.black.opacity(0.5)))
                }

                Spacer()

                // Save to camera roll button
                Button(action: saveVideoToCameraRoll) {
                    Image(systemName: "square.and.arrow.down.fill")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .background(Circle().fill(.black.opacity(0.5)))
                }
            }
            .padding()
        }
        .alert("Video Saved!", isPresented: $showSaveSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Your Try-On video has been saved to your photo library")
        }
        .alert("Save Failed", isPresented: $showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Couldn't save video. Please check photo library permissions in Settings.")
        }
        .onAppear {
            // Create player and autoplay
            let newPlayer = AVPlayer(url: videoURL)
            player = newPlayer
            newPlayer.play() // Autoplay
        }
        .onDisappear {
            player?.pause()
        }
    }

    private func saveVideoToCameraRoll() {
        // Check photo library authorization
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized || status == .limited else {
                DispatchQueue.main.async {
                    showSaveError = true
                }
                return
            }

            // Save video to photo library
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL)
            }) { success, error in
                DispatchQueue.main.async {
                    if success {
                        showSaveSuccess = true
                        HapticManager.shared.success()
                        print("✅ Video saved to camera roll")
                    } else {
                        showSaveError = true
                        HapticManager.shared.error()
                        print("❌ Failed to save video: \(error?.localizedDescription ?? "unknown")")
                    }
                }
            }
        }
    }
}

// MARK: - Zoomable Image View
struct ZoomableImageView: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage

    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color.black
                .edgesIgnoringSafeArea(.all)

            // Zoomable Image
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            let delta = value / lastScale
                            lastScale = value
                            scale = min(max(scale * delta, 1), 4) // Limit zoom between 1x and 4x
                        }
                        .onEnded { _ in
                            lastScale = 1.0
                            // Reset to normal if zoomed out too much
                            if scale < 1 {
                                withAnimation(.spring()) {
                                    scale = 1
                                    offset = .zero
                                }
                            }
                        }
                )
                .simultaneousGesture(
                    DragGesture()
                        .onChanged { value in
                            if scale > 1 {
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
                .onTapGesture(count: 2) {
                    // Double tap to reset zoom
                    withAnimation(.spring()) {
                        scale = 1
                        offset = .zero
                        lastOffset = .zero
                    }
                }

            // Close button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title)
                    .foregroundColor(.white)
                    .padding()
                    .background(Circle().fill(.black.opacity(0.5)))
            }
            .padding()

            // Zoom instructions
            VStack {
                Spacer()
                Text("Pinch to zoom • Drag to pan • Double-tap to reset")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(.black.opacity(0.6))
                    )
                    .padding(.bottom, 40)
            }
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
        creditsUsed: 1
    ))
    .environmentObject(AppState())
}
