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
            
            #if DEBUG
            Button("Debug Files") {
                let fileManager = FileManager.default
                let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                
                do {
                    let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
                    print("Files in documents directory:")
                    for (index, url) in fileURLs.enumerated() {
                        do {
                            let attributes = try fileManager.attributesOfItem(atPath: url.path)
                            let fileSize = attributes[.size] as? UInt64 ?? 0
                            print("\(index+1): \(url.lastPathComponent) - \(fileSize) bytes")
                        } catch {
                            print("\(index+1): \(url.lastPathComponent) - Error getting size")
                        }
                    }
                } catch {
                    print("Error listing files: \(error)")
                }
            }
            .padding()
            #endif
            
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
    
    private func refreshVideos() {
        videos = videoRecorderManager.getVideos().sorted(by: { $0.lastPathComponent > $1.lastPathComponent })
        print("Found \(videos.count) videos")
        for (index, video) in videos.enumerated() {
            print("Video \(index+1): \(video)")
        }
    }
    
    private func formattedDate(from url: URL) -> String {
        let filename = url.lastPathComponent
        
        // Parse the formatted date from the filename
        if filename.hasPrefix("quiz_video_") {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            
            let startIndex = filename.index(filename.startIndex, offsetBy: 11) // "quiz_video_" is 11 characters
            let endIndex = filename.index(filename.endIndex, offsetBy: -4) // ".mp4" is 4 characters
            
            if startIndex < endIndex, let dateRange = Range<String.Index>(uncheckedBounds: (lower: startIndex, upper: endIndex)) {
                let dateString = String(filename[dateRange])
                if let date = dateFormatter.date(from: dateString) {
                    let displayFormatter = DateFormatter()
                    displayFormatter.dateStyle = .short
                    displayFormatter.timeStyle = .medium
                    return displayFormatter.string(from: date)
                }
            }
        }
        
        return filename
    }
    
    private func deleteVideos(at offsets: IndexSet) {
        let urlsToDelete = offsets.map { videos[$0] }
        
        for url in urlsToDelete {
            try? FileManager.default.removeItem(at: url)
        }
        
        // Update our videos list
        refreshVideos()
    }
}