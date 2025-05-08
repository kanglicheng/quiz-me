import Foundation
import AVFoundation
import UIKit

class VideoRecorderManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var latestVideoURL: URL?

    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var timer: Timer?
    private var recordingInterval: TimeInterval = 10.0 // 10 seconds between recordings
    private var recordingDuration: TimeInterval = 5.0 // 5 second clips

    override init() {
        super.init()
        setupCaptureSession()
    }

    private func setupCaptureSession() {
    #if targetEnvironment(simulator)
    print("Camera recording is not available in the simulator")
    return
    #endif

    captureSession = AVCaptureSession()
    
    // Configure session for high quality video
    captureSession?.sessionPreset = .high
    
    // Find back camera
    guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
        print("Unable to access back camera - device may not have a camera")
        return
    }
    
    // Find audio device
    guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
        print("Unable to access audio device")
        return
    }
    
    do {
        // Configure video input
        let videoInput = try AVCaptureDeviceInput(device: backCamera)
        if captureSession!.canAddInput(videoInput) {
            captureSession!.addInput(videoInput)
            print("Successfully added video input")
        } else {
            print("Could not add video input to session")
        }
        
        // Configure audio input
        let audioInput = try AVCaptureDeviceInput(device: audioDevice)
        if captureSession!.canAddInput(audioInput) {
            captureSession!.addInput(audioInput)
            print("Successfully added audio input")
        } else {
            print("Could not add audio input to session")
        }
        
        // Configure video output
        videoOutput = AVCaptureMovieFileOutput()
        if let videoOutput = videoOutput, captureSession!.canAddOutput(videoOutput) {
            captureSession!.addOutput(videoOutput)
            print("Successfully added video output")
            
            // Set maximum duration for recording (in seconds)
            videoOutput.maxRecordedDuration = CMTime(seconds: recordingDuration, preferredTimescale: 600)
        } else {
            print("Could not add video output to session")
        }
        
        // Start the session asynchronously to avoid blocking the UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            print("Starting capture session...")
            self?.captureSession?.startRunning()
            if let running = self?.captureSession?.isRunning {
                print("Capture session running: \(running)")
            }
        }
        
    } catch {
        print("Error setting up capture session: \(error)")
    }
}

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
                // After camera permission is determined, check audio
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
        guard let videoOutput = videoOutput, !isRecording, captureSession?.isRunning == true else {
            print("Cannot start recording: output=\(videoOutput != nil), isRecording=\(isRecording), captureSession running=\(captureSession?.isRunning)")
            return
        }

    // Create a unique filename with timestamp
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    let dateString = dateFormatter.string(from: Date())
    let filename = "quiz_video_\(dateString).mp4"

    let videoFilename = getDocumentsDirectory().appendingPathComponent(filename)

    // Make sure the file doesn't already exist
    if FileManager.default.fileExists(atPath: videoFilename.path) {
        try? FileManager.default.removeItem(at: videoFilename)
    }

    print("Starting video recording to: \(videoFilename)")

    // Start recording
    videoOutput.startRecording(to: videoFilename, recordingDelegate: self)
    isRecording = true

    // Set up timer to stop recording after the specified duration
    DispatchQueue.main.asyncAfter(deadline: .now() + recordingDuration) { [weak self] in
        self?.stopRecording()
    }
}

    private func stopRecording() {
        guard let videoOutput = videoOutput, isRecording else {
            return
}

        print("Stopping video recording")
        videoOutput.stopRecording()
        // isRecording will be set to false in the delegate method
    }

    private func getDocumentsDirectory() -> URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return paths[0]
    }

    func getVideos() -> [URL] {
        let documentsDirectory = getDocumentsDirectory()
    let fileManager = FileManager.default
    do {
            let directoryContents = try fileManager.contentsOfDirectory(at: documentsDirectory, includingPropertiesForKeys: nil)
            return directoryContents.filter { $0.pathExtension == "mp4" }
        } catch {
            print("Error getting videos: \(error)")
            return []
        }
    }

    deinit {
        stopPeriodicRecording()
        captureSession?.stopRunning()
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension VideoRecorderManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        // Recording started
        DispatchQueue.main.async {
            self.isRecording = true
        }
        print("Recording started to: \(fileURL)")
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        // Verify the file exists and has content
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: outputFileURL.path) {
            do {
                let attributes = try fileManager.attributesOfItem(atPath: outputFileURL.path)
                let fileSize = attributes[.size] as? UInt64 ?? 0
                print("Video saved successfully to: \(outputFileURL)")
                print("File size: \(fileSize) bytes")
            } catch {
                print("Error checking file attributes: \(error)")
            }
        } else {
            print("Video file does not exist at path: \(outputFileURL.path)")
    }

        // Recording finished
        DispatchQueue.main.async {
            self.isRecording = false
            self.latestVideoURL = outputFileURL
}

        if let error = error {
            print("Error recording video: \(error)")
        } else {
            print("Recording finished successfully")
        }
    }
}
