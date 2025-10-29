//
//  PromptEngine.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import Foundation

class PromptEngine {

    // MARK: - Drapes Grid Prompt
    static func drapesGridPrompt(colors: [ColorSwatch]) -> String {
        let colorList = colors.map { "\($0.name) (#\($0.hex))" }.joined(separator: ", ")

        return """
        Create a professional personal color analysis draping grid showing the same person wearing simple, solid-colored tops in each of these colors: \(colorList)

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
    static func texturePackPrompt(color: ColorSwatch) -> String {
        return """
        Create a comprehensive texture exploration grid showing the color \(color.name) (#\(color.hex)) in various fabric materials and textures.

        Create a GRID LAYOUT with the same person wearing this color in different fabrics:
        1. Cotton (matte, casual texture)
        2. Silk (glossy, elegant drape)
        3. Linen (visible weave, natural texture)
        4. Wool (knit texture, cozy)
        5. Satin (high sheen, smooth)
        6. Velvet (soft, plush texture)
        7. Denim (structured, casual)
        8. Cashmere (fine knit, luxurious)

        REQUIREMENTS:
        - Create a grid layout showing 6-8 different texture variations
        - Same person, same pose in each grid cell
        - Each texture should be clearly distinguishable
        - Show upper body (neck to waist) to see fabric drape and texture
        - Professional studio lighting to highlight texture differences
        - Label each cell with the fabric type
        - Ensure labels are on separate lines and fully visible
        - Professional quality photography

        Goal: Show how different textures and fabric finishes transform the same color, helping the user understand which textures work best for their coloring.
        """
    }

    // MARK: - Jewelry Pack Prompt
    static func jewelryPackPrompt(color: ColorSwatch, undertone: Undertone) -> String {
        return """
        Create a jewelry and accessories pack showing the color \(color.name) (#\(color.hex)) paired with different metal finishes.

        Show the person wearing this color with:
        1. Gold jewelry (warm, traditional)
        2. Rose Gold jewelry (warm, modern)
        3. Silver jewelry (cool, classic)
        4. Bronze jewelry (warm, earthy)
        5. Copper jewelry (warm, vintage)

        REQUIREMENTS:
        - Same person wearing \(color.name)
        - Show elegant, simple jewelry (earrings, necklace, or bracelets)
        - Focus on metal-color harmony
        - Professional styling
        - Clear view of both color and metal
        - Label each image with metal type

        UNDERTONE CONSIDERATION:
        The person has \(undertone.rawValue) undertones, so emphasize which metals create the best harmony.

        Goal: Show which metal finishes complement this color and undertone best.
        """
    }

    // MARK: - Makeup Pack Prompt
    static func makeupPackPrompt(
        color: ColorSwatch,
        undertone: Undertone,
        contrast: Contrast,
        eyeshadowIntensity: Double = 50,
        eyelinerIntensity: Double = 50,
        blushIntensity: Double = 50,
        lipstickIntensity: Double = 50
    ) -> String {
        // Convert intensity percentages to descriptive levels
        func intensityLevel(_ value: Double) -> String {
            switch value {
            case 0..<20: return "very subtle"
            case 20..<40: return "light"
            case 40..<60: return "medium"
            case 60..<80: return "bold"
            default: return "dramatic"
            }
        }

        return """
        Create a makeup harmony pack showing how \(color.name) (#\(color.hex)) influences coordinating makeup tones.

        Show the person with makeup that harmonizes with this color:
        1. Lipstick in complementary shade - \(intensityLevel(lipstickIntensity)) intensity (\(Int(lipstickIntensity))%)
        2. Blush in harmonizing tone - \(intensityLevel(blushIntensity)) intensity (\(Int(blushIntensity))%)
        3. Eyeshadow in coordinating color - \(intensityLevel(eyeshadowIntensity)) intensity (\(Int(eyeshadowIntensity))%)
        4. Eyeliner - \(intensityLevel(eyelinerIntensity)) intensity (\(Int(eyelinerIntensity))%)
        5. Full makeup look combining all elements

        REQUIREMENTS:
        - Realistic, professional makeup application
        - Show actual face (no mannequins)
        - Natural, flattering lighting
        - Focus on color harmony and coordination
        - Professional beauty photography style
        - Label each with makeup type and intensity level
        - Apply makeup according to the specified intensity levels

        COLOR PROFILE:
        - Undertone: \(undertone.rawValue)
        - Contrast: \(contrast.rawValue)
        - Focus Color: \(color.name)

        INTENSITY GUIDELINES:
        - Eyeshadow: \(intensityLevel(eyeshadowIntensity)) (\(Int(eyeshadowIntensity))% coverage)
        - Eyeliner: \(intensityLevel(eyelinerIntensity)) (\(Int(eyelinerIntensity))% thickness)
        - Blush: \(intensityLevel(blushIntensity)) (\(Int(blushIntensity))% pigmentation)
        - Lipstick: \(intensityLevel(lipstickIntensity)) (\(Int(lipstickIntensity))% color saturation)

        Goal: Show how this color creates a cohesive makeup palette with customized intensity that enhances natural features.
        """
    }

    // Note: ContrastCard and NeutralsMetalsCard prompts removed
    // These cards are now generated locally using StyleCards.swift
}
