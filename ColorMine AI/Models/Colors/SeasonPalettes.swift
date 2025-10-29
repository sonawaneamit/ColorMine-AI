//
//  SeasonPalettes.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import Foundation

struct SeasonPalettes {

    // MARK: - Get Palette for Season
    static func palette(for season: ColorSeason) -> [ColorSwatch] {
        switch season {
        case .deepWinter:
            return deepWinterPalette
        case .clearWinter:
            return clearWinterPalette
        case .coolWinter:
            return coolWinterPalette
        case .deepAutumn:
            return deepAutumnPalette
        case .warmAutumn:
            return warmAutumnPalette
        case .softAutumn:
            return softAutumnPalette
        case .clearSpring:
            return clearSpringPalette
        case .warmSpring:
            return warmSpringPalette
        case .lightSpring:
            return lightSpringPalette
        case .coolSummer:
            return coolSummerPalette
        case .softSummer:
            return softSummerPalette
        case .lightSummer:
            return lightSummerPalette
        }
    }

    // MARK: - Deep Winter
    private static let deepWinterPalette = [
        ColorSwatch(name: "Pure Black", hex: "000000"),
        ColorSwatch(name: "Pure White", hex: "FFFFFF"),
        ColorSwatch(name: "Navy", hex: "000080"),
        ColorSwatch(name: "Royal Blue", hex: "4169E1"),
        ColorSwatch(name: "Emerald", hex: "50C878"),
        ColorSwatch(name: "Deep Teal", hex: "014D4E"),
        ColorSwatch(name: "Ruby Red", hex: "9B111E"),
        ColorSwatch(name: "Magenta", hex: "C9008F"),
        ColorSwatch(name: "Deep Purple", hex: "301934"),
        ColorSwatch(name: "Pine Green", hex: "01796F"),
        ColorSwatch(name: "Burgundy", hex: "800020"),
        ColorSwatch(name: "Charcoal", hex: "36454F"),
        ColorSwatch(name: "Ice Blue", hex: "99BADD"),
        ColorSwatch(name: "Hot Pink", hex: "FF69B4"),
        ColorSwatch(name: "Lemon Yellow", hex: "FFF44F"),
        ColorSwatch(name: "Deep Plum", hex: "5D3954")
    ]

    // MARK: - Clear Winter
    private static let clearWinterPalette = [
        ColorSwatch(name: "Black", hex: "000000"),
        ColorSwatch(name: "White", hex: "FFFFFF"),
        ColorSwatch(name: "True Red", hex: "FF0000"),
        ColorSwatch(name: "Cobalt Blue", hex: "0047AB"),
        ColorSwatch(name: "Bright Pink", hex: "FF007F"),
        ColorSwatch(name: "Electric Blue", hex: "7DF9FF"),
        ColorSwatch(name: "Kelly Green", hex: "4CBB17"),
        ColorSwatch(name: "Purple", hex: "800080"),
        ColorSwatch(name: "Fuchsia", hex: "FF00FF"),
        ColorSwatch(name: "Cyan", hex: "00FFFF"),
        ColorSwatch(name: "Lemon", hex: "FFF700"),
        ColorSwatch(name: "Icy Pink", hex: "FFC0CB"),
        ColorSwatch(name: "Royal Purple", hex: "7851A9"),
        ColorSwatch(name: "Emerald Green", hex: "046307"),
        ColorSwatch(name: "Turquoise", hex: "40E0D0"),
        ColorSwatch(name: "Shocking Pink", hex: "FC0FC0")
    ]

    // MARK: - Cool Winter
    private static let coolWinterPalette = [
        ColorSwatch(name: "Black", hex: "000000"),
        ColorSwatch(name: "White", hex: "FFFFFF"),
        ColorSwatch(name: "Navy Blue", hex: "000080"),
        ColorSwatch(name: "Royal Blue", hex: "4169E1"),
        ColorSwatch(name: "Pine Green", hex: "01796F"),
        ColorSwatch(name: "Burgundy", hex: "800020"),
        ColorSwatch(name: "Plum", hex: "8E4585"),
        ColorSwatch(name: "Raspberry", hex: "E30B5C"),
        ColorSwatch(name: "Icy Blue", hex: "CAE1FF"),
        ColorSwatch(name: "Periwinkle", hex: "CCCCFF"),
        ColorSwatch(name: "Magenta", hex: "CA1F7B"),
        ColorSwatch(name: "Teal", hex: "008080"),
        ColorSwatch(name: "Cool Gray", hex: "8B8589"),
        ColorSwatch(name: "Violet", hex: "8F00FF"),
        ColorSwatch(name: "Cool Pink", hex: "F88379"),
        ColorSwatch(name: "Deep Teal", hex: "003532")
    ]

    // MARK: - Deep Autumn
    private static let deepAutumnPalette = [
        ColorSwatch(name: "Chocolate", hex: "3F2512"),
        ColorSwatch(name: "Deep Rust", hex: "B7410E"),
        ColorSwatch(name: "Forest Green", hex: "014421"),
        ColorSwatch(name: "Burgundy", hex: "800020"),
        ColorSwatch(name: "Deep Teal", hex: "003B46"),
        ColorSwatch(name: "Espresso", hex: "4E2A2A"),
        ColorSwatch(name: "Olive", hex: "556B2F"),
        ColorSwatch(name: "Burnt Orange", hex: "CC5500"),
        ColorSwatch(name: "Deep Gold", hex: "D4AF37"),
        ColorSwatch(name: "Mahogany", hex: "C04000"),
        ColorSwatch(name: "Deep Purple", hex: "4B0082"),
        ColorSwatch(name: "Hunter Green", hex: "355E3B"),
        ColorSwatch(name: "Brick Red", hex: "CB4154"),
        ColorSwatch(name: "Moss", hex: "8A9A5B"),
        ColorSwatch(name: "Dark Teal", hex: "014D4E"),
        ColorSwatch(name: "Bronze", hex: "CD7F32")
    ]

    // MARK: - Warm Autumn
    private static let warmAutumnPalette = [
        ColorSwatch(name: "Rust", hex: "B7410E"),
        ColorSwatch(name: "Golden Yellow", hex: "FFDF00"),
        ColorSwatch(name: "Terracotta", hex: "E2725B"),
        ColorSwatch(name: "Olive Green", hex: "6B8E23"),
        ColorSwatch(name: "Burnt Orange", hex: "CC5500"),
        ColorSwatch(name: "Camel", hex: "C19A6B"),
        ColorSwatch(name: "Warm Brown", hex: "964B00"),
        ColorSwatch(name: "Tomato Red", hex: "FF6347"),
        ColorSwatch(name: "Gold", hex: "FFD700"),
        ColorSwatch(name: "Pumpkin", hex: "FF7518"),
        ColorSwatch(name: "Moss Green", hex: "8A9A5B"),
        ColorSwatch(name: "Copper", hex: "B87333"),
        ColorSwatch(name: "Mustard", hex: "FFDB58"),
        ColorSwatch(name: "Warm Teal", hex: "008080"),
        ColorSwatch(name: "Coral", hex: "FF7F50"),
        ColorSwatch(name: "Bronze", hex: "CD7F32")
    ]

    // MARK: - Soft Autumn
    private static let softAutumnPalette = [
        ColorSwatch(name: "Soft Brown", hex: "A0826D"),
        ColorSwatch(name: "Sage Green", hex: "9CAF88"),
        ColorSwatch(name: "Dusty Rose", hex: "C08081"),
        ColorSwatch(name: "Warm Taupe", hex: "B38B6D"),
        ColorSwatch(name: "Muted Teal", hex: "4C8577"),
        ColorSwatch(name: "Soft Coral", hex: "F08080"),
        ColorSwatch(name: "Khaki", hex: "C3B091"),
        ColorSwatch(name: "Muted Gold", hex: "D9AE5F"),
        ColorSwatch(name: "Olive", hex: "808000"),
        ColorSwatch(name: "Warm Gray", hex: "9A8F83"),
        ColorSwatch(name: "Soft Orange", hex: "E9967A"),
        ColorSwatch(name: "Moss", hex: "8A9A5B"),
        ColorSwatch(name: "Muted Purple", hex: "9F8170"),
        ColorSwatch(name: "Warm Beige", hex: "C9B59A"),
        ColorSwatch(name: "Soft Pink", hex: "E1C6B5"),
        ColorSwatch(name: "Dusty Green", hex: "6C7A5D")
    ]

    // MARK: - Clear Spring
    private static let clearSpringPalette = [
        ColorSwatch(name: "Coral", hex: "FF7F50"),
        ColorSwatch(name: "Bright Yellow", hex: "FFFF00"),
        ColorSwatch(name: "Turquoise", hex: "40E0D0"),
        ColorSwatch(name: "Hot Pink", hex: "FF69B4"),
        ColorSwatch(name: "Apple Green", hex: "8DB600"),
        ColorSwatch(name: "Orange", hex: "FF6600"),
        ColorSwatch(name: "Bright Aqua", hex: "00FFFF"),
        ColorSwatch(name: "Poppy Red", hex: "FF4500"),
        ColorSwatch(name: "Lime", hex: "BFFF00"),
        ColorSwatch(name: "Fuchsia", hex: "FF77FF"),
        ColorSwatch(name: "Warm Blue", hex: "4682B4"),
        ColorSwatch(name: "Golden", hex: "FFD700"),
        ColorSwatch(name: "Bright Purple", hex: "BF00FF"),
        ColorSwatch(name: "Peach", hex: "FFE5B4"),
        ColorSwatch(name: "Electric Blue", hex: "7DF9FF"),
        ColorSwatch(name: "Watermelon", hex: "FC6C85")
    ]

    // MARK: - Warm Spring
    private static let warmSpringPalette = [
        ColorSwatch(name: "Coral", hex: "FF7F50"),
        ColorSwatch(name: "Peach", hex: "FFDAB9"),
        ColorSwatch(name: "Golden Yellow", hex: "FFDF00"),
        ColorSwatch(name: "Warm Aqua", hex: "71D9E2"),
        ColorSwatch(name: "Salmon", hex: "FA8072"),
        ColorSwatch(name: "Bright Orange", hex: "FF8C00"),
        ColorSwatch(name: "Lime Green", hex: "32CD32"),
        ColorSwatch(name: "Warm Pink", hex: "FFB6C1"),
        ColorSwatch(name: "Turquoise", hex: "48D1CC"),
        ColorSwatch(name: "Apricot", hex: "FBCEB1"),
        ColorSwatch(name: "Warm Red", hex: "FF4040"),
        ColorSwatch(name: "Golden Tan", hex: "D2B48C"),
        ColorSwatch(name: "Light Coral", hex: "F08080"),
        ColorSwatch(name: "Bright Teal", hex: "00CED1"),
        ColorSwatch(name: "Cantaloupe", hex: "FFA089"),
        ColorSwatch(name: "Warm Yellow", hex: "FFF68F")
    ]

    // MARK: - Light Spring
    private static let lightSpringPalette = [
        ColorSwatch(name: "Soft Peach", hex: "FFE5B4"),
        ColorSwatch(name: "Light Coral", hex: "F08080"),
        ColorSwatch(name: "Soft Yellow", hex: "FFFACD"),
        ColorSwatch(name: "Light Aqua", hex: "AFEEEE"),
        ColorSwatch(name: "Powder Blue", hex: "B0E0E6"),
        ColorSwatch(name: "Light Pink", hex: "FFB6C1"),
        ColorSwatch(name: "Mint", hex: "98FF98"),
        ColorSwatch(name: "Cream", hex: "FFFDD0"),
        ColorSwatch(name: "Blush", hex: "DE5D83"),
        ColorSwatch(name: "Soft Turquoise", hex: "72D2D6"),
        ColorSwatch(name: "Vanilla", hex: "F3E5AB"),
        ColorSwatch(name: "Soft Orange", hex: "FFD280"),
        ColorSwatch(name: "Light Lime", hex: "E3F988"),
        ColorSwatch(name: "Baby Blue", hex: "89CFF0"),
        ColorSwatch(name: "Light Lavender", hex: "E6E6FA"),
        ColorSwatch(name: "Soft Gold", hex: "F1E5AC")
    ]

    // MARK: - Cool Summer
    private static let coolSummerPalette = [
        ColorSwatch(name: "Soft Navy", hex: "40466E"),
        ColorSwatch(name: "Cool Rose", hex: "C08081"),
        ColorSwatch(name: "Periwinkle", hex: "CCCCFF"),
        ColorSwatch(name: "Slate Blue", hex: "6A5ACD"),
        ColorSwatch(name: "Cool Pink", hex: "F88379"),
        ColorSwatch(name: "Lavender", hex: "E6E6FA"),
        ColorSwatch(name: "Cool Gray", hex: "8B8589"),
        ColorSwatch(name: "Soft Purple", hex: "DDA0DD"),
        ColorSwatch(name: "Dusty Blue", hex: "6B8E98"),
        ColorSwatch(name: "Mauve", hex: "E0B0FF"),
        ColorSwatch(name: "Cool Teal", hex: "5F8A8B"),
        ColorSwatch(name: "Soft Pink", hex: "FFB6C1"),
        ColorSwatch(name: "Cool Raspberry", hex: "E30B5C"),
        ColorSwatch(name: "Steel Blue", hex: "4682B4"),
        ColorSwatch(name: "Soft Violet", hex: "8A84E2"),
        ColorSwatch(name: "Powder Blue", hex: "B0E0E6")
    ]

    // MARK: - Soft Summer
    private static let softSummerPalette = [
        ColorSwatch(name: "Dusty Rose", hex: "DCAE96"),
        ColorSwatch(name: "Soft Blue", hex: "A4C8E1"),
        ColorSwatch(name: "Mauve", hex: "E0B0FF"),
        ColorSwatch(name: "Dusty Purple", hex: "8E4585"),
        ColorSwatch(name: "Soft Teal", hex: "5F8A8B"),
        ColorSwatch(name: "Soft Pink", hex: "D8BFD8"),
        ColorSwatch(name: "Lavender", hex: "B19CD9"),
        ColorSwatch(name: "Pewter", hex: "899499"),
        ColorSwatch(name: "Dusty Blue", hex: "6E8088"),
        ColorSwatch(name: "Soft Green", hex: "8A9A5B"),
        ColorSwatch(name: "Rose Brown", hex: "BC8F8F"),
        ColorSwatch(name: "Cool Taupe", hex: "8B8589"),
        ColorSwatch(name: "Plum", hex: "DDA0DD"),
        ColorSwatch(name: "Soft Raspberry", hex: "E25098"),
        ColorSwatch(name: "Dusty Lavender", hex: "AC9AC9"),
        ColorSwatch(name: "Cool Beige", hex: "C9ADA7")
    ]

    // MARK: - Light Summer
    private static let lightSummerPalette = [
        ColorSwatch(name: "Soft Pink", hex: "FFB6C1"),
        ColorSwatch(name: "Baby Blue", hex: "89CFF0"),
        ColorSwatch(name: "Lavender", hex: "E6E6FA"),
        ColorSwatch(name: "Soft Mint", hex: "AAF0D1"),
        ColorSwatch(name: "Powder Blue", hex: "B0E0E6"),
        ColorSwatch(name: "Light Mauve", hex: "E0B0FF"),
        ColorSwatch(name: "Soft Yellow", hex: "FFFACD"),
        ColorSwatch(name: "Periwinkle", hex: "CCCCFF"),
        ColorSwatch(name: "Light Teal", hex: "A0D6B4"),
        ColorSwatch(name: "Soft Lilac", hex: "C8A2C8"),
        ColorSwatch(name: "Blush Pink", hex: "FFE4E1"),
        ColorSwatch(name: "Sky Blue", hex: "87CEEB"),
        ColorSwatch(name: "Soft Peach", hex: "FFE5B4"),
        ColorSwatch(name: "Light Lavender", hex: "DCD0FF"),
        ColorSwatch(name: "Mint Cream", hex: "F5FFFA"),
        ColorSwatch(name: "Soft Coral", hex: "FFB6B9")
    ]
}
