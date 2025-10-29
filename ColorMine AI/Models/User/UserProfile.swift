//
//  UserProfile.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import Foundation
import UIKit

struct UserProfile: Codable, Identifiable {
    let id: UUID
    let scanDate: Date
    var selfieImageData: Data?

    // Analysis Results
    var season: ColorSeason
    var undertone: Undertone
    var contrast: Contrast
    var confidence: Double

    // Color Selections
    var favoriteColors: [ColorSwatch] = []      // 3-8 selected from palette
    var focusColor: ColorSwatch?                 // The chosen one for deep dive

    // AI Generation Status
    var packsGenerated: PacksGenerationStatus = PacksGenerationStatus()

    // Cached AI Image URLs (local file paths)
    var drapesGridImageURL: URL?
    var texturePackImageURL: URL?
    var jewelryPackImageURL: URL?
    var makeupPackImageURL: URL?

    // Text Cards
    var contrastCard: ContrastCard?
    var neutralsMetalsCard: NeutralsMetalsCard?

    // Computed property to get UIImage from Data
    var selfieImage: UIImage? {
        guard let data = selfieImageData else { return nil }
        return UIImage(data: data)
    }

    init(
        id: UUID = UUID(),
        scanDate: Date = Date(),
        selfieImageData: Data? = nil,
        season: ColorSeason,
        undertone: Undertone,
        contrast: Contrast,
        confidence: Double
    ) {
        self.id = id
        self.scanDate = scanDate
        self.selfieImageData = selfieImageData
        self.season = season
        self.undertone = undertone
        self.contrast = contrast
        self.confidence = confidence
    }
}

// MARK: - Mock Data
extension UserProfile {
    static let mock = UserProfile(
        season: .softAutumn,
        undertone: .warmNeutral,
        contrast: .low,
        confidence: 0.92
    )
}
