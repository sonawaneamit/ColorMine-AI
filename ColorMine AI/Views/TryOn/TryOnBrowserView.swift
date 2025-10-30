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

    let store: Store

    @State private var webView: WKWebView?
    @State private var showSaveConfirmation = false
    @State private var isCapturing = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Web View
                WebView(
                    url: URL(string: store.url)!,
                    webView: $webView
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
            .navigationTitle(store.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
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

            // Create garment item
            let garment = GarmentItem(
                imageURL: garmentURL,
                sourceStore: store.name
            )

            // Add to profile
            guard var profile = appState.currentProfile else {
                print("❌ No current profile")
                return
            }

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

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.allowsBackForwardNavigationGestures = true

        // Store reference
        DispatchQueue.main.async {
            self.webView = webView
        }

        // Load URL
        let request = URLRequest(url: url)
        webView.load(request)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // No updates needed
    }
}

#Preview {
    TryOnBrowserView(store: Store.predefinedStores.first!)
        .environmentObject(AppState())
}
