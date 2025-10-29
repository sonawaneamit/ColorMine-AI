//
//  StyleCards.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import Foundation
import SwiftUI

// MARK: - Neutral & Metal Color Models
struct NeutralColor: Codable, Identifiable {
    let id: UUID
    let name: String
    let hex: String

    init(name: String, hex: String) {
        self.id = UUID()
        self.name = name
        self.hex = hex
    }

    var color: Color {
        Color(hex: hex)
    }
}

struct MetalColor: Codable, Identifiable {
    let id: UUID
    let name: String
    let hex: String

    init(name: String, hex: String) {
        self.id = UUID()
        self.name = name
        self.hex = hex
    }

    var color: Color {
        Color(hex: hex)
    }
}

// MARK: - Contrast Card
struct ContrastCard: Codable {
    let contrastLevel: Contrast
    let description: String
    let tips: [String]

    static func generate(for contrast: Contrast) -> ContrastCard {
        switch contrast {
        case .low:
            return ContrastCard(
                contrastLevel: .low,
                description: "You have soft, blended features with gentle transitions between your hair, skin, and eyes.",
                tips: [
                    "Wear monochromatic outfits in similar tones",
                    "Avoid stark contrasts (like black and white together)",
                    "Choose muted, blended color combinations",
                    "Opt for tone-on-tone accessories",
                    "Soft, diffused patterns work best",
                    "Keep makeup soft and blended"
                ]
            )

        case .medium:
            return ContrastCard(
                contrastLevel: .medium,
                description: "You have moderate contrast between your features, creating balanced and harmonious appearance.",
                tips: [
                    "You can wear both soft and moderate contrasts",
                    "Mix medium-toned colors together",
                    "Combine neutrals with pops of color",
                    "Moderate patterns and prints work well",
                    "Balance light and medium tones",
                    "Semi-bold accessories are flattering"
                ]
            )

        case .high:
            return ContrastCard(
                contrastLevel: .high,
                description: "You have striking contrast between your hair, skin, and eyes, creating dramatic and bold features.",
                tips: [
                    "Wear high-contrast color combinations",
                    "Black and white looks stunning on you",
                    "Bold, dramatic accessories are perfect",
                    "Strong patterns and prints are flattering",
                    "Don't be afraid of statement pieces",
                    "Defined makeup with clear lines works best",
                    "Avoid muddy or overly soft colors"
                ]
            )
        }
    }
}

// MARK: - Neutrals & Metals Card
struct NeutralsMetalsCard: Codable {
    let undertone: Undertone
    let bestNeutrals: [NeutralColor]
    let bestMetals: [MetalColor]
    let avoidsNeutrals: [NeutralColor]
    let avoidsMetals: [MetalColor]

    static func generate(for undertone: Undertone, season: ColorSeason) -> NeutralsMetalsCard {
        // Determine if cool or warm leaning
        let isCool = undertone == .cool || undertone == .coolNeutral
        let isWarm = undertone == .warm || undertone == .warmNeutral

        if isCool {
            return NeutralsMetalsCard(
                undertone: undertone,
                bestNeutrals: [
                    NeutralColor(name: "Pure White", hex: "FFFFFF"),
                    NeutralColor(name: "Cool Gray", hex: "8B8589"),
                    NeutralColor(name: "Charcoal", hex: "36454F"),
                    NeutralColor(name: "Navy Blue", hex: "000080"),
                    NeutralColor(name: "Icy Blue-Gray", hex: "9DB4C0"),
                    NeutralColor(name: "Cool Beige", hex: "C9ADA7"),
                    NeutralColor(name: "Pure Black", hex: "000000")
                ],
                bestMetals: [
                    MetalColor(name: "Silver", hex: "C0C0C0"),
                    MetalColor(name: "White Gold", hex: "E8E8E8"),
                    MetalColor(name: "Platinum", hex: "E5E4E2"),
                    MetalColor(name: "Pewter", hex: "899499")
                ],
                avoidsNeutrals: [
                    NeutralColor(name: "Warm Beige", hex: "C9B59A"),
                    NeutralColor(name: "Camel", hex: "C19A6B"),
                    NeutralColor(name: "Orange-Brown", hex: "A0522D"),
                    NeutralColor(name: "Warm Cream", hex: "FFF8DC")
                ],
                avoidsMetals: [
                    MetalColor(name: "Yellow Gold", hex: "FFD700"),
                    MetalColor(name: "Brass", hex: "B5A642"),
                    MetalColor(name: "Copper", hex: "B87333"),
                    MetalColor(name: "Bronze", hex: "CD7F32")
                ]
            )
        } else if isWarm {
            return NeutralsMetalsCard(
                undertone: undertone,
                bestNeutrals: [
                    NeutralColor(name: "Warm Cream", hex: "FFFDD0"),
                    NeutralColor(name: "Camel", hex: "C19A6B"),
                    NeutralColor(name: "Warm Beige", hex: "C9B59A"),
                    NeutralColor(name: "Chocolate Brown", hex: "3F2512"),
                    NeutralColor(name: "Warm Gray", hex: "9A8F83"),
                    NeutralColor(name: "Olive", hex: "808000"),
                    NeutralColor(name: "Warm Taupe", hex: "B38B6D")
                ],
                bestMetals: [
                    MetalColor(name: "Gold", hex: "FFD700"),
                    MetalColor(name: "Rose Gold", hex: "B76E79"),
                    MetalColor(name: "Copper", hex: "B87333"),
                    MetalColor(name: "Bronze", hex: "CD7F32"),
                    MetalColor(name: "Brass", hex: "B5A642")
                ],
                avoidsNeutrals: [
                    NeutralColor(name: "Pure White", hex: "FFFFFF"),
                    NeutralColor(name: "Cool Gray", hex: "8B8589"),
                    NeutralColor(name: "Icy Tones", hex: "E0FFFF"),
                    NeutralColor(name: "Blue-Gray", hex: "6699CC")
                ],
                avoidsMetals: [
                    MetalColor(name: "Silver", hex: "C0C0C0"),
                    MetalColor(name: "Platinum", hex: "E5E4E2"),
                    MetalColor(name: "Cool White Gold", hex: "F0F0F0")
                ]
            )
        } else {
            // True neutral
            return NeutralsMetalsCard(
                undertone: undertone,
                bestNeutrals: [
                    NeutralColor(name: "Soft White", hex: "F5F5F5"),
                    NeutralColor(name: "Greige", hex: "B6ACA3"),
                    NeutralColor(name: "Medium Gray", hex: "808080"),
                    NeutralColor(name: "Taupe", hex: "B38B6D"),
                    NeutralColor(name: "Soft Beige", hex: "D9CFC1"),
                    NeutralColor(name: "Charcoal", hex: "36454F"),
                    NeutralColor(name: "Navy", hex: "000080")
                ],
                bestMetals: [
                    MetalColor(name: "Rose Gold", hex: "B76E79"),
                    MetalColor(name: "Brushed Gold", hex: "D4AF37"),
                    MetalColor(name: "Antique Silver", hex: "A8A8A8")
                ],
                avoidsNeutrals: [
                    NeutralColor(name: "Stark White", hex: "FFFFFF"),
                    NeutralColor(name: "Pure Black", hex: "000000")
                ],
                avoidsMetals: [
                    MetalColor(name: "Shiny Chrome", hex: "E8E8E8")
                ]
            )
        }
    }
}
