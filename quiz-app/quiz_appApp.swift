//
//  quiz_appApp.swift
//  quiz-app
//
//  Created by Stephen Cheng on 5/7/25.
//


import SwiftUI

@main
struct QuizApp: App {
    @StateObject private var screenshotManager = ScreenshotManager()
    @StateObject private var audioRecorderManager = AudioRecorderManager()
    @StateObject private var videoManager = VideoManager() // New manager
    @StateObject private var motionManager = MotionManager()
    
    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(screenshotManager)
                .environmentObject(audioRecorderManager)
                .environmentObject(videoManager)
                .environmentObject(motionManager)
        }
    }
}