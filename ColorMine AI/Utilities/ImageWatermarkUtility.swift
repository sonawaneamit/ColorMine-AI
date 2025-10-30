//
//  ImageWatermarkUtility.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import UIKit

class ImageWatermarkUtility {
    static let shared = ImageWatermarkUtility()

    private init() {}

    /// Adds a watermark to an image with ColorMineAI.com branding
    func addWatermark(to image: UIImage) -> UIImage {
        // Use higher scale for better quality rendering
        let scale = max(image.scale, UIScreen.main.scale)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = false
        format.preferredRange = .standard

        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)

        let watermarkedImage = renderer.image { context in
            let cgContext = context.cgContext

            // Enable high-quality rendering
            cgContext.setAllowsAntialiasing(true)
            cgContext.setShouldAntialias(true)
            cgContext.interpolationQuality = .high
            cgContext.setAllowsFontSmoothing(true)
            cgContext.setShouldSmoothFonts(true)

            // Draw original image
            image.draw(at: .zero)

            // Configure watermark style
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            // Add text watermark - just the URL
            let text = "ColorMineAI.com"
            // Scale font size based on image dimensions for better proportions
            let fontSize: CGFloat = min(image.size.width, image.size.height) * 0.03
            let font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)

            // First pass: draw shadow for depth (no stroke)
            let shadowAttributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.black.withAlphaComponent(0.6),
                .paragraphStyle: paragraphStyle
            ]

            // Main text attributes: clean white text without stroke
            let textAttributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]

            // Position watermark in bottom center
            let textSize = text.size(withAttributes: textAttributes)
            let padding: CGFloat = max(20, image.size.height * 0.02)
            let xPosition = (image.size.width - textSize.width) / 2
            let yPosition = image.size.height - textSize.height - padding

            let textRect = CGRect(
                x: xPosition,
                y: yPosition,
                width: textSize.width,
                height: textSize.height
            )

            // Add semi-transparent rounded background for better readability
            let backgroundRect = textRect.insetBy(dx: -16, dy: -10)
            let backgroundPath = UIBezierPath(roundedRect: backgroundRect, cornerRadius: 12)
            cgContext.setFillColor(UIColor.black.withAlphaComponent(0.65).cgColor)
            cgContext.addPath(backgroundPath.cgPath)
            cgContext.fillPath()

            // Draw shadow text (slightly offset)
            let shadowRect = textRect.offsetBy(dx: 1, dy: 1)
            text.draw(in: shadowRect, withAttributes: shadowAttributes)

            // Draw main text (clean, no stroke)
            text.draw(in: textRect, withAttributes: textAttributes)
        }

        return watermarkedImage
    }

    /// Shares an image with watermark using UIActivityViewController
    func shareImage(_ image: UIImage, from viewController: UIViewController) {
        let watermarkedImage = addWatermark(to: image)

        let activityViewController = UIActivityViewController(
            activityItems: [watermarkedImage],
            applicationActivities: nil
        )

        // For iPad support
        if let popoverController = activityViewController.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }

        viewController.present(activityViewController, animated: true)
    }

    /// Saves an image with watermark to photo library
    func saveImageToLibrary(_ image: UIImage, completion: @escaping (Bool, Error?) -> Void) {
        let watermarkedImage = addWatermark(to: image)

        UIImageWriteToSavedPhotosAlbum(
            watermarkedImage,
            nil,
            nil,
            nil
        )

        // Simple completion callback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            completion(true, nil)
        }
    }
}
