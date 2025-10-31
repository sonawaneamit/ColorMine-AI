//
//  TryOnBrowserView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import SwiftUI
import WebKit

struct TryOnBrowserView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let store: Store?
    let customURL: String?

    @State private var webView: WKWebView?
    @State private var isCapturing = false
    @State private var isSaved = false
    @State private var currentURL: URL?
    @State private var isLoading = true
    @State private var estimatedProgress: Double = 0
    @State private var showCropOverlay = false  // Show crop overlay for manual positioning

    init(store: Store) {
        self.store = store
        self.customURL = nil
        print("🌐 [TryOnBrowser] Initialized with store: \(store.name), URL: \(store.url)")
    }

    init(customURL: String) {
        self.store = nil
        self.customURL = customURL
        print("🌐 [TryOnBrowser] Initialized with custom URL: \(customURL)")
    }

    private var initialURL: URL {
        if let store = store, let url = URL(string: store.url) {
            print("🌐 [TryOnBrowser] Using store URL: \(url)")
            return url
        } else if let customURL = customURL, let url = URL(string: customURL) {
            print("🌐 [TryOnBrowser] Using custom URL: \(url)")
            return url
        } else {
            print("⚠️ [TryOnBrowser] No valid URL, falling back to Google")
            // Fallback to a default URL
            return URL(string: "https://www.google.com")!
        }
    }

    private var displayName: String {
        store?.name ?? "Browser"
    }

    private var storeName: String? {
        store?.name
    }

    var body: some View {
        let _ = print("🌐 [TryOnBrowser] Body rendering with URL: \(initialURL)")

        NavigationStack {
            ZStack(alignment: .bottom) {
                // Web View
                WebView(
                    url: initialURL,
                    webView: $webView,
                    currentURL: $currentURL,
                    isLoading: $isLoading,
                    estimatedProgress: $estimatedProgress
                )
                .ignoresSafeArea()

                // Loading indicator overlay
                if isLoading {
                    VStack {
                        ProgressView(value: estimatedProgress, total: 1.0)
                            .progressViewStyle(.linear)
                            .tint(.purple)
                        Spacer()
                    }
                    .background(Color.black.opacity(0.1))
                }

                // Crop Overlay for Manual Positioning
                if showCropOverlay {
                    CropOverlayView(
                        onCapture: { captureFromOverlay() },
                        onCancel: { showCropOverlay = false }
                    )
                }

                // Floating "Add to Try-On" Button (hidden when overlay is shown)
                if !showCropOverlay {
                    VStack {
                        Spacer()

                        Button(action: {
                            if !isCapturing && !isSaved {
                                showCropOverlay = true
                            }
                        }) {
                            HStack(spacing: 8) {
                                if isSaved {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.title2)
                                } else if isCapturing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                }
                                Text(isSaved ? "Saved!" : (isCapturing ? "Saving..." : "Save to Try-On"))
                                    .font(.headline)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 14)
                            .background(
                                LinearGradient(
                                    colors: isSaved ? [.green, .green.opacity(0.8)] : [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(30)
                            .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                        }
                        .disabled(isCapturing || isSaved)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationTitle(displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 8) {
                        // Back button
                        Button(action: { webView?.goBack() }) {
                            Image(systemName: "chevron.left")
                        }
                        .disabled(webView?.canGoBack == false)

                        // Forward button
                        Button(action: { webView?.goForward() }) {
                            Image(systemName: "chevron.right")
                        }
                        .disabled(webView?.canGoForward == false)

                        // Reload button
                        Button(action: { webView?.reload() }) {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
        }
    }

    // New function to capture from the crop overlay
    private func captureFromOverlay() {
        guard let webView = webView else {
            print("❌ WebView not available")
            return
        }

        // Hide overlay and show capture progress
        showCropOverlay = false
        isCapturing = true
        appState.isSavingGarment = true

        // Immediate haptic feedback
        HapticManager.shared.success()

        // Capture current URL for product link
        let productURLString = currentURL?.absoluteString

        // Calculate the 9:16 crop frame in the center
        let screenSize = UIScreen.main.bounds.size
        let frameWidth = screenSize.width * 0.8  // 80% of screen width
        let frameHeight = frameWidth * (16.0 / 9.0)  // 9:16 aspect ratio
        let frameX = (screenSize.width - frameWidth) / 2
        let frameY = (screenSize.height - frameHeight) / 2

        let cropRect = CGRect(x: frameX, y: frameY, width: frameWidth, height: frameHeight)

        // Take screenshot of the crop area
        let config = WKSnapshotConfiguration()
        config.rect = cropRect

        webView.takeSnapshot(with: config) { image, error in

            defer {
                Task { @MainActor in
                    self.isCapturing = false
                    self.isSaved = true

                    // Reset saved state after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        self.isSaved = false
                    }
                }
            }

            guard let screenshot = image, error == nil else {
                print("❌ Failed to capture screenshot: \(error?.localizedDescription ?? "unknown")")
                return
            }

            // Optimize image resolution (max 1024px on longest side)
            let optimizedImage = self.resizeImage(screenshot, maxDimension: 1024)

            print("📐 Original size: \(Int(screenshot.size.width))x\(Int(screenshot.size.height))")
            print("📐 Optimized size: \(Int(optimizedImage.size.width))x\(Int(optimizedImage.size.height))")

            // Continue saving in background
            Task {
                // Save to cache with optimized image
                guard let garmentURL = TryOnCacheManager.shared.saveGarment(optimizedImage) else {
                    print("❌ Failed to save garment image")
                    return
                }

                // Get profile
                guard var profile = self.appState.currentProfile else {
                    print("❌ No current profile")
                    return
                }

                // Analyze garment color using OpenAI
                let season = profile.season

                print("🎨 Analyzing garment color with OpenAI...")

                do {
                    let analysis = try await OpenAIService.shared.analyzeGarmentColor(
                        garmentImage: optimizedImage,
                        userSeason: season
                    )

                    // Create garment item with OpenAI analysis
                    // If no store, try to extract domain from current URL
                    let source = self.storeName ?? self.currentURL?.host ?? "Web"

                    let garment = GarmentItem(
                        imageURL: garmentURL,
                        sourceStore: source,
                        productURL: productURLString,  // Save product URL
                        dominantColorHex: nil, // No longer needed with OpenAI
                        matchesUserSeason: analysis.matchScore >= 70,
                        colorMatchScore: analysis.matchScore
                    )

                    // Add to profile
                    profile.savedGarments.append(garment)
                    self.appState.saveProfile(profile)

                    print("✅ Garment saved: \(garment.id) with \(analysis.matchScore)% match")
                    print("🔗 Product URL: \(productURLString ?? "none")")
                    print("🧠 OpenAI reasoning: \(analysis.reasoning)")

                    // Clear saving flag
                    await MainActor.run {
                        self.appState.isSavingGarment = false
                    }

                } catch {
                    print("❌ Failed to analyze garment color: \(error.localizedDescription)")
                    // Still save garment but without color analysis
                    let source = self.storeName ?? self.currentURL?.host ?? "Web"
                    let garment = GarmentItem(
                        imageURL: garmentURL,
                        sourceStore: source,
                        productURL: productURLString,  // Save product URL
                        dominantColorHex: nil,
                        matchesUserSeason: false,
                        colorMatchScore: nil // No score if analysis failed
                    )
                    profile.savedGarments.append(garment)
                    self.appState.saveProfile(profile)

                    print("✅ Garment saved without color analysis")

                    // Clear saving flag
                    await MainActor.run {
                        self.appState.isSavingGarment = false
                    }
                }
            }
        } // End takeSnapshot
    }

    // Helper function to resize image
    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        // If image is already smaller than max, return original
        if size.width <= maxDimension && size.height <= maxDimension {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let ratio = size.width / size.height
        let newSize: CGSize

        if size.width > size.height {
            // Landscape or square
            newSize = CGSize(width: maxDimension, height: maxDimension / ratio)
        } else {
            // Portrait
            newSize = CGSize(width: maxDimension * ratio, height: maxDimension)
        }

        // Resize image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return resizedImage ?? image
    }
}

// MARK: - WebView Wrapper
struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var webView: WKWebView?
    @Binding var currentURL: URL?
    @Binding var isLoading: Bool
    @Binding var estimatedProgress: Double

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        print("🌐 [WebView] Creating WKWebView for URL: \(url)")

        // Enhanced configuration for full browser capabilities
        let configuration = WKWebViewConfiguration()

        // Enable all media types
        configuration.allowsInlineMediaPlayback = true
        configuration.allowsPictureInPictureMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        // Enable JavaScript and modern web features
        let preferences = WKWebpagePreferences()
        preferences.allowsContentJavaScript = true
        configuration.defaultWebpagePreferences = preferences

        // Enable process pool for better performance
        configuration.processPool = WKProcessPool()

        // Create webview with enhanced configuration
        let webView = WKWebView(frame: .zero, configuration: configuration)

        // Enable gestures and interactions
        webView.allowsBackForwardNavigationGestures = true
        webView.allowsLinkPreview = true
        webView.navigationDelegate = context.coordinator

        // Visual settings for proper rendering
        webView.isOpaque = true
        webView.backgroundColor = .systemBackground

        // Enable scrolling and zooming for full page content
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.bounces = true
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 5.0
        webView.scrollView.bouncesZoom = true

        // Set user agent to desktop Safari for full website experience
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"

        print("🌐 [WebView] WKWebView created with full browser capabilities")

        // Add KVO observers for loading state
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        webView.addObserver(context.coordinator, forKeyPath: #keyPath(WKWebView.isLoading), options: .new, context: nil)

        // Store reference
        DispatchQueue.main.async {
            self.webView = webView
            self.currentURL = url
            self.isLoading = true
            print("🌐 [WebView] WebView reference stored")
        }

        // Load URL with proper cache policy
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        webView.load(request)
        print("🌐 [WebView] Load request sent for: \(url)")

        return webView
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        // Remove observers when view is destroyed
        uiView.removeObserver(coordinator, forKeyPath: #keyPath(WKWebView.estimatedProgress))
        uiView.removeObserver(coordinator, forKeyPath: #keyPath(WKWebView.isLoading))
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        // KVO observer for loading progress
        override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
            if keyPath == "estimatedProgress" {
                if let webView = object as? WKWebView {
                    DispatchQueue.main.async {
                        self.parent.estimatedProgress = webView.estimatedProgress
                        print("📊 [Progress] \(Int(webView.estimatedProgress * 100))%")
                    }
                }
            } else if keyPath == "isLoading" {
                if let webView = object as? WKWebView {
                    DispatchQueue.main.async {
                        self.parent.isLoading = webView.isLoading
                        print("⏳ [Loading] isLoading: \(webView.isLoading)")
                    }
                }
            }
        }

        // Called when navigation starts
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("🌐 [Navigation] Started loading: \(webView.url?.absoluteString ?? "unknown")")
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }

        // Called when navigation completes successfully
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("✅ [Navigation] Finished loading: \(webView.url?.absoluteString ?? "unknown")")
            DispatchQueue.main.async {
                self.parent.currentURL = webView.url
                self.parent.isLoading = false
            }
        }

        // Called when navigation fails
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("❌ [Navigation] Failed: \(error.localizedDescription)")
            print("❌ [Navigation] Error details: \(error)")
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }

        // Called when provisional navigation fails
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            print("❌ [Navigation] Provisional navigation failed: \(error.localizedDescription)")
            print("❌ [Navigation] Error details: \(error)")
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }

        // Called when web content process terminates
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            print("⚠️ [Navigation] Web content process terminated!")
        }

        // Called to decide whether to allow navigation
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            print("🌐 [Navigation] Deciding policy for: \(navigationAction.request.url?.absoluteString ?? "unknown")")
            decisionHandler(.allow)
        }
    }
}

// MARK: - Crop Overlay View
struct CropOverlayView: View {
    let onCapture: () -> Void
    let onCancel: () -> Void

    var body: some View {
        ZStack {
            // Semi-transparent overlay outside crop area
            Color.black.opacity(0.7)
                .ignoresSafeArea()

            // Crop frame (9:16 aspect ratio)
            GeometryReader { geometry in
                let frameWidth = geometry.size.width * 0.8
                let frameHeight = frameWidth * (16.0 / 9.0)

                ZStack {
                    // Clear center area showing the crop frame
                    Rectangle()
                        .frame(width: frameWidth, height: frameHeight)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                        .blendMode(.destinationOut)

                    // Border around the crop frame
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white, lineWidth: 3)
                        .frame(width: frameWidth, height: frameHeight)
                        .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
                }
            }

            VStack {
                // Instructions at top
                VStack(spacing: 12) {
                    Text("Position Your Product")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)

                    Text("Zoom and pan to fit the product within the frame")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.top, 60)

                Spacer()

                // Action buttons at bottom
                HStack(spacing: 20) {
                    // Cancel button
                    Button(action: onCancel) {
                        Text("Cancel")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.gray.opacity(0.5))
                            .cornerRadius(12)
                    }

                    // Capture button
                    Button(action: onCapture) {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Capture")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
        .compositingGroup()
    }
}

#Preview {
    TryOnBrowserView(store: Store.predefinedStores.first!)
        .environmentObject(AppState())
}
