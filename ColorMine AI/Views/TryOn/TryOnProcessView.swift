//
//  TryOnProcessView.swift
//  ColorMine AI
//
//  Created by ColorMine Team on 30/10/2025.
//

import SwiftUI

struct TryOnProcessView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    let garment: GarmentItem

    @State private var isProcessing = false
    @State private var processingProgress: Double = 0.0
    @State private var statusMessage = "Preparing your Try-On..."
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var tryOnResult: TryOnResult?
    @State private var showResult = false
    @State private var showCreditsPurchase = false
    @State private var showCropView = false
    @State private var croppedGarmentImage: UIImage?

    private var currentCredits: Int {
        appState.currentProfile?.tryOnCredits ?? 0
    }

    private var hasEnoughCredits: Bool {
        currentCredits >= 1
    }

    private var isReadyForTryOn: Bool {
        croppedGarmentImage != nil && hasEnoughCredits
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer()

                    // Garment preview
                    if let imageData = try? Data(contentsOf: garment.imageURL),
                       let image = UIImage(data: imageData) {
                        VStack(spacing: 16) {
                            Image(uiImage: croppedGarmentImage ?? image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.1), radius: 10)

                            if croppedGarmentImage == nil {
                                Text("⚠️ Crop required to remove text and background")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.orange)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 40)
                            } else {
                                Button(action: {
                                    showCropView = true
                                }) {
                                    Text("Adjust Crop")
                                        .font(.caption)
                                        .foregroundColor(.purple)
                                }
                            }
                        }
                    }

                    // Status
                    VStack(spacing: 12) {
                        if isProcessing {
                            ProgressView(value: processingProgress)
                                .progressViewStyle(.linear)
                                .tint(.purple)
                                .frame(width: 200)
                        }

                        Text(statusMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }

                    Spacer()

                    // Credit Balance Card
                    VStack(spacing: 16) {
                        // Current balance
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Your Balance")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .foregroundColor(.purple)
                                    Text(CreditsManager.formatCredits(currentCredits))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                }
                            }

                            Spacer()

                            // Cost indicator
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Cost")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Text("1 credit")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.purple)
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)

                        // Warning if no credits
                        if !hasEnoughCredits {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text("You need at least 1 credit to Try-On")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)

                    // Action button (transforms based on state)
                    VStack(spacing: 12) {
                        Button(action: {
                            if !hasEnoughCredits {
                                showCreditsPurchase = true
                                HapticManager.shared.buttonTap()
                            } else if croppedGarmentImage == nil {
                                showCropView = true
                                HapticManager.shared.buttonTap()
                            } else {
                                startTryOn()
                            }
                        }) {
                            HStack {
                                if !hasEnoughCredits {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Get Credits")
                                } else if croppedGarmentImage == nil {
                                    Image(systemName: "crop")
                                    Text("Crop Garment")
                                } else {
                                    Image(systemName: "wand.and.stars")
                                    Text("Try It On")
                                }
                            }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(isProcessing)
                        .padding(.horizontal, 40)

                        Button("Cancel") {
                            dismiss()
                        }
                        .disabled(isProcessing)
                        .foregroundColor(.secondary)
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Virtual Try-On")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isProcessing {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .alert("Oops!", isPresented: $showError) {
                Button("OK", role: .cancel) {
                    isProcessing = false
                }
            } message: {
                Text(errorMessage)
            }
            .fullScreenCover(isPresented: $showResult) {
                if let result = tryOnResult {
                    TryOnResultView(result: result)
                }
            }
            .fullScreenCover(isPresented: $showCreditsPurchase) {
                NavigationStack {
                    CreditsPurchaseView()
                }
            }
            .fullScreenCover(isPresented: $showCropView) {
                if let imageData = try? Data(contentsOf: garment.imageURL),
                   let image = UIImage(data: imageData) {
                    NativeCropView(image: image, croppedImage: $croppedGarmentImage)
                }
            }
        }
    }

    // MARK: - Start Try-On
    private func startTryOn() {
        guard var profile = appState.currentProfile else {
            errorMessage = "No profile found. Please set up your profile first."
            showError = true
            return
        }

        // Check credits - if insufficient, show purchase sheet
        guard profile.tryOnCredits >= 1 else {
            showCreditsPurchase = true
            HapticManager.shared.buttonTap()
            return
        }

        // Check full body photo
        guard let fullBodyImage = profile.fullBodyImage else {
            errorMessage = "Please upload a full body photo first in settings."
            showError = true
            return
        }

        // Use cropped garment image
        guard let garmentImage = croppedGarmentImage else {
            errorMessage = "Please crop the garment image first."
            showError = true
            return
        }

        isProcessing = true
        statusMessage = "Preparing your Try-On..."
        processingProgress = 0.1

        Task {
            do {
                // Analyze garment color if not already analyzed
                var updatedGarment = garment
                if garment.colorMatchScore == nil {
                    await updateProgress(0.2, message: "Analyzing garment colors...")

                    do {
                        let analysis = try await OpenAIService.shared.analyzeGarmentColor(
                            garmentImage: garmentImage,
                            userSeason: profile.season
                        )

                        // Update garment with analysis
                        updatedGarment.matchesUserSeason = analysis.matchScore >= 70
                        updatedGarment.colorMatchScore = analysis.matchScore

                        // Update in profile
                        if let index = profile.savedGarments.firstIndex(where: { $0.id == garment.id }) {
                            profile.savedGarments[index] = updatedGarment
                            appState.saveProfile(profile)
                        }

                        // Analysis results already logged by OpenAIService
                    } catch {
                        print("⚠️ Failed to analyze garment color, continuing anyway: \(error.localizedDescription)")
                    }
                }

                // Simulate progress updates
                await updateProgress(0.3, message: "Uploading images...")
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5s

                await updateProgress(0.5, message: "Generating photorealistic Try-On...")

                // Call fal.ai API
                let resultImage = try await FalAIService.shared.generateTryOn(
                    modelPhoto: fullBodyImage,
                    garmentPhoto: garmentImage
                )

                await updateProgress(0.8, message: "Analyzing colors...")
                try await Task.sleep(nanoseconds: 300_000_000) // 0.3s

                // Save result to cache
                guard let resultURL = TryOnCacheManager.shared.saveTryOnResult(resultImage) else {
                    throw TryOnError.failedToSave
                }

                // Create result object (use updated garment with color analysis)
                let result = TryOnResult(
                    id: UUID(),
                    garmentItem: updatedGarment,
                    resultImageURL: resultURL,
                    createdAt: Date(),
                    creditsUsed: 1  // 1 credit = 1 try-on
                )

                // Deduct credits and save
                profile.tryOnCredits -= 1  // 1 credit = 1 try-on
                profile.tryOnHistory.append(result)
                appState.saveProfile(profile)

                await updateProgress(1.0, message: "Ready!")

                // Haptic feedback
                HapticManager.shared.success()

                // Show result
                await MainActor.run {
                    tryOnResult = result
                    showResult = true
                    dismiss()
                }

                print("✅ Try-on completed: \(result.id)")

            } catch {
                await MainActor.run {
                    isProcessing = false
                    errorMessage = "Try-on failed: \(error.localizedDescription)"
                    showError = true
                    print("❌ Try-on error: \(error)")
                }
            }
        }
    }

    @MainActor
    private func updateProgress(_ progress: Double, message: String) async {
        processingProgress = progress
        statusMessage = message
    }
}

// MARK: - Native iOS Photos App-Style Crop (UIKit)
struct NativeCropView: UIViewControllerRepresentable {
    let image: UIImage
    @Binding var croppedImage: UIImage?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UINavigationController {
        let cropVC = CropViewController(image: image)
        cropVC.delegate = context.coordinator
        let navController = UINavigationController(rootViewController: cropVC)
        navController.navigationBar.barStyle = .black
        navController.navigationBar.tintColor = .white
        navController.navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        return navController
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CropViewControllerDelegate {
        let parent: NativeCropView

        init(_ parent: NativeCropView) {
            self.parent = parent
        }

        func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage) {
            parent.croppedImage = image
            parent.dismiss()
        }

        func cropViewControllerDidCancel(_ cropViewController: CropViewController) {
            parent.dismiss()
        }
    }
}

// MARK: - UIKit Crop View Controller (Photos App Style)
protocol CropViewControllerDelegate: AnyObject {
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage)
    func cropViewControllerDidCancel(_ cropViewController: CropViewController)
}

class CropViewController: UIViewController {
    weak var delegate: CropViewControllerDelegate?

    private let image: UIImage
    private var scrollView: UIScrollView!
    private var imageView: UIImageView!
    private var cropOverlay: CropOverlayView!

    init(image: UIImage) {
        self.image = image
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        // Setup scroll view for zoom/pan
        scrollView = UIScrollView(frame: view.bounds)
        scrollView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scrollView.delegate = self
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 5.0
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        // Setup image view
        imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = scrollView.bounds
        scrollView.addSubview(imageView)

        // Setup crop overlay
        cropOverlay = CropOverlayView(frame: view.bounds)
        cropOverlay.isUserInteractionEnabled = true
        view.addSubview(cropOverlay)

        // Setup navigation bar
        setupNavigationBar()
    }

    private func setupNavigationBar() {
        title = "Adjust Crop"

        // Cancel button with icon
        let cancelButton = UIBarButtonItem(
            image: UIImage(systemName: "xmark"),
            style: .plain,
            target: self,
            action: #selector(cancelTapped)
        )
        navigationItem.leftBarButtonItem = cancelButton

        // Done button with checkmark icon and bold text
        let doneButton = UIBarButtonItem(
            image: UIImage(systemName: "checkmark"),
            style: .done,
            target: self,
            action: #selector(doneTapped)
        )
        navigationItem.rightBarButtonItem = doneButton

        // Style the navigation bar
        navigationController?.navigationBar.tintColor = .systemBlue
    }

    @objc private func cancelTapped() {
        delegate?.cropViewControllerDidCancel(self)
    }

    @objc private func doneTapped() {
        let croppedImage = performCrop()
        delegate?.cropViewController(self, didCropToImage: croppedImage)
    }

    private func performCrop() -> UIImage {
        let cropRect = cropOverlay.cropRect
        let zoomScale = scrollView.zoomScale
        let contentOffset = scrollView.contentOffset

        // Calculate crop rect in image coordinates
        let imageViewSize = imageView.frame.size
        let imageSize = image.size

        let scaleX = imageSize.width / imageViewSize.width
        let scaleY = imageSize.height / imageViewSize.height

        let x = (cropRect.origin.x + contentOffset.x) * scaleX / zoomScale
        let y = (cropRect.origin.y + contentOffset.y) * scaleY / zoomScale
        let width = cropRect.width * scaleX / zoomScale
        let height = cropRect.height * scaleY / zoomScale

        let cropRectInImage = CGRect(x: x, y: y, width: width, height: height)

        guard let cgImage = image.cgImage?.cropping(to: cropRectInImage) else {
            return image
        }

        return UIImage(cgImage: cgImage, scale: image.scale, orientation: image.imageOrientation)
    }
}

extension CropViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
}

// MARK: - Crop Overlay View
class CropOverlayView: UIView {
    var cropRect: CGRect = .zero

    private var cornerHandles: [UIView] = []
    private var edgeHandles: [UIView] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCropArea()
        backgroundColor = .clear
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        // Initialize crop rect if needed
        if cropRect == .zero {
            let width: CGFloat = 300
            let height: CGFloat = 400
            cropRect = CGRect(
                x: (bounds.width - width) / 2,
                y: (bounds.height - height) / 2,
                width: width,
                height: height
            )
        }

        updateHandlePositions()
    }

    private func setupCropArea() {
        isUserInteractionEnabled = true

        // Create corner handles
        for _ in 0..<4 {
            let handle = UIView(frame: CGRect(x: 0, y: 0, width: 30, height: 30))
            handle.backgroundColor = .white
            handle.layer.cornerRadius = 15
            handle.layer.borderWidth = 3
            handle.layer.borderColor = UIColor.systemPurple.cgColor
            addSubview(handle)
            cornerHandles.append(handle)

            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            handle.addGestureRecognizer(pan)
        }
    }

    private func updateHandlePositions() {
        guard cornerHandles.count == 4 else { return }

        // Position corner handles
        cornerHandles[0].center = CGPoint(x: cropRect.minX, y: cropRect.minY) // TL
        cornerHandles[1].center = CGPoint(x: cropRect.maxX, y: cropRect.minY) // TR
        cornerHandles[2].center = CGPoint(x: cropRect.minX, y: cropRect.maxY) // BL
        cornerHandles[3].center = CGPoint(x: cropRect.maxX, y: cropRect.maxY) // BR
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        guard let handle = gesture.view,
              let index = cornerHandles.firstIndex(of: handle) else { return }

        var newRect = cropRect
        let minSize: CGFloat = 100

        switch index {
        case 0: // Top-left
            newRect.origin.x = min(cropRect.maxX - minSize, cropRect.minX + translation.x)
            newRect.origin.y = min(cropRect.maxY - minSize, cropRect.minY + translation.y)
            newRect.size.width = cropRect.maxX - newRect.minX
            newRect.size.height = cropRect.maxY - newRect.minY
        case 1: // Top-right
            newRect.origin.y = min(cropRect.maxY - minSize, cropRect.minY + translation.y)
            newRect.size.width = max(minSize, cropRect.width + translation.x)
            newRect.size.height = cropRect.maxY - newRect.minY
        case 2: // Bottom-left
            newRect.origin.x = min(cropRect.maxX - minSize, cropRect.minX + translation.x)
            newRect.size.width = cropRect.maxX - newRect.minX
            newRect.size.height = max(minSize, cropRect.height + translation.y)
        case 3: // Bottom-right
            newRect.size.width = max(minSize, cropRect.width + translation.x)
            newRect.size.height = max(minSize, cropRect.height + translation.y)
        default:
            break
        }

        // Keep within bounds
        newRect.origin.x = max(0, min(newRect.origin.x, bounds.width - minSize))
        newRect.origin.y = max(0, min(newRect.origin.y, bounds.height - minSize))
        newRect.size.width = min(newRect.size.width, bounds.width - newRect.origin.x)
        newRect.size.height = min(newRect.size.height, bounds.height - newRect.origin.y)

        cropRect = newRect
        gesture.setTranslation(.zero, in: self)
        updateHandlePositions()
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)

        guard let context = UIGraphicsGetCurrentContext() else { return }

        // Draw dimming overlay
        context.setFillColor(UIColor.black.withAlphaComponent(0.5).cgColor)
        context.fill(bounds)
        context.setBlendMode(.clear)
        context.fill(cropRect)
        context.setBlendMode(.normal)

        // Draw crop frame border
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(3)
        context.stroke(cropRect)

        // Draw grid lines
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(1)

        // Vertical lines
        let thirdX = cropRect.width / 3
        context.move(to: CGPoint(x: cropRect.minX + thirdX, y: cropRect.minY))
        context.addLine(to: CGPoint(x: cropRect.minX + thirdX, y: cropRect.maxY))
        context.move(to: CGPoint(x: cropRect.minX + 2 * thirdX, y: cropRect.minY))
        context.addLine(to: CGPoint(x: cropRect.minX + 2 * thirdX, y: cropRect.maxY))

        // Horizontal lines
        let thirdY = cropRect.height / 3
        context.move(to: CGPoint(x: cropRect.minX, y: cropRect.minY + thirdY))
        context.addLine(to: CGPoint(x: cropRect.maxX, y: cropRect.minY + thirdY))
        context.move(to: CGPoint(x: cropRect.minX, y: cropRect.minY + 2 * thirdY))
        context.addLine(to: CGPoint(x: cropRect.maxX, y: cropRect.minY + 2 * thirdY))

        context.strokePath()
    }
}

#Preview {
    TryOnProcessView(garment: GarmentItem(
        imageURL: URL(fileURLWithPath: "/tmp/test.jpg"),
        sourceStore: "ASOS"
    ))
    .environmentObject(AppState())
}
