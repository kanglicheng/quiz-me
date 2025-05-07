//
//  QuizView.swift
//  quiz-app
//
//  Created by Stephen Cheng on 5/7/25.
//

import SwiftUI

struct QuizView: View {
    @EnvironmentObject var quizManager: QuizManager
    @Environment(\.presentationMode) var presentationMode
    @State private var selectedAnswerIndex: Int? = nil
    @State private var showResult = false
    @State private var isCorrect = false
    @StateObject private var motionManager = MotionManager()
    @EnvironmentObject var screenshotManager: ScreenshotManager
    
    // Select a random question from the quiz manager
    private var randomQuestion: Question {
        // Get a random index within the questions array bounds
        let randomIndex = Int.random(in: 0..<quizManager.questions.count)
        return quizManager.questions[randomIndex]
    }

    // Store the randomly selected question so it doesn't change during the view lifecycle
    @State private var currentQuestion: Question?

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
        .navigationBarTitle("Quiz", displayMode: .inline)
        .navigationBarItems(trailing: captureButton)
        .onAppear {
            // Set the random question when the view appears
            if currentQuestion == nil {
                currentQuestion = randomQuestion
    }
}
    }

    // Screenshot capture button
    private var captureButton: some View {
                            Button(action: {
            captureScreenshot()
                            }) {
            Image(systemName: "camera")
                .font(.system(size: 20))
                            .foregroundColor(.blue)
                }
}

    // Function to capture screenshot using UIKit
    private func captureScreenshot() {
        // Get reference to the UIWindow
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            screenshotManager.captureScreenshot(of: window)

            // Show a brief flash animation
            let flashView = UIView(frame: window.bounds)
            flashView.backgroundColor = UIColor.white
            flashView.alpha = 0
            window.addSubview(flashView)

            UIView.animate(withDuration: 0.2, animations: {
                flashView.alpha = 0.8
            }, completion: { _ in
                UIView.animate(withDuration: 0.2, animations: {
                    flashView.alpha = 0
                }, completion: { _ in
                    flashView.removeFromSuperview()
                })
            })
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
        QuizView()
            .environmentObject(quizManager)
            .environmentObject(screenshotManager)
    }
}
