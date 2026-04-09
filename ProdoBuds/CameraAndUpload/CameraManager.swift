//
//  ViewController.swift
//  ProdoBuds
//
//  Created by Jean-Claude Bissou on 3/5/26.
//

import Foundation
import AVFoundation

class CameraManager: NSObject {
    
    private let captureSession = AVCaptureSession()
    
    private var deviceInput: AVCaptureDeviceInput?
    
    private var videoOutput: AVCaptureVideoDataOutput?
    
    private var currentCamera: AVCaptureDevice?
    
    private let systemPreferredCamera = AVCaptureDevice.default(for: .video)
    
    private var sessionQueue: DispatchQueue = DispatchQueue(label: "video.preview.session")
    
    // Video recording properties
    private var assetWriter: AVAssetWriter?
    private var assetWriterInput: AVAssetWriterInput?
    private var isRecording = false
    private var recordingStartTime: CMTime?
    private var outputURL: URL?
    private var frameCount: Int = 0
    
    // Timelapse settings
    private(set) var captureFPS: Int32 = 5  // Frames captured per second
    private let playbackFPS: Int32 = 30  // Frames played back per second

    private var isAuthorized: Bool {
        get async {
            let status = AVCaptureDevice.authorizationStatus(for: .video)
            
            // Determine if the user previously authorized camera access.
            var isAuthorized = status == .authorized
            
            // If the system hasn't determined the user's authorization status,
            // explicitly prompt them for approval.
            if status == .notDetermined {
                isAuthorized = await AVCaptureDevice.requestAccess(for: .video)
            }
            
            return isAuthorized
        }
    }
    
    private var addToPreviewStream: ((CGImage) -> Void)?
    
    lazy var previewStream: AsyncStream<CGImage> = {
        AsyncStream { continuation in
            addToPreviewStream = { cgImage in
                continuation.yield(cgImage)
            }
        }
    }()
    
    override init() {
        super.init()
        
        Task {
            await configureSession()
            await startSession()
        }
    }
    
    private func configureSession() async {
        
        guard await isAuthorized,
              let systemPreferredCamera,
              let deviceInput = try? AVCaptureDeviceInput(device: systemPreferredCamera)
        else { return }
        
        // Set the current camera
        currentCamera = systemPreferredCamera
        self.deviceInput = deviceInput
        
        captureSession.beginConfiguration()
        
        defer {
            self.captureSession.commitConfiguration()
        }
        
        // Configure device for lower frame rate (timelapse)
        do {
            try systemPreferredCamera.lockForConfiguration()
            
            // Check supported frame rates
            if let format = systemPreferredCamera.activeFormat.videoSupportedFrameRateRanges.first {
                print("Supported frame rate range: \(format.minFrameRate) - \(format.maxFrameRate) fps")
            }
            
            // Set to lower frame rate for timelapse effect
            systemPreferredCamera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: captureFPS)
            systemPreferredCamera.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: captureFPS)
            
            print("Camera configured for timelapse at \(captureFPS) fps")
            print("Actual min duration: \(systemPreferredCamera.activeVideoMinFrameDuration)")
            print("Actual max duration: \(systemPreferredCamera.activeVideoMaxFrameDuration)")
            
            systemPreferredCamera.unlockForConfiguration()
        } catch {
            print("Failed to configure camera frame rate: \(error)")
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        self.videoOutput = videoOutput
        
        guard captureSession.canAddInput(deviceInput) else {
            print("Unable to add device input to capture session.")
            return
        }
        
        guard captureSession.canAddOutput(videoOutput) else {
            print("Unable to add video output to capture session.")
            return
        }
        
        captureSession.addInput(deviceInput)
        captureSession.addOutput(videoOutput)
    }
    
    private func startSession() async {
        guard await isAuthorized else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.startRunning()
            
            // Configure frame rate AFTER session starts to prevent AVFoundation from overriding it
            guard let camera = self.currentCamera else { return }
            
            do {
                try camera.lockForConfiguration()
                
                // Check supported frame rates
                if let format = camera.activeFormat.videoSupportedFrameRateRanges.first {
                    print("Supported frame rate range: \(format.minFrameRate) - \(format.maxFrameRate) fps")
                }
                
                // Set to lower frame rate for timelapse effect
                camera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: captureFPS)
                camera.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: captureFPS)
                
                print("Camera configured for timelapse at \(captureFPS) fps (after session start)")
                print("Will play back at 30 fps for \(30/captureFPS)x speed")
                print("Actual min duration: \(camera.activeVideoMinFrameDuration)")
                print("Actual max duration: \(camera.activeVideoMaxFrameDuration)")
                
                camera.unlockForConfiguration()
            } catch {
                print("Failed to configure camera frame rate: \(error)")
            }
        }
    }
    
    // MARK: - Video Recording
    
    func startRecording() {
        // Check permissions and device availability
        guard systemPreferredCamera != nil else {
            print("No camera device available")
            return
        }
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        guard status == .authorized else {
            print("Camera access not authorized")
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self, !self.isRecording else { return }
            
            // Create output URL
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let videoFileName = "video_\(Date().timeIntervalSince1970).mov"
            let outputURL = documentsPath.appendingPathComponent(videoFileName)
            
            // Remove file if it already exists
            try? FileManager.default.removeItem(at: outputURL)
            
            self.outputURL = outputURL
            
            // Create asset writer
            guard let assetWriter = try? AVAssetWriter(outputURL: outputURL, fileType: .mov) else {
                print("Failed to create AVAssetWriter")
                return
            }
            
            // Configure video settings for timelapse playback
            // Capture at 5fps but encode for 30fps playback = 6x speed
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 1920,
                AVVideoHeightKey: 1080,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 6000000,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel,
                    AVVideoExpectedSourceFrameRateKey: 30,  // Playback frame rate
                    AVVideoMaxKeyFrameIntervalKey: 30       // One keyframe per second at 30fps
                ]
            ]
            
            let assetWriterInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
            assetWriterInput.expectsMediaDataInRealTime = true
            
            // Set transform for portrait orientation
            assetWriterInput.transform = CGAffineTransform(rotationAngle: .pi / 2)
            
            if assetWriter.canAdd(assetWriterInput) {
                assetWriter.add(assetWriterInput)
            } else {
                print("Cannot add asset writer input")
                return
            }
            
            self.assetWriter = assetWriter
            self.assetWriterInput = assetWriterInput
            self.isRecording = true
            self.recordingStartTime = nil
            self.frameCount = 0
            
            print("Recording setup complete, ready to write at \(self.captureFPS) fps → \(self.playbackFPS) fps playback")
        }
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        // Check permissions and device availability
        guard systemPreferredCamera != nil else {
            print("No camera device available - returning placeholder URL")
            let placeholderURL = URL(string: "https://firebasestorage.googleapis.com/v0/b/gameofchats-762ca.appspot.com/o/message_movies%2F12323439-9729-4941-BA07-2BAE970967C7.mov?alt=media&token=3e37a093-3bc8-410f-84d3-38332af9c726")
            completion(placeholderURL)
            return
        }
        
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        guard status == .authorized else {
            print("Camera access not authorized - returning placeholder URL")
            let placeholderURL = URL(string: "https://firebasestorage.googleapis.com/v0/b/gameofchats-762ca.appspot.com/o/message_movies%2F12323439-9729-4941-BA07-2BAE970967C7.mov?alt=media&token=3e37a093-3bc8-410f-84d3-38332af9c726")
            completion(placeholderURL)
            return
        }
        
        sessionQueue.async { [weak self] in
            guard let self = self, self.isRecording else {
                completion(nil)
                return
            }
            
            self.isRecording = false
            
            guard let assetWriter = self.assetWriter,
                  let assetWriterInput = self.assetWriterInput else {
                completion(nil)
                return
            }
            
            assetWriterInput.markAsFinished()
            
            let outputURL = self.outputURL
            
            assetWriter.finishWriting {
                DispatchQueue.main.async {
                    if assetWriter.status == .completed {
                        print("Video saved successfully at: \(outputURL?.path ?? "unknown")")
                        completion(outputURL)
                    } else {
                        print("Failed to save video: \(assetWriter.error?.localizedDescription ?? "unknown error")")
                        completion(nil)
                    }
                }
                
                self.assetWriter = nil
                self.assetWriterInput = nil
                self.recordingStartTime = nil
                self.outputURL = nil
                self.frameCount = 0
            }
        }
    }
    
    // MARK: - FPS Configuration
    
    func setCaptureFPS(_ fps: Int32) {
        guard [2, 5, 10, 15].contains(fps) else {
            print("Invalid FPS value. Must be 2, 5, 10, or 15")
            return
        }
        
        captureFPS = fps
        
        // Update camera frame rate if available
        guard let camera = currentCamera else { return }
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            do {
                try camera.lockForConfiguration()
                
                camera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: fps)
                camera.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: fps)
                
                print("Camera FPS updated to \(fps) fps")
                print("Playback will be at \(self.playbackFPS) fps for \(self.playbackFPS/fps)x speed")
                
                camera.unlockForConfiguration()
            } catch {
                print("Failed to update camera frame rate: \(error)")
            }
        }
    }
    
    // MARK: - Camera Control
    
    func flipCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.beginConfiguration()
            defer { self.captureSession.commitConfiguration() }
            
            // Remove current input
            if let currentInput = self.deviceInput {
                self.captureSession.removeInput(currentInput)
            }
            
            // Determine new camera position
            let currentPosition = self.currentCamera?.position ?? .back
            let newPosition: AVCaptureDevice.Position = currentPosition == .back ? .front : .back
            
            // Find camera with new position
            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera],
                mediaType: .video,
                position: newPosition
            )
            
            guard let newCamera = discoverySession.devices.first else {
                print("No camera available for position: \(newPosition)")
                // Re-add the current input if flip fails
                if let currentInput = self.deviceInput {
                    self.captureSession.addInput(currentInput)
                }
                return
            }
            
            // Create new input
            do {
                let newInput = try AVCaptureDeviceInput(device: newCamera)
                
                if self.captureSession.canAddInput(newInput) {
                    self.captureSession.addInput(newInput)
                    self.deviceInput = newInput
                    self.currentCamera = newCamera
                    
                    // Configure the new camera for timelapse
                    try newCamera.lockForConfiguration()
                    newCamera.activeVideoMinFrameDuration = CMTime(value: 1, timescale: self.captureFPS)
                    newCamera.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: self.captureFPS)
                    newCamera.unlockForConfiguration()
                    
                    print("Flipped to \(newPosition == .front ? "front" : "back") camera")
                } else {
                    print("Cannot add new camera input")
                    // Re-add the current input if flip fails
                    if let currentInput = self.deviceInput {
                        self.captureSession.addInput(currentInput)
                    }
                }
            } catch {
                print("Error switching camera: \(error)")
                // Re-add the current input if flip fails
                if let currentInput = self.deviceInput {
                    self.captureSession.addInput(currentInput)
                }
            }
        }
    }
}

extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let currentFrame = sampleBuffer.cgImage else { return }
        addToPreviewStream?(currentFrame)
        
        // Write video frame if recording
        if isRecording {
            guard let assetWriter = assetWriter,
                  let assetWriterInput = assetWriterInput else { return }
            
            // Start writing if this is the first frame
            if recordingStartTime == nil {
                // Calculate adjusted timestamp for playback speed
                let adjustedStartTime = CMTime(value: 0, timescale: playbackFPS)
                recordingStartTime = adjustedStartTime
                assetWriter.startWriting()
                assetWriter.startSession(atSourceTime: adjustedStartTime)
                print("Started writing video with \(captureFPS) fps → \(playbackFPS) fps playback")
            }
            
            // Append the sample buffer with adjusted timestamp
            if assetWriterInput.isReadyForMoreMediaData {
                // Calculate the presentation time for this frame at playback speed
                // Each frame should be 1/playbackFPS seconds apart
                let adjustedTimestamp = CMTime(value: CMTimeValue(frameCount), timescale: playbackFPS)
                
                // Create a new sample buffer with the adjusted timestamp
                if let adjustedBuffer = createAdjustedSampleBuffer(from: sampleBuffer, withPresentationTime: adjustedTimestamp) {
                    assetWriterInput.append(adjustedBuffer)
                    frameCount += 1
                    
                    if frameCount % 30 == 0 {
                        let realTime = Double(frameCount) / Double(captureFPS)
                        let playbackTime = Double(frameCount) / Double(playbackFPS)
                        print("Frame \(frameCount): \(String(format: "%.1f", realTime))s real → \(String(format: "%.1f", playbackTime))s playback")
                    }
                }
            }
        }
    }
    
    private func createAdjustedSampleBuffer(from sampleBuffer: CMSampleBuffer, withPresentationTime presentationTime: CMTime) -> CMSampleBuffer? {
        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: playbackFPS),
            presentationTimeStamp: presentationTime,
            decodeTimeStamp: .invalid
        )
        
        var adjustedSampleBuffer: CMSampleBuffer?
        
        CMSampleBufferCreateCopyWithNewTiming(
            allocator: kCFAllocatorDefault,
            sampleBuffer: sampleBuffer,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timingInfo,
            sampleBufferOut: &adjustedSampleBuffer
        )
        
        return adjustedSampleBuffer
    }
}
