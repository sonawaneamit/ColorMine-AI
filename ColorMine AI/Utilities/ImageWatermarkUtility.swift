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
        let renderer = UIGraphicsImageRenderer(size: image.size)

        let watermarkedImage = renderer.image { context in
            // Draw original image
            image.draw(at: .zero)

            // Configure watermark style
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            // Add text watermark - just the URL
            let text = "ColorMineAI.com"
            let fontSize: CGFloat = image.size.width > 1000 ? 32 : 24
            let font = UIFont.systemFont(ofSize: fontSize, weight: .bold)

            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle,
                .strokeColor: UIColor.black.withAlphaComponent(0.7),
                .strokeWidth: -3.0
            ]

            // Position watermark in bottom right corner
            let textSize = text.size(withAttributes: attributes)
            let padding: CGFloat = 20
            let xPosition = image.size.width - textSize.width - padding
            let yPosition = image.size.height - textSize.height - padding

            let textRect = CGRect(
                x: xPosition,
                y: yPosition,
                width: textSize.width,
                height: textSize.height
            )

            // Add semi-transparent background for better readability
            let backgroundRect = textRect.insetBy(dx: -12, dy: -8)
            let backgroundPath = UIBezierPath(roundedRect: backgroundRect, cornerRadius: 10)
            context.cgContext.setFillColor(UIColor.black.withAlphaComponent(0.5).cgColor)
            backgroundPath.fill()

            // Draw text
            text.draw(in: textRect, withAttributes: attributes)
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
