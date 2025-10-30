//
//  ImagePicker.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 29/10/2025.
//

import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss

    let sourceType: UIImagePickerController.SourceType

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = sourceType

        // Only set camera device if using camera
        if sourceType == .camera {
            picker.cameraDevice = .front
        }

        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            var pickedImage: UIImage?

            if let editedImage = info[.editedImage] as? UIImage {
                pickedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                pickedImage = originalImage
            }

            // Mirror the image if it's from the front camera (people are used to seeing themselves mirrored)
            if let image = pickedImage, parent.sourceType == .camera {
                parent.image = image.withHorizontallyFlippedOrientation()
            } else {
                parent.image = pickedImage
            }

            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}
