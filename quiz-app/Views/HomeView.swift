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
    @EnvironmentObject var motionManager: MotionManager
    @State private var navigateToQuiz = false
    @State private var showScreenshot = false
    @State private var showRecordings = false
    @State private var showPrivacyInfo = false
    @State private var showVideos = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Spacer()
                
                Text("Welcome to Quiz App!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Image(systemName: "questionmark.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 150, height: 150)
                    .foregroundColor(.blue)
                
                Text("Test your knowledge with our fun quiz!")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                HStack {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.green)
                    Text("Automatic screenshots")
                
                    Spacer()

                    Image(systemName: "mic.fill")
                        .foregroundColor(.red)
                    Text("Audio recording")
                }
                .font(.subheadline)
                .padding(.horizontal, 50)
                Spacer()

                VStack(spacing: 16) {
                    Button(action: {
                        quizManager.restartQuiz()
                        navigateToQuiz = true
                    }) {
                        Text("Start Quiz")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        screenshotManager.loadLatestScreenshot()
                        showScreenshot = true
                    }) {
                        Text("View Latest Screenshot")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
        }

                    Button(action: {
                        showRecordings = true
                    }) {
                        Text("Audio Recordings")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(12)
    }

                    Button(action: {
                        showVideos = true
                    }) {
                        Text("Video Recordings")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .cornerRadius(12)
                    }

                    Button(action: {
                        showPrivacyInfo = true
                    }) {
                        Label("Privacy Information", systemImage: "info.circle")
                            .font(.headline)
                            .foregroundColor(.blue)
}
                    .padding(.top, 8)
    }
                .padding(.horizontal, 40)

                Spacer()
                    }
                .padding()
            .navigationDestination(isPresented: $navigateToQuiz) {
                QuizView()
                    .environmentObject(quizManager)
            .environmentObject(screenshotManager)
            .environmentObject(audioRecorderManager)
            .environmentObject(motionManager)
    }
            .navigationDestination(isPresented: $showScreenshot) {
                ScreenshotView()
}
            .navigationDestination(isPresented: $showRecordings) {
                RecordingsView()
            }
            .navigationDestination(isPresented: $showVideos) {
                VideoPlayerView()
                    .environmentObject(audioRecorderManager)
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
        let motionManager = MotionManager()

        HomeView()
            .environmentObject(screenshotManager)
            .environmentObject(audioRecorderManager)
            .environmentObject(motionManager)
    }
}
