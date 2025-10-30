//
//  StoreGridView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import SwiftUI

struct StoreGridView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedStore: Store?
    @State private var customURL: String?
    @State private var showBrowser = false
    @State private var showURLInput = false
    @State private var urlInputText = ""

    private let stores = Store.predefinedStores

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Shop Your Colors")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Browse stores and try outfits virtually")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 20)

                // Enter Custom URL Card
                CustomURLCard {
                    showURLInput = true
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
                            print("🛍️ [StoreGrid] Store tapped: \(store.name), URL: \(store.url)")
                            selectedStore = store
                            customURL = nil
                            showBrowser = true
                            print("🛍️ [StoreGrid] showBrowser set to true, selectedStore: \(store.name)")
                        }
                    }
                }
                .padding(.horizontal)

                Spacer().frame(height: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .fullScreenCover(isPresented: $showBrowser) {
            Group {
                if let store = selectedStore {
                    let _ = print("🎬 [StoreGrid] fullScreenCover presenting store: \(store.name)")
                    TryOnBrowserView(store: store)
                        .environmentObject(appState)
                } else if let url = customURL {
                    let _ = print("🎬 [StoreGrid] fullScreenCover presenting custom URL: \(url)")
                    TryOnBrowserView(customURL: url)
                        .environmentObject(appState)
                } else {
                    let _ = print("⚠️ [StoreGrid] fullScreenCover has no store or URL!")
                    Text("No URL selected")
                }
            }
        }
        .sheet(isPresented: $showURLInput) {
            URLInputSheet(urlText: $urlInputText) { url in
                print("🌐 [StoreGrid] Custom URL submitted: \(url)")
                customURL = url
                selectedStore = nil
                showBrowser = true
                print("🌐 [StoreGrid] showBrowser set to true with custom URL")
            }
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
                // Store Icon/Logo
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 120)

                    VStack(spacing: 8) {
                        Image(systemName: "tag.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)

                        Text(store.name)
                            .font(.headline)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                }

                // Category Badge
                Text(store.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }

    private var gradientColors: [Color] {
        // Vary gradient based on category
        switch store.category {
        case .luxury:
            return [.purple, .pink]
        case .fashion:
            return [.blue, .cyan]
        case .streetwear:
            return [.orange, .red]
        case .athletic:
            return [.green, .mint]
        case .sustainable:
            return [.teal, .green]
        }
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

#Preview {
    StoreGridView()
}
