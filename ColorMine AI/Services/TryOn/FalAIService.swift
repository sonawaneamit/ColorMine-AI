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
    private let endpoint = "https://fal.run/fal-ai/fashn/tryon/v1.6"

    private init() {}

    /// Generate virtual try-on using fal.ai FASHN API
    /// - Parameters:
    ///   - modelPhoto: User's full body photo
    ///   - garmentPhoto: Clothing item image
    /// - Returns: Photorealistic try-on result image
    func generateTryOn(
        modelPhoto: UIImage,
        garmentPhoto: UIImage
    ) async throws -> UIImage {

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
            "category": "auto",           // Auto-detect garment type
            "mode": "balanced",           // Balance between speed/quality
            "garment_photo_type": "auto", // Auto-detect flat-lay vs model
            "num_samples": 1,             // Generate 1 image
            "output_format": "png"        // Highest quality
        ]

        // 3. Create request
        guard let url = URL(string: endpoint) else {
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
    case imageDownloadFailed
    case failedToSave

    var errorDescription: String? {
        switch self {
        case .imageConversionFailed(let image):
            return "Couldn't process your \(image) photo. Please try again."
        case .invalidEndpoint:
            return "Invalid service endpoint. Please contact support."
        case .apiRequestFailed(let code):
            return "Try-on service unavailable (Error \(code)). Please try again later."
        case .apiError(let message, _):
            return message
        case .invalidResponse:
            return "Unexpected response from try-on service."
        case .jsonParsingFailed:
            return "Couldn't parse service response."
        case .invalidImageURL:
            return "Couldn't locate your try-on result."
        case .imageDownloadFailed:
            return "Couldn't download your try-on result. Check your internet connection."
        case .failedToSave:
            return "Couldn't save your try-on result to storage."
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .imageConversionFailed:
            return "Make sure your photos are clear and not corrupted."
        case .apiRequestFailed, .apiError:
            return "Try again in a moment. If the problem persists, contact support."
        case .imageDownloadFailed:
            return "Check your internet connection and try again."
        default:
            return "Please try again or contact support if the issue continues."
        }
    }
}
