//
//  TryOnCacheManager.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import Foundation
import UIKit

class TryOnCacheManager {
    static let shared = TryOnCacheManager()

    private let fileManager = FileManager.default
    private var cacheDirectory: URL {
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        let tryOnDirectory = paths[0].appendingPathComponent("TryOnCache", isDirectory: true)

        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: tryOnDirectory.path) {
            try? fileManager.createDirectory(at: tryOnDirectory, withIntermediateDirectories: true)
        }

        return tryOnDirectory
    }

    private init() {}

    // MARK: - Save Garment Image
    /// Save a garment image to cache
    func saveGarment(_ image: UIImage, id: UUID = UUID()) -> URL? {
        let filename = "garment_\(id.uuidString).jpg"
        let fileURL = cacheDirectory.appendingPathComponent(filename)

        guard let data = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert garment image to JPEG")
            return nil
        }

        do {
            try data.write(to: fileURL)
            print("✅ Saved garment image: \(filename)")
            return fileURL
        } catch {
            print("❌ Failed to save garment image: \(error)")
            return nil
        }
    }

    // MARK: - Save Try-On Result
    /// Save a try-on result image to cache
    func saveTryOnResult(_ image: UIImage, id: UUID = UUID()) -> URL? {
        let filename = "tryon_\(id.uuidString).png"
        let fileURL = cacheDirectory.appendingPathComponent(filename)

        guard let data = image.pngData() else {
            print("❌ Failed to convert try-on image to PNG")
            return nil
        }

        do {
            try data.write(to: fileURL)
            print("✅ Saved try-on result: \(filename)")
            return fileURL
        } catch {
            print("❌ Failed to save try-on result: \(error)")
            return nil
        }
    }

    // MARK: - Save Try-On Video
    /// Save a try-on video to cache
    func saveTryOnVideo(_ videoData: Data, id: UUID = UUID()) -> URL? {
        let filename = "tryon_video_\(id.uuidString).mp4"
        let fileURL = cacheDirectory.appendingPathComponent(filename)

        do {
            try videoData.write(to: fileURL)
            print("✅ Saved try-on video: \(filename) (\(videoData.count / 1024 / 1024)MB)")
            return fileURL
        } catch {
            print("❌ Failed to save try-on video: \(error)")
            return nil
        }
    }

    // MARK: - Delete Image
    /// Delete an image from cache
    func deleteImage(at url: URL) -> Bool {
        do {
            try fileManager.removeItem(at: url)
            print("✅ Deleted image: \(url.lastPathComponent)")
            return true
        } catch {
            print("❌ Failed to delete image: \(error)")
            return false
        }
    }

    // MARK: - Clear All Cache
    /// Clear all try-on cache
    func clearAllCache() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for fileURL in contents {
                try fileManager.removeItem(at: fileURL)
            }
            print("✅ Cleared all try-on cache (\(contents.count) files)")
        } catch {
            print("❌ Failed to clear cache: \(error)")
        }
    }

    // MARK: - Get Cache Size
    /// Get total cache size in bytes
    func getCacheSize() -> Int64 {
        var totalSize: Int64 = 0

        do {
            let contents = try fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey])
            for fileURL in contents {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let fileSize = attributes[.size] as? Int64 {
                    totalSize += fileSize
                }
            }
        } catch {
            print("❌ Failed to calculate cache size: \(error)")
        }

        return totalSize
    }

    /// Get cache size in human-readable format
    func getFormattedCacheSize() -> String {
        let bytes = Double(getCacheSize())
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useAll]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
