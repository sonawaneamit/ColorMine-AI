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

        // Sample RGB from face (skin, sclera, lips)
        let rgb = sampleSkinTone(from: cgImage, faceObservation: faceObservation)
        print("📊 Sampled RGB: R=\(String(format: "%.3f", rgb.r)), G=\(String(format: "%.3f", rgb.g)), B=\(String(format: "%.3f", rgb.b))")

        // Convert to LAB for accurate analysis
        let lab = rgbToLab(r: rgb.r, g: rgb.g, b: rgb.b)

        // Calculate chroma (saturation/clarity)
        let skinChroma = calculateChroma(lab: lab)
        print("🎨 Skin chroma: \(String(format: "%.2f", skinChroma))")

        // Calculate depth (using L*)
        let depth = calculateDepth(rgb: rgb)
        print("💡 Calculated depth: \(depth)")

        // Calculate undertone (depth-adjusted)
        let undertone = calculateUndertone(rgb: rgb, depth: depth)
        print("🌡️ Calculated undertone: \(undertone.rawValue)")

        // Calculate contrast
        let contrast = calculateContrast(from: image, faceObservation: faceObservation)
        print("⚖️ Calculated contrast: \(contrast.rawValue)")

        // Calculate relative contrast (skin to features)
        let relativeContrast = calculateRelativeContrast(from: cgImage, faceObservation: faceObservation, skinRGB: rgb)
        print("👁️ Relative contrast: \(String(format: "%.3f", relativeContrast))")

        // Match season with chroma gates
        let season = matchSeasonWithChroma(
            undertone: undertone,
            depth: depth,
            contrast: contrast,
            skinChroma: skinChroma,
            relativeContrast: relativeContrast
        )
        print("🍂 Matched season: \(season.rawValue)")

        // Calculate confidence
        let confidence = calculateConfidence(image: image, rgb: rgb)
        print("✨ Confidence: \(String(format: "%.1f", confidence * 100))%")

        return (season, undertone, contrast, confidence)
    }

    // MARK: - Enhanced Multi-Region Sampling
    private func sampleSkinTone(from cgImage: CGImage, faceObservation: VNFaceObservation) -> (r: CGFloat, g: CGFloat, b: CGFloat) {
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let boundingBox = faceObservation.boundingBox

        var allSamples: [(r: CGFloat, g: CGFloat, b: CGFloat)] = []

        // Region 1: Forehead (9 points) - weight: 1.0
        let foreheadPoints = sampleForehead(boundingBox: boundingBox, imageSize: imageSize)
        for point in foreheadPoints {
            if let color = getPixelColor(at: point, in: cgImage) {
                allSamples.append(color)
            }
        }

        // Region 2: Cheeks (6 points, 3 per side) - weight: 0.8
        let cheekPoints = sampleCheeks(boundingBox: boundingBox, imageSize: imageSize)
        for point in cheekPoints {
            if let color = getPixelColor(at: point, in: cgImage) {
                // Add with 80% weight
                allSamples.append(color)
            }
        }

        // Region 3: Neck area (6 points) - weight: 1.2 (most accurate)
        let neckPoints = sampleNeck(boundingBox: boundingBox, imageSize: imageSize)
        for point in neckPoints {
            if let color = getPixelColor(at: point, in: cgImage) {
                // Add with 120% weight (add twice with 60% each)
                allSamples.append(color)
                allSamples.append((r: color.r * 0.2, g: color.g * 0.2, b: color.b * 0.2))
            }
        }

        guard !allSamples.isEmpty else {
            return (0.5, 0.5, 0.5)
        }

        // Calculate weighted average
        let totalR = allSamples.reduce(0) { $0 + $1.r }
        let totalG = allSamples.reduce(0) { $0 + $1.g }
        let totalB = allSamples.reduce(0) { $0 + $1.b }
        let count = CGFloat(allSamples.count)

        return (r: totalR / count, g: totalG / count, b: totalB / count)
    }

    // Sample 9 points across forehead
    private func sampleForehead(boundingBox: CGRect, imageSize: CGSize) -> [CGPoint] {
        let centerX = (boundingBox.origin.x + boundingBox.width / 2) * imageSize.width
        let centerY = (1 - boundingBox.origin.y - boundingBox.height * 0.85) * imageSize.height

        return [
            // Top row
            CGPoint(x: centerX - 30, y: centerY - 10),
            CGPoint(x: centerX, y: centerY - 10),
            CGPoint(x: centerX + 30, y: centerY - 10),
            // Middle row
            CGPoint(x: centerX - 30, y: centerY),
            CGPoint(x: centerX, y: centerY),
            CGPoint(x: centerX + 30, y: centerY),
            // Bottom row
            CGPoint(x: centerX - 30, y: centerY + 10),
            CGPoint(x: centerX, y: centerY + 10),
            CGPoint(x: centerX + 30, y: centerY + 10)
        ]
    }

    // Sample 6 points on cheeks (3 per side)
    private func sampleCheeks(boundingBox: CGRect, imageSize: CGSize) -> [CGPoint] {
        let centerY = (1 - boundingBox.origin.y - boundingBox.height * 0.5) * imageSize.height
        let leftX = (boundingBox.origin.x + boundingBox.width * 0.25) * imageSize.width
        let rightX = (boundingBox.origin.x + boundingBox.width * 0.75) * imageSize.width

        return [
            // Left cheek
            CGPoint(x: leftX, y: centerY - 15),
            CGPoint(x: leftX, y: centerY),
            CGPoint(x: leftX, y: centerY + 15),
            // Right cheek
            CGPoint(x: rightX, y: centerY - 15),
            CGPoint(x: rightX, y: centerY),
            CGPoint(x: rightX, y: centerY + 15)
        ]
    }

    // Sample 6 points on neck (most accurate region)
    private func sampleNeck(boundingBox: CGRect, imageSize: CGSize) -> [CGPoint] {
        let centerX = (boundingBox.origin.x + boundingBox.width / 2) * imageSize.width
        let neckY = (1 - boundingBox.origin.y + boundingBox.height * 0.1) * imageSize.height

        return [
            // Top neck row
            CGPoint(x: centerX - 20, y: neckY),
            CGPoint(x: centerX, y: neckY),
            CGPoint(x: centerX + 20, y: neckY),
            // Lower neck row
            CGPoint(x: centerX - 20, y: neckY + 15),
            CGPoint(x: centerX, y: neckY + 15),
            CGPoint(x: centerX + 20, y: neckY + 15)
        ]
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

    // MARK: - LAB Color Space Conversion
    // Convert RGB to LAB color space for perceptually uniform analysis
    private func rgbToLab(r: CGFloat, g: CGFloat, b: CGFloat) -> (L: CGFloat, a: CGFloat, b: CGFloat) {
        // Step 1: RGB to XYZ
        var rLinear = r
        var gLinear = g
        var bLinear = b

        // Apply gamma correction (sRGB to linear)
        rLinear = (rLinear > 0.04045) ? pow((rLinear + 0.055) / 1.055, 2.4) : rLinear / 12.92
        gLinear = (gLinear > 0.04045) ? pow((gLinear + 0.055) / 1.055, 2.4) : gLinear / 12.92
        bLinear = (bLinear > 0.04045) ? pow((bLinear + 0.055) / 1.055, 2.4) : bLinear / 12.92

        // Convert to XYZ using D65 illuminant
        let x = rLinear * 0.4124564 + gLinear * 0.3575761 + bLinear * 0.1804375
        let y = rLinear * 0.2126729 + gLinear * 0.7151522 + bLinear * 0.0721750
        let z = rLinear * 0.0193339 + gLinear * 0.1191920 + bLinear * 0.9503041

        // Step 2: XYZ to LAB
        // Reference white point D65
        let xn: CGFloat = 0.95047
        let yn: CGFloat = 1.00000
        let zn: CGFloat = 1.08883

        var fx = x / xn
        var fy = y / yn
        var fz = z / zn

        // Apply LAB transformation function
        let delta: CGFloat = 6.0 / 29.0
        let deltaSquared = delta * delta
        let deltaCubed = delta * delta * delta

        fx = (fx > deltaCubed) ? pow(fx, 1.0/3.0) : (fx / (3 * deltaSquared) + 4.0/29.0)
        fy = (fy > deltaCubed) ? pow(fy, 1.0/3.0) : (fy / (3 * deltaSquared) + 4.0/29.0)
        fz = (fz > deltaCubed) ? pow(fz, 1.0/3.0) : (fz / (3 * deltaSquared) + 4.0/29.0)

        // Calculate LAB values
        let L = 116 * fy - 16  // Lightness (0-100)
        let a = 500 * (fx - fy)  // Green (-) to Red (+)
        let bValue = 200 * (fy - fz)  // Blue (-) to Yellow (+)

        return (L: L, a: a, b: bValue)
    }

    // MARK: - Chroma Calculation
    // Chroma = saturation/clarity of the skin color
    private func calculateChroma(lab: (L: CGFloat, a: CGFloat, b: CGFloat)) -> CGFloat {
        // Chroma in LAB = sqrt(a² + b²)
        // Higher chroma = more vivid/saturated colors
        // Lower chroma = more muted/grayed colors
        let chroma = sqrt(lab.a * lab.a + lab.b * lab.b)
        return chroma
    }

    // MARK: - Undertone Calculation (LAB-based, Depth-Adjusted)
    private func calculateUndertone(rgb: (r: CGFloat, g: CGFloat, b: CGFloat), depth: String) -> Undertone {
        // Convert to LAB for accurate undertone detection
        let lab = rgbToLab(r: rgb.r, g: rgb.g, b: rgb.b)

        // In LAB color space:
        // b* axis: negative = blue (cool), positive = yellow (warm)
        // a* axis: negative = green (cool), positive = red (warm)

        let bStar = lab.b  // Blue to Yellow
        let aStar = lab.a  // Green to Red

        // Calculate combined undertone score
        // Higher score = warmer, lower score = cooler
        let undertoneScore = bStar + (aStar * 0.3)  // b* is more important for undertone

        print("🔬 LAB values: L*=\(String(format: "%.2f", lab.L)), a*=\(String(format: "%.2f", aStar)), b*=\(String(format: "%.2f", bStar)), score=\(String(format: "%.2f", undertoneScore))")

        // DEPTH-ADJUSTED THRESHOLDS
        // Deeper skin often reads warmer due to camera lifting b* values
        // We shrink the warm window for deep skin to compensate

        switch depth {
        case "deep":
            // Narrower thresholds for deep skin
            if undertoneScore < 0 {
                return .cool
            } else if undertoneScore < 3 {
                return .coolNeutral
            } else if undertoneScore > 9 {
                return .warm
            } else if undertoneScore > 6 {
                return .warmNeutral
            } else {
                return .neutral
            }

        case "medium":
            // Balanced thresholds for medium skin
            if undertoneScore < -1 {
                return .cool
            } else if undertoneScore < 2 {
                return .coolNeutral
            } else if undertoneScore > 8 {
                return .warm
            } else if undertoneScore > 5 {
                return .warmNeutral
            } else {
                return .neutral
            }

        case "light":
            // Original thresholds work well for light skin
            if undertoneScore < -3 {
                return .cool
            } else if undertoneScore < 1 {
                return .coolNeutral
            } else if undertoneScore > 8 {
                return .warm
            } else if undertoneScore > 4 {
                return .warmNeutral
            } else {
                return .neutral
            }

        default:
            // Fallback to medium thresholds
            if undertoneScore < -1 {
                return .cool
            } else if undertoneScore < 2 {
                return .coolNeutral
            } else if undertoneScore > 8 {
                return .warm
            } else if undertoneScore > 5 {
                return .warmNeutral
            } else {
                return .neutral
            }
        }
    }

    // MARK: - Depth Calculation (LAB-based)
    private func calculateDepth(rgb: (r: CGFloat, g: CGFloat, b: CGFloat)) -> String {
        // Use L* from LAB color space for perceptually accurate lightness
        let lab = rgbToLab(r: rgb.r, g: rgb.g, b: rgb.b)
        let L = lab.L  // Lightness value (0-100)

        print("💡 Depth L*=\(String(format: "%.2f", L))")

        // Calibrated thresholds for all skin tones
        // Light: Fair to light skin (Fitzpatrick I-II)
        // Medium: Medium skin (Fitzpatrick III-IV)
        // Deep: Deep skin (Fitzpatrick V-VI)

        if L > 65 {
            return "light"
        } else if L > 45 {
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

    // MARK: - Relative Contrast Calculation
    // Compare skin to eye whites (sclera) and lips for feature clarity
    private func calculateRelativeContrast(from cgImage: CGImage, faceObservation: VNFaceObservation, skinRGB: (r: CGFloat, g: CGFloat, b: CGFloat)) -> CGFloat {
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let boundingBox = faceObservation.boundingBox

        // Sample sclera (eye whites) - left eye
        let scleraX = (boundingBox.origin.x + boundingBox.width * 0.3) * imageSize.width
        let scleraY = (1 - boundingBox.origin.y - boundingBox.height * 0.6) * imageSize.height

        var scleraColor: (r: CGFloat, g: CGFloat, b: CGFloat)? = nil
        for xOffset in [-5, 0, 5] {
            for yOffset in [-5, 0, 5] {
                let point = CGPoint(x: scleraX + CGFloat(xOffset), y: scleraY + CGFloat(yOffset))
                if let color = getPixelColor(at: point, in: cgImage) {
                    scleraColor = color
                    break
                }
            }
            if scleraColor != nil { break }
        }

        // Sample lips - lower lip center
        let lipX = (boundingBox.origin.x + boundingBox.width * 0.5) * imageSize.width
        let lipY = (1 - boundingBox.origin.y - boundingBox.height * 0.15) * imageSize.height

        var lipColor: (r: CGFloat, g: CGFloat, b: CGFloat)? = nil
        for xOffset in [-5, 0, 5] {
            for yOffset in [-5, 0, 5] {
                let point = CGPoint(x: lipX + CGFloat(xOffset), y: lipY + CGFloat(yOffset))
                if let color = getPixelColor(at: point, in: cgImage) {
                    lipColor = color
                    break
                }
            }
            if lipColor != nil { break }
        }

        // Calculate luminance differences
        let skinLum = 0.299 * skinRGB.r + 0.587 * skinRGB.g + 0.114 * skinRGB.b

        var totalDiff: CGFloat = 0
        var samples = 0

        if let sclera = scleraColor {
            let scleraLum = 0.299 * sclera.r + 0.587 * sclera.g + 0.114 * sclera.b
            totalDiff += abs(skinLum - scleraLum)
            samples += 1
        }

        if let lip = lipColor {
            let lipLum = 0.299 * lip.r + 0.587 * lip.g + 0.114 * lip.b
            totalDiff += abs(skinLum - lipLum)
            samples += 1
        }

        return samples > 0 ? totalDiff / CGFloat(samples) : 0
    }

    // MARK: - Season Matching with Chroma Gates (Fixed Autumn Bias)
    private func matchSeasonWithChroma(
        undertone: Undertone,
        depth: String,
        contrast: Contrast,
        skinChroma: CGFloat,
        relativeContrast: CGFloat
    ) -> ColorSeason {
        print("🔍 Matching with: undertone=\(undertone.rawValue), depth=\(depth), contrast=\(contrast.rawValue), chroma=\(String(format: "%.1f", skinChroma)), relContrast=\(String(format: "%.2f", relativeContrast))")

        // CHROMA THRESHOLDS - THE KEY TO FIXING AUTUMN BIAS
        // High chroma (>18) = clear, vivid colors → Spring/Winter
        // Medium chroma (12-18) = moderate saturation → transitional
        // Low chroma (<12) = muted, soft → Autumn/Summer

        // ===== PRIORITY 1: WARM/WARM-NEUTRAL - SPLIT BY CHROMA =====
        if undertone == .warm || undertone == .warmNeutral {
            print("🔥 Warm undertone detected - checking chroma gate")

            // HIGH CLARITY WARM → SPRING (not Autumn!)
            if skinChroma > 18 {
                print("✨ High chroma (>18) - routing to Spring")
                if depth == "light" {
                    return contrast == .high ? .clearSpring : .warmSpring
                } else if depth == "medium" {
                    return (contrast == .high || contrast == .medium) ? .warmSpring : .warmAutumn
                } else {
                    // Deep + warm + clear
                    return contrast == .high ? .deepAutumn : .warmAutumn
                }
            }

            // MEDIUM CLARITY WARM → Check contrast
            if skinChroma > 12 {
                print("💫 Medium chroma (12-18) - contrast decides")
                if depth == "light" {
                    return contrast == .low ? .lightSpring : .warmSpring
                } else if depth == "medium" {
                    // Medium depth warm - use relative contrast
                    if relativeContrast > 0.12 || contrast == .high {
                        return .warmSpring  // Clearer features → Spring
                    } else {
                        return .warmAutumn  // Softer features → Autumn
                    }
                } else {
                    return contrast == .high ? .deepAutumn : .warmAutumn
                }
            }

            // LOW CLARITY WARM → AUTUMN
            print("🍂 Low chroma (<12) - routing to Autumn")
            if depth == "deep" {
                return contrast == .low ? .warmAutumn : .deepAutumn
            } else if depth == "medium" {
                return .softAutumn
            } else {
                return contrast == .low ? .lightSpring : .warmSpring
            }
        }

        // ===== PRIORITY 2: COOL UNDERTONES =====
        if undertone == .cool {
            if depth == "deep" {
                return (contrast == .high || contrast == .medium) ? .deepWinter : .coolWinter
            } else if depth == "medium" {
                return contrast == .high ? .clearWinter : (contrast == .medium ? .coolSummer : .softSummer)
            } else {
                return contrast == .high ? .clearWinter : (contrast == .medium ? .lightSummer : .softSummer)
            }
        }

        // ===== PRIORITY 3: COOL NEUTRAL =====
        if undertone == .coolNeutral {
            if depth == "deep" {
                return contrast == .high ? .deepWinter : .coolWinter
            } else if depth == "medium" {
                return contrast == .high ? .clearWinter : (contrast == .medium ? .coolSummer : .softSummer)
            } else {
                return contrast == .high ? .clearWinter : (contrast == .medium ? .lightSummer : .lightSpring)
            }
        }

        // ===== PRIORITY 4: NEUTRAL =====
        // Use relative contrast to decide cool vs warm direction
        if undertone == .neutral {
            if depth == "deep" {
                return contrast == .high ? .deepAutumn : .softAutumn
            } else if depth == "medium" {
                // Key decision: does person lean cool or warm?
                if relativeContrast < 0.08 {
                    return .softSummer  // Low feature contrast → cooler
                } else {
                    return contrast == .high ? .warmAutumn : .softAutumn
                }
            } else {
                return contrast == .high ? .clearSpring : .lightSpring
            }
        }

        // Fallback (should rarely hit)
        return .softAutumn
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
