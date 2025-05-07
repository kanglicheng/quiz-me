import SwiftUI

struct HomeView: View {
    @StateObject private var quizManager = QuizManager()
    @StateObject private var screenshotManager = ScreenshotManager()
    @State private var navigateToQuiz = false
    @State private var showScreenshot = false
    
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
                
                Spacer()
                
                VStack(spacing: 20) {
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
                        // Load screenshot before showing the view
                        screenshotManager.loadLatestScreenshot()
                        showScreenshot = true
                    }) {
                        Text("View Screenshot")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
        }
    }
                .padding(.horizontal, 40)

                Spacer()
            }
            .padding()
            .navigationDestination(isPresented: $navigateToQuiz) {
                QuizView()
                    .environmentObject(quizManager)
                    .environmentObject(screenshotManager)
    }
            .navigationDestination(isPresented: $showScreenshot) {
                ScreenshotView()
                    .environmentObject(screenshotManager)
}
}
        .onAppear {
            // Load any existing screenshot when app starts
            screenshotManager.loadLatestScreenshot()
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
