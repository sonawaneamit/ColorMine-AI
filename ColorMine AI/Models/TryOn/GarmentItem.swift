//
//  GarmentItem.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import Foundation
import SwiftUI

struct GarmentItem: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let imageURL: URL          // Local file path
    let sourceStore: String?   // "ASOS", "H&M", etc.
    let productURL: String?    // Direct link to product page
    let dateAdded: Date

    // Color analysis (optional)
    var dominantColorHex: String?    // Extracted color
    var matchesUserSeason: Bool?     // Does it match their palette?
    var colorMatchScore: Int?        // 0-100 match score

    init(
        id: UUID = UUID(),
        imageURL: URL,
        sourceStore: String? = nil,
        productURL: String? = nil,
        dateAdded: Date = Date(),
        dominantColorHex: String? = nil,
        matchesUserSeason: Bool? = nil,
        colorMatchScore: Int? = nil
    ) {
        self.id = id
        self.imageURL = imageURL
        self.sourceStore = sourceStore
        self.productURL = productURL
        self.dateAdded = dateAdded
        self.dominantColorHex = dominantColorHex
        self.matchesUserSeason = matchesUserSeason
        self.colorMatchScore = colorMatchScore
    }

    // Computed property for dominant color
    var dominantColor: Color? {
        guard let hex = dominantColorHex else { return nil }
        return Color(hex: hex)
    }
}
