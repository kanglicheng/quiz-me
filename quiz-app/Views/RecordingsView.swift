import SwiftUI
import AVFoundation

struct RecordingsView: View {
    @EnvironmentObject var audioRecorderManager: AudioRecorderManager
    @Environment(\.presentationMode) var presentationMode
    @State private var recordings: [URL] = []
    @State private var currentlyPlaying: URL?
    @State private var audioPlayer: AVAudioPlayer?
    @State private var editMode: EditMode = .inactive
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if recordings.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "waveform")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                        
                        Text("No audio recordings available")
                            .font(.title2)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .frame(maxHeight: .infinity)
                } else {
                    List {
                        ForEach(recordings, id: \.self) { url in
                            HStack {
                                Text(formattedDate(from: url))
                                    .font(.headline)
                                
                                Spacer()
                                
                                if editMode == .inactive {
                                    Button(action: {
                                        if currentlyPlaying == url {
                                            stopPlayback()
                                        } else {
                                            playRecording(url)
                                        }
                                    }) {
                                        Image(systemName: currentlyPlaying == url ? "stop.circle.fill" : "play.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .onDelete(perform: deleteRecordings)
                    }
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            EditButton()
                        }
                    }
                    .environment(\.editMode, $editMode)
                    
                    if !recordings.isEmpty {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            Label("Delete All Recordings", systemImage: "trash")
                                .foregroundColor(.red)
                                .padding(.vertical, 10)
                        }
                        .padding(.bottom, 10)
                        .alert("Delete All Recordings?", isPresented: $showDeleteConfirmation) {
                            Button("Delete All", role: .destructive) {
                                deleteAllRecordings()
                            }
                            Button("Cancel", role: .cancel) {}
                        } message: {
                            Text("This will permanently delete all audio recordings. This action cannot be undone.")
                        }
                    }
                }
            }
            .navigationTitle("Audio Recordings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        stopPlayback()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
            .onAppear {
                refreshRecordings()
            }
            .onDisappear {
                stopPlayback()
            }
        }
    }
    
    private func refreshRecordings() {
        // Get all m4a files from documents directory
        recordings = audioRecorderManager.getRecordings().sorted(by: { $0.lastPathComponent > $1.lastPathComponent })
    }
    
    private func formattedDate(from url: URL) -> String {
        // Your existing date formatting logic
        let filename = url.lastPathComponent
        
        // Extract timestamp from filename (quiz_audio_1234567890.m4a)
        if let range = filename.range(of: "quiz_audio_"),
           let timeRange = filename.range(of: ".m4a", options: .backwards) {
            let timestampString = filename[range.upperBound..<timeRange.lowerBound]
            if let timeInterval = Double(timestampString) {
                let date = Date(timeIntervalSince1970: timeInterval)
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .medium
                return formatter.string(from: date)
            }
        }
        
        return filename
    }
    
    private func playRecording(_ url: URL) {
        stopPlayback()
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            currentlyPlaying = url
        } catch {
            print("Error playing recording: \(error)")
        }
    }
    
    private func stopPlayback() {
        audioPlayer?.stop()
        audioPlayer = nil
        currentlyPlaying = nil
    }
    
    private func deleteRecordings(at offsets: IndexSet) {
        let urlsToDelete = offsets.map { recordings[$0] }
        
        for url in urlsToDelete {
            try? FileManager.default.removeItem(at: url)
        }
        
        // Update our recordings list
        refreshRecordings()
    }
    
    private func deleteAllRecordings() {
        for url in recordings {
            try? FileManager.default.removeItem(at: url)
        }
        recordings.removeAll()
    }
}