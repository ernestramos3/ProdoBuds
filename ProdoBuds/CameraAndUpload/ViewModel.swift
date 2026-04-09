//
//  ViewModel.swift
//  ProdoBuds
//
//  Created by Jean-Claude Bissou on 3/7/26.
//

import Foundation
import CoreImage
import Observation
import Photos

@Observable
class ViewModel {
    var currentFrame: CGImage?
    var isRecording = false
    var elapsedTime: String = "00:00"
    var fps: Double = 0.0
    var lastSavedVideoURL: URL?
    
    /// Called on the main actor when recording finishes and video is saved.
    /// Intended for UIKit/SwiftUI view controllers to present the upload screen.
    var onRecordingFinished: ((URL) -> Void)?
    
    private let cameraManager = CameraManager()
    private var recordingStartTime: Date?
    private var timerTask: Task<Void, Never>?
    
    init() {
        // Initialize fps with current capture FPS from CameraManager
        fps = Double(cameraManager.captureFPS)
        
        Task {
            await handleCameraPreviews()
        }
    }
    
    func handleCameraPreviews() async {
        for await image in cameraManager.previewStream {
            Task { @MainActor in
                currentFrame = image
            }
        }
    }
    
    @MainActor
    func startRecording() {
        guard !isRecording else { return }
        
        isRecording = true
        recordingStartTime = Date()
        
        // Start actual video recording
        cameraManager.startRecording()
        
        // Start the timer
        timerTask = Task {
            while !Task.isCancelled {
                if let startTime = recordingStartTime {
                    let elapsed = Date().timeIntervalSince(startTime)
                    updateElapsedTime(elapsed)
                }
                
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
        
        print("Recording started")
    }
    
    @MainActor
    func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        timerTask?.cancel()
        timerTask = nil
        
        // Stop actual video recording and pass to UploadVideoView
        cameraManager.stopRecording { [weak self] url in
            guard let self = self else { return }
            
            if let url = url {
                Task { @MainActor in
                    self.lastSavedVideoURL = url
                    // Pass video URL to UploadVideoView where user can draft or upload
                    self.onRecordingFinished?(url)
                    print("Video recorded at: \(url.path)")
                }
            } else {
                print("Failed to record video")
            }
        }
        
        // Reset timer
        elapsedTime = "00:00"
        recordingStartTime = nil
        
        print("Recording stopped")
    }
    
    @MainActor
    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }
    
    @MainActor
    private func updateElapsedTime(_ timeInterval: TimeInterval) {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        elapsedTime = String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - FPS Configuration
    
    @MainActor
    func setCaptureFPS(_ fps: Int32) {
        cameraManager.setCaptureFPS(fps)
        // Update the displayed fps value
        self.fps = Double(fps)
    }
    
    @MainActor
    func getCurrentCaptureFPS() -> Int32 {
        return cameraManager.captureFPS
    }
    
    // MARK: - Photo Library
    
    private func saveToPhotosLibrary(url: URL) async {
        let status = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        
        var authorized = status == .authorized
        
        if status == .notDetermined {
            authorized = await PHPhotoLibrary.requestAuthorization(for: .addOnly) == .authorized
        }
        
        guard authorized else {
            print("Photo library access denied")
            return
        }
        
        do {
            try await PHPhotoLibrary.shared().performChanges {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }
            print("Video saved to Photos library successfully")
        } catch {
            print("Failed to save video to Photos library: \(error.localizedDescription)")
        }
    }
}
