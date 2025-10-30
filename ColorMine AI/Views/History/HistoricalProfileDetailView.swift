//
//  HistoricalProfileDetailView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import SwiftUI

struct HistoricalProfileDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    let historical: HistoricalProfile

    @State private var selectedPack: PackDetailType?

    private var profile: UserProfile {
        historical.profile
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Header with date and analysis
                    VStack(spacing: 16) {
                        // Date
                        Text(historical.shortDate)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        // Selfie
                        if let selfieImage = profile.selfieImage {
                            Image(uiImage: selfieImage)
                                .resizable()
                                .scaledToFill()
                                .frame(width: 120, height: 120)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [.purple, .pink],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            ),
                                            lineWidth: 3
                                        )
                                )
                                .shadow(radius: 8)
                        }

                        // Season
                        Text(profile.season.rawValue)
                            .font(.largeTitle)
                            .fontWeight(.heavy)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        // Analysis details
                        HStack(spacing: 20) {
                            ProfileAnalysisDetail(
                                title: "Undertone",
                                value: profile.undertone.rawValue,
                                icon: "circle.hexagongrid"
                            )
                            ProfileAnalysisDetail(
                                title: "Contrast",
                                value: profile.contrast.rawValue,
                                icon: "circle.lefthalf.filled"
                            )
                            ProfileAnalysisDetail(
                                title: "Confidence",
                                value: "\(Int(profile.confidence * 100))%",
                                icon: "checkmark.seal"
                            )
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)

                        // Focus color
                        if let focusColor = profile.focusColor {
                            HStack(spacing: 12) {
                                Circle()
                                    .fill(focusColor.color)
                                    .frame(width: 30, height: 30)
                                Text("Focus Color: \(focusColor.name)")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground))
                            .cornerRadius(20)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    Divider()
                        .padding(.horizontal)

                    // Packs Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Generated Packs")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        // Drapes Grid
                        if let drapesURL = profile.drapesGridImageURL,
                           let uiImage = UIImage(contentsOfFile: drapesURL.path) {
                            PackCard(
                                title: "Drapes Grid",
                                subtitle: "Your perfect colors",
                                image: uiImage,
                                icon: "square.grid.3x3.fill"
                            ) {
                                selectedPack = .drapesGrid
                            }
                        }

                        // Texture Pack
                        if profile.selectedPacks.contains("texture"),
                           let textureURL = profile.texturePackImageURL,
                           let uiImage = UIImage(contentsOfFile: textureURL.path) {
                            PackCard(
                                title: "Texture Pack",
                                subtitle: "Perfect fabric patterns",
                                image: uiImage,
                                icon: "square.grid.3x3.fill"
                            ) {
                                selectedPack = .texturePack
                            }
                        }

                        // Jewelry Pack
                        if profile.selectedPacks.contains("jewelry"),
                           let jewelryURL = profile.jewelryPackImageURL,
                           let uiImage = UIImage(contentsOfFile: jewelryURL.path) {
                            PackCard(
                                title: "Jewelry Pack",
                                subtitle: "Metals and gemstones",
                                image: uiImage,
                                icon: "sparkles"
                            ) {
                                selectedPack = .jewelryPack
                            }
                        }

                        // Makeup Pack
                        if profile.selectedPacks.contains("makeup"),
                           let makeupURL = profile.makeupPackImageURL,
                           let uiImage = UIImage(contentsOfFile: makeupURL.path) {
                            PackCard(
                                title: "Makeup Pack",
                                subtitle: "Your ideal makeup shades",
                                image: uiImage,
                                icon: "paintbrush.fill"
                            ) {
                                selectedPack = .makeupPack
                            }
                        }

                        // Hair Color Pack
                        if profile.selectedPacks.contains("hair"),
                           let hairURL = profile.hairColorPackImageURL,
                           let uiImage = UIImage(contentsOfFile: hairURL.path) {
                            PackCard(
                                title: "Hair Color Pack",
                                subtitle: "Hair colors for your season",
                                image: uiImage,
                                icon: "person.crop.circle.fill"
                            ) {
                                selectedPack = .hairColorPack
                            }
                        }
                    }

                    Spacer().frame(height: 40)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Historical Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .navigationDestination(item: $selectedPack) { packType in
                PackDetailView(profile: profile, packType: packType)
                    .environmentObject(appState)
            }
        }
    }
}

// Reuse ProfileAnalysisDetail from ProfileDashboardView
private struct ProfileAnalysisDetail: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.purple)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)

            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HistoricalProfileDetailView(
        historical: HistoricalProfile(
            profile: UserProfile(
                selfieImageData: nil,
                season: .clearSpring,
                undertone: .warm,
                contrast: .high,
                confidence: 0.89
            )
        )
    )
    .environmentObject(AppState())
}
