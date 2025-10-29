//
//  ImageCacheManager.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import Foundation
import UIKit

class ImageCacheManager {
    static let shared = ImageCacheManager()

    private let fileManager = FileManager.default
    private var cacheDirectory: URL

    private init() {
        // Create cache directory
        let paths = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("AIImageCache", isDirectory: true)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Save AI Image
    func saveAIImage(_ image: UIImage, for packType: PackType, userID: UUID) -> URL? {
        guard let imageData = image.jpegData(compressionQuality: 0.9) else {
            return nil
        }

        let filename = "\(userID.uuidString)_\(packType.rawValue).jpg"
        let fileURL = cacheDirectory.appendingPathComponent(filename)

        do {
            try imageData.write(to: fileURL)
            print("✅ Saved \(packType.rawValue) to cache")
            return fileURL
        } catch {
            print("❌ Failed to save image: \(error)")
            return nil
        }
    }

    // MARK: - Load AI Image
    func loadAIImage(for packType: PackType, userID: UUID) -> UIImage? {
        let filename = "\(userID.uuidString)_\(packType.rawValue).jpg"
        let fileURL = cacheDirectory.appendingPathComponent(filename)

        guard fileManager.fileExists(atPath: fileURL.path),
              let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) else {
            return nil
        }

        return image
    }

    // MARK: - Delete Image
    func deleteImage(for packType: PackType, userID: UUID) {
        let filename = "\(userID.uuidString)_\(packType.rawValue).jpg"
        let fileURL = cacheDirectory.appendingPathComponent(filename)

        try? fileManager.removeItem(at: fileURL)
    }

    // MARK: - Clear All Cache
    func clearAllCache() {
        guard let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) else {
            return
        }

        for file in contents {
            try? fileManager.removeItem(at: file)
        }

        print("✅ Cleared all cached images")
    }

    // MARK: - Get Cache Size
    func getCacheSize() -> Int64 {
        guard let contents = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }

        var totalSize: Int64 = 0
        for file in contents {
            if let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(size)
            }
        }

        return totalSize
    }
}
