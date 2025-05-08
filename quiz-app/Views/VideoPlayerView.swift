import SwiftUI
import AVKit

struct VideoPlayerView: View {
    @EnvironmentObject var videoRecorderManager: VideoRecorderManager
    @Environment(\.presentationMode) var presentationMode
    @State private var videos: [URL] = []
    @State private var selectedVideo: URL?
    @State private var showPlayer = false
    @State private var player: AVPlayer?
    
    var body: some View {
        VStack {
            Text("Quiz Video Recordings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            if videos.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "video.slash")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                    
                    Text("No video recordings available")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .padding()
                .frame(maxHeight: .infinity)
            } else {
                List {
                    ForEach(videos, id: \.self) { url in
                        HStack {
                            Text(formattedDate(from: url))
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: {
                                // Create player before showing sheet
                                player = AVPlayer(url: url)
                                selectedVideo = url
                                showPlayer = true
                            }) {
                                Image(systemName: "play.circle")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onDelete(perform: deleteVideos)
                }
            }
            
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
                    .padding(.vertical, 20)
            }
        }
        .onAppear {
            refreshVideos()
        }
        .sheet(isPresented: $showPlayer) {
            if let player = player {
                VideoPlayerControlsView(player: player)
            }
        }
    }
    
    // Create a separate video player view with controls
    struct VideoPlayerControlsView: View {
        let player: AVPlayer
        @Environment(\.dismiss) var dismiss
        
        var body: some View {
            ZStack {
                VideoPlayer(player: player)
                    .edgesIgnoringSafeArea(.all)
                    .onAppear {
                        player.play() // Auto-play when view appears
                    }
                    .onDisappear {
                        player.pause() // Pause when view disappears
                    }
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            dismiss()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                    }
                    .padding()
                    
                    Spacer()
                }
            }
        }
    }
    
    // Rest of your code remains the same...
    private func refreshVideos() {
        videos = videoRecorderManager.getVideos().sorted(by: { $0.lastPathComponent > $1.lastPathComponent })
        print("Found \(videos.count) videos")
        for (index, video) in videos.enumerated() {
            print("Video \(index+1): \(video)")
        }
    }
    
    private func formattedDate(from url: URL) -> String {
        // Existing implementation...
    }
    
    private func deleteVideos(at offsets: IndexSet) {
        // Existing implementation...
    }
}