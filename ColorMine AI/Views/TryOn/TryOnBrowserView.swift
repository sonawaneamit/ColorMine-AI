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

    init(store: Store) {
        self.store = store
        self.customURL = nil
    }

    init(customURL: String) {
        self.store = nil
        self.customURL = customURL
    }

    private var initialURL: URL {
        if let store = store, let url = URL(string: store.url) {
            return url
        } else if let customURL = customURL, let url = URL(string: customURL) {
            return url
        } else {
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

                // Floating "Add to Try-On" Button
                VStack {
                    Spacer()

                    Button(action: {
                        if !isCapturing && !isSaved {
                            captureScreenshot()
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
            .navigationTitle(displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 12) {
                        // Back button
                        Button(action: { webView?.goBack() }) {
                            Image(systemName: "chevron.left")
                                .font(.body)
                        }
                        .disabled(webView?.canGoBack == false)

                        // Forward button
                        Button(action: { webView?.goForward() }) {
                            Image(systemName: "chevron.right")
                                .font(.body)
                        }
                        .disabled(webView?.canGoForward == false)

                        // Reload button
                        Button(action: { webView?.reload() }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.body)
                        }
                    }
                }
            }
        }
    }

    // Capture screenshot and use Gemini to extract the clothing item
    private func captureScreenshot() {
        guard let webView = webView else { return }

        isCapturing = true
        appState.isSavingGarment = true

        // Immediate haptic feedback
        HapticManager.shared.success()

        // Capture current URL for product link
        let productURLString = currentURL?.absoluteString

        // Take full visible area screenshot
        let config = WKSnapshotConfiguration()
        config.rect = CGRect(origin: .zero, size: webView.bounds.size)

        webView.takeSnapshot(with: config) { fullImage, error in
            // Update UI on main thread
            Task { @MainActor in
                self.isCapturing = false
                self.isSaved = true

                // Reset saved state after 2 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.isSaved = false
                }
            }

            guard let screenshot = fullImage, error == nil else {
                return
            }

            // Save screenshot directly (Gemini will focus on clothing during try-on)
            Task {
                // Optimize image resolution (max 1024px on longest side)
                let optimizedImage = self.resizeImage(screenshot, maxDimension: 1024)

                // Save to cache
                guard let garmentURL = TryOnCacheManager.shared.saveGarment(optimizedImage) else {
                    await MainActor.run {
                        self.appState.isSavingGarment = false
                    }
                    return
                }

                // Get profile
                guard var profile = self.appState.currentProfile else {
                    await MainActor.run {
                        self.appState.isSavingGarment = false
                    }
                    return
                }

                // Create garment item WITHOUT color analysis (will analyze on try-on)
                let source = self.storeName ?? self.currentURL?.host ?? "Web"
                let garment = GarmentItem(
                    imageURL: garmentURL,
                    sourceStore: source,
                    productURL: productURLString,
                    dominantColorHex: nil,
                    matchesUserSeason: false,  // Will be analyzed during try-on
                    colorMatchScore: nil  // Will be analyzed during try-on
                )

                // Add to profile and save immediately
                profile.savedGarments.append(garment)
                self.appState.saveProfile(profile)

                await MainActor.run {
                    self.appState.isSavingGarment = false
                }
            }
        }
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

        // Set user agent to mobile Safari for mobile-optimized experience
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"

        // Store reference
        DispatchQueue.main.async {
            self.webView = webView
            self.currentURL = url
            self.isLoading = true
        }

        // Load URL with proper cache policy
        var request = URLRequest(url: url)
        request.cachePolicy = .returnCacheDataElseLoad
        webView.load(request)

        return webView
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        // Clean up
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        // Called when navigation starts
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
                // Update progress manually
                self.parent.estimatedProgress = 0.1
            }
        }

        // Called when navigation completes successfully
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.currentURL = webView.url
                self.parent.isLoading = false
                self.parent.estimatedProgress = 1.0
            }
        }

        // Called when navigation fails
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }

        // Called when provisional navigation fails
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }

        // Called to decide whether to allow navigation
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            decisionHandler(.allow)
        }
    }
}

#Preview {
    TryOnBrowserView(store: Store.predefinedStores.first!)
        .environmentObject(AppState())
}
