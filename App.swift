import SwiftUI

@main
struct QuizApp: App {
    @StateObject private var screenshotManager = ScreenshotManager()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(screenshotManager)
        }
    }
}