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
            paragraphStyle.alignment = .right

            // Try to load app icon
            let hasIcon = addAppIcon(context: context, imageSize: image.size)

            // Add text watermark
            let text = "ColorMineAI.com"
            let fontSize: CGFloat = image.size.width > 1000 ? 28 : 20
            let font = UIFont.systemFont(ofSize: fontSize, weight: .semibold)

            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle,
                .strokeColor: UIColor.black.withAlphaComponent(0.5),
                .strokeWidth: -2.0
            ]

            // Position watermark in bottom right corner
            let textSize = text.size(withAttributes: attributes)
            let padding: CGFloat = 20
            let xPosition = hasIcon ? image.size.width - textSize.width - 80 - padding : image.size.width - textSize.width - padding
            let yPosition = image.size.height - textSize.height - padding

            let textRect = CGRect(
                x: xPosition,
                y: yPosition,
                width: textSize.width,
                height: textSize.height
            )

            // Add semi-transparent background for better readability
            let backgroundRect = textRect.insetBy(dx: -10, dy: -5)
            let backgroundPath = UIBezierPath(roundedRect: backgroundRect, cornerRadius: 8)
            context.cgContext.setFillColor(UIColor.black.withAlphaComponent(0.4).cgColor)
            backgroundPath.fill()

            // Draw text
            text.draw(in: textRect, withAttributes: attributes)
        }

        return watermarkedImage
    }

    /// Attempts to add app icon to the watermark
    private func addAppIcon(context: UIGraphicsImageRendererContext, imageSize: CGSize) -> Bool {
        // Try to load app icon from asset catalog or bundle
        if let appIcon = UIImage(named: "AppIcon") ?? getAppIcon() {
            let iconSize: CGFloat = imageSize.width > 1000 ? 60 : 50
            let padding: CGFloat = 20

            let iconRect = CGRect(
                x: imageSize.width - iconSize - padding,
                y: imageSize.height - iconSize - padding,
                width: iconSize,
                height: iconSize
            )

            // Draw white background circle for icon
            context.cgContext.setFillColor(UIColor.white.cgColor)
            context.cgContext.fillEllipse(in: iconRect.insetBy(dx: -3, dy: -3))

            // Draw icon with rounded corners
            let clipPath = UIBezierPath(roundedRect: iconRect, cornerRadius: iconSize * 0.2)
            clipPath.addClip()
            appIcon.draw(in: iconRect)

            return true
        }

        return false
    }

    /// Attempts to get app icon from bundle
    private func getAppIcon() -> UIImage? {
        // Try to get app icon from Info.plist
        if let icons = Bundle.main.object(forInfoDictionaryKey: "CFBundleIcons") as? [String: Any],
           let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
           let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
           let lastIcon = iconFiles.last {
            return UIImage(named: lastIcon)
        }

        return nil
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
