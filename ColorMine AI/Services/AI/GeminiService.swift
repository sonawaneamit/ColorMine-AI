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
    private let imageModel = "gemini-2.5-flash-image"  // Gemini 2.5 Flash Image (Nano Banana) for image generation
    private let videoModel = "veo-3.1-generate-preview"  // Veo 3.1 for video generation
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"

    // 🎨 Image Generation Mode
    // ⚠️ Note: Nano Banana (gemini-2.0-flash-exp) cannot generate images
    // Now using: Gemini 2.5 Flash Image for real AI generation
    private let useMockMode = false  // ✅ REAL AI image generation enabled!

    private init() {}

    // MARK: - AI-Based Season Analysis
    /// Uses Gemini Vision API to analyze color season from selfie
    /// Alternative to on-device ColorAnalyzer for comparison
    func analyzeSeasonWithAI(selfieImage: UIImage) async throws -> (
        season: ColorSeason,
        undertone: Undertone,
        contrast: Contrast,
        confidence: Double
    ) {
        // Convert image to base64
        guard let imageData = selfieImage.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.invalidImage
        }
        let base64Image = imageData.base64EncodedString()

        // Build request URL using VISION model for analysis
        let endpoint = "\(baseURL)/\(visionModel):generateContent"
        guard var urlComponents = URLComponents(string: endpoint) else {
            throw GeminiError.invalidURL
        }
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = urlComponents.url else {
            throw GeminiError.invalidURL
        }

        // Create comprehensive prompt for season analysis
        let prompt = """
        You are an expert color analyst specializing in seasonal color analysis.

        Analyze this person's photo and determine their color season using the 12-season system.

        THE 12 SEASONAL COLOR SEASONS:

        SPRING FAMILY (warm undertone):
        - Clear Spring: warm, high contrast, clear/bright colors
        - Warm Spring: warm, medium-high contrast, golden warm tones
        - Light Spring: warm-neutral, light depth, soft pastels with warmth

        SUMMER FAMILY (cool undertone):
        - Light Summer: cool-neutral, light depth, soft pastels with coolness
        - Cool Summer: cool, medium contrast, muted cool tones
        - Soft Summer: cool-neutral, low contrast, very muted soft colors

        AUTUMN FAMILY (warm undertone):
        - Soft Autumn: warm-neutral, low contrast, very muted warm tones
        - Warm Autumn: warm, medium contrast, rich earthy tones
        - Deep Autumn: warm, high contrast, deep rich warm colors

        WINTER FAMILY (cool undertone):
        - Deep Winter: cool, very high contrast, deep cool dramatic colors
        - Cool Winter: cool, high contrast, icy cool tones
        - Clear Winter: cool-neutral, high contrast, clear vivid colors

        ANALYSIS FACTORS:
        1. UNDERTONE: Is the skin warm (golden/yellow), cool (pink/blue), or neutral?
        2. DEPTH: Is the overall coloring light, medium, or deep?
        3. CONTRAST: High (strong difference between skin/hair/eyes), Medium, or Low contrast?
        4. CHROMA/CLARITY: Are their colors clear and vivid, or soft and muted?
        5. EYE COLOR: What is the iris color and is it cooler or warmer than the skin?

        IMPORTANT NOTES FOR ACCURACY:
        - Deep skin + warm undertone does NOT automatically mean Autumn
        - Check chroma: warm + high clarity = Spring, warm + low clarity = Autumn
        - Deep skin + cool undertone = Winter (often Deep Winter)
        - Medium skin + warm + clear features = likely Spring, not Autumn
        - Look at the eyes: cool/clear eyes often indicate Spring or Winter even with warm skin

        RESPOND IN THIS EXACT JSON FORMAT:
        {
          "season": "one of: clearSpring, warmSpring, lightSpring, lightSummer, coolSummer, softSummer, softAutumn, warmAutumn, deepAutumn, deepWinter, coolWinter, clearWinter",
          "undertone": "one of: warm, warmNeutral, neutral, coolNeutral, cool",
          "contrast": "one of: high, medium, low",
          "depth": "one of: light, medium, deep",
          "confidence": 0.XX (between 0.50 and 0.98),
          "reasoning": "Brief explanation of why this season was chosen, mentioning undertone, chroma, contrast, and eye color"
        }

        Analyze the photo now and respond with ONLY valid JSON, no other text.
        """

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
                "temperature": 0.3,  // Lower temp for more consistent analysis
                "topK": 32,
                "topP": 1,
                "maxOutputTokens": 2048
            ]
        ]

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        print("🤖 Requesting Gemini AI season analysis...")

        // Make API call
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        // Check status code
        guard httpResponse.statusCode == 200 else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                print("❌ Gemini API Error: \(message)")
                throw GeminiError.apiErrorWithMessage(message)
            }
            throw GeminiError.apiError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let textResponse = firstPart["text"] as? String else {
            print("❌ Could not parse Gemini response")
            throw GeminiError.invalidResponse
        }

        print("📝 Gemini response: \(textResponse)")

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
            print("❌ Could not parse JSON from Gemini text response")
            print("❌ Response was: \(cleanedResponse)")
            throw GeminiError.invalidResponse
        }

        // Extract values
        guard let seasonString = analysisResult["season"] as? String,
              let undertoneString = analysisResult["undertone"] as? String,
              let contrastString = analysisResult["contrast"] as? String,
              let confidence = analysisResult["confidence"] as? Double else {
            print("❌ Missing required fields in analysis result")
            throw GeminiError.invalidResponse
        }

        // Convert strings to enums
        guard let season = ColorSeason(rawValue: seasonString),
              let undertone = Undertone(rawValue: undertoneString),
              let contrast = Contrast(rawValue: contrastString) else {
            print("❌ Invalid enum values in analysis result")
            throw GeminiError.invalidResponse
        }

        // Log reasoning if available
        if let reasoning = analysisResult["reasoning"] as? String {
            print("🧠 Gemini reasoning: \(reasoning)")
        }

        print("✅ Gemini analysis complete: \(season.rawValue), \(undertone.rawValue), \(contrast.rawValue)")

        return (season: season, undertone: undertone, contrast: contrast, confidence: confidence)
    }

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

    // MARK: - Extract Clothing from Screenshot
    /// Use Gemini to identify and extract the main clothing item from a webpage screenshot
    /// - Parameter screenshot: Full webpage screenshot
    /// - Returns: Extracted clothing item image
    func extractClothingFromScreenshot(_ screenshot: UIImage) async throws -> UIImage {
        // Convert image to base64
        guard let imageData = screenshot.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.invalidImage
        }
        let base64Image = imageData.base64EncodedString()

        // Build request URL using VISION model for analysis
        let endpoint = "\(baseURL)/\(visionModel):generateContent"
        guard var urlComponents = URLComponents(string: endpoint) else {
            throw GeminiError.invalidURL
        }
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = urlComponents.url else {
            throw GeminiError.invalidURL
        }

        // Succinct prompt for Gemini
        let prompt = "Identify the main clothing item in this image and return its exact bounding box coordinates. Return JSON: {\"x\": top-left x, \"y\": top-left y, \"width\": width, \"height\": height}"

        // Build request body
        let requestBody: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": prompt],
                    ["inline_data": [
                        "mime_type": "image/jpeg",
                        "data": base64Image
                    ]]
                ]
            ]],
            "generationConfig": [
                "temperature": 0.1,
                "maxOutputTokens": 100
            ]
        ]

        // Make API request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.networkError(NSError(domain: "Invalid response", code: -1))
        }

        guard httpResponse.statusCode == 200 else {
            if let errorJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = errorJSON["error"] as? [String: Any],
               let message = error["message"] as? String {
                throw GeminiError.apiErrorWithMessage(message)
            }
            throw GeminiError.apiError(statusCode: httpResponse.statusCode)
        }

        // Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw GeminiError.invalidResponse
        }

        // Parse bounding box from JSON response
        guard let jsonData = text.data(using: .utf8),
              let bbox = try? JSONSerialization.jsonObject(with: jsonData) as? [String: CGFloat],
              let x = bbox["x"], let y = bbox["y"],
              let width = bbox["width"], let height = bbox["height"] else {
            throw GeminiError.invalidResponse
        }

        // Crop the image to the bounding box
        let cropRect = CGRect(x: x, y: y, width: width, height: height)
        return try cropImage(screenshot, toRect: cropRect)
    }

    // Helper to crop image
    private func cropImage(_ image: UIImage, toRect rect: CGRect) throws -> UIImage {
        let scale = image.scale
        let scaledRect = CGRect(
            x: rect.origin.x * scale,
            y: rect.origin.y * scale,
            width: rect.size.width * scale,
            height: rect.size.height * scale
        )

        guard let cgImage = image.cgImage,
              let croppedCGImage = cgImage.cropping(to: scaledRect) else {
            throw GeminiError.invalidImage
        }

        return UIImage(cgImage: croppedCGImage, scale: image.scale, orientation: image.imageOrientation)
    }

    // MARK: - Virtual Try-On
    /// Generate virtual try-on using Gemini Nano Banana (same model used for drapes/packs)
    /// - Parameters:
    ///   - personPhoto: Full body photo of the person
    ///   - garmentPhoto: Photo of the clothing item to try on
    /// - Returns: Photorealistic try-on result image
    func generateTryOn(
        personPhoto: UIImage,
        garmentPhoto: UIImage
    ) async throws -> UIImage {

        print("🎨 Starting Gemini Nano Banana try-on generation...")

        // Convert images to base64
        guard let personData = personPhoto.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.invalidImage
        }
        guard let garmentData = garmentPhoto.jpegData(compressionQuality: 0.8) else {
            throw GeminiError.invalidImage
        }

        let personBase64 = personData.base64EncodedString()
        let garmentBase64 = garmentData.base64EncodedString()

        // Build request URL using IMAGE GENERATION model (Nano Banana)
        let endpoint = "\(baseURL)/\(imageModel):generateContent"
        guard var urlComponents = URLComponents(string: endpoint) else {
            throw GeminiError.invalidURL
        }
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = urlComponents.url else {
            throw GeminiError.invalidURL
        }

        // Craft detailed prompt for virtual try-on
        let prompt = """
        You will receive two images: (1) a full-body photo of a person wearing casual clothes (reference) and (2) an image containing a clothing item (may be a product photo, screenshot, or photo).

        IMPORTANT: In image #2, identify and focus ONLY on the main clothing item (the most prominent garment). Ignore any background elements, text, UI elements, or other items in the image.

        First, automatically identify the main garment type from image #2 (dress, top/shirt/jacket, or pants/shorts). Then generate a photorealistic image of the person from image #1 now wearing that main garment from image #2, with the following rules:

        • Replace the original clothing in image #1 appropriately:
          - If it's a dress: remove any pants/jeans in the original photo and show bare legs (or appropriate length) consistent with the dress length.
          - If it's a top/shirt/jacket: keep the original lower body clothing exactly as in the photo; only replace the upper body.
          - If it's pants/shorts: keep the original top exactly and only replace lower body.
            - If it's top and bottom: replace both.

        • Always preserve the person's face, hair, skin tone, body shape, and proportions from the reference image.
        • Fit the new garment naturally, with realistic drape, fabric fold, shadowing and seamless transition at neckline, waist/hips, sleeves, hemline and shoes (if visible).
        • If shoes conflict with the new outfit (for example, dress length vs casual sneakers): adjust or remove shoes if necessary for realism.
        • Output is a single high-resolution photorealistic image, showing the person as if they changed into the new garment.

        CRITICAL: The output image MUST be in 9:16 aspect ratio (vertical/portrait format) for mobile display. Regardless of the input image aspect ratios, always generate the final result in 9:16 vertical format.

        Please produce only the image result.
        """

        // Build request body with BOTH images
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": personBase64
                            ]
                        ],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": garmentBase64
                            ]
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "responseModalities": ["Image"],  // Request image output
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
        request.timeoutInterval = 60 // 60 second timeout

        print("📤 Sending try-on request to Gemini Nano Banana...")

        // Make API call
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        print("📥 Response status code: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
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

        // Extract image from response (same structure as drapes/packs)
        if let candidates = json["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let content = firstCandidate["content"] as? [String: Any],
           let parts = content["parts"] as? [[String: Any]] {

            // Try to find image in any part
            for part in parts {
                if let imageData = part["inline_data"] as? [String: Any] ?? part["inlineData"] as? [String: Any],
                   let base64String = imageData["data"] as? String,
                   let decodedData = Data(base64Encoded: base64String),
                   let generatedImage = UIImage(data: decodedData) {
                    print("✅ Gemini try-on generation complete!")
                    return generatedImage
                }
            }
        }

        // Check for early termination
        if let candidates = json["candidates"] as? [[String: Any]],
           let firstCandidate = candidates.first,
           let finishReason = firstCandidate["finishReason"] as? String {
            if finishReason == "SAFETY" {
                throw GeminiError.apiErrorWithMessage("Content safety filters blocked this request. Try with different photos.")
            } else if finishReason == "IMAGE_OTHER" || finishReason == "OTHER" {
                throw GeminiError.apiErrorWithMessage("Unable to generate try-on image. This can happen with complex poses or unclear garment images. Try with a clear, front-facing photo and a well-lit garment image.")
            } else {
                throw GeminiError.apiErrorWithMessage("Generation stopped: \(finishReason)")
            }
        }

        print("❌ Could not parse try-on image from response")
        throw GeminiError.invalidResponse
    }

    // MARK: - Video Generation
    /// Generate video from try-on result using Gemini Veo 3.1
    /// - Parameters:
    ///   - tryOnImage: The try-on result image to animate
    ///   - prompt: Optional custom prompt (default: fashion model animation)
    /// - Returns: Video data (MP4)
    func generateVideo(
        from image: UIImage,
        prompt: String? = nil
    ) async throws -> Data {

        print("🎬 Starting Gemini Veo 3.1 video generation...")

        // Default prompt for fashion try-on video
        let defaultPrompt = "The person slowly turns and poses naturally to showcase the outfit from different angles, smooth fashion model movement, professional photoshoot"
        let finalPrompt = prompt ?? defaultPrompt

        // Build request URL for video generation (predictLongRunning endpoint)
        let endpoint = "\(baseURL)/\(videoModel):predictLongRunning"
        guard var urlComponents = URLComponents(string: endpoint) else {
            throw GeminiError.invalidURL
        }
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = urlComponents.url else {
            throw GeminiError.invalidURL
        }

        // Convert image to base64 for imageBytes
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw GeminiError.invalidImage
        }
        let base64Image = imageData.base64EncodedString()

        // Build request body with correct Veo 3.1 image-to-video format
        let requestBody: [String: Any] = [
            "instances": [[
                "prompt": finalPrompt,
                "image": [
                    "imageBytes": base64Image,
                    "mimeType": "image/jpeg"
                ]
            ]],
            "parameters": [
                "aspectRatio": "9:16",
                "durationSeconds": "8"
            ]
        ]

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 30 // Initial request should be quick

        print("📤 Sending video generation request to Gemini Veo 3.1...")

        // Make API request to start long-running operation
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        print("📥 Video response status code: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                print("❌ Gemini API Error: \(message)")
                throw GeminiError.apiErrorWithMessage(message)
            }
            throw GeminiError.apiError(statusCode: httpResponse.statusCode)
        }

        // Parse response to get operation name
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let operationName = json["name"] as? String else {
            print("❌ Could not parse operation name from response")
            throw GeminiError.invalidResponse
        }

        print("✅ Video generation started, operation: \(operationName)")
        print("⏳ Polling for video completion...")

        // Poll the operation until complete
        return try await pollVideoOperation(operationName: operationName)
    }

    /// Upload image to Gemini File API and return the file URI
    private func uploadImageToGemini(_ image: UIImage) async throws -> String {
        // Convert image to JPEG data
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            throw GeminiError.invalidImage
        }

        // Build upload URL
        let uploadEndpoint = "https://generativelanguage.googleapis.com/upload/v1beta/files"
        guard var urlComponents = URLComponents(string: uploadEndpoint) else {
            throw GeminiError.invalidURL
        }
        urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
        guard let url = urlComponents.url else {
            throw GeminiError.invalidURL
        }

        // Create multipart/related request with correct format
        let boundary = "----WebKitFormBoundary\(UUID().uuidString.replacingOccurrences(of: "-", with: ""))"
        var requestBody = Data()

        // Part 1: JSON metadata
        let metadata = """
        {
            "file": {
                "displayName": "try_on_image.jpg",
                "mimeType": "image/jpeg"
            }
        }
        """

        requestBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        requestBody.append("Content-Disposition: form-data; name=\"metadata\"\r\n".data(using: .utf8)!)
        requestBody.append("Content-Type: application/json; charset=UTF-8\r\n\r\n".data(using: .utf8)!)
        requestBody.append(metadata.data(using: .utf8)!)
        requestBody.append("\r\n".data(using: .utf8)!)

        // Part 2: File data
        requestBody.append("--\(boundary)\r\n".data(using: .utf8)!)
        requestBody.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        requestBody.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        requestBody.append(imageData)
        requestBody.append("\r\n".data(using: .utf8)!)

        // End boundary
        requestBody.append("--\(boundary)--\r\n".data(using: .utf8)!)

        // Create upload request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/related; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue(String(requestBody.count), forHTTPHeaderField: "Content-Length")
        request.httpBody = requestBody
        request.timeoutInterval = 60

        print("📤 Upload request size: \(requestBody.count) bytes")

        // Upload file
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            let responseString = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ File upload failed (status \(httpResponse.statusCode)): \(responseString)")

            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let error = json["error"] as? [String: Any],
               let message = error["message"] as? String {
                print("❌ File upload error: \(message)")
                throw GeminiError.apiErrorWithMessage(message)
            }
            throw GeminiError.apiError(statusCode: httpResponse.statusCode)
        }

        // Parse response to get file URI
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let file = json["file"] as? [String: Any],
              let uri = file["uri"] as? String else {
            let responseString = String(data: data, encoding: .utf8) ?? "Unknown response"
            print("❌ Could not parse file URI from upload response: \(responseString)")
            throw GeminiError.invalidResponse
        }

        print("✅ File uploaded successfully: \(uri)")
        return uri
    }

    private func pollVideoOperation(operationName: String) async throws -> Data {
        let maxAttempts = 120  // 10 minutes max (5 second intervals)
        var attempts = 0

        while attempts < maxAttempts {
            attempts += 1

            // Wait before polling
            try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds

            // Build polling URL
            let pollingEndpoint = "https://generativelanguage.googleapis.com/v1beta/\(operationName)"
            guard var urlComponents = URLComponents(string: pollingEndpoint) else {
                throw GeminiError.invalidURL
            }
            urlComponents.queryItems = [URLQueryItem(name: "key", value: apiKey)]
            guard let url = urlComponents.url else {
                throw GeminiError.invalidURL
            }

            // Make polling request
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                continue // Retry on error
            }

            guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                continue
            }

            // Check if operation is done
            if let done = json["done"] as? Bool, done {
                print("✅ Video generation complete!")

                // Extract video URI from response
                if let response = json["response"] as? [String: Any],
                   let predictions = response["predictions"] as? [[String: Any]],
                   let firstPrediction = predictions.first,
                   let video = firstPrediction["video"] as? [String: Any],
                   let videoURI = video["uri"] as? String {

                    print("📥 Downloading video from: \(videoURI)")

                    // Download video from URI
                    return try await downloadVideo(from: videoURI)
                } else {
                    print("❌ Could not extract video URI from response")
                    throw GeminiError.invalidResponse
                }
            } else {
                print("⏳ Still processing... (attempt \(attempts)/\(maxAttempts))")
            }
        }

        throw GeminiError.apiErrorWithMessage("Video generation timed out after \(maxAttempts * 5) seconds")
    }

    private func downloadVideo(from urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidURL
        }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GeminiError.networkError(NSError(domain: "Failed to download video", code: -1))
        }

        print("✅ Video downloaded: \(data.count) bytes")
        return data
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
