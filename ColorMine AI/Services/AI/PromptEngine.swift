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
        Create a professional personal color analysis draping grid showing the same person wearing simple, solid-colored tops in each of these colors: \(colorList)

        🚨 CRITICAL - PRESERVE ORIGINAL APPEARANCE:
        - The person's skin tone, complexion, and ethnicity MUST remain EXACTLY as shown in the reference photo
        - DO NOT alter, lighten, darken, or change the skin color in any way
        - Maintain the person's natural features, face shape, and appearance
        - ONLY change the clothing color - everything else stays identical

        REQUIREMENTS:
        - Show ONLY the person's upper body (neck to waist)
        - Each image should show the person in the EXACT same pose, lighting, and expression
        - Use simple crew neck or scoop neck tops in solid colors
        - No patterns, textures, or embellishments
        - Professional, clean background
        - Consistent natural lighting across all images
        - Grid layout with \(colors.count) tiles
        - Each tile labeled with the color name on the first line and hex code on the second line (two separate lines)
        - Ensure labels are fully visible and not truncated
        - Use a clear, readable font for labels with good contrast against the background
        - High resolution, professional quality
        - Focus on how each color affects the person's complexion

        The goal is color comparison, so keep everything else identical except the clothing color.
        """
    }

    // MARK: - Texture Pack Prompt
    static func texturePackPrompt(color: ColorSwatch, season: ColorSeason) -> String {
        let seasonKey = getSeasonKey(season)

        return """
        Create a professional texture options grid showing the same person wearing \(color.name) (#\(color.hex)) clothing in 6 different fabric textures.

        IMPORTANT - Keep consistent:
        - Same person's face, skin tone, and features in all 6 tiles
        - Same clothing color \(color.name) in all tiles
        - Same pose and lighting
        - ONLY the fabric texture should change between tiles (matte, shiny, smooth, textured, etc.)

        GRID FORMAT:
        - 2×3 grid layout (2 columns, 3 rows = 6 tiles total)
        - Vertical orientation for mobile viewing
        - Show upper body to clearly display fabric texture and drape
        - Label each tile with the fabric type name

        FABRIC TEXTURES for \(season.rawValue):
        Choose 6 different textures that suit \(season.rawValue) coloring:
        - Examples: Silk (shiny), Cotton (matte), Linen (textured), Wool (soft), Cashmere (smooth), Velvet (plush), Satin (glossy), Suede (textured)
        - Include variety from structured to flowing fabrics
        - Mix casual and elegant options

        STYLE:
        - Professional fashion photography
        - Clear lighting to show texture differences
        - High quality, realistic rendering
        - Each fabric should look distinctly different in finish and texture

        The goal is to show how the color \(color.name) appears in different fabric finishes while keeping the person and color consistent.
        """
    }

    // MARK: - Jewelry Pack Prompt
    static func jewelryPackPrompt(color: ColorSwatch, undertone: Undertone, season: ColorSeason) -> String {
        let seasonKey = getSeasonKey(season)

        return """
        Create a professional jewelry options grid showing the same person wearing \(color.name) (#\(color.hex)) clothing with 6 different jewelry metal finishes.

        IMPORTANT - Keep consistent:
        - Same person's face, skin tone, and features in all 6 tiles
        - Same clothing color \(color.name) in all tiles
        - Same pose and lighting
        - ONLY the jewelry metal/finish should change between tiles

        GRID FORMAT:
        - 2×3 grid layout (2 columns, 3 rows = 6 tiles total)
        - Vertical orientation for mobile viewing
        - Person wearing \(color.name) clothing in all tiles
        - Each tile clearly labeled with the metal type

        JEWELRY METALS for \(season.rawValue) with \(undertone.rawValue) undertones:
        Show 6 different metal finishes suited for this season:
        - Examples: Yellow Gold, Rose Gold, White Gold, Silver, Platinum, Bronze, Copper, Champagne Gold
        - Include best metals for \(season.rawValue) season
        - Show elegant, simple jewelry (earrings, necklace, or delicate bracelets)
        - Each metal should be visually distinct

        STYLE:
        - Professional fashion photography
        - Clear view of both clothing and jewelry
        - Natural lighting showing true metal tones
        - High quality, realistic rendering

        The goal is to show which jewelry metals complement \(season.rawValue) coloring with \(undertone.rawValue) undertones when wearing \(color.name).
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
        Create a professional makeup options grid showing the same person with 6 different complete makeup looks suited for \(season.rawValue) coloring.

        IMPORTANT - Keep consistent:
        - Same person's face, skin tone, and features in all 6 tiles
        - Same pose and lighting
        - ONLY the makeup application should change between tiles

        GRID FORMAT:
        - 2×3 grid layout (2 columns, 3 rows = 6 tiles total)
        - Vertical orientation for mobile viewing
        - Each tile clearly labeled with the makeup style name

        6 MAKEUP LOOKS TO SHOW:
        1. Natural/Everyday - Soft, subtle, barely-there
        2. Professional/Work - Polished, refined, appropriate
        3. Evening/Glam - Bold, dramatic, statement-making
        4. Romantic/Soft - Feminine, delicate, dreamy
        5. Smoky Eye - Sultry, intense eye focus
        6. Fresh/Minimal - Clean, luminous, effortless

        SEASON-APPROPRIATE MAKEUP FOR \(season.rawValue):
        Based on professional color analysis for season "\(seasonKey)":
        - Undertone: \(undertone.rawValue) - Use \(getMakeupGuidance(for: undertone))
        - Contrast Level: \(contrast.rawValue) - \(getContrastMakeupGuidance(for: contrast))
        \(color != nil ? "- Coordinate with color: \(color!.name)" : "")
        - Apply season-appropriate lip, blush, and eye color tones
        - Respect the season's depth, chroma, and temperature

        REQUIREMENTS:
        - Professional makeup application for each style
        - Natural, flattering lighting showing true makeup colors
        - High resolution, professional beauty photography
        - Show how different makeup intensities work with \(season.rawValue) coloring
        - All makeup should harmonize with the person's natural coloring

        Goal: Provide a complete range of makeup options from minimal to dramatic, all tailored to \(season.rawValue) season guidelines.
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
        Create a professional hair color options grid showing the same person with 6 different hair colors that complement \(season.rawValue) coloring with \(undertone.rawValue) undertones.

        IMPORTANT - Keep consistent:
        - Same person's face, skin tone, and features in all 6 tiles
        - Same pose and lighting
        - ONLY the hair color should change between tiles

        GRID FORMAT:
        - 2×3 grid layout (2 columns, 3 rows = 6 tiles total)
        - Vertical orientation for mobile viewing
        - Show head and shoulders to clearly display hair color
        - Each tile clearly labeled with the hair color name

        HAIR COLORS for \(season.rawValue) with \(undertone.rawValue) undertones:
        Show 6 different hair colors suited for this season:
        - Include variety: lighter, medium, and darker tones
        - Professional salon-quality coloring
        - Natural-looking application
        - Examples: "Golden Blonde", "Warm Chestnut", "Rich Auburn", "Ash Brown", "Honey Caramel", etc.

        SEASON GUIDANCE:
        \(getSeasonHairGuidance(for: season, undertone: undertone))

        STYLE:
        - Professional styling and photography
        - Natural lighting showing true hair color
        - High quality, realistic rendering
        - Each hair color should be visually distinct

        The goal is to visualize which hair colors enhance \(season.rawValue) coloring while maintaining natural appearance.
        """
    }

    // MARK: - Season Hair Guidance
    private static func getSeasonHairGuidance(for season: ColorSeason, undertone: Undertone) -> String {
        switch season {
        case .deepWinter, .clearWinter, .coolWinter:
            return """
            Winter seasons look best in:
            - Deep, rich colors with cool undertones
            - Blue-black, deep espresso, cool dark brown
            - Icy blonde, platinum, silver-white
            - Cool burgundy, deep wine
            - Avoid warm golden or brassy tones
            """
        case .deepAutumn, .warmAutumn, .softAutumn:
            return """
            Autumn seasons look best in:
            - Warm, rich, earthy tones
            - Golden blonde, honey, caramel
            - Warm chestnut, auburn, copper
            - Rich chocolate, warm mahogany
            - Deep golden brown with warm undertones
            - Avoid cool ashy or icy tones
            """
        case .clearSpring, .warmSpring, .lightSpring:
            return """
            Spring seasons look best in:
            - Warm, bright, golden tones
            - Golden blonde, strawberry blonde
            - Warm honey, light caramel
            - Warm light brown, peach-toned highlights
            - Copper, warm red
            - Avoid dark, cool, or ashy tones
            """
        case .coolSummer, .softSummer, .lightSummer:
            return """
            Summer seasons look best in:
            - Cool, soft, muted tones
            - Ash blonde, cool beige blonde
            - Cool light brown, mushroom brown
            - Soft rose gold, cool chestnut
            - Cool gray tones for mature hair
            - Avoid warm golden or orange tones
            """
        }
    }

    // Note: ContrastCard and NeutralsMetalsCard prompts removed
    // These cards are now generated locally using StyleCards.swift
}
