//
//  StoreGridView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import SwiftUI

struct StoreGridView: View {
    @State private var selectedStore: Store?
    @State private var showBrowser = false

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

                // Store Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(stores) { store in
                        StoreCard(store: store) {
                            selectedStore = store
                            showBrowser = true
                        }
                    }
                }
                .padding(.horizontal)

                Spacer().frame(height: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .fullScreenCover(isPresented: $showBrowser) {
            if let store = selectedStore {
                TryOnBrowserView(store: store)
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

#Preview {
    StoreGridView()
}
