// MultiCamManager.swift
import Foundation
import AVFoundation
import UIKit

class MultiCamManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var videoURLs: [URL] = []
    
    // Session and outputs
    private var multiCamSession: AVCaptureMultiCamSession?
    private var backCameraOutput: AVCaptureMovieFileOutput?
    private var frontCameraOutput: AVCaptureMovieFileOutput?
    
    // Recording configuration
    private let recordingDuration: TimeInterval = 5.0
    private let recordingInterval: TimeInterval = 10.0
    private var timer: Timer?
    
    // Camera status
    private var isFrontCameraConfigured = false
    private var isBackCameraConfigured = false
    private var useFrontCamera = false
    private var cameraSwitchCount = 0
    
    override init() {
        super.init()
        checkMultiCamSupport()
        loadSavedVideos()
    }
    
    private func checkMultiCamSupport() {
        // Check device support for multi-cam
        if !AVCaptureMultiCamSession.isMultiCamSupported {
            print("MultiCam not supported on this device - using fallback implementation")
            return
        }
        
        // Create multi-cam session
        multiCamSession = AVCaptureMultiCamSession()
        setupMultiCamSession()
    }
    
    private func setupMultiCamSession() {
        guard let multiCamSession = multiCamSession else { return }
        
        // Begin configuration
        multiCamSession.beginConfiguration()
        
        // 1. Configure back camera
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Back camera not available")
            return
        }
        
        do {
            // Back camera input
            let backInput = try AVCaptureDeviceInput(device: backCamera)
            if multiCamSession.canAddInput(backInput) {
                multiCamSession.addInputWithNoConnections(backInput)
                
                // Back camera output
                backCameraOutput = AVCaptureMovieFileOutput()
                if let backCameraOutput = backCameraOutput, multiCamSession.canAddOutput(backCameraOutput) {
                    multiCamSession.addOutputWithNoConnections(backCameraOutput)
                    
                    // Connect input ports to output
                    if let videoPort = backInput.ports(for: .video, sourceDeviceType: backCamera.deviceType, sourceDevicePosition: backCamera.position).first {
                        let backConnection = AVCaptureConnection(inputPorts: [videoPort], output: backCameraOutput)
                        if multiCamSession.canAddConnection(backConnection) {
                            multiCamSession.addConnection(backConnection)
                            isBackCameraConfigured = true
                            print("Back camera configured successfully")
                        }
                    }
                }
            }
            
            // 2. Configure front camera
            guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                print("Front camera not available")
                return
            }
            
            // Front camera input
            let frontInput = try AVCaptureDeviceInput(device: frontCamera)
            if multiCamSession.canAddInput(frontInput) {
                multiCamSession.addInputWithNoConnections(frontInput)
                
                // Front camera output
                frontCameraOutput = AVCaptureMovieFileOutput()
                if let frontCameraOutput = frontCameraOutput, multiCamSession.canAddOutput(frontCameraOutput) {
                    multiCamSession.addOutputWithNoConnections(frontCameraOutput)
                    
                    // Connect input ports to output
                    if let videoPort = frontInput.ports(for: .video, sourceDeviceType: frontCamera.deviceType, sourceDevicePosition: frontCamera.position).first {
                        let frontConnection = AVCaptureConnection(inputPorts: [videoPort], output: frontCameraOutput)
                        if multiCamSession.canAddConnection(frontConnection) {
                            multiCamSession.addConnection(frontConnection)
                            isFrontCameraConfigured = true
                            print("Front camera configured successfully")
                        }
                    }
                }
            }
            
            // 3. Configure audio (connected to both outputs)
            if let audioDevice = AVCaptureDevice.default(for: .audio) {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if multiCamSession.canAddInput(audioInput) {
                    multiCamSession.addInputWithNoConnections(audioInput)
                    
                    // Get audio port from input
                    if let audioPort = audioInput.ports(for: .audio, sourceDeviceType: audioDevice.deviceType, sourceDevicePosition: .unspecified).first {
                        
                        // Connect audio to back camera output
                        if let backOutput = backCameraOutput {
                            let backAudioConnection = AVCaptureConnection(inputPorts: [audioPort], output: backOutput)
                            if multiCamSession.canAddConnection(backAudioConnection) {
                                multiCamSession.addConnection(backAudioConnection)
                                print("Audio connected to back camera output")
                            }
                        }
                        
                        // Connect audio to front camera output
                        if let frontOutput = frontCameraOutput {
                            let frontAudioConnection = AVCaptureConnection(inputPorts: [audioPort], output: frontOutput)
                            if multiCamSession.canAddConnection(frontAudioConnection) {
                                multiCamSession.addConnection(frontAudioConnection)
                                print("Audio connected to front camera output")
                            }
                        }
                    }
                }
            }
            
            // Commit configuration
            multiCamSession.commitConfiguration()
            
            // Start the session
            DispatchQueue.global(qos: .userInitiated).async {
                self.multiCamSession?.startRunning()
                print("MultiCam session started")
            }
            
        } catch {
            print("Error setting up multicam: \(error)")
            multiCamSession.commitConfiguration()
        }
    }
    
    func startSimultaneousRecording() {
        guard let multiCamSession = multiCamSession, multiCamSession.isRunning else {
            print("MultiCam session not running")
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        
        // Start back camera recording
        if isBackCameraConfigured, let backOutput = backCameraOutput, !backOutput.isRecording {
            let backFilename = "video_\(timestamp)_back.mp4"
            let backFileURL = getDocumentsDirectory().appendingPathComponent(backFilename)
            backOutput.startRecording(to: backFileURL, recordingDelegate: self)
            print("Started back camera recording to: \(backFileURL.path)")
        }
        
        // Start front camera recording
        if isFrontCameraConfigured, let frontOutput = frontCameraOutput, !frontOutput.isRecording {
            let frontFilename = "video_\(timestamp)_front.mp4"
            let frontFileURL = getDocumentsDirectory().appendingPathComponent(frontFilename)
            frontOutput.startRecording(to: frontFileURL, recordingDelegate: self)
            print("Started front camera recording to: \(frontFileURL.path)")
        }
        
        DispatchQueue.main.async {
            self.isRecording = true
        }
        
        // Set up timer to stop recording after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + recordingDuration) { [weak self] in
            self?.stopSimultaneousRecording()
        }
    }
    
    func stopSimultaneousRecording() {
        // Stop back camera recording
        if let backOutput = backCameraOutput, backOutput.isRecording {
            backOutput.stopRecording()
        }
        
        // Stop front camera recording
        if let frontOutput = frontCameraOutput, frontOutput.isRecording {
            frontOutput.stopRecording()
        }
    }
    
    func startPeriodicRecording() {
        // Start first recording
        startSimultaneousRecording()
        
        // Set up timer for subsequent recordings
        timer = Timer.scheduledTimer(withTimeInterval: recordingInterval, repeats: true) { [weak self] _ in
            self?.startSimultaneousRecording()
        }
    }
    
    func stopPeriodicRecording() {
        timer?.invalidate()
        timer = nil
        
        if isRecording {
            stopSimultaneousRecording()
        }
    }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        // Check camera and microphone permissions
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        func checkBothPermissions() {
            let cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
            let audioAuthorized = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
            DispatchQueue.main.async {
                completion(cameraAuthorized && audioAuthorized)
            }
        }
        
        if cameraStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { _ in
                if audioStatus == .notDetermined {
                    AVCaptureDevice.requestAccess(for: .audio) { _ in
                        checkBothPermissions()
                    }
                } else {
                    checkBothPermissions()
                }
            }
        } else if audioStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { _ in
                checkBothPermissions()
            }
        } else {
            checkBothPermissions()
        }
    }
    
    // MARK: File Management
    
    private func getDocumentsDirectory() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private func loadSavedVideos() {
        do {
            let directory = getDocumentsDirectory()
            let files = try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            videoURLs = files.filter { $0.pathExtension.lowercased() == "mp4" }
            print("Found \(videoURLs.count) existing videos")
        } catch {
            print("Error loading videos: \(error)")
        }
    }
    
    func deleteVideo(at url: URL) {
        do {
            try FileManager.default.removeItem(at: url)
            if let index = videoURLs.firstIndex(of: url) {
                videoURLs.remove(at: index)
            }
        } catch {
            print("Error deleting video: \(error)")
        }
    }
    
    func deleteAllVideos() {
        for url in videoURLs {
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                print("Error deleting video: \(error)")
            }
        }
        videoURLs.removeAll()
    }
    
    deinit {
        stopPeriodicRecording()
        multiCamSession?.stopRunning()
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension MultiCamManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        // Recording started for one of the outputs
        print("Started recording to: \(fileURL.path)")
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error recording to \(outputFileURL.path): \(error)")
        } else {
            // Check file size to ensure it's valid
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: outputFileURL.path) {
                do {
                    let attributes = try fileManager.attributesOfItem(atPath: outputFileURL.path)
                    let fileSize = attributes[.size] as? UInt64 ?? 0
                    print("Recorded video: \(outputFileURL.lastPathComponent), size: \(fileSize) bytes")
                    
                    if fileSize > 1000 {
                        DispatchQueue.main.async {
                            self.videoURLs.append(outputFileURL)
                            self.videoURLs.sort { $0.lastPathComponent > $1.lastPathComponent }
                        }
                    }
                } catch {
                    print("Error checking file: \(error)")
                }
            }
        }
        
        // Check if all recordings have stopped
        DispatchQueue.main.async {
            let backRecording = self.backCameraOutput?.isRecording ?? false
            let frontRecording = self.frontCameraOutput?.isRecording ?? false
            
            if !backRecording && !frontRecording {
                self.isRecording = false
            }
        }
    }
}