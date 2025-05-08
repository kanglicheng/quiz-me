import SwiftUI
import AVKit

struct VideoListView: View {
    @EnvironmentObject var videoManager: VideoManager
    @State private var selectedVideo: URL?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Text("Video Recordings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            if videoManager.videoURLs.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "video.slash")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.gray)
                    
                    Text("No videos recorded yet")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(videoManager.videoURLs, id: \.self) { url in
                        Button(action: {
                            selectedVideo = url
                            playVideo(url)
                        }) {
                            HStack {
                                Text(formatDate(from: url))
                                    .font(.headline)
                                
                                Spacer()
                                
                                Image(systemName: "play.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title3)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .onDelete { indexSet in
                        let urlsToDelete = indexSet.map { videoManager.videoURLs[$0] }
                        for url in urlsToDelete {
                            videoManager.deleteVideo(at: url)
                        }
                    }
                }
            }
            
            Button("Close") {
                dismiss()
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .frame(width: 200)
            .background(Color.blue)
            .cornerRadius(10)
            .padding(.bottom, 20)
        }
        .padding()
    }
    
    private func playVideo(_ url: URL) {
        let player = AVPlayer(url: url)
        let controller = AVPlayerViewController()
        controller.player = player
        
        // Find the UIWindow scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            // Find the top-most presented controller
            var topController = rootViewController
            while let presentedController = topController.presentedViewController {
                topController = presentedController
            }
            
            // Present the player
            topController.present(controller, animated: true) {
                player.play()
            }
        }
    }
    
    private func formatDate(from url: URL) -> String {
        let filename = url.lastPathComponent
        
        if filename.hasPrefix("video_") && filename.hasSuffix(".mp4") {
            // Extract the date part
            let dateStart = filename.index(filename.startIndex, offsetBy: 6) // "video_" length
            let dateEnd = filename.index(filename.endIndex, offsetBy: -4)    // ".mp4" length
            
            if dateStart < dateEnd {
                let dateString = String(filename[dateStart..<dateEnd])
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyyMMdd_HHmmss"
                
                if let date = formatter.date(from: dateString) {
                    let displayFormatter = DateFormatter()
                    displayFormatter.dateStyle = .short
                    displayFormatter.timeStyle = .medium
                    return displayFormatter.string(from: date)
                }
            }
        }
        
        return filename
    }
}