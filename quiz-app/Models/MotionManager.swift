//
//  MotionManager.swift
//  quiz-app
//
//  Created by Stephen Cheng on 5/7/25.
//

import Foundation
import CoreMotion

class MotionManager: ObservableObject {
    private let motionManager = CMMotionManager()
    @Published var isDeviceFlat = false
    
    init() {
        // Check if motion data is available
        if motionManager.isDeviceMotionAvailable {
            // Set update interval
            motionManager.deviceMotionUpdateInterval = 0.2
            
            // Start monitoring device motion
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
                guard let data = data, error == nil else { return }
                
                // Get gravity vector
                let gravity = data.gravity
                
                // Check if device is lying flat on its back
                // When flat, z-component of gravity is close to -1
                // Small threshold for slight device tilt
                let isFlat = abs(gravity.z + 1.0) < 0.2
                
                // Update state if changed
                if self?.isDeviceFlat != isFlat {
                    self?.isDeviceFlat = isFlat
                }
            }
        }
    }
    
    deinit {
        // Stop monitoring when object is deallocated
        motionManager.stopDeviceMotionUpdates()
    }
}
