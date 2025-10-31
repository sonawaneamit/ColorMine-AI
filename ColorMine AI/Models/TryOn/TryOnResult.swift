//
//  TryOnResult.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import Foundation

struct TryOnResult: Identifiable, Codable, Equatable {
    let id: UUID
    let garmentItem: GarmentItem
    let resultImageURL: URL     // Local cached fal.ai result
    let createdAt: Date
    let creditsUsed: Int
    var videoURL: URL?           // Optional video result (costs 3 additional credits)
    var videoCreditsUsed: Int?   // Track video generation cost separately

    init(
        id: UUID = UUID(),
        garmentItem: GarmentItem,
        resultImageURL: URL,
        createdAt: Date = Date(),
        creditsUsed: Int = 1,
        videoURL: URL? = nil,
        videoCreditsUsed: Int? = nil
    ) {
        self.id = id
        self.garmentItem = garmentItem
        self.resultImageURL = resultImageURL
        self.createdAt = createdAt
        self.creditsUsed = creditsUsed
        self.videoURL = videoURL
        self.videoCreditsUsed = videoCreditsUsed
    }

    // Helper to check if result is recent
    var isRecent: Bool {
        let daysSinceCreation = Calendar.current.dateComponents([.day], from: createdAt, to: Date()).day ?? 0
        return daysSinceCreation <= 7
    }

    // Formatted date for display
    var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: createdAt, relativeTo: Date())
    }
}
