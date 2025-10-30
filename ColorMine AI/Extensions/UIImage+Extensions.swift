//
//  UIImage+Extensions.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import UIKit

extension UIImage {
    /// Fixes the image orientation by rendering it upright, then returns a mirrored version
    /// Used to mirror selfies from front camera so people see themselves as in a mirror
    func withHorizontallyFlippedOrientation() -> UIImage {
        // First, fix the orientation to render upright
        let fixedImage = self.fixedOrientation()

        // Then flip it horizontally
        return fixedImage.flipped() ?? fixedImage
    }

    /// Fixes image orientation by re-rendering it
    /// This ensures the image is displayed upright regardless of EXIF orientation
    func fixedOrientation() -> UIImage {
        // If already in correct orientation, return self
        if imageOrientation == .up {
            return self
        }

        // Render the image in the correct orientation
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }

        draw(in: CGRect(origin: .zero, size: size))

        return UIGraphicsGetImageFromCurrentImageContext() ?? self
    }

    private func flipOrientation(_ orientation: UIImage.Orientation) -> UIImage.Orientation {
        switch orientation {
        case .up:
            return .upMirrored
        case .upMirrored:
            return .up
        case .down:
            return .downMirrored
        case .downMirrored:
            return .down
        case .left:
            return .leftMirrored
        case .leftMirrored:
            return .left
        case .right:
            return .rightMirrored
        case .rightMirrored:
            return .right
        @unknown default:
            return .up
        }
    }

    /// Flips the image horizontally and returns a new UIImage (renders the flip)
    /// This actually creates a new image with the flip applied
    func flipped() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        defer { UIGraphicsEndImageContext() }

        guard let context = UIGraphicsGetCurrentContext() else { return nil }

        // Flip the context horizontally
        context.translateBy(x: self.size.width, y: 0)
        context.scaleBy(x: -1.0, y: 1.0)

        // Draw the image
        self.draw(at: .zero)

        return UIGraphicsGetImageFromCurrentImageContext()
    }
}
