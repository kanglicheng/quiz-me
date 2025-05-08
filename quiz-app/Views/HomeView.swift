//
//  HomeView.swift
//  quiz-app
//
//  Created by Stephen Cheng on 5/7/25.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var quizManager = QuizManager()
    @EnvironmentObject var screenshotManager: ScreenshotManager
    @EnvironmentObject var audioRecorderManager: AudioRecorderManager
    @EnvironmentObject var videoManager: VideoManager
    @EnvironmentObject var motionManager: MotionManager
    @State private var navigateToQuiz = false
    @State private var showScreenshot = false
    @State private var showRecordings = false
    @State private var showVideos = false
    @State private var showPrivacyInfo = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) { // Reduced spacing
                // Header section
                VStack(spacing: 8) { // Reduced spacing
                    Text("Quiz App")
                        .font(.title) // Smaller font
                    .fontWeight(.bold)
                Image(systemName: "questionmark.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80) // Smaller icon
                    .foregroundColor(.blue)
                
                Text("Test your knowledge with our fun quiz!")
                        .font(.subheadline) // Smaller font
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                        .padding(.bottom, 8)
                }
                        .padding(.top, 20)

                // Features section
                HStack(spacing: 24) {
                    VStack(spacing: 2) {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.green)
                        Text("Screenshots")
                            .font(.caption)
                }
                    VStack(spacing: 2) {
                        Image(systemName: "mic.fill")
                            .foregroundColor(.red)
                        Text("Audio")
                            .font(.caption)
            }

                    VStack(spacing: 2) {
                        Image(systemName: "video.fill")
                            .foregroundColor(.purple)
                        Text("Video")
                            .font(.caption)
                    }
                }
                .padding(10)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)

                // Main buttons section - more compact grid layout
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    // Main quiz button spans both columns
                    Button(action: {
                        quizManager.restartQuiz()
                        navigateToQuiz = true
                    }) {
                        VStack {
                            Image(systemName: "play.fill")
                                .font(.title2)
                            Text("Start Quiz")
                                .font(.headline)
        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
    }
                    .gridCellColumns(2) // Span both columns

                    // Media buttons are in the grid
                    MediaButton(
                        title: "Screenshots",
                        icon: "photo.fill",
                        color: .green
                    ) {
                        screenshotManager.loadLatestScreenshot()
                        showScreenshot = true
        }

                    MediaButton(
                        title: "Audio",
                        icon: "headphones",
                        color: .orange
                    ) {
                        showRecordings = true
    }

                    MediaButton(
                        title: "Videos",
                        icon: "film.fill",
                        color: .purple
                    ) {
                        showVideos = true
                    }

                    MediaButton(
                        title: "Privacy",
                        icon: "lock.shield.fill",
                        color: .gray
                    ) {
                        showPrivacyInfo = true
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)

                Spacer() // Push content to the top
            }
            .padding(.horizontal)
            .navigationDestination(isPresented: $navigateToQuiz) {
                QuizView()
                    .environmentObject(quizManager)
            .environmentObject(screenshotManager)
            .environmentObject(audioRecorderManager)
                    .environmentObject(videoManager)
                    .environmentObject(motionManager)
    }
            .navigationDestination(isPresented: $showScreenshot) {
                ScreenshotView()
                    .environmentObject(screenshotManager)
}
            .navigationDestination(isPresented: $showRecordings) {
                RecordingsView()
                    .environmentObject(audioRecorderManager)
            }
            .navigationDestination(isPresented: $showVideos) {
                VideoListView()
                    .environmentObject(videoManager)
            }
            .sheet(isPresented: $showPrivacyInfo) {
                PrivacyInfoView()
            }
        }
        .onAppear {
            // Load any existing screenshot when app starts
            screenshotManager.loadLatestScreenshot()
        }
    }
}

// Helper view for media buttons
struct MediaButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                Text(title)
                    .font(.callout)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
    }
}

// A new view to explain the app's privacy features
struct PrivacyInfoView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        Text("Privacy Information")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.bottom, 5)

                        Text("This app captures data during your quiz session to enhance your experience. Here's what you should know:")
                            .font(.body)
                    }

                    Divider()

                    Group {
                        Text("Automatic Screenshots")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("• Screenshots are taken every 15 seconds while the quiz is active")
                        Text("• A subtle flash effect indicates when a screenshot is captured")
                        Text("• Screenshots are stored only within the app")
                        Text("• Screenshots pause when the device is lying flat")
                    }

                    Divider()

                    Group {
                        Text("Audio Recording")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("• 5-second audio clips are recorded every 30 seconds")
                        Text("• A red indicator appears in the navigation bar during recording")
                        Text("• Microphone permission is required and can be revoked in Settings")
                        Text("• Recordings are stored only within the app")
                    }

                    Divider()

                    Group {
                        Text("Device Motion")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("• The app detects when your device is lying flat")
                        Text("• Quiz and recordings pause when the device is flat")
                        Text("• No motion data is stored or transmitted")
                    }

                    Text("All data captured is stored locally on your device and is not shared with third parties.")
                        .font(.headline)
                        .padding(.top, 20)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let screenshotManager = ScreenshotManager()
        let audioRecorderManager = AudioRecorderManager()
        let videoManager = VideoManager()
        let motionManager = MotionManager()

        HomeView()
            .environmentObject(screenshotManager)
            .environmentObject(audioRecorderManager)
            .environmentObject(videoManager)
            .environmentObject(motionManager)
    }
}
