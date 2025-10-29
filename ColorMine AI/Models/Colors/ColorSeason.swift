//
//  ColorSeason.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import Foundation

enum ColorSeason: String, Codable, CaseIterable {
    case deepWinter = "Deep Winter"
    case clearWinter = "Clear Winter"
    case coolWinter = "Cool Winter"
    case deepAutumn = "Deep Autumn"
    case warmAutumn = "Warm Autumn"
    case softAutumn = "Soft Autumn"
    case clearSpring = "Clear Spring"
    case warmSpring = "Warm Spring"
    case lightSpring = "Light Spring"
    case coolSummer = "Cool Summer"
    case softSummer = "Soft Summer"
    case lightSummer = "Light Summer"

    var id: String { rawValue }
}

enum Undertone: String, Codable {
    case warm = "Warm"
    case cool = "Cool"
    case neutral = "Neutral"
    case warmNeutral = "Warm Neutral"
    case coolNeutral = "Cool Neutral"
}

enum Contrast: String, Codable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"
}

struct ColorPalette: Codable {
    let season: ColorSeason
    let colors: [ColorSwatch]  // 12-24 colors per season
    let description: String
}
