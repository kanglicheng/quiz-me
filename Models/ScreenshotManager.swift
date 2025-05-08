import SwiftUI
import UIKit

class ScreenshotManager: ObservableObject {
    @Published var latestScreenshot: UIImage?
    private var timer: Timer?
    private var isAutoCaptureEnabled = false
    
    // Capture a screenshot of the given view
    func captureScreenshot(of view: UIView) {
        // Create a renderer with the size of the view
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        
        // Render the view into an image
        let screenshot = renderer.image { context in
            view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        }
        
        // Save the screenshot
        latestScreenshot = screenshot
        
        // Also save to documents directory for persistence
        saveScreenshotToDocuments(screenshot)
    }
    
    // Start automatic screenshot capture
    func startAutoCapture() {
        guard !isAutoCaptureEnabled else { return }

        isAutoCaptureEnabled = true

        // Create a timer that fires every 15 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            self?.captureCurrentScreen()
        }
    }

    // Stop automatic screenshot capture
    func stopAutoCapture() {
        timer?.invalidate()
        timer = nil
        isAutoCaptureEnabled = false
    }

    // Capture screenshot of current screen
    private func captureCurrentScreen() {
        // Find the key window
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {

            captureScreenshot(of: window)

            // Create a brief flash animation
            let flashView = UIView(frame: window.bounds)
            flashView.backgroundColor = UIColor.white
            flashView.alpha = 0
            window.addSubview(flashView)

            UIView.animate(withDuration: 0.1, animations: {
                flashView.alpha = 0.3
            }, completion: { _ in
                UIView.animate(withDuration: 0.1, animations: {
                    flashView.alpha = 0
                }, completion: { _ in
                    flashView.removeFromSuperview()
                })
            })
        }
    }

    // Save screenshot to documents directory
    private func saveScreenshotToDocuments(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        
        do {
            let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsDirectory.appendingPathComponent("latest_quiz_screenshot.jpg")
            try data.write(to: fileURL)
        } catch {
            print("Error saving screenshot: \(error)")
        }
    }
    
    // Load the latest screenshot from documents directory
    func loadLatestScreenshot() {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent("latest_quiz_screenshot.jpg")
        
        if FileManager.default.fileExists(atPath: fileURL.path),
           let data = try? Data(contentsOf: fileURL),
           let image = UIImage(data: data) {
            latestScreenshot = image
        }
    }

    deinit {
        stopAutoCapture()
    }
}
