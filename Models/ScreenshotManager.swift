import SwiftUI
import UIKit

class ScreenshotManager: ObservableObject {
    @Published var latestScreenshot: UIImage?
    
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
}
