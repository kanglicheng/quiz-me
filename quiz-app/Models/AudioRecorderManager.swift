//
//  AudioRecorderManager.swift
//  quiz-app
//
//  Created by Stephen Cheng on 5/8/25.
//

import Foundation
import AVFoundation

class AudioRecorderManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var latestRecordingURL: URL?
    
    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var recordingSession: AVAudioSession?
    private var recordingDuration: TimeInterval = 5.0 // 5 seconds
    private var recordingInterval: TimeInterval = 30.0 // every 30 seconds
    
    override init() {
        super.init()
        setupRecordingSession()
    }
    
    private func setupRecordingSession() {
        recordingSession = AVAudioSession.sharedInstance()
        do {
            try recordingSession?.setCategory(.playAndRecord, mode: .default)
            try recordingSession?.setActive(true)
        } catch {
            print("Failed to set up recording session: \(error)")
        }
    }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        // Use the new API if available (iOS 17+), otherwise fall back to the deprecated one
        if #available(iOS 17.0, *) {
            AVAudioApplication.requestRecordPermission { allowed in
                DispatchQueue.main.async {
                    completion(allowed)
                }
            }
        } else {
            // For iOS 16 and earlier
            recordingSession?.requestRecordPermission { allowed in
                DispatchQueue.main.async {
                    completion(allowed)
                }
            }
        }
    }
    
    func startPeriodicRecording() {
        guard timer == nil else { return }
        
        // Start the first recording immediately
        startRecording()
        
        // Set up timer for subsequent recordings
        timer = Timer.scheduledTimer(withTimeInterval: recordingInterval, repeats: true) { [weak self] _ in
            self?.startRecording()
        }
    }
    
    func stopPeriodicRecording() {
        timer?.invalidate()
        timer = nil
        
        if isRecording {
            stopRecording()
        }
    }
    
    private func startRecording() {
        guard !isRecording else { return }
        
        let audioFilename = getDocumentsDirectory().appendingPathComponent("quiz_audio_\(Date().timeIntervalSince1970).m4a")
        
        let settings = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: audioFilename, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.record()
            isRecording = true
            
            // Set up timer to stop recording after the specified duration
            DispatchQueue.main.asyncAfter(deadline: .now() + recordingDuration) { [weak self] in
                self?.stopRecording()
            }
        } catch {
            print("Could not start recording: \(error)")
        }
    }
    
    private func stopRecording() {
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
    }
    
    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }
    
    func getRecordings() -> [URL] {
        let documentsDirectory = getDocumentsDirectory()
        let fileManager = FileManager.default
        
        do {
            let directoryContents = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            return directoryContents.filter { $0.pathExtension == "m4a" }
        } catch {
            print("Error getting recordings: \(error)")
            return []
        }
    }
    
    deinit {
        stopPeriodicRecording()
    }
}

// MARK: - AVAudioRecorderDelegate
extension AudioRecorderManager: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            latestRecordingURL = recorder.url
        }
    }
}
