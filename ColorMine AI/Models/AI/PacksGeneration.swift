//
//  PacksGeneration.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import Foundation

struct PacksGenerationStatus: Codable {
    var drapes: Bool = false
    var textures: Bool = false
    var jewelry: Bool = false
    var makeup: Bool = false
    var hairColor: Bool = false
    var contrastCard: Bool = false
    var neutralsMetalsCard: Bool = false

    // Check if all SELECTED packs are generated
    func allGenerated(selectedPacks: Set<String>) -> Bool {
        // Always check drapes and style cards
        guard drapes && contrastCard && neutralsMetalsCard else {
            return false
        }

        // Check only the packs user selected
        if selectedPacks.contains("texture") && !textures {
            return false
        }
        if selectedPacks.contains("jewelry") && !jewelry {
            return false
        }
        if selectedPacks.contains("makeup") && !makeup {
            return false
        }
        if selectedPacks.contains("hair") && !hairColor {
            return false
        }

        return true
    }

    func percentComplete(selectedPacks: Set<String>) -> Double {
        // Calculate based on selected packs + drapes + style cards (always included)
        var total = 3.0 // drapes + 2 style cards
        var completed = 0.0

        // Always count these
        if drapes { completed += 1 }
        if contrastCard { completed += 1 }
        if neutralsMetalsCard { completed += 1 }

        // Count selected packs
        if selectedPacks.contains("texture") {
            total += 1
            if textures { completed += 1 }
        }
        if selectedPacks.contains("jewelry") {
            total += 1
            if jewelry { completed += 1 }
        }
        if selectedPacks.contains("makeup") {
            total += 1
            if makeup { completed += 1 }
        }
        if selectedPacks.contains("hair") {
            total += 1
            if hairColor { completed += 1 }
        }

        return (completed / total) * 100
    }
}

// Note: ContrastCard and NeutralsMetalsCard are defined in StyleCards.swift

enum PackType: String {
    case drapesGrid = "Drapes Grid"
    case texturePack = "Texture Pack"
    case jewelryPack = "Jewelry Pack"
    case makeupPack = "Makeup Pack"
    case hairColorPack = "Hair Color Pack"
}
