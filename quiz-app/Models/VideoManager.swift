import Foundation
import AVFoundation
import UIKit

class VideoManager: NSObject, ObservableObject {
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var videoURLs: [URL] = []
    
    // MARK: - Private Properties
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var timer: Timer?
    
    // Recording configuration
    private let recordingDuration: TimeInterval = 5.0  // 5 second clips
    private let recordingInterval: TimeInterval = 10.0 // Every 10 seconds
    
    // Camera alternating state
    private var cameraSwitchCount = 0
    private var alternatingCamerasEnabled = true
    
    // MARK: - Initialization
    override init() {
        super.init()
        setupCaptureSession()
        loadSavedVideos()
    }
    
    // MARK: - Session Setup
    private func setupCaptureSession() {
        #if targetEnvironment(simulator)
        print("Camera recording is not available in the simulator")
        return
        #endif
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .medium
        
        // Configure video output
        videoOutput = AVCaptureMovieFileOutput()
        if let videoOutput = videoOutput, let captureSession = captureSession {
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
                videoOutput.maxRecordedDuration = CMTime(seconds: recordingDuration, preferredTimescale: 30)
                print("Added video output to session")
            }
        }
        
        // Start the session in background
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession?.startRunning()
            print("Capture session started")
        }
    }
    
    // MARK: - Camera Configuration
    private func configureCameraForRecording() {
        guard let captureSession = self.captureSession, captureSession.isRunning else {
            print("Cannot configure camera: No active capture session")
            return
        }
        
        // Determine which camera to use (even = back, odd = front)
        let useFrontCamera = cameraSwitchCount % 2 == 1
        
        print("Configuring camera #\(cameraSwitchCount+1): \(useFrontCamera ? "Front" : "Back")")
        
        // Begin configuration
        captureSession.beginConfiguration()
        
        // Remove all existing inputs
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }
        
        // Add the selected camera
        let cameraPosition = useFrontCamera ? AVCaptureDevice.Position.front : .back
        
        if let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition) {
            do {
                let cameraInput = try AVCaptureDeviceInput(device: camera)
                if captureSession.canAddInput(cameraInput) {
                    captureSession.addInput(cameraInput)
                    print("Added \(useFrontCamera ? "front" : "back") camera input")
                }
            } catch {
                print("Error creating camera input: \(error)")
            }
        } else {
            print("Could not find \(useFrontCamera ? "front" : "back") camera")
        }
        
        // Add audio input
        if let audioDevice = AVCaptureDevice.default(for: .audio) {
            do {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if captureSession.canAddInput(audioInput) {
                    captureSession.addInput(audioInput)
                    print("Added audio input")
                }
            } catch {
                print("Error adding audio input: \(error)")
            }
        }
        
        // Commit configuration
        captureSession.commitConfiguration()
    }
    
    // MARK: - Recording Methods
    func startPeriodicRecording() {
        guard captureSession?.isRunning == true else {
            print("Cannot start recording: Capture session not running")
            return
        }
        
        // Reset counter and start with back camera
        cameraSwitchCount = 0
        configureCameraForRecording()
        
        // Start first recording after brief delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.startSingleRecording()
        }
        
        // Set up timer for subsequent recordings
        timer = Timer.scheduledTimer(withTimeInterval: recordingInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Increment counter to alternate cameras if enabled
            if self.alternatingCamerasEnabled {
                self.cameraSwitchCount += 1
                print("Timer fired - preparing recording #\(self.cameraSwitchCount+1)")
                self.configureCameraForRecording()
            }
            
            // Wait briefly for camera configuration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.startSingleRecording()
            }
        }
    }
    
    func stopPeriodicRecording() {
        // Cancel timer
        timer?.invalidate()
        timer = nil
        
        // Stop any ongoing recording
        if isRecording {
            videoOutput?.stopRecording()
        }
        
        print("Periodic recording stopped")
    }
    
    private func startSingleRecording() {
        guard let videoOutput = videoOutput, !isRecording, captureSession?.isRunning == true else {
            print("Cannot start recording: output=\(videoOutput != nil), isRecording=\(isRecording), sessionRunning=\(captureSession?.isRunning == true)")
            return
        }
        
        // Verify which camera is active
        var currentCameraIsFront = false
        if let captureSession = captureSession {
            for input in captureSession.inputs {
                if let deviceInput = input as? AVCaptureDeviceInput,
                   deviceInput.device.hasMediaType(.video) {
                    currentCameraIsFront = deviceInput.device.position == .front
                    break
                }
            }
        }
        
        // Create filename with timestamp and camera info
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = dateFormatter.string(from: Date())
        let cameraTag = currentCameraIsFront ? "front" : "back"
        let filename = "video_\(timestamp)_\(cameraTag).mp4"
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)
        
        print("Starting recording to: \(fileURL.path) with \(currentCameraIsFront ? "front" : "back") camera")
        videoOutput.startRecording(to: fileURL, recordingDelegate: self)
    }
    
    // MARK: - Permission Handling
    func requestPermission(completion: @escaping (Bool) -> Void) {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let audioStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        // Helper function to check both permissions
        func checkBothPermissions() {
            let cameraAuthorized = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
            let audioAuthorized = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
            
            DispatchQueue.main.async {
                completion(cameraAuthorized && audioAuthorized)
            }
        }
        
        // Request camera permission if needed
        if cameraStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { _ in
                // After camera permission, check audio
                if audioStatus == .notDetermined {
                    AVCaptureDevice.requestAccess(for: .audio) { _ in
                        checkBothPermissions()
                    }
                } else {
                    checkBothPermissions()
                }
            }
        } 
        // Request audio permission if camera is already determined
        else if audioStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { _ in
                checkBothPermissions()
            }
        } 
        // Both permissions are already determined
        else {
            checkBothPermissions()
        }
    }
    
    // MARK: - File Management
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
            print("Deleted video: \(url.lastPathComponent)")
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
        print("All videos deleted")
    }
    
    // MARK: - Configuration
    func setAlternatingCameras(enabled: Bool) {
        alternatingCamerasEnabled = enabled
        print("Camera alternating \(enabled ? "enabled" : "disabled")")
    }
    
    // MARK: - Cleanup
    deinit {
        stopPeriodicRecording()
        captureSession?.stopRunning()
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension VideoManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        DispatchQueue.main.async {
            self.isRecording = true
            print("Recording started")
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        // Handle recording error if any
        if let error = error {
            print("Error recording video: \(error)")
        }
        
        // Verify the recording
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: outputFileURL.path) {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: outputFileURL.path)
                let fileSize = attributes[.size] as? UInt64 ?? 0
                print("Recorded video: \(outputFileURL.lastPathComponent), size: \(fileSize) bytes")
                
                DispatchQueue.main.async {
                    // Only add to videoURLs if file size is reasonable
                    if fileSize > 1000 {
                        self.videoURLs.append(outputFileURL)
                        // Sort videos by name (newest first)
                        self.videoURLs.sort { $0.lastPathComponent > $1.lastPathComponent }
                    } else {
                        print("Warning: Video file too small, may be corrupted")
                    }
                    
                    self.isRecording = false
                }
            } catch {
                print("Error checking file: \(error)")
                DispatchQueue.main.async {
                    self.isRecording = false
                }
            }
        } else {
            print("Warning: Recorded file does not exist")
            DispatchQueue.main.async {
                self.isRecording = false
            }
        }
    }
}