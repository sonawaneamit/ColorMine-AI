//
//  FalAIService.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import Foundation
import UIKit

class FalAIService {
    static let shared = FalAIService()

    private let apiKey = APIKeys.falAIKey
    private let tryOnEndpoint = "https://fal.run/fal-ai/fashn/tryon/v1.6"
    private let videoEndpoint = "https://fal.run/fal-ai/veo3.1/fast/first-last-frame-to-video"

    // Using Gemini for virtual try-on generation (per user requirement)
    // Gemini 2.5 Flash for try-on images, fal.ai Veo 3.1 for videos
    private let useGeminiForTryOn = true  // ✅ Using Gemini Nano Banana

    // Use fal.ai Veo 3.1 for video generation (Gemini not working)
    private let useGeminiForVideo = false  // ✅ Using fal.ai Veo 3.1

    private init() {}

    /// Generate virtual try-on using either Gemini Nano Banana or fal.ai FASHN API
    /// - Parameters:
    ///   - modelPhoto: User's full body photo
    ///   - garmentPhoto: Clothing item image
    /// - Returns: Photorealistic try-on result image
    func generateTryOn(
        modelPhoto: UIImage,
        garmentPhoto: UIImage
    ) async throws -> UIImage {

        // Use Gemini Nano Banana if enabled (better quality and control)
        if useGeminiForTryOn {
            print("🎨 Using Gemini Nano Banana for try-on generation...")
            return try await GeminiService.shared.generateTryOn(
                personPhoto: modelPhoto,
                garmentPhoto: garmentPhoto
            )
        }

        // Otherwise use fal.ai FASHN (original implementation)
        print("🎨 Starting fal.ai try-on generation...")

        // 1. Convert images to base64
        guard let modelBase64 = modelPhoto.jpegData(compressionQuality: 0.8)?
            .base64EncodedString() else {
            throw TryOnError.imageConversionFailed(image: "model")
        }

        guard let garmentBase64 = garmentPhoto.jpegData(compressionQuality: 0.8)?
            .base64EncodedString() else {
            throw TryOnError.imageConversionFailed(image: "garment")
        }

        // 2. Build request body
        let requestBody: [String: Any] = [
            "model_image": "data:image/jpeg;base64,\(modelBase64)",
            "garment_image": "data:image/jpeg;base64,\(garmentBase64)",
            "category": "tops",           // Most garments are tops; helps prevent lower body errors
            "mode": "quality",            // Higher quality for better segmentation (slower but more accurate)
            "garment_photo_type": "auto", // Auto-detect flat-lay vs model (works with both)
            "num_samples": 1,             // Generate 1 image
            "output_format": "png"        // Highest quality
        ]

        // 3. Create request
        guard let url = URL(string: tryOnEndpoint) else {
            throw TryOnError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 60 // 60 second timeout

        print("📤 Sending request to fal.ai...")

        // 4. Make API request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TryOnError.invalidResponse
        }

        print("📥 Response status code: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            // Try to parse error message
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["detail"] as? String {
                throw TryOnError.apiError(message: errorMessage, statusCode: httpResponse.statusCode)
            }
            throw TryOnError.apiRequestFailed(statusCode: httpResponse.statusCode)
        }

        // 5. Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TryOnError.jsonParsingFailed
        }

        guard let images = json["images"] as? [[String: Any]],
              let firstImage = images.first,
              let imageUrlString = firstImage["url"] as? String,
              let imageUrl = URL(string: imageUrlString) else {
            print("❌ Invalid JSON structure: \(json)")
            throw TryOnError.invalidImageURL
        }

        print("🔗 Image URL received: \(imageUrlString)")

        // 6. Download result image
        print("⬇️ Downloading result image...")
        let (imageData, _) = try await URLSession.shared.data(from: imageUrl)

        guard let resultImage = UIImage(data: imageData) else {
            throw TryOnError.imageDownloadFailed
        }

        print("✅ Try-on generation complete! Image size: \(resultImage.size)")

        return resultImage
    }

    /// Generate video from try-on result using either Gemini Veo 3.1 or fal.ai
    /// - Parameters:
    ///   - tryOnImage: The try-on result image to animate
    ///   - prompt: Optional custom prompt (default: fashion model animation)
    /// - Returns: Video data (MP4)
    func generateTryOnVideo(
        tryOnImage: UIImage,
        prompt: String? = nil
    ) async throws -> Data {

        // Use Gemini Veo 3.1 if enabled (same model, better integration)
        if useGeminiForVideo {
            print("🎬 Using Gemini Veo 3.1 for video generation...")
            return try await GeminiService.shared.generateVideo(
                from: tryOnImage,
                prompt: prompt
            )
        }

        // Otherwise use fal.ai Veo 3.1 (first-last-frame-to-video)
        print("🎬 Starting fal.ai Veo 3.1 video generation...")

        // 1. Convert image to base64 data URL
        guard let imageData = tryOnImage.jpegData(compressionQuality: 0.9),
              imageData.count <= 8_000_000 else { // 8MB limit
            throw TryOnError.imageConversionFailed(image: "try-on result")
        }

        let base64Image = imageData.base64EncodedString()
        let dataURL = "data:image/jpeg;base64,\(base64Image)"

        // 2. Build request body (using same image for first and last frame to animate from single image)
        let defaultPrompt = "The person slowly turns and poses naturally to showcase the outfit from different angles, smooth fashion model movement, professional photoshoot"

        let requestBody: [String: Any] = [
            "first_frame_url": dataURL,       // Start frame
            "last_frame_url": dataURL,        // End frame (same as start for single image animation)
            "prompt": prompt ?? defaultPrompt,
            "aspect_ratio": "9:16",           // Portrait for mobile
            "duration": "8s",                 // 8 seconds
            "resolution": "720p",             // 720p for balance
            "generate_audio": false           // No audio to save cost (~$0.80)
        ]

        // 3. Create request
        guard let url = URL(string: videoEndpoint) else {
            throw TryOnError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Key \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 120 // 2 minute timeout for video processing

        print("📤 Sending video generation request to fal.ai Veo 3.1...")

        // 4. Make API request
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw TryOnError.invalidResponse
        }

        print("📥 Video response status code: \(httpResponse.statusCode)")

        guard httpResponse.statusCode == 200 else {
            // Try to parse error message
            if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorMessage = errorJson["detail"] as? String {
                throw TryOnError.apiError(message: errorMessage, statusCode: httpResponse.statusCode)
            }
            throw TryOnError.apiRequestFailed(statusCode: httpResponse.statusCode)
        }

        // 5. Parse response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw TryOnError.jsonParsingFailed
        }

        guard let video = json["video"] as? [String: Any],
              let videoUrlString = video["url"] as? String,
              let videoUrl = URL(string: videoUrlString) else {
            print("❌ Invalid video JSON structure: \(json)")
            throw TryOnError.invalidVideoURL
        }

        print("🔗 Video URL received: \(videoUrlString)")

        // 6. Download video
        print("⬇️ Downloading video...")
        let (videoData, _) = try await URLSession.shared.data(from: videoUrl)

        print("✅ Video generation complete! Size: \(videoData.count / 1024 / 1024)MB")

        return videoData
    }
}

// MARK: - Error Types
enum TryOnError: LocalizedError {
    case imageConversionFailed(image: String)
    case invalidEndpoint
    case apiRequestFailed(statusCode: Int)
    case apiError(message: String, statusCode: Int)
    case invalidResponse
    case jsonParsingFailed
    case invalidImageURL
    case invalidVideoURL
    case imageDownloadFailed
    case videoDownloadFailed
    case failedToSave

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed(let image):
            return "Couldn't process your \(image) photo. Please try again."
        case .invalidEndpoint:
            return "Invalid service endpoint. Please contact support."
        case .apiRequestFailed(let code):
            return "Service unavailable (Error \(code)). Please try again later."
        case .apiError(let message, _):
            return message
        case .invalidResponse:
            return "Unexpected response from service."
        case .jsonParsingFailed:
            return "Couldn't parse service response."
        case .invalidImageURL:
            return "Couldn't locate your try-on result."
        case .invalidVideoURL:
            return "Couldn't locate your video result."
        case .imageDownloadFailed:
            return "Couldn't download your try-on result. Check your internet connection."
        case .videoDownloadFailed:
            return "Couldn't download your video. Check your internet connection."
        case .failedToSave:
            return "Couldn't save your result to storage."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .imageConversionFailed:
            return "Make sure your photos are clear and not corrupted."
        case .apiRequestFailed, .apiError:
            return "Try again in a moment. If the problem persists, contact support."
        case .imageDownloadFailed, .videoDownloadFailed:
            return "Check your internet connection and try again."
        default:
            return "Please try again or contact support if the issue continues."
        }
    }
}
