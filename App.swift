import SwiftUI

@main
struct QuizApp: App {
    // Create as StateObjects at the app level so they persist
    @StateObject private var screenshotManager = ScreenshotManager()
    @StateObject private var audioRecorderManager = AudioRecorderManager()
    @StateObject private var motionManager = MotionManager()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(screenshotManager)
                .environmentObject(audioRecorderManager)
                .environmentObject(motionManager)
        }
    }
}