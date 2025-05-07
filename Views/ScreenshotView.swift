import SwiftUI

struct ScreenshotView: View {
    @EnvironmentObject var screenshotManager: ScreenshotManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            if let screenshot = screenshotManager.latestScreenshot {
                Image(uiImage: screenshot)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
                    .padding()
                    .shadow(radius: 10)
                
                Text("Quiz Screenshot")
                    .font(.headline)
                    .padding(.top)
                
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Text("Close")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(width: 200)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.top, 30)
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "photo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                    
                    Text("No screenshot available")
                        .font(.title2)
                        .foregroundColor(.gray)
                    
                    Text("Take a screenshot during the quiz by tapping the camera button")
                        .font(.body)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                    
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("Close")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(width: 200)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.top, 30)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitle("Screenshot", displayMode: .inline)
        .onAppear {
            // Load any saved screenshot when view appears
            screenshotManager.loadLatestScreenshot()
        }
    }
}

struct ScreenshotView_Previews: PreviewProvider {
    static var previews: some View {
        let screenshotManager = ScreenshotManager()
        ScreenshotView().environmentObject(screenshotManager)
    }
}