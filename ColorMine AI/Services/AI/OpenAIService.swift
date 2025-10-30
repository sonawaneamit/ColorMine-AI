//
//  OpenAIService.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import Foundation
import UIKit

class OpenAIService {
    static let shared = OpenAIService()

    private let apiKey = APIKeys.openAIAPIKey
    private let model = "gpt-4o"  // GPT-4o has vision capabilities and is cost-effective
    private let baseURL = "https://api.openai.com/v1/chat/completions"

    private init() {}

    // MARK: - AI-Based Season Analysis
    /// Uses OpenAI GPT-4 Vision to analyze color season from selfie
    /// More accurate than Gemini for visual color analysis
    func analyzeSeasonWithAI(selfieImage: UIImage) async throws -> (
        season: ColorSeason,
        undertone: Undertone,
        contrast: Contrast,
        confidence: Double,
        reasoning: String?
    ) {
        // Convert image to base64
        guard let imageData = selfieImage.jpegData(compressionQuality: 0.8) else {
            throw OpenAIError.invalidImage
        }
        let base64Image = imageData.base64EncodedString()

        // Create comprehensive prompt for season analysis
        let systemPrompt = """
        You are an expert color analyst specializing in seasonal color analysis using the 12-season system.

        Analyze photos with precision, focusing on:
        1. Undertone (warm/cool/neutral) - Look at the yellow vs pink cast in skin
        2. Depth (light/medium/deep) - Overall darkness of coloring
        3. Contrast (high/medium/low) - Difference between skin, hair, and eyes
        4. Chroma/Clarity - Are colors clear and vivid, or soft and muted?
        5. Eye color - Is the iris cooler or warmer than the skin?

        CRITICAL ANTI-BIAS RULES:
        - Deep skin + warm undertone does NOT automatically mean Autumn
        - Check chroma: warm + high clarity = Spring, warm + low clarity = Autumn
        - Deep skin + cool undertone = Winter (often Deep Winter)
        - Medium skin + warm + clear features = likely Spring, not Autumn
        - Cool/clear eyes often indicate Spring or Winter even with warm skin

        Respond ONLY with valid JSON using EXACT season names with spaces.
        """

        let userPrompt = """
        Analyze this person's seasonal color type.

        THE 12 SEASONS (use exact names with spaces):

        SPRING FAMILY (warm):
        - "Clear Spring": warm, high contrast, clear bright colors
        - "Warm Spring": warm, medium-high contrast, golden warm tones
        - "Light Spring": warm-neutral, light depth, soft pastels with warmth

        SUMMER FAMILY (cool):
        - "Light Summer": cool-neutral, light depth, soft pastels with coolness
        - "Cool Summer": cool, medium contrast, muted cool tones
        - "Soft Summer": cool-neutral, low contrast, very muted soft colors

        AUTUMN FAMILY (warm):
        - "Soft Autumn": warm-neutral, low contrast, very muted warm tones
        - "Warm Autumn": warm, medium contrast, rich earthy tones
        - "Deep Autumn": warm, high contrast, deep rich warm colors

        WINTER FAMILY (cool):
        - "Deep Winter": cool, very high contrast, deep cool dramatic colors
        - "Cool Winter": cool, high contrast, icy cool tones
        - "Clear Winter": cool-neutral, high contrast, clear vivid colors

        RESPOND WITH THIS EXACT JSON FORMAT (no other text):
        {
          "season": "one of the exact names above with spaces",
          "undertone": "one of: Warm, Warm Neutral, Neutral, Cool Neutral, Cool",
          "contrast": "one of: High, Medium, Low",
          "depth": "one of: light, medium, deep",
          "confidence": 0.XX,
          "reasoning": "Brief explanation mentioning undertone, chroma, contrast, and eye color"
        }
        """

        // Build request body
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": userPrompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)",
                                "detail": "high"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 500,
            "temperature": 0.3  // Lower temp for more consistent analysis
        ]

        // Create request
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("🤖 Requesting OpenAI GPT-4 Vision season analysis...")

        // Make API call
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        // Check status code
        guard httpResponse.statusCode == 200 else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                print("❌ OpenAI API Error: \(message)")
                throw OpenAIError.apiErrorWithMessage(message)
            }
            throw OpenAIError.apiError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let textResponse = message["content"] as? String else {
            print("❌ Could not parse OpenAI response")
            throw OpenAIError.invalidResponse
        }

        print("📝 OpenAI response: \(textResponse)")

        // Clean up response - remove markdown code blocks if present
        var cleanedResponse = textResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedResponse.hasPrefix("```json") {
            cleanedResponse = cleanedResponse.replacingOccurrences(of: "```json", with: "")
            cleanedResponse = cleanedResponse.replacingOccurrences(of: "```", with: "")
            cleanedResponse = cleanedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if cleanedResponse.hasPrefix("```") {
            cleanedResponse = cleanedResponse.replacingOccurrences(of: "```", with: "")
            cleanedResponse = cleanedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Parse JSON from text response
        guard let jsonData = cleanedResponse.data(using: .utf8),
              let analysisResult = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            print("❌ Could not parse JSON from OpenAI text response")
            print("❌ Response was: \(cleanedResponse)")
            throw OpenAIError.invalidResponse
        }

        // Extract values
        guard let seasonString = analysisResult["season"] as? String,
              let undertoneString = analysisResult["undertone"] as? String,
              let contrastString = analysisResult["contrast"] as? String,
              let confidence = analysisResult["confidence"] as? Double else {
            print("❌ Missing required fields in analysis result")
            throw OpenAIError.invalidResponse
        }

        // Convert strings to enums (using rawValue which has spaces)
        guard let season = ColorSeason(rawValue: seasonString),
              let undertone = Undertone(rawValue: undertoneString),
              let contrast = Contrast(rawValue: contrastString) else {
            print("❌ Invalid enum values in analysis result")
            print("❌ Season: '\(seasonString)', Undertone: '\(undertoneString)', Contrast: '\(contrastString)'")
            throw OpenAIError.invalidResponse
        }

        // Extract reasoning if available
        let reasoning = analysisResult["reasoning"] as? String
        if let reasoning = reasoning {
            print("🧠 OpenAI reasoning: \(reasoning)")
        }

        print("✅ OpenAI analysis complete: \(season.rawValue), \(undertone.rawValue), \(contrast.rawValue)")

        return (season: season, undertone: undertone, contrast: contrast, confidence: confidence, reasoning: reasoning)
    }

    // MARK: - Garment Color Analysis
    /// Analyzes how well a garment's color matches the user's seasonal color palette
    func analyzeGarmentColor(
        garmentImage: UIImage,
        userSeason: ColorSeason
    ) async throws -> (matchScore: Int, reasoning: String) {
        // Convert image to base64
        guard let imageData = garmentImage.jpegData(compressionQuality: 0.8) else {
            throw OpenAIError.invalidImage
        }
        let base64Image = imageData.base64EncodedString()

        // Get season-specific color guidelines
        let seasonGuidelines = getSeasonGuidelines(for: userSeason)

        let systemPrompt = """
        You are an expert color analyst specializing in seasonal color analysis.
        Your task is to analyze garment colors and determine how well they match a person's seasonal color palette.

        Focus ONLY on the garment/clothing item in the image, NOT the model wearing it.
        Analyze the dominant color(s) of the clothing item itself.
        """

        let userPrompt = """
        This person's color season is: \(userSeason.rawValue)

        \(seasonGuidelines)

        Analyze the GARMENT/CLOTHING item in this image (ignore the person wearing it).

        Consider:
        1. What is the dominant color of the garment?
        2. What is the color temperature (warm/cool)?
        3. What is the saturation level (muted/clear/bright)?
        4. What is the value/brightness (light/medium/dark)?
        5. How well does this specific color align with the \(userSeason.rawValue) palette?

        Give a match score from 0-100 where:
        - 90-100: Perfect match, ideal color for this season
        - 70-89: Good match, harmonizes well with the palette
        - 50-69: Acceptable but not ideal, slightly off in temperature/saturation/value
        - 30-49: Poor match, clashes with the palette
        - 0-29: Very poor match, completely wrong for this season

        RESPOND WITH THIS EXACT JSON FORMAT (no other text):
        {
          "matchScore": 0-100,
          "dominantColor": "name of the main garment color",
          "reasoning": "2-3 sentence explanation of why this score, mentioning temperature, saturation, and value"
        }
        """

        // Build request body
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": userPrompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 500,
            "temperature": 0.3 // Lower temperature for more consistent color analysis
        ]

        // Make API request
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("🎨 Sending garment color analysis request to OpenAI...")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        if httpResponse.statusCode != 200 {
            print("❌ OpenAI API error: \(httpResponse.statusCode)")
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJson["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw OpenAIError.apiErrorWithMessage(message)
            }
            throw OpenAIError.apiError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let textResponse = message["content"] as? String else {
            print("❌ Could not parse OpenAI response")
            throw OpenAIError.invalidResponse
        }

        print("📝 OpenAI garment analysis response: \(textResponse)")

        // Clean up response
        var cleanedResponse = textResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedResponse.hasPrefix("```json") {
            cleanedResponse = cleanedResponse.replacingOccurrences(of: "```json", with: "")
            cleanedResponse = cleanedResponse.replacingOccurrences(of: "```", with: "")
            cleanedResponse = cleanedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        } else if cleanedResponse.hasPrefix("```") {
            cleanedResponse = cleanedResponse.replacingOccurrences(of: "```", with: "")
            cleanedResponse = cleanedResponse.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Parse JSON
        guard let jsonData = cleanedResponse.data(using: .utf8),
              let analysisResult = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let matchScore = analysisResult["matchScore"] as? Int,
              let reasoning = analysisResult["reasoning"] as? String else {
            print("❌ Could not parse garment analysis JSON")
            throw OpenAIError.invalidResponse
        }

        print("✅ Garment color analysis complete: \(matchScore)% match")
        print("🧠 Reasoning: \(reasoning)")

        return (matchScore: matchScore, reasoning: reasoning)
    }

    // MARK: - Season Guidelines Helper
    private func getSeasonGuidelines(for season: ColorSeason) -> String {
        switch season {
        case .clearSpring:
            return """
            BEST COLORS: Clear, bright, warm colors with high saturation. Think coral, bright aqua, clear red, golden yellow.
            AVOID: Muted colors, dusty tones, very dark colors, pure black, pure white (opt for warm ivory).
            """
        case .warmSpring:
            return """
            BEST COLORS: Warm, golden colors with medium-high saturation. Think peach, golden yellow, warm coral, warm green.
            AVOID: Cool tones, icy colors, pure black, pure white, dusty muted colors.
            """
        case .lightSpring:
            return """
            BEST COLORS: Light, warm pastels with delicate clarity. Think light peach, warm pink, light golden yellow, soft aqua.
            AVOID: Very dark colors, pure black, highly saturated jewel tones, stark white.
            """
        case .lightSummer:
            return """
            BEST COLORS: Light, cool pastels with soft clarity. Think powder blue, soft pink, lavender, mint green.
            AVOID: Very dark colors, warm golden tones, bright saturated colors, pure black.
            """
        case .coolSummer:
            return """
            BEST COLORS: Cool, muted colors with medium saturation. Think soft blue, mauve, rose, cool teal.
            AVOID: Warm golden tones, bright saturated colors, orange, pure white, pure black.
            """
        case .softSummer:
            return """
            BEST COLORS: Soft, muted, cool colors with low contrast. Think dusty rose, soft blue-grey, sage green, soft mauve.
            AVOID: Bright clear colors, warm golden tones, high contrast colors, pure black, pure white.
            """
        case .softAutumn:
            return """
            BEST COLORS: Soft, muted, warm colors with low saturation. Think sage green, dusty teal, soft terracotta, muted olive.
            AVOID: Bright clear colors, pure white, pure black, cool icy tones, highly saturated colors.
            """
        case .warmAutumn:
            return """
            BEST COLORS: Rich, warm, earthy colors. Think rust, olive green, golden brown, warm terracotta, mustard.
            AVOID: Cool tones, icy colors, pure black, pure white, bright clear colors, dusty muted tones.
            """
        case .deepAutumn:
            return """
            BEST COLORS: Deep, rich, warm colors. Think chocolate brown, deep olive, rust, warm burgundy, deep teal with warmth.
            AVOID: Light pastels, icy cool tones, pure black, muted soft colors, bright clear colors.
            """
        case .deepWinter:
            return """
            BEST COLORS: Deep, cool, dramatic colors with high contrast. Think true black, pure white, deep burgundy, royal blue, emerald.
            AVOID: Light pastels, muted dusty colors, warm golden tones, beige, soft colors.
            """
        case .coolWinter:
            return """
            BEST COLORS: Cool, icy colors with high saturation. Think icy blue, icy pink, cool magenta, true black, pure white.
            AVOID: Warm golden tones, earthy colors, muted dusty tones, soft pastels.
            """
        case .clearWinter:
            return """
            BEST COLORS: Clear, cool, vivid colors with high contrast. Think true red, royal blue, bright fuchsia, true black, pure white.
            AVOID: Muted colors, warm golden tones, dusty tones, soft pastels, earthy colors.
            """
        }
    }
}

// MARK: - OpenAI Errors
enum OpenAIError: LocalizedError {
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
            return "OpenAI API: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}
