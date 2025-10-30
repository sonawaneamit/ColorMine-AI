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
        Create a professional texture options grid showing \(color.name) (#\(color.hex)) in 6 different fabric textures suited for \(season.rawValue) coloring.

        🚨 CRITICAL - PRESERVE ORIGINAL APPEARANCE:
        - The person's skin tone, complexion, and ethnicity MUST remain EXACTLY as shown in the reference photo
        - DO NOT alter, lighten, darken, or change the skin color in any way
        - Maintain the person's natural features, face shape, and appearance
        - ONLY change the fabric texture - everything else stays identical

        CRITICAL GRID FORMAT:
        - Create EXACTLY a 2×3 grid (2 columns, 3 rows = 6 total tiles)
        - Vertical orientation (taller than wide) optimized for phone screens
        - Same person, same pose, same lighting in each tile
        - Show upper body (neck to waist) to display fabric texture and drape
        - Each tile clearly labeled with the fabric type

        SEASON-APPROPRIATE TEXTURES FOR \(season.rawValue):
        Based on professional color analysis for season "\(seasonKey)", select 6 textures from these categories:
        - Recommended textures that enhance \(season.rawValue) coloring
        - Vary from structured to flowing
        - Include both casual and elegant options
        - Examples: Silk, Cotton, Linen, Wool, Cashmere, Velvet, Satin, Suede, Leather, Fine Knit

        REQUIREMENTS:
        - Professional studio lighting to showcase texture differences
        - Each fabric should show distinct visual texture (matte vs. shiny, smooth vs. textured, etc.)
        - High resolution, professional quality
        - Labels clearly visible on each tile
        - Color \(color.name) should appear consistent across all tiles

        Goal: Show how the same color transforms with different textures, helping visualize which fabric finishes work best for \(season.rawValue) season coloring.
        """
    }

    // MARK: - Jewelry Pack Prompt
    static func jewelryPackPrompt(color: ColorSwatch, undertone: Undertone, season: ColorSeason) -> String {
        let seasonKey = getSeasonKey(season)

        return """
        Create a professional jewelry options grid showing the same person wearing \(color.name) (#\(color.hex)) with 6 different metal finishes.

        🚨 CRITICAL - PRESERVE ORIGINAL APPEARANCE:
        - The person's skin tone, complexion, and ethnicity MUST remain EXACTLY as shown in the reference photo
        - DO NOT alter, lighten, darken, or change the skin color in any way
        - Maintain the person's natural features, face shape, and appearance
        - ONLY change the jewelry/metal - everything else stays identical

        CRITICAL GRID FORMAT:
        - Create EXACTLY a 2×3 grid (2 columns, 3 rows = 6 total tiles)
        - Vertical orientation (taller than wide) optimized for phone screens
        - Same person, same pose, same lighting in each tile
        - Person wearing \(color.name) in ALL tiles
        - Each tile clearly labeled with the metal type

        SEASON-APPROPRIATE METALS FOR \(season.rawValue):
        Based on professional color analysis for season "\(seasonKey)" with \(undertone.rawValue) undertones, show 6 metal options:
        - Include best metals for this season (prioritize these)
        - Include 1-2 okay/acceptable metals for comparison
        - Common metals: Yellow Gold, Rose Gold, White Gold, Silver, Platinum, Bronze, Copper, Champagne Gold, Antique Gold
        - Show elegant, simple jewelry (earrings, necklace, or delicate bracelets)

        REQUIREMENTS:
        - Professional styling and photography
        - Clear view of both the clothing color and metal jewelry
        - High resolution, professional quality
        - Natural lighting that shows true metal tones
        - Each metal should be visually distinct

        UNDERTONE GUIDANCE:
        The person has \(undertone.rawValue) undertones. Emphasize how each metal finish complements or contrasts with the undertone and \(color.name).

        Goal: Help visualize which jewelry metals create the most harmonious look for \(season.rawValue) coloring.
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

        🚨 CRITICAL - PRESERVE ORIGINAL APPEARANCE:
        - The person's skin tone, complexion, and ethnicity MUST remain EXACTLY as shown in the reference photo
        - DO NOT alter, lighten, darken, or change the skin color in any way
        - Maintain the person's natural features, face shape, and appearance
        - ONLY change the makeup application - the base skin tone stays identical

        CRITICAL GRID FORMAT:
        - Create EXACTLY a 2×3 grid (2 columns, 3 rows = 6 total tiles)
        - Vertical orientation (taller than wide) optimized for phone screens
        - Same person, same pose, same lighting in each tile
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
        Create a professional hair color options grid showing 6 different hair colors that complement \(season.rawValue) coloring with \(undertone.rawValue) undertones.

        🚨 CRITICAL - PRESERVE ORIGINAL APPEARANCE:
        - The person's skin tone, complexion, and ethnicity MUST remain EXACTLY as shown in the reference photo
        - DO NOT alter, lighten, darken, or change the skin color in any way
        - Maintain the person's natural facial features, face shape, and appearance
        - ONLY change the hair color - the person's skin tone and features stay completely identical
        - This is essential for respectful, accurate representation

        CRITICAL GRID FORMAT:
        - Create EXACTLY a 2×3 grid (2 columns, 3 rows = 6 total tiles)
        - Vertical orientation (taller than wide) optimized for phone screens
        - Same person, same pose, same lighting in each tile
        - Show head and shoulders to clearly display hair color
        - Each tile clearly labeled with the hair color name

        SEASON-APPROPRIATE HAIR COLORS FOR \(season.rawValue):
        Based on professional color analysis for season "\(seasonKey)" with \(undertone.rawValue) undertones, show 6 hair color options:
        - Include a variety: lighter, medium, and darker tones
        - All colors should harmonize with \(season.rawValue) coloring
        - Professional salon-quality coloring and styling
        - Natural-looking application (not costume/wig-like)
        - Examples of color names: "Golden Blonde", "Warm Chestnut", "Rich Auburn", "Ash Brown", "Honey Caramel", etc.

        SEASON-SPECIFIC GUIDANCE:
        \(getSeasonHairGuidance(for: season, undertone: undertone))

        REQUIREMENTS:
        - Professional styling and photography
        - Natural, flattering lighting to show true hair color
        - High resolution, professional quality
        - Each hair color should be visually distinct
        - Labels clearly visible on each tile

        Goal: Help visualize which hair colors from the \(season.rawValue) palette will enhance natural coloring and create the most harmonious look.
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
