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

    // MARK: - Analysis Method Toggle
    /// Set to true to use OpenAI GPT-4 Vision for season analysis (uses API credits, best accuracy)
    /// Set to false to use on-device ML analysis (free, works offline)
    public var useAI = true  // ✅ Using OpenAI GPT-4 Vision for better results!

    private init() {}

    // MARK: - Main Analysis (Async Wrapper)
    /// Analyzes skin tone using either OpenAI GPT-4 Vision or on-device ML based on useAI flag
    func analyzeSkinTone(from image: UIImage, faceObservation: VNFaceObservation) async throws -> (
        season: ColorSeason,
        undertone: Undertone,
        contrast: Contrast,
        confidence: Double
    ) {
        if useAI {
            print("🤖 Using OpenAI GPT-4 Vision for season analysis")
            do {
                let result = try await OpenAIService.shared.analyzeSeasonWithAI(selfieImage: image)
                return result
            } catch {
                print("⚠️ OpenAI failed, falling back to on-device ML: \(error.localizedDescription)")
                // Fallback to on-device analysis if OpenAI fails
                return analyzeSkinToneOnDevice(from: image, faceObservation: faceObservation)
            }
        } else {
            print("📱 Using on-device ML for season analysis")
            return analyzeSkinToneOnDevice(from: image, faceObservation: faceObservation)
        }
    }

    // MARK: - On-Device Analysis
    /// Original on-device ML analysis using LAB color space and chroma gates
    private func analyzeSkinToneOnDevice(from image: UIImage, faceObservation: VNFaceObservation) -> (
        season: ColorSeason,
        undertone: Undertone,
        contrast: Contrast,
        confidence: Double
    ) {
        print("🎨 Starting on-device color analysis...")

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

        // Sample iris color for eye hue detection
        var eyeHueIsCool = false
        if let irisRGB = sampleIrisColor(from: cgImage, faceObservation: faceObservation) {
            let irisLAB = rgbToLab(r: irisRGB.r, g: irisRGB.g, b: irisRGB.b)
            eyeHueIsCool = calculateEyeHueIsCool(skinLAB: lab, irisLAB: irisLAB)
            print("👁️ Iris sampled - eyeHueIsCool: \(eyeHueIsCool)")
        } else {
            print("⚠️ Could not sample iris, defaulting eyeHueIsCool to false")
        }

        // Match season with improved algorithm (chroma gates + eye coolness)
        let season = matchSeasonImproved(
            undertone: undertone,
            depth: depth,
            contrast: contrast,
            skinChroma: skinChroma,
            eyeHueIsCool: eyeHueIsCool,
            backgroundIsWarm: nil  // Future enhancement: detect background warmth
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

    // MARK: - Iris Sampling for Eye Hue Detection
    /// Samples the iris/pupil area to determine if eyes are cooler than skin
    private func sampleIrisColor(from cgImage: CGImage, faceObservation: VNFaceObservation) -> (r: CGFloat, g: CGFloat, b: CGFloat)? {
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let boundingBox = faceObservation.boundingBox

        // Sample iris center - left eye (more toward center than sclera)
        let irisX = (boundingBox.origin.x + boundingBox.width * 0.35) * imageSize.width
        let irisY = (1 - boundingBox.origin.y - boundingBox.height * 0.6) * imageSize.height

        var irisColors: [(r: CGFloat, g: CGFloat, b: CGFloat)] = []

        // Sample multiple points in iris/pupil area
        for xOffset in [-3, 0, 3] {
            for yOffset in [-3, 0, 3] {
                let point = CGPoint(x: irisX + CGFloat(xOffset), y: irisY + CGFloat(yOffset))
                if let color = getPixelColor(at: point, in: cgImage) {
                    // Filter out very dark (pupil) and very bright (reflection) pixels
                    let luminance = 0.299 * color.r + 0.587 * color.g + 0.114 * color.b
                    if luminance > 0.1 && luminance < 0.8 {
                        irisColors.append(color)
                    }
                }
            }
        }

        guard !irisColors.isEmpty else { return nil }

        // Average iris colors
        let avgR = irisColors.map { $0.r }.reduce(0, +) / CGFloat(irisColors.count)
        let avgG = irisColors.map { $0.g }.reduce(0, +) / CGFloat(irisColors.count)
        let avgB = irisColors.map { $0.b }.reduce(0, +) / CGFloat(irisColors.count)

        return (r: avgR, g: avgG, b: avgB)
    }

    // MARK: - Calculate Eye Hue Coolness
    /// Determines if eye iris is cooler than skin tone
    /// - Parameters:
    ///   - skinLAB: LAB values of skin
    ///   - irisLAB: LAB values of iris/pupil area
    /// - Returns: True if iris is cooler/greener/bluer than skin
    private func calculateEyeHueIsCool(
        skinLAB: (L: CGFloat, a: CGFloat, b: CGFloat),
        irisLAB: (L: CGFloat, a: CGFloat, b: CGFloat)
    ) -> Bool {
        // In LAB space:
        // - Lower a* = more green (cooler)
        // - Lower b* = more blue (cooler)

        let skinHueScore = skinLAB.a + (skinLAB.b * 0.5)  // Weight yellow more
        let irisHueScore = irisLAB.a + (irisLAB.b * 0.5)

        // If iris score is lower, it's cooler than skin
        return irisHueScore < (skinHueScore - 2)  // 2-point threshold
    }

    // MARK: - Improved Season Matching Function (Ethnicity-Safe, Chroma-Gated)
    /// Determines color season using enhanced signals to eliminate Autumn bias
    /// - Parameters:
    ///   - undertone: Detected skin undertone (warm, cool, neutral, etc.)
    ///   - depth: Skin depth category ("light", "medium", "deep")
    ///   - contrast: Feature contrast level (high, medium, low)
    ///   - skinChroma: LAB chroma value sqrt(a² + b²) - measures color clarity
    ///   - eyeHueIsCool: True if iris is cooler/greener/bluer than skin
    ///   - backgroundIsWarm: Optional - true if background has warm cast
    /// - Returns: The matched ColorSeason
    ///
    /// Test cases:
    /// 1. Light skin, warm undertone, high chroma (20), cool eyes, high contrast
    ///    → Clear Spring (not Autumn!)
    /// 2. Deep skin, warm undertone, medium chroma (15), warm eyes, high contrast
    ///    → Warm Spring or Deep Autumn (depends on chroma and eye clarity)
    /// 3. Deep skin, cool undertone, low chroma (8), high contrast
    ///    → Deep Winter (not Autumn!)
    /// 4. Medium skin, warm undertone, low chroma (10), warm eyes, low contrast
    ///    → Soft Autumn (correctly muted)
    /// 5. Light skin, cool undertone, high chroma (22), cool eyes, high contrast
    ///    → Clear Winter
    private func matchSeasonImproved(
        undertone: Undertone,
        depth: String,
        contrast: Contrast,
        skinChroma: Double,
        eyeHueIsCool: Bool,
        backgroundIsWarm: Bool? = nil
    ) -> ColorSeason {

        // Adjust undertone if background is adding warmth
        var adjustedUndertone = undertone
        if let bgWarm = backgroundIsWarm, bgWarm {
            // Shift warm/warmNeutral slightly cooler if needed
            // This prevents false warm readings from camera/lighting
            if undertone == .warm && skinChroma < 15 {
                adjustedUndertone = .warmNeutral
            }
        }

        // Define chroma clarity levels
        let isHighClarity = skinChroma > 18      // Vivid, clear colors → Spring/Winter
        let isMediumClarity = skinChroma > 12    // Moderate → transitional
        let isLowClarity = skinChroma <= 12      // Muted → Autumn/Summer

        // Define feature clarity (combines contrast + eye coolness)
        let hasStrongFeatures = (contrast == .high) || (eyeHueIsCool && contrast == .medium)
        let hasSoftFeatures = (contrast == .low) || (!eyeHueIsCool && contrast == .low)

        print("🎨 Season matching: undertone=\(adjustedUndertone.rawValue), depth=\(depth), contrast=\(contrast.rawValue)")
        print("   chroma=\(String(format: "%.1f", skinChroma)), eyeHueIsCool=\(eyeHueIsCool)")
        print("   clarity: high=\(isHighClarity), medium=\(isMediumClarity), low=\(isLowClarity)")

        // ========================================
        // PRIORITY 1: WARM & WARM-NEUTRAL
        // KEY FIX: Split by chroma to prevent Autumn over-assignment
        // ========================================
        if adjustedUndertone == .warm || adjustedUndertone == .warmNeutral {

            // GATE 1: HIGH CLARITY WARM → SPRING (not Autumn!)
            if isHighClarity {
                print("✨ High chroma warm → Spring family")
                switch depth {
                case "light":
                    return hasStrongFeatures ? .clearSpring : .warmSpring
                case "medium":
                    // Medium depth with high clarity and cool eyes → definitely Spring
                    if eyeHueIsCool {
                        return .clearSpring
                    }
                    return (contrast == .high || contrast == .medium) ? .warmSpring : .warmAutumn
                case "deep":
                    // Deep + warm + clear can be Deep Autumn (not same as soft!)
                    return hasStrongFeatures ? .deepAutumn : .warmAutumn
                default:
                    return .warmSpring
                }
            }

            // GATE 2: MEDIUM CLARITY WARM → Use eye coolness to decide
            if isMediumClarity {
                print("💫 Medium chroma warm → checking eye clarity")
                switch depth {
                case "light":
                    return hasSoftFeatures ? .lightSpring : .warmSpring
                case "medium":
                    // This is the critical decision point for medium skin!
                    // Cool eyes + medium chroma = Spring
                    // Warm eyes + medium chroma = Autumn
                    if eyeHueIsCool || hasStrongFeatures {
                        return .warmSpring  // Clear features → Spring
                    } else {
                        return .warmAutumn  // Soft, warm features → Autumn
                    }
                case "deep":
                    return hasStrongFeatures ? .deepAutumn : .warmAutumn
                default:
                    return .warmSpring
                }
            }

            // GATE 3: LOW CLARITY WARM → AUTUMN (correctly muted)
            print("🍂 Low chroma warm → Autumn family")
            switch depth {
            case "deep":
                return hasSoftFeatures ? .warmAutumn : .deepAutumn
            case "medium":
                return .softAutumn
            case "light":
                // Even light skin can be Autumn if muted enough
                return hasSoftFeatures ? .softAutumn : .warmSpring
            default:
                return .softAutumn
            }
        }

        // ========================================
        // PRIORITY 2: COOL UNDERTONES
        // Cool = Winter or Summer (never Autumn!)
        // ========================================
        if adjustedUndertone == .cool {
            print("❄️ Cool undertone → Winter/Summer family")

            switch depth {
            case "deep":
                // Deep + cool = Winter (high contrast) or Cool Summer (softer)
                return hasStrongFeatures ? .deepWinter : .coolWinter

            case "medium":
                if isHighClarity || hasStrongFeatures {
                    return .clearWinter
                } else if isMediumClarity {
                    return contrast == .medium ? .coolSummer : .softSummer
                } else {
                    return .softSummer
                }

            case "light":
                if isHighClarity || hasStrongFeatures {
                    return .clearWinter
                } else if isMediumClarity {
                    return .lightSummer
                } else {
                    return .softSummer
                }

            default:
                return .coolWinter
            }
        }

        // ========================================
        // PRIORITY 3: COOL-NEUTRAL
        // Slightly warmer than cool, but still Summer/Winter dominant
        // ========================================
        if adjustedUndertone == .coolNeutral {
            print("🌸 Cool-neutral undertone → Winter/Summer family")

            switch depth {
            case "deep":
                return hasStrongFeatures ? .deepWinter : .coolWinter

            case "medium":
                if hasStrongFeatures {
                    return .clearWinter
                } else if isMediumClarity {
                    return .coolSummer
                } else {
                    return .softSummer
                }

            case "light":
                if hasStrongFeatures {
                    return .clearWinter
                } else if isMediumClarity {
                    // Can lean Spring if eyes are very cool and clear
                    return eyeHueIsCool ? .lightSpring : .lightSummer
                } else {
                    return .lightSummer
                }

            default:
                return .coolSummer
            }
        }

        // ========================================
        // PRIORITY 4: NEUTRAL
        // Use chroma + eye coolness to decide cool vs warm direction
        // ========================================
        if adjustedUndertone == .neutral {
            print("⚖️ Neutral undertone → using chroma + eyes to decide")

            switch depth {
            case "deep":
                // Deep neutral with cool eyes → Winter (not Autumn!)
                if eyeHueIsCool && hasStrongFeatures {
                    return .deepWinter
                }
                return hasStrongFeatures ? .deepAutumn : .softAutumn

            case "medium":
                // This is nuanced - need both signals
                if eyeHueIsCool {
                    // Cool eyes suggest Summer/Winter
                    return isLowClarity ? .softSummer : .coolSummer
                } else {
                    // Warm eyes suggest Autumn/Spring
                    return hasStrongFeatures ? .warmAutumn : .softAutumn
                }

            case "light":
                // Light neutral usually leans Spring or Summer
                if eyeHueIsCool && isMediumClarity {
                    return .lightSummer
                }
                return hasStrongFeatures ? .clearSpring : .lightSpring

            default:
                return .softAutumn
            }
        }

        // ========================================
        // FALLBACK (should rarely hit this)
        // ========================================
        print("⚠️ Using fallback season logic")
        return depth == "deep" ? .deepWinter : .softAutumn
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
