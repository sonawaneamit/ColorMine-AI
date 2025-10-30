//
//  FocusColorView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import SwiftUI

struct FocusColorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    let profile: UserProfile

    @State private var isGenerating = false
    @State private var navigateToPacks = false

    var body: some View {
        ZStack {
            // Gradient background matching focus color
            if let focusColor = profile.focusColor {
                LinearGradient(
                    colors: [
                        focusColor.color.opacity(0.3),
                        Color.purple.opacity(0.2),
                        Color.pink.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
            }

            ScrollView {
                VStack(spacing: 40) {
                    Spacer().frame(height: 40)

                    // Focus Color Display
                    if let focusColor = profile.focusColor {
                        VStack(spacing: 24) {
                            Text("Your Focus Color")
                                .font(.title2)
                                .fontWeight(.semibold)

                            // Large color circle
                            ZStack {
                                Circle()
                                    .fill(focusColor.color)
                                    .frame(width: 180, height: 180)
                                    .shadow(color: focusColor.color.opacity(0.5), radius: 20)

                                Circle()
                                    .strokeBorder(Color.white, lineWidth: 6)
                                    .frame(width: 180, height: 180)
                            }

                            Text(focusColor.name)
                                .font(.title)
                                .fontWeight(.bold)

                            Text(focusColor.hex.uppercased())
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color(.systemBackground).opacity(0.8))
                                .cornerRadius(8)

                            // Change Color Button
                            Button(action: {
                                goBackToChangeColor()
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                        .font(.subheadline)
                                    Text("Change Focus Color")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                .foregroundColor(.purple)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .background(Color(.systemBackground).opacity(0.9))
                                .cornerRadius(20)
                            }
                        }
                    }

                    // What's Next Section
                    VStack(spacing: 20) {
                        Text("What's Next?")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        Text("Choose which personalized style guides you'd like to create")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        // Feature cards
                        VStack(spacing: 16) {
                            PackFeatureCard(
                                icon: "square.grid.3x3.fill",
                                title: "Texture Pack",
                                description: "See fabric patterns that enhance your look"
                            )

                            PackFeatureCard(
                                icon: "sparkles",
                                title: "Jewelry Pack",
                                description: "Discover metals and gemstones that shine on you"
                            )

                            PackFeatureCard(
                                icon: "paintbrush.fill",
                                title: "Makeup Pack",
                                description: "Find your perfect makeup shades"
                            )

                            PackFeatureCard(
                                icon: "person.crop.circle.fill",
                                title: "Hair Color Pack",
                                description: "Explore hair colors for your season"
                            )

                            PackFeatureCard(
                                icon: "doc.text.fill",
                                title: "Style Cards",
                                description: "Get personalized contrast and neutral color guides"
                            )
                        }
                        .padding(.horizontal)
                    }

                    // Continue Button
                    Button(action: {
                        startGeneration()
                    }) {
                        HStack(spacing: 12) {
                            if isGenerating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Loading...")
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title3)
                                Text("Choose My Packs")
                                    .font(.headline)
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.purple, .pink],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                        .shadow(color: .purple.opacity(0.3), radius: 10, y: 5)
                    }
                    .disabled(isGenerating)
                    .padding(.horizontal)

                    Spacer().frame(height: 40)
                }
            }
        }
        .navigationTitle("Focus Color")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToPacks) {
            if let updatedProfile = appState.currentProfile {
                PackSelectionView(profile: updatedProfile)
                    .environmentObject(appState)
            }
        }
    }

    // MARK: - Start Generation
    private func startGeneration() {
        isGenerating = true

        // Small delay for UI smoothness
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            navigateToPacks = true
            isGenerating = false
        }
    }

    // MARK: - Go Back to Change Color
    private func goBackToChangeColor() {
        // Clear the focus color and navigate back to drapes grid
        var updatedProfile = profile
        updatedProfile.focusColor = nil
        appState.saveProfile(updatedProfile)
        dismiss()
    }
}

// MARK: - Pack Feature Card
struct PackFeatureCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(.purple)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground).opacity(0.9))
        .cornerRadius(12)
    }
}

#Preview {
    NavigationStack {
        FocusColorView(
            profile: UserProfile(
                selfieImageData: nil,
                season: .clearSpring,
                undertone: .warm,
                contrast: .high,
                confidence: 0.89
            )
        )
        .environmentObject(AppState())
    }
}
