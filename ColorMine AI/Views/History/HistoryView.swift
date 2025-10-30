//
//  HistoryView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedProfile: HistoricalProfile?

    var body: some View {
        Group {
            if appState.profileHistory.profiles.isEmpty {
                // Empty state
                VStack(spacing: 20) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))

                    Text("No History Yet")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Your generated color analyses will appear here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(.systemGroupedBackground))
            } else {
                // History list
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(appState.profileHistory.sortedProfiles()) { historical in
                            HistoryCard(historical: historical)
                                .onTapGesture {
                                    selectedProfile = historical
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        deleteProfile(historical)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
        }
        .sheet(item: $selectedProfile) { historical in
            HistoricalProfileDetailView(historical: historical)
                .environmentObject(appState)
        }
    }

    private func deleteProfile(_ historical: HistoricalProfile) {
        withAnimation {
            appState.profileHistory.deleteProfile(historical.id)
        }
    }
}

// MARK: - History Card
struct HistoryCard: View {
    let historical: HistoricalProfile

    var body: some View {
        HStack(spacing: 16) {
            // Thumbnail
            Group {
                if let thumbnail = historical.thumbnailImage {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundColor(.gray)
                }
            }
            .frame(width: 80, height: 80)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .clipped()

            // Details
            VStack(alignment: .leading, spacing: 6) {
                Text(historical.profile.season.rawValue)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "circle.hexagongrid")
                            .font(.caption2)
                        Text(historical.profile.undertone.rawValue)
                            .font(.caption)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "circle.lefthalf.filled")
                            .font(.caption2)
                        Text(historical.profile.contrast.rawValue)
                            .font(.caption)
                    }
                }
                .foregroundColor(.secondary)

                Text(historical.shortDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 5, y: 2)
    }
}

#Preview {
    HistoryView()
        .environmentObject(AppState())
}
