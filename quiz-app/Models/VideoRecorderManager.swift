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

// In HomeView.swift
.navigationDestination(isPresented: $showVideos) {
    VideoPlayerView()
        .environmentObject(videoRecorderManager)
}

// Add this somewhere in VideoPlayerView
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
