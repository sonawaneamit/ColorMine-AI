//
//  CustomCameraView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import SwiftUI
import AVFoundation
import UIKit

struct CustomCameraView: View {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    @StateObject private var camera = CameraModel()

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(camera: camera)
                .ignoresSafeArea()

            // Overlay with oval guide
            GeometryReader { geometry in
                ZStack {
                    // Dark overlay with oval cutout
                    OvalCutoutOverlay()
                        .fill(style: FillStyle(eoFill: true))
                        .foregroundColor(Color.black.opacity(0.5))

                    // Oval guide stroke
                    Ellipse()
                        .strokeBorder(Color.white, lineWidth: 3)
                        .frame(
                            width: geometry.size.width * 0.7,
                            height: geometry.size.height * 0.5
                        )
                        .position(
                            x: geometry.size.width / 2,
                            y: geometry.size.height * 0.4
                        )

                    // Guide text
                    VStack {
                        Spacer()
                            .frame(height: geometry.size.height * 0.15)

                        Text("Position your face in the oval")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(8)

                        Spacer()
                    }
                }
            }

            // Controls
            VStack {
                // Top bar
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding()

                    Spacer()

                    Button(action: {
                        camera.switchCamera()
                    }) {
                        Image(systemName: "camera.rotate")
                            .font(.title2)
                            .foregroundColor(.white)
                            .padding()
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding()
                }

                Spacer()

                // Capture button
                Button(action: {
                    camera.capturePhoto { image in
                        if let image = image {
                            // Mirror the image (front camera)
                            capturedImage = image.withHorizontallyFlippedOrientation()
                            dismiss()
                        }
                    }
                }) {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 4)
                        .frame(width: 70, height: 70)
                        .overlay(
                            Circle()
                                .fill(Color.white)
                                .frame(width: 60, height: 60)
                        )
                }
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            camera.checkPermissions()
            camera.setupCamera()
        }
        .onDisappear {
            camera.stopSession()
        }
    }
}

// MARK: - Oval Cutout Overlay Shape
struct OvalCutoutOverlay: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        // Full rectangle
        path.addRect(rect)

        // Oval cutout
        let ovalWidth = rect.width * 0.7
        let ovalHeight = rect.height * 0.5
        let ovalX = (rect.width - ovalWidth) / 2
        let ovalY = rect.height * 0.4 - ovalHeight / 2

        let ovalRect = CGRect(x: ovalX, y: ovalY, width: ovalWidth, height: ovalHeight)
        path.addEllipse(in: ovalRect)

        return path
    }
}

// MARK: - Camera Preview
struct CameraPreview: UIViewRepresentable {
    @ObservedObject var camera: CameraModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)

        camera.preview = AVCaptureVideoPreviewLayer(session: camera.session)
        camera.preview.frame = view.bounds
        camera.preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(camera.preview)

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            camera.preview.frame = uiView.bounds
        }
    }
}

// MARK: - Camera Model
class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var session = AVCaptureSession()
    @Published var preview = AVCaptureVideoPreviewLayer()
    @Published var isCameraAuthorized = false

    private var output = AVCapturePhotoOutput()
    private var currentCamera: AVCaptureDevice.Position = .front
    private var captureCompletion: ((UIImage?) -> Void)?

    // MARK: - Check Permissions
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            isCameraAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.isCameraAuthorized = granted
                }
            }
        default:
            isCameraAuthorized = false
        }
    }

    // MARK: - Setup Camera
    func setupCamera() {
        session.beginConfiguration()

        // Remove existing inputs
        session.inputs.forEach { session.removeInput($0) }

        // Setup input (front camera)
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCamera),
              let input = try? AVCaptureDeviceInput(device: device) else {
            session.commitConfiguration()
            return
        }

        if session.canAddInput(input) {
            session.addInput(input)
        }

        // Setup output
        if session.canAddOutput(output) {
            session.addOutput(output)
        }

        session.commitConfiguration()

        // Start session on background thread
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.session.startRunning()
        }
    }

    // MARK: - Switch Camera
    func switchCamera() {
        currentCamera = currentCamera == .front ? .back : .front
        setupCamera()
    }

    // MARK: - Capture Photo
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        self.captureCompletion = completion

        let settings = AVCapturePhotoSettings()
        output.capturePhoto(with: settings, delegate: self)
    }

    // MARK: - Photo Capture Delegate
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            captureCompletion?(nil)
            return
        }

        captureCompletion?(image)
    }

    // MARK: - Stop Session
    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.session.stopRunning()
            }
        }
    }
}
