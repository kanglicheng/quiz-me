import Foundation
import AVFoundation
import UIKit

class VideoManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var videoURLs: [URL] = []
    @Published var isUsingFrontCamera = false
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var timer: Timer?
    private let recordingDuration: TimeInterval = 5.0 // 5 second clips
    private let recordingInterval: TimeInterval = 10.0 // Every 10 seconds
    
    private var currentVideoInput: AVCaptureDeviceInput?
    private var shouldAlternateCamera = true // Control whether to alternate cameras

    override init() {
        super.init()
        setupCaptureSession()
        loadSavedVideos()
    }
    
    private func setupCaptureSession() {
        #if targetEnvironment(simulator)
        print("Camera recording is not available in the simulator")
        return
        #endif
        
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .medium

        // Start with back camera
        addCameraInput(position: .back)

        // Configure microphone
        guard let microphone = AVCaptureDevice.default(for: .audio) else {
            print("Could not find microphone")
            return
        }
        
        do {
            // Add microphone input
            let micInput = try AVCaptureDeviceInput(device: microphone)
            if captureSession!.canAddInput(micInput) {
                captureSession!.addInput(micInput)
                print("Added microphone input")
            }
            
            // Configure video output
            videoOutput = AVCaptureMovieFileOutput()
            videoOutput?.maxRecordedDuration = CMTime(seconds: recordingDuration, preferredTimescale: 30)
            
            if let videoOutput = videoOutput, captureSession!.canAddOutput(videoOutput) {
                captureSession!.addOutput(videoOutput)
                print("Added video output")
            }
            
            // Start the session in the background
            DispatchQueue.global(qos: .background).async { [weak self] in
                self?.captureSession?.startRunning()
                print("Capture session started")
            }
            
        } catch {
            print("Error setting up capture session: \(error)")
        }
    }
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        let cameraAuthStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let micAuthStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        // Helper to check final status
        func checkFinalStatus() {
            let cameraGranted = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
            let micGranted = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
            DispatchQueue.main.async {
                completion(cameraGranted && micGranted)
            }
        }
        
        // Request camera permission if needed
        if cameraAuthStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { _ in
                // After camera permission, check microphone
                if micAuthStatus == .notDetermined {
                    AVCaptureDevice.requestAccess(for: .audio) { _ in
                        checkFinalStatus()
                    }
                } else {
                    checkFinalStatus()
                }
            }
        } else if micAuthStatus == .notDetermined {
            // Camera already determined, just check microphone
            AVCaptureDevice.requestAccess(for: .audio) { _ in
                checkFinalStatus()
            }
        } else {
            // Both already determined
            checkFinalStatus()
        }
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
    
    func stopPeriodicRecording() {
        // Cancel timer
        timer?.invalidate()
        timer = nil
        
        // Stop any ongoing recording
        if isRecording {
            videoOutput?.stopRecording()
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
    
    func getVideoThumbnail(for url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        
        // Try to get thumbnail at 0.5 seconds
        do {
            let time = CMTime(seconds: 0.5, preferredTimescale: 30)
            let imageRef = try imageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch {
            print("Error generating thumbnail: \(error)")
            return nil
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
    
    private func addCameraInput(position: AVCaptureDevice.Position) {
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: position) else {
            print("Could not find \(position == .front ? "front" : "back") camera")
            return
        }

        do {
            // Create new input
            let newInput = try AVCaptureDeviceInput(device: camera)

            // Begin configuration
            captureSession?.beginConfiguration()

            // Remove existing camera input if any
            if let currentInput = currentVideoInput {
                captureSession?.removeInput(currentInput)
            }

            // Add the new input
            if captureSession!.canAddInput(newInput) {
                captureSession!.addInput(newInput)
                currentVideoInput = newInput
                isUsingFrontCamera = (position == .front)
                print("Switched to \(position == .front ? "front" : "back") camera")
            }

            // Commit configuration
            captureSession?.commitConfiguration()

        } catch {
            print("Error adding camera input: \(error)")
        }
    }

    func toggleCamera() {
        let newPosition: AVCaptureDevice.Position = isUsingFrontCamera ? .back : .front
        addCameraInput(position: newPosition)
    }

    func setCamera(front: Bool) {
        let newPosition: AVCaptureDevice.Position = front ? .front : .back
        if isUsingFrontCamera != front {
            addCameraInput(position: newPosition)
        }
    }

    func toggleAutoCameraSwitching(_ enabled: Bool) {
        shouldAlternateCamera = enabled
    }

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
        if let error = error {
            print("Error recording: \(error)")
        }
        
        // Verify the recording
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: outputFileURL.path) {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: outputFileURL.path)
                let fileSize = attributes[.size] as? UInt64 ?? 0
                print("Recorded video: \(outputFileURL.lastPathComponent), size: \(fileSize) bytes")
                
                if fileSize > 1000 {
                    // Add to our video list if size is reasonable
                    DispatchQueue.main.async {
                        self.videoURLs.append(outputFileURL)
                        self.videoURLs.sort { $0.lastPathComponent > $1.lastPathComponent }
                    }
                } else {
                    print("Video file too small, may be corrupted")
                }
            } catch {
                print("Error checking file: \(error)")
            }
        }
        
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }
}
