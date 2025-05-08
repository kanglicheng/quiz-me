//
//  RecordingsView.swift
//  quiz-app
//
//  Created by Stephen Cheng on 5/8/25.
//

import SwiftUI
import AVFoundation

// Coordinator class to handle AVAudioPlayerDelegate conformance
class AudioPlayerCoordinator: NSObject, AVAudioPlayerDelegate {
    var onFinishPlaying: () -> Void

    init(onFinishPlaying: @escaping () -> Void) {
        self.onFinishPlaying = onFinishPlaying
        super.init()
    }

    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        onFinishPlaying()
    }
}

struct RecordingsView: View {
    @EnvironmentObject var audioRecorderManager: AudioRecorderManager
    @Environment(\.presentationMode) var presentationMode
    @State private var recordings: [URL] = []
    @State private var audioPlayer: AVAudioPlayer?
    @State private var playingURL: URL?
    @State private var coordinator: AudioPlayerCoordinator?

    var body: some View {
        VStack {
            Text("Quiz Audio Recordings")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()
            
            if recordings.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "waveform")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(.gray)
                    
                    Text("No recordings available")
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
                            
                            Button(action: {
                                playRecording(url: url)
                            }) {
                                Image(systemName: playingURL == url ? "stop.circle" : "play.circle")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .onDelete(perform: deleteRecordings)
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
            refreshRecordings()
        }
    }
    
    private func refreshRecordings() {
        recordings = audioRecorderManager.getRecordings().sorted(by: { $0.lastPathComponent > $1.lastPathComponent })
    }
    
    private func formattedDate(from url: URL) -> String {
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
    
    private func playRecording(url: URL) {
        if playingURL == url {
            // Stop playing if this is the currently playing URL
            audioPlayer?.stop()
            playingURL = nil
            return
        }
        
        // Play the selected recording
        do {
            audioPlayer?.stop() // Stop any playing audio
            
            audioPlayer = try AVAudioPlayer(contentsOf: url)

            // Create coordinator to handle playback completion
            coordinator = AudioPlayerCoordinator {
                // This will be called when playback finishes
                DispatchQueue.main.async {
                    self.playingURL = nil
                }
            }

            audioPlayer?.delegate = coordinator
            audioPlayer?.play()
            playingURL = url
        } catch {
            print("Error playing audio: \(error)")
        }
    }
    
    private func deleteRecordings(at offsets: IndexSet) {
        let urlsToDelete = offsets.map { recordings[$0] }
        
        for url in urlsToDelete {
            try? FileManager.default.removeItem(at: url)
        }
        
        // Update our recordings list
        refreshRecordings()
    }
}

