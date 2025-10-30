//
//  ColorAnalyzer.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import Foundation
import UIKit
import Vision

class ColorAnalyzer {
    static let shared = ColorAnalyzer()

    private init() {}

    // MARK: - Main Analysis
    func analyzeSkinTone(from image: UIImage, faceObservation: VNFaceObservation) -> (
        season: ColorSeason,
        undertone: Undertone,
        contrast: Contrast,
        confidence: Double
    ) {
        print("🎨 Starting color analysis...")

        guard let cgImage = image.cgImage else {
            print("❌ ERROR: cgImage is nil, returning default softAutumn")
            return (.softAutumn, .neutral, .medium, 0.5)
        }

        print("✅ cgImage loaded successfully")

        // Sample RGB from face
        let rgb = sampleSkinTone(from: cgImage, faceObservation: faceObservation)
        print("📊 Sampled RGB: R=\(String(format: "%.3f", rgb.r)), G=\(String(format: "%.3f", rgb.g)), B=\(String(format: "%.3f", rgb.b))")

        // Calculate undertone
        let undertone = calculateUndertone(rgb: rgb)
        print("🌡️ Calculated undertone: \(undertone.rawValue)")

        // Calculate depth
        let depth = calculateDepth(rgb: rgb)
        print("💡 Calculated depth: \(depth)")

        // Calculate contrast
        let contrast = calculateContrast(from: image, faceObservation: faceObservation)
        print("⚖️ Calculated contrast: \(contrast.rawValue)")

        // Match season
        let season = matchSeason(undertone: undertone, depth: depth, contrast: contrast)
        print("🍂 Matched season: \(season.rawValue)")

        // Calculate confidence
        let confidence = calculateConfidence(image: image, rgb: rgb)
        print("✨ Confidence: \(String(format: "%.1f", confidence * 100))%")

        return (season, undertone, contrast, confidence)
    }

    // MARK: - RGB Sampling
    private func sampleSkinTone(from cgImage: CGImage, faceObservation: VNFaceObservation) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let boundingBox = faceObservation.boundingBox

        // Sample from forehead area
        let foreheadX = (boundingBox.origin.x + boundingBox.width / 2) * imageSize.width
        let foreheadY = (1 - boundingBox.origin.y - boundingBox.height * 0.85) * imageSize.height

        let samplePoints = [
            CGPoint(x: foreheadX, y: foreheadY),
            CGPoint(x: foreheadX - 20, y: foreheadY),
            CGPoint(x: foreheadX + 20, y: foreheadY),
            CGPoint(x: foreheadX, y: foreheadY + 10)
        ]

        var totalR: CGFloat = 0
        var totalG: CGFloat = 0
        var totalB: CGFloat = 0
        var validSamples = 0

        for point in samplePoints {
            if let color = getPixelColor(at: point, in: cgImage) {
                totalR += color.r
                totalG += color.g
                totalB += color.b
                validSamples += 1
            }
        }

        guard validSamples > 0 else {
            return (0.5, 0.5, 0.5)
        }

        return (
            r: totalR / CGFloat(validSamples),
            g: totalG / CGFloat(validSamples),
            b: totalB / CGFloat(validSamples)
        )
    }

    private func getPixelColor(at point: CGPoint, in cgImage: CGImage) -> (r: CGFloat, g: CGFloat, b: CGFloat)? {
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let pixels = CFDataGetBytePtr(data) else {
            return nil
        }

        let x = Int(point.x)
        let y = Int(point.y)

        guard x >= 0 && x < cgImage.width && y >= 0 && y < cgImage.height else {
            return nil
        }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        let pixelIndex = (y * bytesPerRow) + (x * bytesPerPixel)

        let r = CGFloat(pixels[pixelIndex]) / 255.0
        let g = CGFloat(pixels[pixelIndex + 1]) / 255.0
        let b = CGFloat(pixels[pixelIndex + 2]) / 255.0

        return (r, g, b)
    }

    // MARK: - Undertone Calculation
    private func calculateUndertone(rgb: (r: CGFloat, g: CGFloat, b: CGFloat)) -> Undertone {
        let redGreenRatio = rgb.r / max(rgb.g, 0.01)
        let blueRedRatio = rgb.b / max(rgb.r, 0.01)

        if blueRedRatio > 0.95 {
            return .cool
        } else if blueRedRatio > 0.85 {
            return .coolNeutral
        } else if redGreenRatio > 1.15 && rgb.b < 0.5 {
            return .warm
        } else if redGreenRatio > 1.05 {
            return .warmNeutral
        } else {
            return .neutral
        }
    }

    // MARK: - Depth Calculation
    private func calculateDepth(rgb: (r: CGFloat, g: CGFloat, b: CGFloat)) -> String {
        let luminance = 0.299 * rgb.r + 0.587 * rgb.g + 0.114 * rgb.b

        if luminance > 0.6 {
            return "light"
        } else if luminance > 0.35 {
            return "medium"
        } else {
            return "deep"
        }
    }

    // MARK: - Contrast Calculation
    private func calculateContrast(from image: UIImage, faceObservation: VNFaceObservation) -> Contrast {
        guard let faceImage = VisionService.shared.extractFaceRegion(from: image, faceObservation: faceObservation),
              let cgImage = faceImage.cgImage else {
            return .medium
        }

        let variance = calculateColorVariance(in: cgImage)

        if variance > 0.15 {
            return .high
        } else if variance > 0.08 {
            return .medium
        } else {
            return .low
        }
    }

    private func calculateColorVariance(in cgImage: CGImage) -> CGFloat {
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let pixels = CFDataGetBytePtr(data) else {
            return 0
        }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        let sampleSize = min(100, cgImage.width * cgImage.height)

        var values: [CGFloat] = []

        for _ in 0..<sampleSize {
            let x = Int.random(in: 0..<cgImage.width)
            let y = Int.random(in: 0..<cgImage.height)
            let pixelIndex = (y * bytesPerRow) + (x * bytesPerPixel)

            let r = CGFloat(pixels[pixelIndex]) / 255.0
            let g = CGFloat(pixels[pixelIndex + 1]) / 255.0
            let b = CGFloat(pixels[pixelIndex + 2]) / 255.0

            let luminance = 0.299 * r + 0.587 * g + 0.114 * b
            values.append(luminance)
        }

        let mean = values.reduce(0, +) / CGFloat(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / CGFloat(values.count)

        return variance
    }

    // MARK: - Season Matching
    private func matchSeason(undertone: Undertone, depth: String, contrast: Contrast) -> ColorSeason {
        print("🔍 Matching season with: undertone=\(undertone.rawValue), depth=\(depth), contrast=\(contrast.rawValue)")

        switch (undertone, depth, contrast) {
        // Winters: Cool undertone, high contrast
        case (.cool, "deep", .high):
            return .deepWinter
        case (.cool, "medium", .high), (.cool, "light", .high):
            return .clearWinter
        case (.cool, _, .medium), (.cool, _, .low), (.coolNeutral, _, _):
            return .coolWinter

        // Autumns: Warm undertone, rich colors
        case (.warm, "deep", .high):
            return .deepAutumn
        case (.warm, "medium", .medium), (.warm, "medium", .high), (.warmNeutral, "medium", _):
            return .warmAutumn
        case (.warm, _, .low), (.warmNeutral, _, .low):
            return .softAutumn

        // Springs: Warm undertone, lighter
        case (.warm, "light", .high):
            return .clearSpring
        case (.warm, "light", .medium), (.warmNeutral, "light", .medium):
            return .warmSpring
        case (.neutral, "light", .low):
            return .lightSpring

        // Summers: Cool undertone, softer
        case (.cool, "medium", .medium):
            return .coolSummer
        case (.cool, _, .low), (.neutral, _, .low):
            return .softSummer
        case (.cool, "light", _):
            return .lightSummer

        default:
            print("⚠️ WARNING: No season match found! Using default softAutumn. This indicates a logic gap in matchSeason.")
            return .softAutumn
        }
    }

    // MARK: - Confidence Calculation
    private func calculateConfidence(image: UIImage, rgb: (r: CGFloat, g: CGFloat, b: CGFloat)) -> Double {
        let lightingScore = assessLightingQuality(image: image)
        let toneScore = assessToneConsistency(rgb: rgb)

        let confidence = (lightingScore * 0.6) + (toneScore * 0.4)
        return min(max(confidence, 0.5), 0.98)  // Between 50% and 98%
    }

    private func assessLightingQuality(image: UIImage) -> Double {
        guard let cgImage = image.cgImage else { return 0.7 }

        let brightness = calculateAverageBrightness(cgImage)

        if brightness >= 0.4 && brightness <= 0.7 {
            return 0.95
        } else if brightness >= 0.3 && brightness <= 0.8 {
            return 0.85
        } else {
            return 0.70
        }
    }

    private func calculateAverageBrightness(_ cgImage: CGImage) -> CGFloat {
        guard let dataProvider = cgImage.dataProvider,
              let data = dataProvider.data,
              let pixels = CFDataGetBytePtr(data) else {
            return 0.5
        }

        let bytesPerPixel = cgImage.bitsPerPixel / 8
        let bytesPerRow = cgImage.bytesPerRow
        let sampleSize = min(1000, cgImage.width * cgImage.height)

        var totalBrightness: CGFloat = 0

        for _ in 0..<sampleSize {
            let x = Int.random(in: 0..<cgImage.width)
            let y = Int.random(in: 0..<cgImage.height)
            let pixelIndex = (y * bytesPerRow) + (x * bytesPerPixel)

            let r = CGFloat(pixels[pixelIndex]) / 255.0
            let g = CGFloat(pixels[pixelIndex + 1]) / 255.0
            let b = CGFloat(pixels[pixelIndex + 2]) / 255.0

            let brightness = (r + g + b) / 3.0
            totalBrightness += brightness
        }

        return totalBrightness / CGFloat(sampleSize)
    }

    private func assessToneConsistency(rgb: (r: CGFloat, g: CGFloat, b: CGFloat)) -> Double {
        let maxComponent = max(rgb.r, rgb.g, rgb.b)
        let minComponent = min(rgb.r, rgb.g, rgb.b)
        let difference = maxComponent - minComponent

        if difference < 0.15 {
            return 0.95
        } else if difference < 0.3 {
            return 0.85
        } else {
            return 0.70
        }
    }
}
