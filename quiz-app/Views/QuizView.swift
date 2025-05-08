import SwiftUI

struct QuizView: View {
    @EnvironmentObject var quizManager: QuizManager
    @EnvironmentObject var screenshotManager: ScreenshotManager
    @EnvironmentObject var audioRecorderManager: AudioRecorderManager
    @EnvironmentObject var videoManager: VideoManager
    @EnvironmentObject var motionManager: MotionManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var selectedAnswerIndex: Int? = nil
    @State private var showResult = false
    @State private var isCorrect = false
    @State private var recordingPermissionGranted = false
    @State private var showPermissionAlert = false
    @State private var permissionAlertType = ""
    @State private var currentQuestion: Question?
    
    // Select a random question from the quiz manager
    private var randomQuestion: Question {
        guard !quizManager.questions.isEmpty else {
            // Return a default question if the array is empty
            return Question(
                text: "Sample question",
                options: ["Option 1", "Option 2", "Option 3", "Option 4"],
                correctAnswerIndex: 0
            )
        }
        
        let randomIndex = Int.random(in: 0..<quizManager.questions.count)
        return quizManager.questions[randomIndex]
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 30) {
                if showResult {
                    resultView
                } else {
                    questionView
                }
            }
            .padding()
            
            // Overlay when device is flat
            if motionManager.isDeviceFlat {
                flatDeviceOverlay
            }
        }
        .navigationTitle("Quiz")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // Indicators for recording activity
                HStack(spacing: 12) {
                    // Audio recording indicator
                    if audioRecorderManager.isRecording {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text("Audio")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                    
                    // Video recording indicator
                    if videoManager.isRecording {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 8, height: 8)
                            
                            Text("Video")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                }
            }
        }
        .onAppear {
            // Set the random question when the view appears
            if currentQuestion == nil {
                currentQuestion = randomQuestion
            }
            
            // Start automatic screenshot capture
            screenshotManager.startAutoCapture()
            
            // Request audio recording permission
            audioRecorderManager.requestPermission { granted in
                if granted {
                    audioRecorderManager.startPeriodicRecording()
                } else {
                    permissionAlertType = "audio"
                    showPermissionAlert = true
                }
            }
            
            // Request video recording permission with alternating cameras
            videoManager.requestPermission { granted in
                if granted {
            // Enable alternating cameras (back then front)
            videoManager.setAlternatingCameras(enabled: true)
            // Start the periodic recording
            videoManager.startPeriodicRecording()
        } else {
            permissionAlertType = "video"
            showPermissionAlert = true
        }
    }
}
        .onDisappear {
            // Stop all recordings when leaving the view
            screenshotManager.stopAutoCapture()
            audioRecorderManager.stopPeriodicRecording()
            videoManager.stopPeriodicRecording()
        }
        .alert(isPresented: $showPermissionAlert) {
            Alert(
                title: Text("Permission Required"),
                message: Text(permissionAlertType == "audio"
                           ? "This app requires microphone access to record audio during quizzes."
                           : "This app requires camera access to record video during quizzes."),
                primaryButton: .default(Text("Settings"), action: openSettings),
                secondaryButton: .cancel(Text("Continue Anyway"))
            )
        }
    }
    
    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // View displaying the question
    private var questionView: some View {
        Group {
            if let question = currentQuestion {
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Question text
                    Text(question.text)
                        .font(.title)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Spacer()
                    
                    // Answer options
                    VStack(spacing: 16) {
                        ForEach(0..<question.options.count, id: \.self) { index in
                            Button(action: {
                                selectedAnswerIndex = index
                                isCorrect = (index == question.correctAnswerIndex)
                                showResult = true
                            }) {
                                Text(question.options[index])
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.blue)
                                    .cornerRadius(10)
                            }
                            .disabled(motionManager.isDeviceFlat)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            } else {
                ProgressView()
                    .onAppear {
                        currentQuestion = randomQuestion
                    }
            }
        }
    }
    
    // Overlay displayed when device is flat
    private var flatDeviceOverlay: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 25) {
                Image(systemName: "iphone.gen3")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(90))
                    .foregroundColor(.white)
                
                Text("Quiz Paused")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text("Please lift your device to continue")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                    .padding(.horizontal)
            }
        }
        .transition(.opacity)
        .animation(.easeInOut, value: motionManager.isDeviceFlat)
    }
    
    // View displaying the result
    private var resultView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            if isCorrect {
                // Correct answer result
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.green)
                    
                    Text("You're smart!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                    
                    Text("Test Complete")
                        .font(.title2)
                        .padding(.top)
                }
            } else {
                // Incorrect answer result
                VStack(spacing: 20) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.red)
                    
                    Text("You tried, but that's not correct")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                    
                    if let question = currentQuestion {
                        Text("The correct answer is:")
                            .font(.headline)
                            .padding(.top)
                        
                        Text(question.options[question.correctAnswerIndex])
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .padding(.horizontal)
                    }
                }
            }
            
            Spacer()
            
            // Return to home button
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text(isCorrect ? "Return Home" : "End")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .disabled(motionManager.isDeviceFlat)
            
            Spacer()
        }
    }
}

struct QuizView_Previews: PreviewProvider {
    static var previews: some View {
        let quizManager = QuizManager()
        let screenshotManager = ScreenshotManager()
        let audioRecorderManager = AudioRecorderManager()
        let videoManager = VideoManager()
        let motionManager = MotionManager()
        
        QuizView()
            .environmentObject(quizManager)
            .environmentObject(screenshotManager)
            .environmentObject(audioRecorderManager)
            .environmentObject(videoManager)
            .environmentObject(motionManager)
    }
}