//
//  PromptEngine.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import Foundation

class PromptEngine {

    // MARK: - Season Data Helper
    private static func getSeasonKey(_ season: ColorSeason) -> String {
        switch season {
        case .lightSpring: return "light_spring"
        case .warmSpring: return "warm_spring"
        case .clearSpring: return "clear_spring"
        case .lightSummer: return "light_summer"
        case .coolSummer: return "cool_summer"
        case .softSummer: return "soft_summer"
        case .softAutumn: return "soft_autumn"
        case .warmAutumn: return "warm_autumn"
        case .deepAutumn: return "deep_autumn"
        case .deepWinter: return "deep_winter"
        case .coolWinter: return "cool_winter"
        case .clearWinter: return "clear_winter"
        }
    }

    // MARK: - Drapes Grid Prompt
    static func drapesGridPrompt(colors: [ColorSwatch]) -> String {
        let colorList = colors.map { "\($0.name) (#\($0.hex))" }.joined(separator: ", ")

        return """
        Create a professional color draping grid showing the same person wearing solid-colored tops in these colors: \(colorList)

        Grid layout:
        - \(colors.count) tiles showing the person from neck to waist
        - Same person, same pose, same lighting in each tile
        - Simple crew neck or scoop neck solid-colored tops
        - Professional clean background
        - Each tile labeled with color name and hex code

        The person should look natural and consistent across all tiles, with only the clothing color changing between images.
        """
    }

    // MARK: - Texture Pack Prompt
    static func texturePackPrompt(color: ColorSwatch, season: ColorSeason) -> String {
        let seasonKey = getSeasonKey(season)

        return """
        Create a 2x3 grid showing the same person wearing \(color.name) clothing in 6 different fabric textures.

        Show these fabric textures (suited for \(season.rawValue) season):
        - Silk, Cotton, Linen, Wool, Cashmere, Velvet, Satin, or Suede
        - Mix of matte, shiny, smooth, and textured finishes
        - Include both casual and elegant options

        Grid format:
        - 6 tiles in 2 columns, 3 rows
        - Same person from neck to waist in each tile
        - Clothing stays in the \(color.name) color range
        - Each tile labeled with fabric name
        - Professional fashion photography with good lighting

        Focus on showing how different fabric textures look in this color.
        """
    }

    // MARK: - Jewelry Pack Prompt
    static func jewelryPackPrompt(color: ColorSwatch, undertone: Undertone, season: ColorSeason) -> String {
        let seasonKey = getSeasonKey(season)

        return """
        Create a 2x3 grid showing the same person wearing \(color.name) clothing with 6 different jewelry metal finishes.

        Jewelry metals to show (suited for \(season.rawValue) with \(undertone.rawValue) undertones):
        - Yellow Gold, Rose Gold, White Gold, Silver, Platinum, Bronze, Copper, or Champagne Gold
        - Simple, elegant pieces like earrings, necklace, or delicate bracelets
        - Each metal should look distinct

        Grid format:
        - 6 tiles in 2 columns, 3 rows
        - Same person from neck to shoulders in each tile
        - Clothing stays in the \(color.name) color range
        - Each tile labeled with the metal name
        - Professional fashion photography with natural lighting

        Focus on showing which jewelry metals complement this coloring.
        """
    }

    // MARK: - Makeup Pack Prompt
    static func makeupPackPrompt(
        color: ColorSwatch?,
        undertone: Undertone,
        contrast: Contrast,
        season: ColorSeason
    ) -> String {
        let seasonKey = getSeasonKey(season)

        return """
        Create a 2x3 grid showing the same person with 6 different makeup looks for \(season.rawValue) coloring.

        6 makeup styles to show:
        1. Natural/Everyday - Soft and subtle
        2. Professional/Work - Polished and refined
        3. Evening/Glam - Bold and dramatic
        4. Romantic/Soft - Feminine and delicate
        5. Smoky Eye - Sultry and intense
        6. Fresh/Minimal - Clean and luminous

        Makeup guidance for \(season.rawValue):
        - Undertone: \(undertone.rawValue) - \(getMakeupGuidance(for: undertone))
        - Contrast: \(contrast.rawValue) - \(getContrastMakeupGuidance(for: contrast))
        \(color != nil ? "- Coordinate with \(color!.name)" : "")

        Grid format:
        - 6 tiles in 2 columns, 3 rows
        - Same person's face in each tile
        - Each tile labeled with makeup style
        - Professional beauty photography with natural lighting

        Show a range from minimal to dramatic makeup, all suited for this season.
        """
    }

    // MARK: - Makeup Guidance by Undertone
    private static func getMakeupGuidance(for undertone: Undertone) -> String {
        switch undertone {
        case .warm, .warmNeutral:
            return "warm-toned makeup (peach, coral, bronze, warm browns, terracotta)"
        case .cool, .coolNeutral:
            return "cool-toned makeup (pink, rose, berry, cool browns, mauve)"
        case .neutral:
            return "both warm and cool tones, focus on balanced, versatile shades"
        }
    }

    // MARK: - Makeup Guidance by Contrast
    private static func getContrastMakeupGuidance(for contrast: Contrast) -> String {
        switch contrast {
        case .high:
            return "Can wear bold, dramatic makeup with strong color payoff"
        case .medium:
            return "Works well with medium intensity makeup, can go bolder or softer"
        case .low:
            return "Looks best in softer, more subtle makeup shades with less contrast"
        }
    }

    // MARK: - Hair Color Pack Prompt
    static func hairColorPackPrompt(season: ColorSeason, undertone: Undertone) -> String {
        let seasonKey = getSeasonKey(season)

        return """
        Create a 2x3 grid showing the same person with 6 different hair colors for \(season.rawValue) coloring with \(undertone.rawValue) undertones.

        Hair colors to show:
        - Mix of lighter, medium, and darker tones
        - Professional, natural-looking colors
        - Examples: Golden Blonde, Warm Chestnut, Rich Auburn, Ash Brown, Honey Caramel, Platinum, etc.

        Season guidance:
        \(getSeasonHairGuidance(for: season, undertone: undertone))

        Grid format:
        - 6 tiles in 2 columns, 3 rows
        - Same person's face from head to shoulders
        - Each tile labeled with hair color name
        - Professional photography with natural lighting

        Focus on showing hair colors that enhance this season's coloring.
        """
    }

    // MARK: - Season Hair Guidance
    private static func getSeasonHairGuidance(for season: ColorSeason, undertone: Undertone) -> String {
        switch season {
        case .deepWinter, .clearWinter, .coolWinter:
            return "Winter: Deep cool tones like blue-black, espresso, platinum blonde, cool burgundy. Avoid warm golden tones."
        case .deepAutumn, .warmAutumn, .softAutumn:
            return "Autumn: Warm earthy tones like golden blonde, caramel, auburn, copper, warm chestnut. Avoid cool ashy tones."
        case .clearSpring, .warmSpring, .lightSpring:
            return "Spring: Warm bright tones like golden blonde, strawberry blonde, honey, warm light brown, copper. Avoid dark cool tones."
        case .coolSummer, .softSummer, .lightSummer:
            return "Summer: Cool soft tones like ash blonde, mushroom brown, rose gold, cool chestnut. Avoid warm golden tones."
        }
    }

    // Note: ContrastCard and NeutralsMetalsCard prompts removed
    // These cards are now generated locally using StyleCards.swift
}
