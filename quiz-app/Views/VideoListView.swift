import SwiftUI
import AVKit

struct VideoListView: View {
    @EnvironmentObject var videoManager: VideoManager
    @State private var selectedVideo: URL?
    @Environment(\.dismiss) var dismiss
    @State private var editMode: EditMode = .inactive
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            VStack {
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
                                if editMode == .inactive {
                                    selectedVideo = url
                                    playVideo(url)
                                }
                            }) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(formatDate(from: url))
                                            .font(.headline)
                                    
                                        // Show camera type based on filename
                                        Text(url.lastPathComponent.contains("_front") ? "Front Camera" : "Back Camera")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if editMode == .inactive {
                                        Image(systemName: "play.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.title3)
                                    }
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
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            EditButton()
                    }
                }
                    .environment(\.editMode, $editMode)
            }

                if !videoManager.videoURLs.isEmpty {
                    Button(action: {
                        // Show confirmation alert
                        showDeleteConfirmation = true
                    }) {
                        Label("Delete All Videos", systemImage: "trash")
                            .foregroundColor(.red)
                            .padding(.vertical, 10)
                    }
                    .padding(.bottom, 10)
                    .alert("Delete All Videos?", isPresented: $showDeleteConfirmation) {
                        Button("Delete All", role: .destructive) {
                            videoManager.deleteAllVideos() // Call the method on VideoManager
                        }
                        Button("Cancel", role: .cancel) {}
                    } message: {
                        Text("This will permanently delete all videos. This action cannot be undone.")
                    }
                }
            }
            .navigationTitle("Video Recordings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
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
            let dateStart = filename.index(filename.startIndex, offsetBy: 6) // "video_" length

            if let lastUnderscoreRange = filename.range(of: "_", options: .backwards, range: dateStart..<filename.index(filename.endIndex, offsetBy: -4)) {
                let dateString = String(filename[dateStart..<lastUnderscoreRange.lowerBound])
                
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

func startPeriodicRecording() {
    guard captureSession?.isRunning == true else {
        print("Capture session not running")
        return
    }

    // Start with back camera for first recording
    if shouldAlternateCamera {
        setCamera(front: false)
    }

    // Start first recording immediately
    startSingleRecording()

    // Set timer for periodic recordings
    timer = Timer.scheduledTimer(withTimeInterval: recordingInterval, repeats: true) { [weak self] _ in
        guard let self = self else { return }

        // Switch camera before next recording if auto-switching is enabled
        if self.shouldAlternateCamera {
            self.toggleCamera()
        }

        // Start the recording with the current camera
        self.startSingleRecording()
    }
}
    private func startSingleRecording() {
        guard let videoOutput = videoOutput, !isRecording, captureSession?.isRunning == true else {
            print("Cannot start recording: videoOutput=\(videoOutput != nil), isRecording=\(isRecording), sessionRunning=\(captureSession?.isRunning == true)")
            return
        }

        // Create unique filename - include camera position in filename
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let cameraTag = isUsingFrontCamera ? "front" : "back"
        let filename = "video_\(dateFormatter.string(from: Date()))_\(cameraTag).mp4"
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)

        print("Starting recording to: \(fileURL.path) with \(isUsingFrontCamera ? "front" : "back") camera")
        videoOutput.startRecording(to: fileURL, recordingDelegate: self)
    }
}
