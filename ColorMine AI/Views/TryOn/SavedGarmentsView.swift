//
//  SavedGarmentsView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import SwiftUI

struct SavedGarmentsView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedGarment: GarmentItem?
    @State private var garmentToDelete: GarmentItem?
    @State private var showDeleteConfirmation = false

    private var savedGarments: [GarmentItem] {
        appState.currentProfile?.savedGarments ?? []
    }

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if savedGarments.isEmpty {
                emptyStateView
            } else {
                garmentsGridView
            }
        }
        .navigationTitle("Saved Garments")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedGarment) { garment in
            TryOnProcessView(garment: garment)
                .environmentObject(appState)
        }
        .alert("Remove Garment?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                garmentToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let garment = garmentToDelete {
                    deleteGarment(garment)
                }
            }
        } message: {
            Text("This will remove the garment from your gallery")
        }
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tshirt")
                .font(.system(size: 70))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple.opacity(0.5), .pink.opacity(0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                Text("No Saved Garments Yet")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Browse stores and save items to try on")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }

    // MARK: - Garments Grid
    private var garmentsGridView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text("\(savedGarments.count) saved item\(savedGarments.count == 1 ? "" : "s")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 12)

                // Grid
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ], spacing: 12) {
                    ForEach(savedGarments) { garment in
                        GarmentCard(garment: garment)
                            .onTapGesture {
                                print("🖼️ [SavedGarments] Garment tapped: \(garment.id)")
                                selectedGarment = garment
                            }
                            .onLongPressGesture {
                                garmentToDelete = garment
                                showDeleteConfirmation = true
                            }
                    }
                }
                .padding(.horizontal)

                Spacer().frame(height: 40)
            }
        }
    }

    // MARK: - Delete Garment
    private func deleteGarment(_ garment: GarmentItem) {
        guard var profile = appState.currentProfile else { return }

        // Delete image from cache
        _ = TryOnCacheManager.shared.deleteImage(at: garment.imageURL)

        // Remove from profile
        profile.savedGarments.removeAll { $0.id == garment.id }
        appState.saveProfile(profile)

        print("✅ Deleted garment: \(garment.id)")

        // Haptic feedback
        HapticManager.shared.buttonTap()

        garmentToDelete = nil
    }
}

// MARK: - Garment Card
struct GarmentCard: View {
    let garment: GarmentItem
    @State private var garmentImage: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Image
            ZStack {
                if let image = garmentImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray5))
                        .frame(height: 200)
                        .overlay {
                            ProgressView()
                        }
                }

                // Color match badge (if available)
                if let matchScore = garment.colorMatchScore {
                    VStack {
                        HStack {
                            Spacer()
                            colorMatchBadge(score: matchScore)
                                .padding(8)
                        }
                        Spacer()
                    }
                }
            }

            // Store name
            if let store = garment.sourceStore {
                HStack(spacing: 4) {
                    Image(systemName: "tag.fill")
                        .font(.caption2)
                    Text(store)
                        .font(.caption)
                }
                .foregroundColor(.secondary)
            }
        }
        .onAppear {
            loadImage()
        }
    }

    private func loadImage() {
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: garment.imageURL),
               let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.garmentImage = image
                }
            }
        }
    }

    @ViewBuilder
    private func colorMatchBadge(score: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: score >= 70 ? "checkmark.circle.fill" : "info.circle.fill")
                .font(.caption2)
            Text("\(score)%")
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(score >= 70 ? Color.green : Color.orange)
        )
        .shadow(color: .black.opacity(0.2), radius: 4, y: 2)
    }
}

#Preview {
    NavigationStack {
        SavedGarmentsView()
            .environmentObject(AppState())
    }
}
