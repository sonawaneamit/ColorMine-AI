//
//  UIImage+Extensions.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import UIKit

extension UIImage {
    /// Returns a horizontally flipped version of the image (mirrored)
    /// Used to mirror selfies from front camera so people see themselves as in a mirror
    func withHorizontallyFlippedOrientation() -> UIImage {
        guard let cgImage = self.cgImage else { return self }

        // Create a new image with flipped orientation
        return UIImage(cgImage: cgImage, scale: self.scale, orientation: flipOrientation(self.imageOrientation))
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
