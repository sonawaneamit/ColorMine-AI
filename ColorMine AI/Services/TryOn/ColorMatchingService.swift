//
//  ColorMatchingService.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import UIKit
import SwiftUI

/// On-device color matching service for garments
/// Analyzes garment colors and matches against user's season palette
class ColorMatchingService {
    static let shared = ColorMatchingService()

    private init() {}

    // MARK: - Analyze Garment
    /// Analyze a garment image and calculate color match with user's palette
    func analyzeGarment(
        _ garmentImage: UIImage,
        userSeason: ColorSeason?,
        userPalette: [ColorSwatch]
    ) -> (dominantColorHex: String, matchScore: Int, matchesSeason: Bool) {

        // Extract dominant color from garment
        let dominantColor = extractDominantColor(from: garmentImage)
        let dominantHex = dominantColor.toHex()

        // If no user season data, return neutral score
        guard let season = userSeason, !userPalette.isEmpty else {
            return (dominantHex, 50, false)
        }

        // Calculate match score against user's palette
        let matchScore = calculateMatchScore(
            garmentColor: dominantColor,
            palette: userPalette
        )

        let matchesSeason = matchScore >= 70

        return (dominantHex, matchScore, matchesSeason)
    }

    // MARK: - Extract Dominant Color
    /// Extract the dominant color from an image using color quantization
    private func extractDominantColor(from image: UIImage) -> UIColor {
        guard let cgImage = image.cgImage else {
            return UIColor.gray
        }

        // Resize image for faster processing
        let size = CGSize(width: 150, height: 150)
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(origin: .zero, size: size))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        guard let inputCGImage = resizedImage?.cgImage else {
            return UIColor.gray
        }

        // Get pixel data
        let width = inputCGImage.width
        let height = inputCGImage.height
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)

        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return UIColor.gray
        }

        context.draw(inputCGImage, in: CGRect(x: 0, y: 0, width: width, height: height))

        // Count color frequencies (simplified k-means approach)
        var colorCounts: [UIColor: Int] = [:]

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * width + x) * bytesPerPixel
                let r = CGFloat(pixelData[offset]) / 255.0
                let g = CGFloat(pixelData[offset + 1]) / 255.0
                let b = CGFloat(pixelData[offset + 2]) / 255.0

                // Skip very light or very dark pixels (likely background)
                let brightness = (r + g + b) / 3.0
                if brightness > 0.95 || brightness < 0.05 {
                    continue
                }

                // Quantize color to reduce variations
                let quantizedColor = quantizeColor(r: r, g: g, b: b)
                colorCounts[quantizedColor, default: 0] += 1
            }
        }

        // Find most frequent color
        guard let dominantColor = colorCounts.max(by: { $0.value < $1.value })?.key else {
            return UIColor.gray
        }

        return dominantColor
    }

    // MARK: - Quantize Color
    /// Reduce color precision to group similar colors
    private func quantizeColor(r: CGFloat, g: CGFloat, b: CGFloat) -> UIColor {
        let levels: CGFloat = 8.0 // Reduce to 8 levels per channel
        let quantize: (CGFloat) -> CGFloat = { value in
            round(value * levels) / levels
        }

        return UIColor(
            red: quantize(r),
            green: quantize(g),
            blue: quantize(b),
            alpha: 1.0
        )
    }

    // MARK: - Calculate Match Score
    /// Calculate how well a color matches the user's palette (0-100)
    private func calculateMatchScore(
        garmentColor: UIColor,
        palette: [ColorSwatch]
    ) -> Int {

        guard !palette.isEmpty else { return 50 }

        // Convert garment color to HSL
        let garmentHSL = garmentColor.toHSL()

        // Find closest color in palette
        var bestMatchScore: Double = 0.0

        for swatch in palette {
            let paletteColor = UIColor(swatch.color)
            let paletteHSL = paletteColor.toHSL()

            // Calculate color distance in HSL space
            let hueDistance = min(
                abs(garmentHSL.h - paletteHSL.h),
                360.0 - abs(garmentHSL.h - paletteHSL.h)
            ) / 360.0

            let satDistance = abs(garmentHSL.s - paletteHSL.s)
            let lightDistance = abs(garmentHSL.l - paletteHSL.l)

            // Weighted distance (hue matters most for color matching)
            let distance = (hueDistance * 0.6) + (satDistance * 0.2) + (lightDistance * 0.2)
            let similarity = 1.0 - distance

            bestMatchScore = max(bestMatchScore, similarity)
        }

        // Convert to 0-100 scale
        return Int(bestMatchScore * 100)
    }
}

// MARK: - UIColor Extensions
extension UIColor {
    /// Convert UIColor to hex string
    func toHex() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        let rgb = Int(r * 255) << 16 | Int(g * 255) << 8 | Int(b * 255)
        return String(format: "#%06x", rgb)
    }

    /// Convert UIColor to HSL (Hue, Saturation, Lightness)
    func toHSL() -> (h: Double, s: Double, l: Double) {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        let max = max(r, g, b)
        let min = min(r, g, b)
        let delta = max - min

        // Lightness
        let l = (max + min) / 2.0

        // Saturation
        var s: CGFloat = 0
        if delta != 0 {
            s = l < 0.5 ? delta / (max + min) : delta / (2.0 - max - min)
        }

        // Hue
        var h: CGFloat = 0
        if delta != 0 {
            if max == r {
                h = ((g - b) / delta).truncatingRemainder(dividingBy: 6)
            } else if max == g {
                h = ((b - r) / delta) + 2
            } else {
                h = ((r - g) / delta) + 4
            }
            h *= 60
            if h < 0 {
                h += 360
            }
        }

        return (Double(h), Double(s), Double(l))
    }
}
