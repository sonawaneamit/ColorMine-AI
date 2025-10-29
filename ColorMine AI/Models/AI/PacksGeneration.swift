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
    var contrastCard: Bool = false
    var neutralsMetalsCard: Bool = false

    var allGenerated: Bool {
        drapes && textures && jewelry && makeup && contrastCard && neutralsMetalsCard
    }

    var percentComplete: Double {
        let total = 6.0
        var completed = 0.0
        if drapes { completed += 1 }
        if textures { completed += 1 }
        if jewelry { completed += 1 }
        if makeup { completed += 1 }
        if contrastCard { completed += 1 }
        if neutralsMetalsCard { completed += 1 }
        return (completed / total) * 100
    }
}

// Note: ContrastCard and NeutralsMetalsCard are defined in StyleCards.swift

enum PackType: String {
    case drapesGrid = "Drapes Grid"
    case texturePack = "Texture Pack"
    case jewelryPack = "Jewelry Pack"
    case makeupPack = "Makeup Pack"
}
