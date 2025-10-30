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
    @State private var showSaveConfirmation = false
    @State private var isCapturing = false
    @State private var currentURL: URL?

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
                    currentURL: $currentURL
                )
                .ignoresSafeArea()

                // Floating "Add to Try-On" Button
                VStack {
                    Spacer()

                    Button(action: captureGarment) {
                        HStack(spacing: 8) {
                            if isCapturing {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                            }
                            Text(isCapturing ? "Saving..." : "Save to Try-On")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(30)
                        .shadow(color: .black.opacity(0.2), radius: 10, y: 4)
                    }
                    .disabled(isCapturing)
                    .padding(.bottom, 30)
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
            .alert("Saved!", isPresented: $showSaveConfirmation) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("This item has been saved to your try-on gallery")
            }
        }
    }

    private func captureGarment() {
        guard let webView = webView else {
            print("❌ WebView not available")
            return
        }

        isCapturing = true

        // Take screenshot of web view
        let config = WKSnapshotConfiguration()
        config.rect = webView.bounds

        webView.takeSnapshot(with: config) { image, error in
            defer { isCapturing = false }

            guard let screenshot = image, error == nil else {
                print("❌ Failed to capture screenshot: \(error?.localizedDescription ?? "unknown")")
                return
            }

            // Save to cache
            guard let garmentURL = TryOnCacheManager.shared.saveGarment(screenshot) else {
                print("❌ Failed to save garment image")
                return
            }

            // Get profile
            guard var profile = appState.currentProfile else {
                print("❌ No current profile")
                return
            }

            // Analyze garment color (on-device)
            let season = profile.season
            let palette = profile.favoriteColors
            let analysis = ColorMatchingService.shared.analyzeGarment(
                screenshot,
                userSeason: season,
                userPalette: palette
            )

            // Create garment item with color analysis
            // If no store, try to extract domain from current URL
            let source = storeName ?? currentURL?.host ?? "Web"

            let garment = GarmentItem(
                imageURL: garmentURL,
                sourceStore: source,
                dominantColorHex: analysis.dominantColorHex,
                matchesUserSeason: analysis.matchesSeason,
                colorMatchScore: analysis.matchScore
            )

            // Add to profile
            profile.savedGarments.append(garment)
            appState.saveProfile(profile)

            print("✅ Garment saved: \(garment.id)")

            // Haptic feedback
            HapticManager.shared.success()

            // Show confirmation
            showSaveConfirmation = true
        }
    }
}

// MARK: - WebView Wrapper
struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var webView: WKWebView?
    @Binding var currentURL: URL?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = context.coordinator

        // Store reference
        DispatchQueue.main.async {
            self.webView = webView
            self.currentURL = url
        }

        // Load URL
        let request = URLRequest(url: url)
        webView.load(request)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.currentURL = webView.url
            }
        }
    }
}

#Preview {
    TryOnBrowserView(store: Store.predefinedStores.first!)
        .environmentObject(AppState())
}
