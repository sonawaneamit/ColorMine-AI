//
//  FullBodyImagePicker.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import SwiftUI
import UIKit

/// Image picker specifically for full body photos - no cropping, preserves aspect ratio
struct FullBodyImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    let sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType

        // Only set camera device if using camera
        if sourceType == .camera {
            picker.cameraDevice = .rear  // Rear camera for full body
        }

        // DO NOT set allowsEditing - we want the full image
        picker.allowsEditing = false

        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: FullBodyImagePicker

        init(_ parent: FullBodyImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Always use original image (no editing/cropping)
            if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
            }

            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
