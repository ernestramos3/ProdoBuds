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
    
    private var deviceInput: AVCaptureDevice?
    
    private var videoOutput: AVCaptureVideoDataOutput?
    
    private let systemPreferredCamera = AVCaptureDevice.default(for: .video)
    
    private var sessionQueue: DispatchQueue = DispatchQueue(label: "video.preview.session")
    
    // Video recording properties
    private var assetWriter: AVAssetWriter?
    private var assetWriterInput: AVAssetWriterInput?
    private var isRecording = false
    private var recordingStartTime: CMTime?
    private var outputURL: URL?

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
        
        captureSession.beginConfiguration()
        
        defer {
            self.captureSession.commitConfiguration()
        }
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
        
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
        
        captureSession.startRunning()
    }
    
    // MARK: - Video Recording
    
    func startRecording() {
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
            
            // Configure video settings
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 1920,
                AVVideoHeightKey: 1080,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 6000000,
                    AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel
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
            
            print("Recording setup complete, ready to write")
        }
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
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
            
            let timestamp = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            
            // Start writing if this is the first frame
            if recordingStartTime == nil {
                recordingStartTime = timestamp
                assetWriter.startWriting()
                assetWriter.startSession(atSourceTime: timestamp)
                print("Started writing video at timestamp: \(timestamp.seconds)")
            }
            
            // Append the sample buffer
            if assetWriterInput.isReadyForMoreMediaData {
                assetWriterInput.append(sampleBuffer)
            }
        }
    }
}
