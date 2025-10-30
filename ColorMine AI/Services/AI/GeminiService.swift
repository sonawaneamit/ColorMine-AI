//
//  GeminiService.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import Foundation
import UIKit

class GeminiService {
    static let shared = GeminiService()

    // IMPORTANT: In production, move API key to secure storage or environment variable
    private let apiKey = APIKeys.geminiAPIKey

    // Different models for different purposes
    private let visionModel = "gemini-2.0-flash-exp"  // Nano Banana - for analysis/text
    private let imageModel = "gemini-2.5-flash-image"  // For image generation
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"

    // 🎨 Image Generation Mode
    // ⚠️ Note: Nano Banana (gemini-2.0-flash-exp) cannot generate images
    // Now using: Gemini 2.5 Flash Image for real AI generation
    private let useMockMode = false  // ✅ REAL AI image generation enabled!

    private init() {}

    // MARK: - Generate Drapes Grid
    func generateDrapesGrid(
        selfieImage: UIImage,
        favoriteColors: [ColorSwatch]
    ) async throws -> UIImage {
        let prompt = PromptEngine.drapesGridPrompt(colors: favoriteColors)
        return try await generateImage(
            prompt: prompt,
            selfieImage: selfieImage,
            packType: .drapesGrid
        )
    }

    // MARK: - Generate Texture Pack
    func generateTexturePack(
        selfieImage: UIImage,
        focusColor: ColorSwatch,
        season: ColorSeason
    ) async throws -> UIImage {
        let prompt = PromptEngine.texturePackPrompt(color: focusColor, season: season)
        return try await generateImage(
            prompt: prompt,
            selfieImage: selfieImage,
            packType: .texturePack
        )
    }

    // MARK: - Generate Jewelry Pack
    func generateJewelryPack(
        selfieImage: UIImage,
        focusColor: ColorSwatch,
        undertone: Undertone,
        season: ColorSeason
    ) async throws -> UIImage {
        let prompt = PromptEngine.jewelryPackPrompt(color: focusColor, undertone: undertone, season: season)
        return try await generateImage(
            prompt: prompt,
            selfieImage: selfieImage,
            packType: .jewelryPack
        )
    }

    // MARK: - Generate Makeup Pack
    func generateMakeupPack(
        selfieImage: UIImage,
        focusColor: ColorSwatch?,
        undertone: Undertone,
        contrast: Contrast,
        season: ColorSeason
    ) async throws -> UIImage {
        let prompt = PromptEngine.makeupPackPrompt(
            color: focusColor,
            undertone: undertone,
            contrast: contrast,
            season: season
        )
        return try await generateImage(
            prompt: prompt,
            selfieImage: selfieImage,
            packType: .makeupPack
        )
    }

    // MARK: - Generate Hair Color Pack
    func generateHairColorPack(
        selfieImage: UIImage,
        season: ColorSeason,
        undertone: Undertone
    ) async throws -> UIImage {
        let prompt = PromptEngine.hairColorPackPrompt(season: season, undertone: undertone)
        return try await generateImage(
            prompt: prompt,
            selfieImage: selfieImage,
            packType: .hairColorPack
        )
    }

    // MARK: - Core Image Generation
    private func generateImage(
        prompt: String,
        selfieImage: UIImage,
        packType: PackType
    ) async throws -> UIImage {
        // Use mock mode if enabled
        if useMockMode {
            return try await generateMockImage(selfieImage: selfieImage, packType: packType)
        }

        // Convert image to base64
        guard let imageData = selfieImage.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.invalidImage
        }
        let base64Image = imageData.base64EncodedString()

        // Build request URL using IMAGE GENERATION model
        let endpoint = "\(baseURL)/\(imageModel):generateContent"
        guard var urlComponents = URLComponents(string: endpoint) else {
            throw GeminiError.invalidURL
        }
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = urlComponents.url else {
            throw GeminiError.invalidURL
        }

        // Build request body
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.4,
                "topK": 32,
                "topP": 1,
                "maxOutputTokens": 4096
            ]
        ]

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // Make API call
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        // Check status code
        guard httpResponse.statusCode == 200 else {
            // Try to parse error message
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                print("❌ Gemini API Error: \(message)")
                throw GeminiError.apiErrorWithMessage(message)
            }
            throw GeminiError.apiError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw GeminiError.invalidResponse
        }

        // Debug: Print full response structure
        print("📦 Gemini Response keys: \(json.keys)")

        // Debug candidates structure
        if let candidates = json["candidates"] as? [[String: Any]] {
            print("📦 Found \(candidates.count) candidates")
            if let firstCandidate = candidates.first {
                print("📦 Candidate keys: \(firstCandidate.keys)")

                // Check for early termination reasons
                if let finishReason = firstCandidate["finishReason"] as? String {
                    print("⚠️ Finish Reason: \(finishReason)")
                }
                if let finishMessage = firstCandidate["finishMessage"] as? String {
                    print("⚠️ Finish Message: \(finishMessage)")
                }

                if let content = firstCandidate["content"] as? [String: Any] {
                    print("📦 Content keys: \(content.keys)")
                    if let parts = content["parts"] as? [[String: Any]] {
                        print("📦 Found \(parts.count) parts")
                        for (index, part) in parts.enumerated() {
                            print("📦 Part \(index) keys: \(part.keys)")
                            // Check for inline_data OR inlineData
                            if let inlineData = part["inline_data"] as? [String: Any] ?? part["inlineData"] as? [String: Any] {
                                print("📦 Inline data keys: \(inlineData.keys)")
                                if let mimeType = inlineData["mime_type"] as? String ?? inlineData["mimeType"] as? String {
                                    print("✅ Found image! MIME type: \(mimeType)")
                                }
                            }
                        }
                    }
                } else {
                    print("❌ No 'content' key found - Gemini stopped without generating image")

                    // Provide helpful error message based on finish reason
                    if let finishReason = firstCandidate["finishReason"] as? String {
                        if finishReason == "SAFETY" {
                            throw GeminiError.apiErrorWithMessage("Content safety filters blocked this request. The prompt may need adjustment.")
                        } else if finishReason == "MAX_TOKENS" || finishReason == "RECITATION" {
                            throw GeminiError.apiErrorWithMessage("Request exceeded limits or contains copyrighted content.")
                        } else {
                            throw GeminiError.apiErrorWithMessage("Generation stopped: \(finishReason)")
                        }
                    }
                }
            }
        }

        // Try to extract image from response
        if let candidates = json["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]] {

            // Try to find image in any part
            for part in parts {
                // Try both snake_case and camelCase
                if let imageData = part["inline_data"] as? [String: Any] ?? part["inlineData"] as? [String: Any],
                   let base64String = imageData["data"] as? String,
                   let decodedData = Data(base64Encoded: base64String),
                   let generatedImage = UIImage(data: decodedData) {
                    print("✅ Successfully generated image!")
                    return generatedImage
                }
            }
        }

        // If we got here, the response format wasn't what we expected
        print("❌ Could not parse image from response")
        throw GeminiError.invalidResponse
    }

    // MARK: - Generate Text Cards
    // Note: ContrastCard and NeutralsMetalsCard are generated locally
    // using static methods in StyleCards.swift - no AI generation needed

    // MARK: - Mock Image Generation (for UI testing)
    private func generateMockImage(selfieImage: UIImage, packType: PackType) async throws -> UIImage {
        // Simulate API delay
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Create a placeholder image with text
        let size = CGSize(width: 800, height: 800)
        let renderer = UIGraphicsImageRenderer(size: size)

        let image = renderer.image { context in
            // Background gradient
            let colors = [UIColor.purple.withAlphaComponent(0.3).cgColor,
                         UIColor.systemPink.withAlphaComponent(0.3).cgColor]
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                     colors: colors as CFArray,
                                     locations: [0.0, 1.0])!
            context.cgContext.drawLinearGradient(gradient,
                                                 start: CGPoint(x: 0, y: 0),
                                                 end: CGPoint(x: size.width, y: size.height),
                                                 options: [])

            // Draw selfie in center
            let selfieSize = CGSize(width: 300, height: 300)
            let selfieRect = CGRect(x: (size.width - selfieSize.width) / 2,
                                   y: 100,
                                   width: selfieSize.width,
                                   height: selfieSize.height)
            selfieImage.draw(in: selfieRect)

            // Add text
            let text = "Mock \(packType.rawValue)\n\n⚠️ Image Generation Coming Soon\n\nGemini Flash is a text model.\nFor real images, use:\n• Imagen API\n• DALL-E 3\n• Stable Diffusion\n• Midjourney"
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .medium),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]
            let textRect = CGRect(x: 50, y: 450, width: size.width - 100, height: 300)
            text.draw(in: textRect, withAttributes: attributes)
        }

        print("🎨 Generated mock image for \(packType.rawValue)")
        return image
    }
}

// MARK: - Gemini Errors
enum GeminiError: LocalizedError {
    case invalidImage
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
    case apiErrorWithMessage(String)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Unable to process the image. Please try again."
        case .invalidURL:
            return "Invalid API endpoint."
        case .invalidResponse:
            return "Unable to parse AI response. Please try again."
        case .apiError(let code):
            return "API error (Code: \(code)). Please try again later."
        case .apiErrorWithMessage(let message):
            return "Gemini API: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
