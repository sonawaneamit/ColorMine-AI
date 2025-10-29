//
//  VisionService.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import Foundation
import Vision
import UIKit

class VisionService {
    static let shared = VisionService()

    private init() {}

    // MARK: - Detect Face with Landmarks
    func detectFaceLandmarks(in image: UIImage) async throws -> VNFaceObservation {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNDetectFaceLandmarksRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let observations = request.results as? [VNFaceObservation],
                      let faceObservation = observations.first else {
                    continuation.resume(throwing: VisionError.noFaceDetected)
                    return
                }

                // Check for multiple faces
                if observations.count > 1 {
                    continuation.resume(throwing: VisionError.multipleFacesDetected)
                    return
                }

                continuation.resume(returning: faceObservation)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    // MARK: - Extract Face Region
    func extractFaceRegion(from image: UIImage, faceObservation: VNFaceObservation) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        let boundingBox = faceObservation.boundingBox

        // Convert normalized coordinates to pixel coordinates
        let x = boundingBox.origin.x * imageSize.width
        let y = (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height
        let width = boundingBox.size.width * imageSize.width
        let height = boundingBox.size.height * imageSize.height

        let rect = CGRect(x: x, y: y, width: width, height: height)

        guard let croppedImage = cgImage.cropping(to: rect) else { return nil }

        return UIImage(cgImage: croppedImage)
    }
}

// MARK: - Vision Errors
enum VisionError: LocalizedError {
    case invalidImage
    case noFaceDetected
    case multipleFacesDetected
    case landmarksNotFound

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "Unable to process the image. Please try again."
        case .noFaceDetected:
            return "No face detected. Please ensure your face is clearly visible and well-lit."
        case .multipleFacesDetected:
            return "Multiple faces detected. Please ensure only your face is in the frame."
        case .landmarksNotFound:
            return "Unable to detect facial features. Please try again with better lighting."
        }
    }
}
