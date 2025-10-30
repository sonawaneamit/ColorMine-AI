//
//  ColorSeason.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import Foundation
import SwiftUI

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

    /// Returns a gradient with colors appropriate for this season
    var gradient: LinearGradient {
        let colors = gradientColors
        return LinearGradient(
            colors: colors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    /// Season-specific gradient colors based on color theory
    private var gradientColors: [Color] {
        switch self {
        // WINTER SEASONS (cool, clear, high contrast)
        case .deepWinter:
            return [Color(red: 0.1, green: 0.1, blue: 0.3), Color(red: 0.5, green: 0.0, blue: 0.3)] // Navy to burgundy
        case .clearWinter:
            return [Color(red: 0.0, green: 0.3, blue: 0.7), Color(red: 0.7, green: 0.0, blue: 0.5)] // Royal blue to magenta
        case .coolWinter:
            return [Color(red: 0.5, green: 0.7, blue: 0.9), Color(red: 0.7, green: 0.5, blue: 0.8)] // Icy blue to cool lavender

        // SUMMER SEASONS (cool, muted, soft)
        case .lightSummer:
            return [Color(red: 0.7, green: 0.7, blue: 0.9), Color(red: 0.9, green: 0.7, blue: 0.8)] // Powder blue to soft rose
        case .coolSummer:
            return [Color(red: 0.5, green: 0.6, blue: 0.7), Color(red: 0.7, green: 0.5, blue: 0.6)] // Dusty blue to mauve
        case .softSummer:
            return [Color(red: 0.6, green: 0.6, blue: 0.7), Color(red: 0.7, green: 0.6, blue: 0.6)] // Soft gray-blue to dusty rose

        // SPRING SEASONS (warm, clear, light)
        case .clearSpring:
            return [Color(red: 1.0, green: 0.5, blue: 0.3), Color(red: 0.3, green: 0.8, blue: 0.7)] // Coral to turquoise
        case .warmSpring:
            return [Color(red: 1.0, green: 0.6, blue: 0.4), Color(red: 0.9, green: 0.7, blue: 0.2)] // Peach to golden
        case .lightSpring:
            return [Color(red: 1.0, green: 0.7, blue: 0.6), Color(red: 0.6, green: 0.9, blue: 0.7)] // Light peach to mint

        // AUTUMN SEASONS (warm, muted, rich)
        case .softAutumn:
            return [Color(red: 0.7, green: 0.6, blue: 0.5), Color(red: 0.8, green: 0.5, blue: 0.4)] // Warm taupe to terracotta
        case .warmAutumn:
            return [Color(red: 0.8, green: 0.4, blue: 0.2), Color(red: 0.6, green: 0.5, blue: 0.2)] // Rust to olive
        case .deepAutumn:
            return [Color(red: 0.5, green: 0.2, blue: 0.2), Color(red: 0.6, green: 0.4, blue: 0.1)] // Burgundy to bronze
        }
    }
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
