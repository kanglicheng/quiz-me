import Foundation
import AVFoundation
import UIKit

class VideoManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var videoURLs: [URL] = []
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var timer: Timer?
    private let recordingDuration: TimeInterval = 5.0 // 5 second clips
    private let recordingInterval: TimeInterval = 10.0 // Every 10 seconds
    
    private var isUsingFrontCamera = false
    private var alternatingCamerasEnabled = true
    private var cameraSwitchCount = 0

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
        captureSession?.sessionPreset = .medium // Use medium quality for better performance
        
        // Configure camera
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("Could not find back camera")
            return
        }
        
        // Configure microphone
        guard let microphone = AVCaptureDevice.default(for: .audio) else {
            print("Could not find microphone")
            return
        }
        
        do {
            // Add camera input
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            if captureSession!.canAddInput(cameraInput) {
                captureSession!.addInput(cameraInput)
                print("Added camera input")
            }
            
            // Add microphone input
            let micInput = try AVCaptureDeviceInput(device: microphone)
            if captureSession!.canAddInput(micInput) {
                captureSession!.addInput(micInput)
                print("Added microphone input")
            }
            
            // Configure video output
            videoOutput = AVCaptureMovieFileOutput()
            
            // Limit max recording duration
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
    
    private func setupCameraForRecording() {
        guard let captureSession = captureSession else { return }

        // Determine which camera to use based on alternating pattern
        let shouldUseFrontCamera: Bool

        if alternatingCamerasEnabled {
            // If we're alternating, use the cameraSwitchCount to determine which camera
            shouldUseFrontCamera = cameraSwitchCount % 2 == 1 // Odd numbers use front camera
        } else {
            // If not alternating, just use the current camera
            shouldUseFrontCamera = isUsingFrontCamera
        }

        // Begin configuration
        captureSession.beginConfiguration()

        // Remove all existing inputs
        for input in captureSession.inputs {
            captureSession.removeInput(input)
        }

        // Determine which camera device to use
        let cameraPosition = shouldUseFrontCamera ? AVCaptureDevice.Position.front : .back
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: cameraPosition) else {
            print("Could not find \(shouldUseFrontCamera ? "front" : "back") camera")
            captureSession.commitConfiguration()
            return
        }

        do {
            // Add camera input
            let cameraInput = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(cameraInput) {
                captureSession.addInput(cameraInput)
                print("Using \(shouldUseFrontCamera ? "front" : "back") camera")

                // Update the tracking property
                isUsingFrontCamera = shouldUseFrontCamera
                // Add audio input
                if let audioDevice = AVCaptureDevice.default(for: .audio) {
                    let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                    if captureSession.canAddInput(audioInput) {
                        captureSession.addInput(audioInput)
                    }
                }
            }
            } catch {
            print("Error setting up camera: \(error)")
            }

        captureSession.commitConfiguration()
        }
        
    func startPeriodicRecording() {
        guard captureSession?.isRunning == true else {
            print("Capture session not running")
            return
        }

        // Reset our counter when starting fresh
        cameraSwitchCount = 0

        // Setup initial camera (back camera)
        setupCameraForRecording()

        // Start first recording
        startSingleRecording()

        // Set up timer for periodic recordings
        timer = Timer.scheduledTimer(withTimeInterval: recordingInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            // Increment the counter before setting up camera
            self.cameraSwitchCount += 1

            // Setup camera for this recording
            self.setupCameraForRecording()

            // Short delay to ensure camera is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // Start new recording
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
    }
    
    private func startSingleRecording() {
        guard let videoOutput = videoOutput, !isRecording, captureSession?.isRunning == true else {
            print("Cannot start recording")
            return
        }
        // Determine current camera
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

        // Create filename with camera info
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let cameraInfo = currentCameraIsFront ? "front" : "back"
        let filename = "video_\(dateFormatter.string(from: Date()))_\(cameraInfo).mp4"
        let fileURL = getDocumentsDirectory().appendingPathComponent(filename)

        print("Starting recording with \(currentCameraIsFront ? "front" : "back") camera to: \(fileURL.path)")
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
    
    deinit {
        stopPeriodicRecording()
        captureSession?.stopRunning()
    }

    func switchCamera() {
        // Determine current camera
        var isCurrentlyFrontCamera = false
        if let captureSession = captureSession, !captureSession.inputs.isEmpty {
            for input in captureSession.inputs {
                if let deviceInput = input as? AVCaptureDeviceInput,
                   deviceInput.device.hasMediaType(.video) {
                    isCurrentlyFrontCamera = deviceInput.device.position == .front
                    break
                }
            }
        }

        // Switch to the other camera
        if isCurrentlyFrontCamera {
            _ = setupBackCamera()
        } else {
            _ = setupFrontCamera()
        }
    }

    func setAlternatingCameras(enabled: Bool) {
        alternatingCamerasEnabled = enabled
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
